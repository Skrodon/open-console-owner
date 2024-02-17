package OwnerConsole::Controller::Emailaddrs;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util              qw(flat :validate new_token);
use OwnerConsole::Proof::EmailAddr1 ();
use OwnerConsole::Challenge         ();

sub index()
{   my $self = shift;
	$self->render(template => 'emailaddrs/index');
}

sub emailaddr(%)
{   my ($self, %args) = @_;
	my $proofid  = $self->param('proofid');
	my $account  = $self->account;
	my $proof    = $proofid eq 'new'
	  ? OwnerConsole::Proof::EmailAddr1->create({owner => $account})
	  : $account->proof(emailaddrs => $proofid);

warn "PAGE EDIT PROOF $proofid, $proof.";

	$self->render(template => 'emailaddrs/algo1', proof => $proof );
}

sub acceptEmailaddr1()
{	my ($self, $session, $proof) = @_;
	$self->acceptProof($session, $proof);

	no warnings 'uninitialized';

	my $email   = $session->optionalParam('email');
	if($proof->isNew)
	{	# Cannot change email-address unless a new proof is created
		if(my $cleaned = is_valid_email $email)
		{	$proof->setData(email => $cleaned) && $proof->invalidate;
		}
		else
		{	$session->addError(email => defined $email
			  ? (__x"Invalid email address.")
			  : (__x"Email address is required."));
		}
	}
	elsif(defined $email && $email ne $proof->email)
	{	$session->addError(email => __x"Attempt to change email address.");
	}

	my $subaddr = $session->optionalParam(subaddr => 'no');
	$proof->setData(sub_addressing => $subaddr) && $proof->invalidate;
	$self;
}

sub configEmailaddr()
{   my $self     = shift;
	my $session  = $self->ajaxSession;

	my $proof    = $session->openProof('OwnerConsole::Proof::EmailAddr1')
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
	}

	$self->acceptFormData($session, $proof, 'acceptEmailaddr1');

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

__PACKAGE__->challengeHandler(proof_emailaddr1 => 'challengeEmailaddr1');

sub _startVerification1($%)
{	my ($self, %args) = @_;
	my $account   = $self->account;
	my $proof     = $args{proof};
	my $challenge = $args{challenge} = OwnerConsole::Challenge->create($account,
	  {	purpose => 'proof_emailaddr1',
		payload => { proofid => $proof->proofId },
	  },
	);
	$challenge->save;

	OwnerConsole::Email->create(
		subject => __"Proof email address ownership",
		text    => $self->render_to_string('emailaddrs/mail_challenge', format => 'txt', %args),
		html    => $self->render_to_string('emailaddrs/mail_challenge', format => 'html', %args),
		sender  => $proof->identity($account),
		sendto  => $proof->email,
		purpose => 'proof_emailaddr',
	)->queue;
}

sub challengeEmailaddr1($$)
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