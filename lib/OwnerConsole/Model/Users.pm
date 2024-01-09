package OwnerConsole::Model::Users;
use Mojo::Base -base;

use Mango::BSON ':bson';

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
has accounts => sub { $_[0]->db->collection('accounts') };

#---------------------
=section UserDB configuration
=cut

sub upgrade
{	my $self = shift;

	# We can run this as often as we want
	$self->accounts->ensure_index({ userid => 1 }, { unique => bson_true });

# $self->accounts->drop_index('email');
	$self->accounts->ensure_index({ email  => 1 }, {
		unique    => bson_true,
		collation => { locale => 'en', strength => 2 },
	});
	$self;
}

#---------------------
=section The "account" table
=cut

sub createAccount($%)
{	my ($self, $insert, %args) = @_;
	$insert or return;

	my $account = OwnerConsole::Account->create($insert);
	$self->accounts->insert($account->toDB);
	$account;  # Does not contain all info, like db object_id
}

sub account($)
{	my ($self, $userid) = @_;
	my $data = $self->accounts->find_one({userid => $userid})
		or return;

	OwnerConsole::Account->fromDB($data);
}

sub accountByEmail($)
{	my ($self, $email) = @_;
	my $data = $self->accounts->find_one({email => $email})
		or return;

	OwnerConsole::Account->fromDB($data);
}

sub removeAccount($)
{	my ($self, $userid) = @_;
	$self->accounts->remove({userid => $userid})
		or return;
}

sub saveAccount($)
{	my ($self, $account) = @_;
	$self->accounts->save($account->toDB);
}

sub allAccounts()
{	my $self = shift;
my $all = $self->accounts->find->all;
use Data::Dumper;
warn Dumper $all;
}

1;
