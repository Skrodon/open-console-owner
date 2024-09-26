# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use List::Util    qw(first);

use OpenConsole::Session::Ajax ();

# Required by extensions at load time, so before their 'use'
my %challenge_handlers;
sub challengeHandler($$)
{	my ($class, $purpose, $method) = @_;
	$class->isa(__PACKAGE__) or panic;

	$challenge_handlers{$purpose} = sub {
		my $self = (bless shift, $class);  # upgrade
		$self->$method(@_);
	};
}

# When missing, the controllers get autoloaded.
use OwnerConsole::Controller::Account;
use OwnerConsole::Controller::Contracts;
use OwnerConsole::Controller::Dashboard;
use OwnerConsole::Controller::Emailaddrs;
use OwnerConsole::Controller::Groups;
use OwnerConsole::Controller::Identities;
use OwnerConsole::Controller::Login;
use OwnerConsole::Controller::Outsider;
use OwnerConsole::Controller::Services;
use OwnerConsole::Controller::Websites;

#XXX To be separated out later
use OwnerConsole::Controller::Connect;

=chapter NAME
OwnerConsole::Controller - base-class for Mojo C's

=chapter METHODS
=cut

sub ajaxSession(%)
{	my ($self, %args) = @_;
	OpenConsole::Session::Ajax->create(\%args, controller => $self);
}

sub acceptFormData($$$)
{	my ($self, $session, $object, $handler) = @_;

	my $r = try {
		$self->$handler($session, $object);
	};

	$session->notify(error => $_) for $@->exceptions;
	$r;
}

sub acceptObject($$)
{	my ($self, $session, $proof) = @_;
	$self;
}

sub openObject($$$$)
{	my ($self, $session, $objclass, $idlabel, $get) = @_;
	my $objid = $session->about($idlabel) or panic $idlabel;

	return $objclass->create($self->account)
		if $objid eq 'new';

	my $object = $get->($objid);
	unless($object)
	{	$session->internalError(__x"The object has disappeared.");
		return undef;
	}

	$object;
}

sub openAsset($$)
{	my ($self, $session, $objclass) = @_;
	my $assetid = $session->about('assetid');

	if($assetid eq 'new')
	{	trace "Create new $objclass asset";
		return $objclass->create({ owner => $self->account })
	}

	my $asset = $self->account->asset($objclass->set, $assetid);
	unless($asset)
	{	info "Asset $assetid of type $objclass has disappeared.";
		$session->internalError(__x"Proof has disappeared.");
		return undef;
	}

	$asset;
}

#-------------
=section Generic code for Proofs
=cut

sub acceptProof($$)
{	my ($self, $session, $proof) = @_;
	$self;
}

=method badge ($asset|$status)
Returns an HTML fragment which displays the badge which matched the asset's status.
Not all assets support the same statusses: more important here, is a consequent use
of colors.
=cut

my %asset_status = (    # translatable name, bg-color
	blocked  => [ __"Blocked",    'dark'    ],
	disabled => [ __"Disabled",   'warning' ],
	enabled  => [ __"Enabled",    'success' ],
	expired  => [ __"Expired",    'dark'    ],
	proven   => [ __"Proven",     'success' ],
	public   => [ __"Public",     'success' ],
	refresh  => [ __"Refreshing", 'info'    ],  # only when refreshing takes long
	testing  => [ __"Testing",    'info'    ],
	unproven => [ __"Unproven",   'warning' ],
	verify   => [ __"Verifying",  'info'    ],  # only when verification takes long
);

sub badge($)
{	my ($self, $asset) = @_;
	my $status = ref $asset ? $asset->status : $asset;
	my $config = $asset_status{$status};
	my $label  = $config ? $config->[0]->toString : "XX${status}XX";
	my $color  = 'text-bg-' . ($config ? $config->[1] : 'danger');
	qq{<span class="badge $color">$label</span>};
}

#-------------
=section Generic code for Challenges

The "challenge dispatcher".
=cut

sub challenge()
{	my $self     = shift;
	my $token    = $self->param('token');

	my $challenge = $::app->batch->challenge($token);
	unless($challenge)
	{	$self->notify(warning => __"The challenge does not exist (anymore).");
		return $self->redirect_to('/dashboard');
	}

	if($challenge->hasExpired)
	{	# Expired, but still visible
		$self->notify(info => __"The challenge has expired.");
		return $self->redirect_to('/dashboard');
	}

	my $account  = $self->account;
	unless($challenge->isFor($account))
	{	# Wrong person tries to use challenge
		$self->notify(error => __"The challenge is not for you.");
		return $self->redirect_to('/dashboard');
	}

	my $purpose = $challenge->purpose;
	my $handler = $challenge_handlers{$purpose};
	unless($handler)
	{	$self->notify(error => (__x"Unimplemented purpose '{purpose}'.", purpose => $purpose));
		return $self->redirect_to('/dashboard');
	}

	$self->$handler($account, $challenge);
}

#-------------
=section Running tasks

=method taskWait $session, $task, $poll, %options
Initialize the task waiting.  Does nothing when the C<$task> is undefined.
=cut

sub taskWait($$$%)
{	my ($self, $session, $task, $poll) = @_;
	defined $task or return $session;

	$session->startPoll($poll, $task);
	$session->mergeTaskResults($task);
	$session->setData(show_trace => $self->showTrace($task->trace));
	$session;
}

=method taskPoll $session, %options
Generic task polling code.
=cut

sub taskPoll($%)
{	my ($self, $session, %args) = @_;

	my $taskid = $session->requiredParam('task');
	my $task = $::app->tasks->ping($taskid);
	$session->mergeTaskResults($task);
	$session->setData(show_trace => $self->showTrace($task->trace));
	$task;
}

=method showTrace
Convert a trace into user-consumable text.
=cut

sub showTrace($%)
{	my ($self, $trace, %args) = @_;
	$trace && @$trace or return [];

	my @lines;
	my ($first, @trace) = @$trace;
	my $start = DateTime->from_epoch(epoch => $first->[0]);
	my $tz    = $self->account->timezone;
	$start->set_time_zone($tz) if $tz;

	push @lines, [ $start->stringify =~ s/T/\n/r, $first->[1] ];
	push @lines, [ (sprintf "+%0.3fs", $_->[0] - $first->[0]), $_->[1] ]
		for @trace;

	\@lines;
}

#-------------
=section Other

=method detectLanguage
Returns the preferred interface language for a user, based on its previous
choice.  Defaults from the user's browser settings.
=cut

my ($iflangs, $langs);
sub detectLanguage()
{	my $self  = shift;
	if(my $if = $self->session('iflang')) { return $if }

	$iflangs ||= $self->config->{interface_languages};
#warn "IFLANGS=@$iflangs";
	$langs   ||= +{ map +($_ => 1), @$iflangs };

	my @wants = $self->browser_languages;
	my $code  = first { exists $langs->{$_} } @wants;

	unless($code)
	{	my @langs = map language_name($_), @wants;
#XXX notify is not shows
		$self->notify(warning => __x("None of the languages configured in your browser ({langs}) is supported for the Open Console interface at the moment.", langs => \@langs));
		$code = $iflangs->[0];
	}

	$self->session(iflang => $code);
	$code;
}

1;
