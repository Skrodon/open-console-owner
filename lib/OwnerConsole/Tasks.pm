# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Tasks;
use Mojo::Base 'OpenConsole::Mango::Object';

# No parts of the tasks are currently saved in the Mango database, still
# this object is prepared for it.

# The Minion administration uses PostgreSQL, because that seems to be
# the backend the developers of Minion are using.  The Mongo/Mango
# backends do did not get all changes around jobs admistration.

use Log::Report 'open-console-owner';

use Minion                       ();
use Minion::Backend::Pg          ();

use OwnerConsole::Prover::Website ();
use OwnerConsole::Session::TaskResults ();

my %tasks;
use constant {
	POSTGRESQL_SERVER => 'localhost:5432',
	MINION_USER       => 'ocminion',
	MINION_DATABASE   => 'ocminion',
};

=chapter NAME

OwnerConsole::Tasks - Coordinate batch processing

=chapter SYNOPSIS

=chapter DESCRIPTION

Batch processing is handled by Minion, which integrates nicely with
Mojolicious.

=chapter METHODS

=section Constructors
Standard M<Mojo::Base> constructors.

=c_method new %options
=cut

=method startup $config, %options
=cut

sub startup($%)
{	my ($self, $config, %args) = @_;

	my %minion = %{$config->{minion} || {}};

	### Connect to the minion support database

	my $dbuser = delete $minion{dbuser}   || MINION_USER;
	my $dbpwd  = delete $minion{dbpasswd} or panic "Task database configuration requires a password.";
	my $conn   = Mojo::URL->new;
	$conn->scheme('postgresql');
	$conn->host_port(delete $minion{dbserver} || POSTGRESQL_SERVER);
	$conn->userinfo("$dbuser:$dbpwd");  # no colon in username!
	$conn->path(delete $minion{dbname} || MINION_DATABASE);

	#XXX it seems not possible to pass the Mojo::URL as object for Mojo::Pg :-(
	$::app->plugin(Minion => { Pg => $conn->to_unsafe_string }, %minion);
	my $minion = $self->{OT_minion} = $::app->minion;

	my $admin = $config->{minion_admin} || {};
	if($admin->{enabled})
	{	# management under /minion
		$::app->plugin('Minion::Admin' => %$admin);
	}

	$::app->plugin('OwnerConsole::Prover::Website');
	$self;
}

#----------------
=section Attributes

=method minion
=cut

sub minion() { $_[0]->{OT_minion} }

#----------------
=section Task management

=method run $task, $params, \%args
=cut

sub run($$)
{	my ($self, $task, $params, $args) = @_;
	$params->{lang} ||= $::app->account->ifLang;

	my $jobid = $::app->minion->enqueue($task, [ $params ], $args);
	($jobid, 'started');
}

=method ping $session, $jobid, $label
Returns a M<OwnerConsole::Session::TaskResults>.
=cut

sub ping($$)
{	my ($self, $session, $jobid) = @_;
	OwnerConsole::Session::TaskResults->job($session, $jobid);
}

#----------------
=section Specific tasks


=method verifyWebsiteURL $url, %options
=cut

sub verifyWebsiteURL($%)
{	my ($self, $session, $params, %args) = @_;
	my ($jobid, $status) = $self->run(verifyWebsiteURL => $params);
	($jobid, $status);
}

#----------------
=section Other

=cut

1;
