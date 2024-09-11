# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Tasks;
use Mojo::Base 'OpenConsole::Mango::Object';

# No parts of the tasks are currently saved in the Mango database, still
# this object is prepared for it.

use Log::Report 'open-console-owner';

use Mojo::UserAgent ();

use OpenConsole::Util            qw(flat);
use OpenConsole::Session::Task   ();

=chapter NAME

OwnerConsole::Tasks - Coordinate task processing

=chapter SYNOPSIS

	my $tasks = OwnerConsole::Tasks->new(config => \%config);
	my $tasks = $::app->tasks;

=chapter DESCRIPTION

Activities which consume considerable time, for instance waiting for
external resources, should be handled by a separate daemon: not hinder
the website processes.  Therefore, we have special daemons, implemented
in GitHUB project 'open-console-tasks'.

This module implements the interface to these task performing daemons.
The response of these daemons is fast, very fast compared to the execution
time of their tasks.

=chapter METHODS

=section Constructors
Standard M<Mojo::Base> constructors.

=c_method new %options

=cut

#----------------
=section Attributes

=method config
=method userAgent
=cut

has config    => sub { ... };
has userAgent => sub { Mojo::UserAgent->new };

sub servers() { @{$_[0]->config->{servers}} }

#----------------
=section Task management

=method call $task, \%params, %options

=option  server LABEL
=default server C<undef>
=cut

sub call($$)
{	my ($self, $task, $params, %args) = @_;
	my $label = $args{server};

	my $resp;
	foreach my $server ($self->servers)
	{	my $endpoint = $server->{endpoint};
		next if defined $label && $server->{label} ne $label;

		my $tx = $self->userAgent->post("$endpoint/$task" =>
			{ Authentication => "Bearer $server->{authentication}" },
			json => $params,
		);

		$resp = $tx->res;
		next unless $resp->is_success;

		my $result = $resp->json;
use Data::Dumper;
warn "CALL $endpoint, $label = ", Dumper $result;

		return OpenConsole::Session::Task->fromResponse($result, server => $server);
	}

	error $label
		? __x("Could not get task {task} to server {label}.", task => $task, label => $label)
		: __x("Could not get task {task} to any server.", task => $task);
}

=method ping $ession, $taskid
=cut

sub ping($$)
{	my ($self, $taskid) = @_;
	my ($label, $jobid) = split '-', $taskid;
	$self->call("job/$jobid", {}, server => $label);
}

#----------------
=section Specific tasks

=method verifyWebsiteURL \%params, %options
=cut

sub verifyWebsiteURL($%)
{	my ($self, $params, %args) = @_;
	my $task = $self->call('proof/verifyWebsiteURL' => $params);
}

=method proofWebsiteFile \%params, %options
=cut

sub proofWebsiteFile($%)
{	my ($self, $params, %args) = @_;
	my $task = $self->call('proof/proofWebsiteFile' => $params);
}

=method proofWebsiteHTML \%params, %options
=cut

sub proofWebsiteHTML($%)
{	my ($self, $params, %args) = @_;
	my $task = $self->call('proof/proofWebsiteHTML' => $params);
}

=method proofWebsiteDNS \%params, %options
=cut

sub proofWebsiteDNS($%)
{	my ($self, $params, %args) = @_;
	my $task = $self->call('proof/proofWebsiteDNS' => $params);
}

1;
