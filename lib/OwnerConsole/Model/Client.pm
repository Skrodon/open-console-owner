# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Model::Client;
use Mojo::Base 'OpenConsole::Model';

use Mango::BSON ':bson';
use OpenConsole::Util           qw(:time);

use OwnerConsole::Email         ();
use OwnerConsole::Group::Invite ();
use OwnerConsole::Challenge     ();

=chapter NAME
OwnerConsole::Model::Client - database with information for the Client demo.

=chapter DESCRIPTION

collections:
=over 4
=item * 'client_objs': the open console client login demo. ::Controller::Client.pm
=back

=chapter METHODS
=cut

has db          => undef;
has client_objs => sub { $_[0]->{OMB_client}  ||= $_[0]->db->collection('client')};

sub upgrade
{	my $self = shift;
	$self->SUPER::upgrade(@_);
	$self->_upgrade_client;
	$self;
}

#---------------------
=section Demo Client
This is the helper table for the client demo, which is included in the
website.  See M<Mojolicious::Plugin::OpenConsole> for the needs.
=cut

sub _upgrade_client()
{	my $self = shift;
	$self->SUPER::_upgrade($self->client_objs);
	$self->client_objs->ensure_index({ id => 1 }, { unique => bson_true  });
	$self->client_objs->ensure_index({ service => 1 }, { unique => bson_false  });
	$self;
}

sub OpenConsoleLoad($$%)
{	my ($self, $type, $id, %args) = @_;
	my $obj  = $self->client_objs->find_one({id => $id}) or return ();
	my $data = $obj->{_data};
	wantarray ? ($data, $obj) : $data;
}

sub OpenConsoleSave($$%)
{	my ($self, $type, $data, %meta) = @_;
	$meta{_data}   = $data;
	$meta{expires} = timestamp2bson $meta{expires};
	$meta{type}    = $type;

	$self->client_objs->save(\%meta);
}

sub OpenConsoleServiceSession($%)
{	my ($self, $service, %args) = @_;
	my @sessions = $self->client_objs->find({type => 'appsession', service => $service });
	@sessions or return ();

	# We ignore expires, which is used for database cleanup.
	my $obj      = (sort { $a->{deprecate} cmp $b->{deprecate} } @sessions)[-1];
	my $data     = $obj->{_data};
	wantarray ? ($data, $obj) : $data;
}

1;
