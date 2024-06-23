# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Prover::Website;
use  Mojo::Base 'Minion::Job';

sub run($%)
{	my ($self, %args) = @_;

    +{	status => 'success',
		text   => 'hurray',
		args   => \%args,
	 };
}

1;
