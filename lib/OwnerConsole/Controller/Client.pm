# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Client;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

#use OpenConsole::Util       qw();

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
	my $auth  = $self->OpenConsole->buttonClick($self);
warn "LOGIN($auth)";
	$self->redirect_to($auth);
}

1;
