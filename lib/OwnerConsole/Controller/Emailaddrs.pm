package OwnerConsole::Controller::Emailaddrs;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util              qw(flat :validate new_token);
use OwnerConsole::Proof::EmailAddr1 ();
use OwnerConsole::Challenge         ();
use OwnerConsole::AjaxAnswer        ();

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

sub configProof()
{   my $self     = shift;
	my $answer   = OwnerConsole::AjaxAnswer->new();

	my $req      = $self->req;
	my $how      = $req->url->query;

	my $account  = $self->account;
	my $proofid  = $self->param('proofid');
	my $params   = $req->json || $req->body_params->to_hash;
warn "#1 $proofid";
use Data::Dumper;
warn 'PARAMS=', Dumper $params;
	my $is_new   = $proofid eq 'new';

	my $proof;
	if($is_new)
	{	$proof = OwnerConsole::Proof::EmailAddr1->create({owner => $account});
	}
	else
	{	unless($proof = $account->proof(emailaddrs => $proofid))
		{	$answer->notify(__x"Proof has disappeard");
			$answer->redirect('/dashboard/emailaddrs');
    		return $self->render(json => $answer->data);
		}
	}

	if($how eq 'reown')
	{	my $ownerid = $params->{new_owner};
warn "OID=$ownerid";
		$proof->changeOwner($account, $ownerid);
		$proof->save;
    	return $self->render(json => $answer->data);
	}

	# Validate
	my $data    = $proof->_data;
	my $needs_confirm = $is_new;

	if($is_new)
	{	# Cannot change email-address unless a new proof is created
    	if(not $data->{email} = is_valid_email(delete $params->{email}))
    	{   $answer->addError(email => __x"Invalid email-address");
    	}
	}

	my $subaddr = (delete $params->{subaddr} // 'no') eq 'yes' // 0;
	if($is_new || $subaddr ne $data->{sub_addressing})
	{	$data->{sub_addressing} = $subaddr;
		$needs_confirm++;
	}

	my $ownerid = delete $params->{owner} or error __x"No owner";
	if($is_new || $ownerid ne $proof->ownerId)
	{	$data->{ownerid} = $ownerid;
		# Does not need to verify again
	}

warn "PROOF=", Dumper $data;
    if($how eq 'save' && ! $answer->hasErrors)
	{	$proof->save(by_user => 1);
		if($needs_confirm)
		{	$self->_startVerification($account, proof => $proof);
			$answer->notify(__x"Follow the instructions in the email.");
		}
		$answer->redirect('/dashboard/emailaddrs');
    }

	warn "Unprocessed parameters: ", join ', ', sort keys %$params if keys %$params;

    $self->render(json => $answer->data);
}

#--------------------
=section Email verification
=cut

sub _startVerification($$%)
{	my ($self, $account, %args) = @_;
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

# The user has received an (email address) verification token.
# For now, there is only one process which uses the challenge.  Later, we may need to
# create a separate controller for this.

my %challenge_handlers = (
	proof_emailaddr1 => 'challengeEmailaddr1',
);

sub challenge()
{	my $self     = shift;
	my $token    = $self->param('token');

	my $challenge = $::app->proofs->challenge($token);
	unless($challenge)
	{	$self->notify(__"The challenge does not exist (anymore).");
		return $self->redirect_to('/dashboard');
	}

	if($challenge->hasExpired)
	{	# Expired, but still visible
		$self->notify(__"The challenge has expired.");
		return $self->redirect_to('/dashboard');
	}

	my $account  = $self->account;
	unless($challenge->isFor($account))
	{	# Wrong person tries to use challenge
		$self->notify(__"The challenge is not for you.");
		return $self->redirect_to('/dashboard');
	}

	my $purpose = $challenge->purpose;
	my $handler = $challenge_handlers{$purpose};
	unless($handler)
	{	$self->notify(__x"Unimplemented purpose '{purpose}'.", purpose => $purpose);
		return $self->redirect_to('/dashboard');
	}

	$self->$handler($account, $challenge);
}

sub challengeEmailaddr1($$)
{	my ($self, $account, $challenge) = @_;
	my $payload = $challenge->payload;
	my $proof = $::app->proofs->proof($payload->{proofid});

	unless($proof)
	{	$self->notify(__x"Proof has disappeared");
		return $self->redirect_to('/dashboard');
	}
	$proof->accepted;
	$self->redirect_to('/dashboard/emailaddrs');
}

1;
