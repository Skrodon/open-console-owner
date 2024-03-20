# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::AjaxSession ();

sub ajaxSession(%)
{	my ($self, %args) = @_;
	OwnerConsole::AjaxSession->new(controller => $self, %args);
}

#-------------
=section Generic code for any database object loading
=cut

sub acceptFormData($$$)
{	my ($self, $session, $object, $handler) = @_;

	try {
		$self->$handler($session, $object);
	};

	$session->notify(error => $_->message->toString)
		for $@->exceptions;

	$self;
}

sub acceptObject($$)
{	my ($self, $session, $proof) = @_;
	$self;
}

#-------------
=section Generic code for Proofs
=cut

sub acceptProof($$)
{	my ($self, $session, $proof) = @_;
	$self;
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

1;
