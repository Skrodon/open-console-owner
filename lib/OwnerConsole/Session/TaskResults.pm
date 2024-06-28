# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Session::TaskResults;
use Mojo::Base 'OpenConsole::Session';

use Log::Report 'open-console-owner';

use OpenConsole::Util qw(val_line);

=chapter NAME

OwnerConsole::Session::TaskResults - a session which runs a task

=chapter SYNOPSIS

=chapter DESCRIPTION

B<Be warned:> this object, nor its extensions, should contain references
to other objects: the client-side of this response may (=is probably)
not be Perl, hence objects will not be portable.

=chapter METHODS

=section Constructors

=method job $session, $jobid, %options
Collect the results from a task ran or still running.  The %options
are passed to M<new()>.
=cut

sub job($$)
{	my ($class, $session, $jobid) = (shift, shift, shift);
	my $job  = $::app->minion->job($jobid);
	unless($job)
	{	$session->addError(__x"Job {id} disappeared.", id => $jobid);
		return;
	}

use Data::Dumper;
warn "JOB $jobid RETURNED=", Dumper $job->info;
	$class->new(_data => $job->info);
}

#------------------
=section Attributes

=cut

# Raw job data, see F<https://metacpan.org/pod/Minion::Job#info>.
# Create abstracted methods!

=method state
=cut

sub state  { $_[0]->_data->{state} }

=method result
=cut

sub result { $_[0]->_data->{result} }

=method finished
Returns a timestamp (which is also used as a boolean) when the task has finished.
=cut

sub finished { $_[0]->_data->{finished} }

1;
