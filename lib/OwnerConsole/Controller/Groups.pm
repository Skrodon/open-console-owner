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

sub submit_group($)
{   my $self = shift;
	my $answer  = OwnerConsole::AjaxAnswer->new();

	my $req     = $self->req;
	my $how     = $req->url->query;

#use Data::Dumper;
#warn "GROUP QUERY=$how";

	my $account  = $self->account;
	my $id       = $self->param('groupid');

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

	my $email = $data->{email} = val_line(delete $params->{email});
	! defined $email || is_valid_email $email
		or $answer->addError(email => __x"Invalid email address");

	my $phone = $data->{phone} = val_line delete $params->{phone};
	! defined $phone || is_valid_phone $phone
		or $answer->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");

	my $postal = $data->{postal} = val_text delete $params->{postal};

#warn "Unprocessed parameters: ", join ', ', sort keys %$params if keys %$params ;
#warn "DATA OUT =", Dumper $data;

	if($how eq 'save' && ! $answer->hasErrors)
	{	$answer->redirect('/dashboard/groups');  # order browser to redirect
#warn "SAVING GROUP";
#warn Dumper $self->users->allGroups;
		$group->save(by_user => 1);
#warn "DONE SAVING";
#warn Dumper $self->users->allGroups;
		$account->addGroup($group);

		$self->notify(info => __x"New group created") if $id eq 'new';
	}

    $self->render(json => $answer->data);
}

sub _sendInvitation($$)
{	my ($self, $invite, $group, %args) = @_;
	@args{keys %$invite} = values %$invite;

	my $email = OwnerConsole::Email->create(
		templates => 'group/mail_invite',
		text    => $self->render_to_string('group/mail_invite', format => 'txt'),
		html    => $self->render_to_string('group/mail_invite', format => 'html'),
		sender  => $self->account,
		sendto  => $args{sendto},
		purpose => 'invite',
		state   => $args{state},
	);

	$email;
}

has invite_expiration => sub {
my $x =
 ($_[0]->config->{groups}{invite_expiration} || 7) * 86400
; warn "EXPIRE AFTER $x"; $x };

sub submit_member($)
{   my $self = shift;
	my $answer  = OwnerConsole::AjaxAnswer->new();

	my $req     = $self->req;
	my $how     = $req->url->query;

use Data::Dumper;
#warn "INVITE QUERY=$how";

	my $account  = $self->account;
	my $id       = $self->param('groupid');
	my $params   = $req->json || $req->body_params->to_hash;
#warn Dumper $params;

   	my $group = $account->group($id);
	if(! $group)
	{	# or not linked to this account (anymore)
        $answer->addError(invite_emails => __x"This group seems to have disappeared");
	}
	elsif($how eq 'invite_remove')
	{	my $email = $params->{email};
		$group->removeInvitation($email);
		$group->log("removed invitation to $email");
		$group->save;
	}
	elsif($how eq 'invite_new')
	{	my @emails = split /[, ]+/, val_line($params->{emails}) || '';
		my $expire = $self->invite_expiration;
		my @added;
		foreach my $email (@emails)
		{	unless(is_valid_email $email)
			{	$answer->addWarning(invite_emails => __x"Incorrect email address '{addr}' skipped", addr => $email);
				next;
			}
			push @added, $email;
			my $invite = $group->inviteMember($email, expiration => $expire);
			$group->log("invited $email");
			$group->save;
			$self->_sendInvitation($invite, sendto => $email, group => $group, state => 'invite_start');
		}
		$answer->data->{added} = \@added;
	}
	elsif($how eq 'invite_resend')
	{	my $email  = $params->{email};
		my $invite = $group->extendInvitation($email, $self->invite_expiration);
		$group->log("extended the invitation for $email");
		$group->save;
		$self->_sendInvitation($invite, sendto => $email, group => $group, state => 'invite_resend');
	}
	else
	{	error __x"No action '{action}' for invite.", id => $id;
	}

    $self->render(json => $answer->data);
}

1;
