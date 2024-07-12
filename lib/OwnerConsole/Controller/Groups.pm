# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Groups;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util    qw(:validate);
use OpenConsole::Group   ();

use OwnerConsole::Tables qw(:is_valid);
use OwnerConsole::Email  ();

sub index($)
{	my $self = shift;
	$self->render(template => 'groups/index');
}

sub group($)
{	my ($self, %args) = @_;
	my $groupid  = $self->param('groupid');

	my $account  = $self->account;
	my $group = $groupid eq 'new' ? OpenConsole::Group->create($account) : $account->group($groupid);
	$self->render(template => 'groups/group', group => $group);
}

### Keep this logic in sync with OpenConsole::Group attributes

sub _acceptGroup($$)
{	my ($self, $session, $group) = @_;

	$group->setData(
		name         => val_line $session->requiredParam('name'),
		fullname     => val_line $session->optionalParam('fullname'),
		organization => val_line $session->optionalParam('organization'),
		department   => val_line $session->optionalParam('department'),
		postal       => val_text $session->optionalParam('postal'),
	);

	my $lang = $session->optionalParam(language => '');
	! length $lang || is_valid_language $lang
		or $session->addError(lang => __x"Unsupported language '{code}'", code => $lang);
	$group->setData(language => $lang);

	my $country = $session->optionalParam(country => '');
	! length $country || is_valid_country $country
		or $session->addError(country => __x"Invalid country");
	$group->setData(country => $country);

	my $tz = $session->optionalParam(timezone => '');
	! length $tz || is_valid_timezone $tz
		or $session->addError(timezone => __x"Unsupported time-zone '{tz}'", tz => $tz);
	$group->setData(timezone => $tz);

	my $email = val_line $session->optionalParam(email => undef);
	! defined $email || is_valid_email $email
		or $session->addError(email => __x"Invalid email address");
	$group->setData(email => $email);

	my $phone = val_line $session->optionalParam(phone => undef);
	! defined $phone || is_valid_phone $phone
		or $session->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");
	$group->setData(phone => $phone);

	$self;
}

