# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Tasks;
use Mojo::Base 'Mojolicious';

use Log::Report 'open-console-owner';

#use Minion::Backend::Mango        ();
use Minion::Backend::MongoDB       ();

use OwnerConsole::Prover::Website ();
use OwnerConsole::Session::TaskResults ();

my %tasks;

=chapter NAME

OwnerConsole::Tasks - Coordinate batch processing

=chapter SYNOPSIS

=chapter DESCRIPTION

Batch processing is handled by Minion, which integrate nicely with Mojolicious.

=chapter METHODS

=section Constructors
Standard M<Mojo::Base> constructors.

=c_method start %options
=requires dbserver URL
=cut

sub start(%)
{	my ($class, %args) = @_;
	my $server = $args{dbserver} or panic;

#	$::app->plugin(Minion => { Mango => $server });
	$::app->plugin(Minion => { MongoDB => $server });

	my $minion = $::app->minion;
	$minion->add_task(verifyWebsiteURL => \&_taskVerifyWebsiteURL);

#   $::app->plugin(Minion::Admin => { });   # under /minion
	my $self   = $class->new;
}

#----------------
=section Attributes
=cut

#----------------
=section Task management

=method run $task, $params, \%args
=cut

sub run($$)
{	my ($self, $task, $params, $args) = @_;
	$params->{lang} ||= $::app->account->ifLang;

	my $jobid = $::app->minion->enqueue($task, $params, $args);
use Data::Dumper;
warn "job $jobid: $task ", Dumper $params, $args;
	($jobid, 'started');
}

#----------------
=section Tasks helpers

=method run $task, \%args
=cut

=method ping $session, $jobid, $label
Returns a M<OwnerConsole::Session::TaskResults>.
=cut

sub ping($$)
{	my ($self, $session, $jobid) = @_;
	my $results = OwnerConsole::Session::TaskResults->job($jobid);
}

#----------------
=section Specific tasks


=method verifyWebsiteURL $url, %options
=cut

sub _taskVerifyWebsiteURL(%)
{	my ($job, %args) = @_;
warn "_taskVerifyWebsiteURL ", join ';', %args;
	OwnerConsole::Prover::Website->run;
}
$tasks{verifyWebsiteURL} = \&_taskVerifyWebsiteURL;

sub verifyWebsiteURL($%)
{	my ($self, $session, $params, %args) = @_;
warn "Start verifyWebsiteURL ", join ';', %$params;
	my ($jobid, $status) = $self->run(verifyWebsiteURL => $params);
	($jobid, $status);
}

#----------------
=section Other

=cut

1;
