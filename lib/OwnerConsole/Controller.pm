# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use List::Util    qw(first);

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
