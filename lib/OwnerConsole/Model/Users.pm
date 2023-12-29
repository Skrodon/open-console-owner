package OwnerConsole::Model::Users;
use Mojo::Base -base;

use OwnerConsole::Account  ();
use OwnerConsole::Identity ();

=section DESCRIPTION
This object handles the "users" database, which contains all information
which related to perticular people with a login.

collections:
=over 4
=item * 'account': the login of a user
=item * 'identity': the public representation of a Person
=back

=cut

has db => undef;

sub createAccount($%)
{	my ($self, $insert, %args) = @_;
	$insert or return;

	my $account = OwnerConsole::Account->create($insert);
	$self->db->collection('accounts')->insert($account);

	$self;   # call account() to get the ::Account object: db will add stuff
}

sub account($)
{	my ($self, $user) = @_;
	my $data = $self->db->collection('accounts')->find_one({user => $user})
		or return;

use Data::Dumper;
warn "get account: ", Dumper $data;
	OwnerConsole::Account->fromDB($data);
}

1;