sub configGroup()
{	my $self     = shift;
	my $session  = $self->ajaxSession;
	my $how      = $session->query || 'validate';

	my $account  = $self->account;
	my $group    = $self->openObject($session, 'OpenConsole::Group', groupid => sub { $account->group($_[0]) })
		or error __x"Group has disappeared.";

	my $is_new   = $group->groupId eq 'new';
	$how eq 'validate' || $is_new || $group->memberIsAdmin($account)
		or error __x"Tried to modify group '{id}', not being admin.", id => $group->groupId;

	if($how eq 'delete') {
		$::app->users->removeGroup($group);
		$::app->batch->removeEmailsRelatedTo($group->groupId);

		$account->removeGroup($group);
		$account->save;

		$session->redirect('/dashboard/groups');
		return $session->reply;
	}


	$self->acceptFormData($session, $group, '_acceptGroup');

	if($how eq 'save' && $session->isHappy)
	{	$group->save(by_user => 1);
		$account->save(by_user => 1);

		if($is_new)
		{	$session->notify(info => __x"New group created");
			$account->addGroup($group);
			$account->save;
		}
		$session->redirect('/dashboard/groups');
	}

	$session->checkParamsUsed->reply;
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
{	my $self     = shift;
	my $session  = $self->ajaxSession;
	my $how      = $session->query || '(unspecified)';

	my $account  = $self->account;

	my $groupid  = $session->about('groupid');
   	my $group    = $account->group($groupid);
	unless($group)
	{	# or not linked to this account (anymore)
	    $session->addError(invite => __x"This group seems to have disappeared");
		return $session->reply;
	}

	my $identity = $group->memberIdentityOf($account)
		or error __x"Group identity disappeared.";

	if($how eq 'change_identity')
	{	my $identid = $session->requiredParam('identid');
		if($group->changeIdentity($account, $identid))
		{	$group->save;  # when change is permitted
		}
		return $session->reply;
	}

	if(! $group->memberIsAdmin($account))
	{	$session->addError(invite => __x"You are not admin for this group.");
	}
	elsif($how eq 'invite_remove')
	{	my $email = $session->requiredParam('email');
	 	my $token = $session->requiredParam('token');
		if($self->removeInvitation($group, $token))
		{	$group->log("removed invitation to $email");
			$group->save;
		}
		else
		{	$session->addError(invite => __x"This invitation cannot be removed.");
		}
	}
	elsif($how eq 'invite_new')
	{	my $emails = val_line $session->requiredParam('emails');
		my @emails = split /[, ]+/, $emails // '';
		my @added;
		foreach my $email (@emails)
		{	unless(is_valid_email $email)
			{	$session->addWarning(invite_emails => __x"Incorrect email-address '{addr}' skipped", addr => $email);
				next;
			}

			if($group->findMemberWithEmail($email))
			{	$session->addWarning(invite_emails => __x"The person with email-address '{addr}' is already a member", addr => $email);
				next;
			}

			push @added, $email;
			my $invite = OwnerConsole::Group::Invite->create($identity, $self, $email);
			$::app->batch->saveInvite($invite);
			$group->log("invited $email");

			$group->save;
			$self->_emailInvite(invite => $invite, identity => $identity, group => $group,
				subject => (__x"Your are invited to take part in group '{name}'", name => $group->name));
		}
		$session->setData(added => \@added);
	}
	elsif($how eq 'invite_resend')
	{	my $email = $session->requiredParam('email');
	 	my $token = $session->requiredParam('token');
		if(my $invite = $self->extendInvitation($group, $token))
		{	$self->_sendInvite(invite => $invite, identity => $identity, group => $group,
				subject => (__x"Your invitation to group '{group}' got extended", group => $group->name));
			$group->log("extended the invitation for $email");
		}
		else
		{	$session->addWarning(invite_emails => (__x"Missing invite for '{email}'.", email => $email));
		}
	}
	else
	{	error __x"No action '{action}' for invite.", id => $group->groupId;
	}

	$session->reply;
}

#!!! Outside, so no $account
sub inviteChoice()
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
	else { panic "inviteChoice:$how#".length($how) }

	$self->render(template => 'groups/invite_choice', invite => $invite);
}

sub allInvites($)
{	my ($self, $group) = @_;
	my $inv = $::app->batch->invitesForGroup($group);
	@$inv;
}

sub inviteWithToken($$)
{	my ($self, $group, $token) = @_;
	defined $token or return ();
	first { lc($_->token) eq lc($token) } $self->allInvites($group);
}

sub extendInvitation($$)
{	my ($self, $group, $token) = @_;
	my $invite = $self->inviteWithToken($group, $token) or return;
	$invite->extend;
	$invite->save;
}

sub removeInvitation($$)
{	my ($self, $group, $token) = @_;
	my $invite = $self->inviteWithToken($token) or return 1;
	return 0 if $invite->state eq 'spam';

	delete $self->{OCG_invites};
	$::app->batch->removeInvite($token);
	1;
}

#!!! Inside, so with $account
sub inviteAccept()
{	my $self    = shift;
	my $token   = $self->param('token');
	my $invite  = $::app->batch->invite($token)
		or return $self->render(template => 'groups/invite_failed');

	my $account = $self->account;
	if(my $identity  = $account->preferredIdentity)
	{	if(my $group = $invite->invitedTo)
		{	$group->addMember($account, $identity);
			$account->addGroup($group);
			$group->save;
			$account->save;
			$invite->changeState('accept');
		}
		else
		{	$self->notify(error => __x"Sorry, the group seems to have disappeared.");
		}
	}
	else
	{	$self->notify(error => __x"First create an identity, then accept again.");
		return $self->render(template => 'identities/index');
	}

	$self->render(template => 'groups/index');
}

1;
