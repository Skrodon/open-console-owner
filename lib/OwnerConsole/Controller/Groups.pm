package OwnerConsole::Controller::Groups;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util   qw(flat :validate);
use OwnerConsole::Email  ();

sub index($)
{   my $self = shift;
    $self->render(template => 'groups/index');
}

sub group($)
{   my ($self, %args) = @_;
	my $groupid  = $self->param('groupid');

	my $account  = $self->account;
	my $group = $groupid eq 'new' ? OwnerConsole::Group->create($account) : $account->group($groupid);
    $self->render(template => 'groups/group', group => $group);
}

### Keep this logic in sync with OwnerConsole::Group attributes

sub configGroup($)
{   my $self   = shift;
	my $answer = OwnerConsole::AjaxAnswer->new();

	my $req    = $self->req;
	my $how    = $req->url->query;

#use Data::Dumper;
#warn "GROUP QUERY=$how";

	my $account = $self->account;
	my $id      = $self->param('groupid');

	my $group;
	if($id eq 'new')
	{	$group = OwnerConsole::Group->create($account);
	}
	else
	{	$group = $account->group($id)
			or error __x"Tried to access group '{id}'", id => $id;
	}

	if($how eq 'delete') {
		$::app->users->removeGroup($group);
		$::app->emails->removeOutgoingRelatedTo($group->groupId);
		$account->removeGroup($group);
		$answer->redirect('/dashboard/groups');
    	return $self->render(json => $answer->data);
	}

	my $params = $req->json || $req->body_params->to_hash;
	my $data   = $group->_data;

#warn "PARAMS=", Dumper $params;
#warn "DATA IN =", Dumper $data;

	my $name = $data->{name} = val_line delete $params->{name};
	defined $name
		or $answer->addError(name => __x"The name name is required, used in the overviews.");

	$data->{fullname}     = val_line delete $params->{fullname};

	my $lang              = delete $params->{language} || '';
	$data->{language}     = length $lang ? $lang : undef;
	! length $lang || is_valid_language($lang)
		or $answer->addError(lang => __x"Unsupported language '{code}'", code => $lang);

	$data->{organization} = val_line delete $params->{organization};
	$data->{department}   = val_line delete $params->{department};

	my $tz = $data->{timezone} = delete $params->{timezone};
	! defined $tz || is_valid_timezone($tz)
		or $answer->addError(timezone => __x"Unsupported time-zone '{timezone}'", timezone => $tz);

	my $email = $data->{email} = val_line(delete $params->{email});
	! defined $email || is_valid_email $email
		or $answer->addError(email => __x"Invalid email address");

	my $phone = $data->{phone} = val_line delete $params->{phone};
	! defined $phone || is_valid_phone $phone
		or $answer->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");

	my $postal = $data->{postal} = val_text delete $params->{postal};


warn "Unprocessed parameters: ", join ', ', sort keys %$params if keys %$params;

	if($how eq 'save' && ! $answer->hasErrors)
	{	$answer->redirect('/dashboard/groups');  # order browser to redirect
		$group->save(by_user => 1);
		$account->addGroup($group);

		$self->notify(info => __x"New group created") if $id eq 'new';
	}

    $self->render(json => $answer->data);
}

sub _emailInvite(%)
{	my ($self, %args) = @_;
	my $invite = $args{invite};

    OwnerConsole::Email->create(
        subject => $args{subject},
        text    => $self->render_to_string('groups/mail_invite', format => 'txt', %args),
        html    => $self->render_to_string('groups/mail_invite', format => 'html', %args),
        sender  => $args{identity} || $invite->invitedBy,
        sendto  => $invite->email,
        purpose => 'invite',
    )->queue;
}

