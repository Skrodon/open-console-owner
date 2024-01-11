package OwnerConsole::Account;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Crypt::PBKDF2 ();
my $crypt = Crypt::PBKDF2->new;

use OwnerConsole::Tables qw(language_name);
use OwnerConsole::Identity ();

use constant ACCOUNT_SCHEMA => '20240102';

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	my $userid = $insert->{userid} = $::app->newUnique;
	$insert->{schema}    //= ACCOUNT_SCHEMA;
	$insert->{languages} //= [ 'en', 'nl' ];
	$insert->{iflang}    //= 'en';
	$insert->{timezone}  //= 'Europe/Amsterdam';

	my $password = delete $insert->{password};

	my $self = $class->SUPER::create($insert, %args);

	$self->log("created account $userid");
	$self->changePassword($password);
	$self;
}

sub fromDB($)
{   my ($class, $data) = @_;
	if($data->{schema} < ACCOUNT_SCHEMA) {
		# We may need to upgrade the user object partially automatically,
		# partially with the user's help.
	}
	$class->SUPER::fromDB($data);
}

#------------------
=section Attributes
=cut

#### Keep these attributes in sync with OwnerConsole::Collector::Account::submit()

sub schema()    { $_[0]->_data->{schema} }

sub userId()    { $_[0]->_data->{userid} }
sub email()     { $_[0]->_data->{email}  }
sub birth()     { $_[0]->_data->{birth_date} }
sub gender()    { $_[0]->_data->{gender} }
sub languages() { @{$_[0]->_data->{languages} || []} }
sub phone()     { $_[0]->_data->{phone} }
sub iflang()    { $_[0]->_data->{iflang} }
sub timezone()  { $_[0]->_data->{timezone} }
sub identityIds() { @{$_[0]->_data->{identities} || []} }

sub isAdmin()   { $::app->isAdmin($_[0]) }
sub ifLanguage  { language_name($_[0]->iflang) }

sub nrIdentities { scalar $_[0]->identityIds }

#------------------
=section Password handling
=cut

sub encryptedPassword { $_[0]->_data->{password}{encrypted} }

sub correctPassword($)
{	my ($self, $password) = @_;
	$crypt->validate($self->encryptedPassword, $password);
}

sub changePassword($)
{	my ($self, $password) = @_;
	$self->_data->{password} = +{
		encrypted => $crypt->generate($password),
		algorithm => 'PBKDF2',
	};
	$self->log("changed password");
	$self;
}

#------------------
=section Identities
=cut

sub addIdentity($)  # by id or object
{	my ($self, $identity) = @_;
	defined $identity or return;

	my $ids = $self->_data->{identities} ||= [];
	my $id  = ref $identity ? $identity->identityId : $identity;
	return $self if grep $id eq $_, @$ids;

	push @$ids, $id;

	$self->log("added identity $id");
	$self->save;

	delete $self->{OA_ids};  # clean cache
	$self;
}

sub removeIdentity($)
{	my ($self, $identity) = @_;
	my $id  = $identity->identityId;
	$self->_data->{identities} = [ grep $_ ne $id, $self->identityIds ];
	delete $self->{OA_ids};
	$self;
}

sub identity($)
{	my ($self, $id) = @_;
	$::app->users->identity($id);
}

sub identities
{	my $self = shift;
	$self->{OA_ids} ||= [ sort {$a->role cmp $b->role} map $self->identity($_), $self->identityIds ];
	@{$self->{OA_ids}};
}


#------------------
=section Actions
=cut

sub save(%)
{	my ($self, %args) = @_;
	$self->_data->{schema} = ACCOUNT_SCHEMA if $args{by_user};
	$self->log('changed account settings');
	$::app->users->saveAccount($self);
}


1;
