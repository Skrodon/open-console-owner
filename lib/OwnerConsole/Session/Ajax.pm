# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Session::Ajax;
use Mojo::Base 'OpenConsole::Session';

use Log::Report 'open-console-owner';

use OpenConsole::Util qw(val_line);

=chapter NAME

OwnerConsole::Session::Ajax - a session which communicates with a browser

=chapter SYNOPSIS

=chapter DESCRIPTION

B<Be warned:> this object, nor its extensions, should contain references
to other objects: the client-side of this response may (=is probably)
not be Perl, hence objects will not be portable.

=chapter METHODS

=section Constructors
=cut

#------------------
=section Attributes
=cut

has controller => sub { ... };
has account    => sub { $_[0]->controller->account };
has lang       => sub { $_[0]->account->iflang };

#------------------
=section About the request
=cut

sub request() { $_[0]->{OA_request} ||= $_[0]->controller->req }

sub query()
{	my $self = shift;
	exists $self->{OA_query} or $self->{OA_query} = $self->request->url->query;
	$self->{OA_query};
}

sub about($)
{	my ($self, $idlabel) = @_;
	$self->controller->param($idlabel);
}

sub params()
{	my $self = shift;
	my $req  = $self->request;
my $new = ! defined $self->{OA_params};
my $p =
	$self->{OA_params} ||= $req->json || $req->body_params->to_hash;
use Data::Dumper;
warn "PARAMS=", Dumper $p if $new;
$p;
}

sub optionalParam($;$) { delete $_[0]->params->{$_[1]} // $_[2] }
sub ignoreParam($)     { delete $_[0]->params->{$_[1]} }

sub requiredParam($)
{	my ($self, $param) = @_;
	my $p = val_line $self->optionalParam($param);

	unless(defined $p && length $p)
	{	$self->addError($param => __x"Required parameter missing.");
		return 'missing';
	}

	$p;
}

sub checkParamsUsed()
{	my $self   = shift;
	my $params = $self->params;
	keys %$params == 0
		or warn "Unprocessed parameters: ", join ', ', sort keys %$params;
	$self;
}

#------------------
=section Collecting the answer
=cut

sub redirect($)
{	my ($self, $location) = @_;
	$self->_data->{redirect} = $location;
}

sub reply()
{	my $self = shift;
	$self->controller->render(json => $self->_data);
}

sub pollFor($$%)
{	my ($self, $where, $token, %args) = @_;
	state $delay = $::app->config->{tasks}{poll_interval} // 5000;
warn "DELAY=$delay";
	$self->_data->{poll} = { where => $where, token => $token, delay => $args{delay} // $delay };
}

sub stopPolling()
{	$_[0]->_data->{task_ready} = 1;
}

#------------------
=section Trace
=cut

sub showTrace($%)
{	my ($self, $account, %args) = @_;
	my @trace = @{$self->_data->{trace}};
	@trace or return [];

	my @lines;
	my $first = shift @trace;
	my $start = DateTime->from_epoch(epoch => $first->[0]);
	$start->set_time_zone($account->timezone) if $account;

	push @lines, [ $start->stringify, $first->[1] ];
	push @lines, [ (sprintf "+%ds", $_->[0] - $first->[0]), $_->[1] ]
		for @trace;

	\@lines;
}

1;

1;
