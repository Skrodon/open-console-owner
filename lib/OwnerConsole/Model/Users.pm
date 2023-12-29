package OwnerConsole::Model::Users;
use Mojo::Base -base;

use OwnerConsole::User ();

=section DESCRIPTION
This object handles the "users" database, which contains all information
which related to perticular people with a login.

collections:
=over 4
=item * 'user': the login of a user, including a change-log
=back

=cut

has 'db';

use Data::Dumper;

sub createUser($%)
{	my ($self, $user, %args) = @_;
	$user or return;

	$user->{user} //= lc $user->{email};
	$self->db->collection('user')->insert($user);

	$self;   # call user() to get the user object: db will add stuff
}

sub user($)
{	my ($self, $user) = @_;
	my $data = $self->db->collection('user')->find_one() # ({user => $user})
		or return;

warn "getUser: ", Dumper $data;
	OwnerConsole::User->fromDB($data);
}

1;
