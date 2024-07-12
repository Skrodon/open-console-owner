# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use List::Util    qw(first);

use OpenConsole::Session::Ajax ();

sub ajaxSession(%)
{	my ($self, %args) = @_;
	OpenConsole::Session::Ajax->create(\%args, controller => $self);
}

#-------------
=section Generic code for any database object loading
=cut

sub acceptFormData($$$)
{	my ($self, $session, $object, $handler) = @_;

	try {
		$self->$handler($session, $object);
	};

	$session->notify(error => $_) for $@->exceptions;
	$self;
}

sub acceptObject($$)
{	my ($self, $session, $proof) = @_;
	$self;
}

sub openObject($$$$)
{	my ($self, $session, $objclass, $idlabel, $get) = @_;
	my $objid = $session->about($idlabel) or panic $idlabel;

	return $objclass->create($self->account)
		if $objid eq 'new';

	my $object = $get->($objid);
	unless($object)
	{	$session->internalError(__x"The object has disappeared.");
		return undef;
	}

	$object;
}

#-------------
=section Generic code for Proofs
=cut

sub acceptProof($$)
{	my ($self, $session, $proof) = @_;
	$self;
}

sub openProof($$)
{	my ($self, $session, $objclass) = @_;
	my $proofid = $session->about('proofid');

  	if($proofid eq 'new')
	{	trace "Create new $objclass proof";
		return $objclass->create({ owner => $self->account })
	}

	my $proof = $self->account->proof($objclass->set, $proofid);
	unless($proof)
	{	info "Proof $proofid of type $objclass has disappeared.";
	$session->internalError(__x"Proof has disappeared.");
		return undef;
	}

	$proof;
}

my %proof_status = (    # translatable name, bg-color
	unproven => [ __"Unproven",   'warning' ],
	verify   => [ __"Verifying",  'info'    ],
	refresh  => [ __"Refreshing", 'info'    ],
	proven   => [ __"Proven",     'success' ],
	expired  => [ __"Expired",    'dark'    ],
);

sub proofStatusText($;$)
{	my ($self, $proof, $label) = @_;
	$label  ||= $proof->status;
	my $repr  = $proof_status{$label} or return "XX${label}XX";
	$repr->[0]->toString;
}

# Returns a badge color class: https://getbootstrap.com/docs/5.3/components/badge/
sub proofStatusBgColorClass($;$)
{	my ($self, $proof, $label) = @_;
	$label ||= $proof->status;
	my $repr  = $proof_status{$label} or return 'text-bg-danger';
	'text-bg-' . $repr->[1];
}

#-------------
=section Generic code for Challenges

The "challenge dispatcher".
=cut

my %challenge_handlers;
sub challengeHandler($$)
{	my ($class, $purpose, $method) = @_;
	$class->isa(__PACKAGE__) or panic;

	$challenge_handlers{$purpose} = sub {
		my $self = (bless shift, $class);  # upgrade
		$self->$method(@_);
	};
}

sub challenge()
{	my $self     = shift;
	my $token    = $self->param('token');

	my $challenge = $::app->proofs->challenge($token);
	unless($challenge)
	{	$self->notify(warning => __"The challenge does not exist (anymore).");
		return $self->redirect_to('/dashboard');
	}

	if($challenge->hasExpired)
	{	# Expired, but still visible
		$self->notify(info => __"The challenge has expired.");
		return $self->redirect_to('/dashboard');
	}

	my $account  = $self->account;
	unless($challenge->isFor($account))
	{	# Wrong person tries to use challenge
		$self->notify(error => __"The challenge is not for you.");
		return $self->redirect_to('/dashboard');
	}

	my $purpose = $challenge->purpose;
	my $handler = $challenge_handlers{$purpose};
	unless($handler)
	{	$self->notify(error => (__x"Unimplemented purpose '{purpose}'.", purpose => $purpose));
		return $self->redirect_to('/dashboard');
	}

	$self->$handler($account, $challenge);
}

#-------------
=section Running tasks

=method taskStart $session, $taskname, \%params, %options;
=cut

sub taskStart($$$%)
{	my ($self, $session, $taskname, $params, %args) = @_;
	$params->{lang} ||= $session->lang;
	my ($taskid, $state) = $::app->tasks->$taskname($session, $params);
warn "Started task $taskname in $taskid\n";

	if(my $poll = delete $args{poll})
	{	$session->pollFor($poll, $taskid);
	}

	$taskid;
}

=method taskPoll $session, $taskid, %options
=cut

sub taskPoll($%)
{	my ($self, $session, $taskid, %args) = @_;
	$::app->tasks->ping($session, $taskid);
}

=method taskEnded $session, $options
Flag the user's browser that polling can stop.
=cut

sub taskEnded($%)
{	my ($self, $session, %args) = @_;
	$session->stopPolling;
}

#-------------
=section Other

=method detectLanguage
Returns the preferred interface language for a user, based on its previous
choice.  Defaults from the user's browser settings.
=cut

my ($iflangs, $langs);
sub detectLanguage()
{	my $self  = shift;
	if(my $if = $self->session('iflang')) { return $if }

    $iflangs ||= $self->config->{interface_languages};
warn "IFLANGS=@$iflangs";
    $langs   ||= +{ map +($_ => 1), @$iflangs };

	my @wants = $self->browser_languages;
	my $code  = first { exists $langs->{$_} } @wants;

	unless($code)
	{	my @langs = map language_name($_), @wants;
#XXX notify is not shows
		$self->notify(warning => __x("None of the languages configured in your browser ({langs}) is supported for the Open Console interface at the moment.", langs => \@langs));
		$code = $iflangs->[0];
	}

	$self->session(iflang => $code);
	$code;
}

1;
