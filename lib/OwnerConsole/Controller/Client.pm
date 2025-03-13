# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Client;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';
#use OpenConsole::Util       qw();

# Inside OpenConsole, we use method name sessionCookie()
# to avoid confusion with other session objects.  But
# Mojolicious::Plugin::OpenConsole uses the name session(),
# being a generic plugin.
sub session() { shift->sessionCookie(@_) }

# This shows the font-end of the demo

sub index()
{   my $self = shift;
	$self->render(
		template      => 'client/index',
	);
}

# The "login via Open Console" button is pressed on the application website
# (in this demo case, our own site)

sub login()
{	my $self  = shift;
	my $auth  = $self->OpenConsole->buttonClick($self)
		or return;

warn "LOGIN($auth)";
	$self->redirect_to($auth);
}

sub service()
{	my $self = shift;
	my ($token, $state, $session) = $self->OpenConsole->acceptUser($self);

	# $token is a comply_id in the OpenConsole server, but this demo
	# code does not need to know: it is simply the access token.
	$token or return ();

	$self->render(
		access_token => $token,
		template     => 'client/service',
	);
}

1;
