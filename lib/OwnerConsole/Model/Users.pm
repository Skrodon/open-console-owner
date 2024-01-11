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
has accounts   => sub { $_[0]->{OMU_account} ||= $_[0]->db->collection('accounts')   };
has identities => sub { $_[0]->{OMU_ident}   ||= $_[0]->db->collection('identities') };

#---------------------
=section UserDB configuration
=cut

sub upgrade
{	my $self = shift;

    #### Indices
	# We can run "ensure_index()" as often as we want.

#$self->accounts->drop_index('email');
	$self->accounts->ensure_index({ userid => 1 }, { unique => bson_true });

	$self->accounts->ensure_index({ email  => 1 }, {
		unique    => bson_true,
		collation => { locale => 'en', strength => 2 },  # address is case-insensitive
	});

#$self->identities->drop_index('userid');
	$self->identities->ensure_index({ identid => 1 }, { unique => bson_true });
	$self->identities->ensure_index({ userid  => 1 }, { unique => bson_false });
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
	$self->accounts->find->all;
}

#---------------------
=section The "identity" table
=cut

sub identity($)
{	my ($self, $identid) = @_;
	my $data = $self->identities->find_one({identid => $identid})
		or return;

	OwnerConsole::Identity->fromDB($data);
}

sub removeIdentity($)
{	my ($self, $identity) = @_;
	$self->identities->remove({identid => $identity->identityId});
}

sub saveIdentity($)
{	my ($self, $identity) = @_;
	$self->identities->save($identity->toDB);
}

sub allIdentities()
{	my $self = shift;
	$self->identities->find->all;
}


1;
