# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Emailaddrs;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw(flat :validate new_token);
use OpenConsole::Proof::EmailAddr ();

use OwnerConsole::Challenge ();
use OwnerConsole::Email     ();

sub index()
{   my $self = shift;
	$self->render(template => 'emailaddrs/index');
}

sub emailaddr(%)
{   my ($self, %args) = @_;
	my $proofid  = $self->param('proofid');
	my $account  = $self->account;
	my $proof    = $proofid eq 'new'
	  ? OpenConsole::Proof::EmailAddr->create({owner => $account})
	  : $account->proof(emailaddrs => $proofid);

warn "PAGE EDIT PROOF $proofid, $proof.";

	$self->render(template => 'emailaddrs/emailaddr', proof => $proof );
}

sub _acceptEmailaddr()
{	my ($self, $session, $proof) = @_;
	$self->acceptProof($session, $proof);

	no warnings 'uninitialized';

	my $email   = $session->optionalParam('email');
	if($proof->isNew)
	{	# Cannot change email-address unless a new proof is created
		if(! defined $email || $email eq '')
		{	$session->addError(email => __x"Email address is required.");
		}
		elsif(is_valid_email $email)
		{	$proof->setData(email => $email) && $proof->invalidate;
		}
		else
		{	$session->addError(email => __x"Invalid email address.");
		}
	}
	elsif(defined $email && $email ne $proof->email)
	{	$session->addError(email => __x"Attempt to change email address.");
	}

	my $subaddr = $session->optionalParam(subaddr => 'no');
	$proof->setData(sub_addressing => ($subaddr eq 'yes' || 0)) && $proof->invalidate;
	$self;
}

sub configEmailaddr()
{   my $self     = shift;
	my $session  = $self->ajaxSession;

	my $proof    = $self->openProof($session, 'OpenConsole::Proof::EmailAddr')
		or $session->reply;

	my $how      = $session->query;
warn "HOW=$how";
	if($how eq 'reown')
	{	my $ownerid = $session->requiredParam('new_owner');
		$proof->changeOwner($session->account, $ownerid);
		$proof->save;
		return $session->reply;
	}

	if($how eq 'delete')
	{	$proof->delete;
		$session->notify(info => __x"Proof for Email address '{email}' removed.", email => $proof->email);
		$session->redirect('/dashboard/emailaddrs');
		return $session->reply;
	}

	$self->acceptFormData($session, $proof, '_acceptEmailaddr');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		if($proof->isInvalid)
		{	$self->_startVerification1(proof => $proof);
			$session->notify(info => __x"Follow the instructions in the email.");
		}
		$session->redirect('/dashboard/emailaddrs');
	}

	$session->checkParamsUsed->reply;
}

#--------------------
=section Email verification
=cut

__PACKAGE__->challengeHandler(proof_emailaddr => 'challengeEmailaddr');

sub _startVerification1($%)
{	my ($self, %args) = @_;
	my $account   = $self->account;
	my $proof     = $args{proof};
	my $challenge = $args{challenge} = OwnerConsole::Challenge->create($account,
	  {	purpose => 'proof_emailaddr',
		payload => { proofid => $proof->proofId },
	  },
	);
	$challenge->save;

	my $email     = $proof->email;
	$email =~ s/\@/+oc@/ if $proof->supportsSubAddressing;

	OwnerConsole::Email->create(
		subject => __"Proof email address ownership",
		text    => $self->render_to_string('emailaddrs/mail_challenge', format => 'txt', %args),
		html    => $self->render_to_string('emailaddrs/mail_challenge', format => 'html', %args),
		sender  => $proof->identity($account),
		sendto  => $email,
		purpose => 'proof_emailaddr',
	)->queue;
}

sub challengeEmailaddr($$)
{	my ($self, $account, $challenge) = @_;
	my $payload = $challenge->payload;
	my $proof = $::app->proofs->proof($payload->{proofid});

	unless($proof)
	{	$self->notify(error => __x"The proof has disappeared.");
		return $self->redirect_to('/dashboard');
	}

	$proof->accepted;
	$proof->save;
	$self->redirect_to('/dashboard/emailaddrs');
}

1;