sub configMember()
{   my $self    = shift;
	my $answer  = OwnerConsole::AjaxAnswer->new();

	my $req     = $self->req;
	my $how     = $req->url->query;

use Data::Dumper;
#warn "INVITE QUERY=$how";

	my $account  = $self->account;
	my $id       = $self->param('groupid');
	my $params   = $req->json || $req->body_params->to_hash;

   	my $group    = $account->group($id);
	my $identity = $group->memberIdentityOf($account);

	if(! $group)
	{	# or not linked to this account (anymore)
        $answer->addError(invite => __x"This group seems to have disappeared");
	}
	elsif($how eq 'invite_remove')
	{	my $email = $params->{email};
	 	my $token = $params->{token};
		if($group->removeInvitation($token))
		{	$group->log("removed invitation to $email");
			$group->save;
		}
		else
		{	$answer->addError(invite => __x"This invitation cannot be removed.");
		}
	}
	elsif($how eq 'invite_new')
	{	my @emails = split /[, ]+/, val_line($params->{emails}) || '';
		my @added;
		foreach my $email (@emails)
		{	unless(is_valid_email $email)
			{	$answer->addWarning(invite_emails => __x"Incorrect email-address '{addr}' skipped", addr => $email);
				next;
			}

			if($group->findMemberWithEmail($email))
			{	$answer->addWarning(invite_emails => __x"The person with email-address '{addr}' is already a member", addr => $email);
				next;
			}

			push @added, $email;
			my $invite = $group->inviteMember($identity, $email);
			$group->log("invited $email");
			$group->save;
			$self->_emailInvite(invite => $invite, identity => $identity, group => $group,
				subject => (__x"Your are invited to take part in group '{name}'", name => $group->name));
		}
		$answer->data->{added} = \@added;
	}
	elsif($how eq 'invite_resend')
	{	my $email  = $params->{email};
		my $token  = $params->{token};
		if(my $invite = $group->extendInvitation($token))
		{	$self->_sendInvite(invite => $invite, identity => $identity, group => $group,
				subject => (__x"Your invitation to group '{group}' got extended", group => $group->name));
			$group->log("extended the invitation for $email");
		}
		else
		{	$answer->addWarning(invite_emails => (__x"Missing invite for '{email}'.", email => $email));
		}
	}
	elsif($how eq 'change_identity')
	{	my $identid = $params->{identid};
		if($group->changeIdentity($account, $identid))
		{	$group->save;  # when change is permitted
		}
	}
	else
	{	error __x"No action '{action}' for invite.", id => $id;
	}
    $self->render(json => $answer->data);
}

#!!! Outside, so no $account
sub invite_choice()
{	my $self   = shift;
	my $token  = $self->param('token');
	my $invite = $::app->batch->invite($token)
		or return $self->render(template => 'groups/invite_failed');

	my $how    = $self->req->url->query;
	if($how eq '' || $how eq 'show') { }
	elsif($how eq 'reject')
	{	$invite->changeState('reject');
		$self->notify(info => __x"You have rejected the this invitation: a signal to the sender you did not like it.");
	}
	elsif($how eq 'ignore')
	{	$invite->changeState('ignore');
		$self->notify(info => __x"You choose to ignore this invitation.");
	}
	elsif($how eq 'spam')
	{	$invite->changeState('spam');
		$self->notify(warning => __x"You expressed you did not like to receive this invitation.  The statement will hinder the sender inviting new members for some time.");
	}
	else { panic "invite_choice:$how#".length($how) }

    $self->render(template => 'groups/invite_choice', invite => $invite);
}

#!!! Inside, so with $account
sub inviteAccept()
{	my $self   = shift;
	my $token  = $self->param('token');
	my $invite = $::app->batch->invite($token)
		or return $self->render(template => 'groups/invite_failed');

	my $account  = $self->account;
	if(my $identity = $account->preferredIdentity)
	{	if(my $group    = $invite->invitedTo)
		{	$group->addMember($account, $identity);
			$invite->changeState('accept');
		}
		else
		{	$self->notify(error => __x"Sorry, the group seems to have disappeared.");
		}
	}
	else
	{	$self->notify(error => __x"First create an identity, then accept again.");
	}

	$self->render(template => 'groups/index');
}

1;
