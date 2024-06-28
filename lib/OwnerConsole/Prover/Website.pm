# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Prover::Website;
use  Mojo::Base 'Mojolicious::Plugin';

sub register($$$)
{	my ($self, $app, $config) = @_;
	$app->minion->add_task(verifyWebsiteURL => \&_verifyWebsiteURL);
}

sub _verifyWebsiteURL($$)
{	my ($job, $args) = @_;
	# my $ua = $job->app->ua;

use Data::Dumper;
warn "MINION JOB RUN=", Dumper $args;

	$job->finish([
    +{	status => 'success',
		text   => 'hurray',
		args   => $args,
	 }]);
}

1;
