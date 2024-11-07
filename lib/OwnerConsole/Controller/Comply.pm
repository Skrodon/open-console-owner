# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Comply;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw();

sub show_error()   # function name error() used by Log::Report
{   my $self = shift;
	my $req  = $self->req;
	$self->render(
		template   => 'comply/error',
		error      => $req->param('error'),
	);
}

1;
