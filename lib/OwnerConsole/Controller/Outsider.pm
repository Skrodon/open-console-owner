# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Outsider;
use Mojo::Base 'OwnerConsole::Controller';

sub frontpage()
{	my $self = shift;
	$self->render(template => 'frontpage');
}

sub set()
{	my $self = shift;
	if(my $lang = $self->param('language'))
	{	$self->session('iflang', $lang);
	}
	$self->frontpage;
}

1;
