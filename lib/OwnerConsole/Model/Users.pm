package OwnerConsole::Model::Users;
use Mojo::Base -base;

use OwnerConsole::User ();
use OwnerConsole::Identity ();

=section DESCRIPTION
This object handles the "users" database, which contains all information
which related to perticular people with a login.

collections:
=over 4
=item * 'user': the login of a user
=item * 'identity': the public representation of a Person
=back

=cut

has db => undef, weak => 1;

sub createUser($%)
{	my ($self, $user, %args) = @_;
	$user or return;

	$user->{user} //= lc $user->{email};
	$self->db->collection('user')->insert($user);

	$self;   # call user() to get the user object: db will add stuff
}

sub user($)
{	my ($self, $user) = @_;
	my $data = $self->db->collection('user')->find_one({user => $user})
		or return;

use Data::Dumper;
warn "getUser: ", Dumper $data;
	OwnerConsole::User->fromDB($data);
}

1;
