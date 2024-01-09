package OwnerConsole::Account;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Crypt::PBKDF2 ();
my $crypt = Crypt::PBKDF2->new;

use OwnerConsole::Tables qw(language_name);

use constant COLL_SCHEMA => '20240102';

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	my $userid = $insert->{userid} = $::app->newUnique;
	$insert->{schema}    //= COLL_SCHEMA;
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
	if($data->{schema} < COLL_SCHEMA) {
		#XXX We may need to upgrade the user object automatically
	    $data->{schema} = COLL_SCHEMA;
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
sub iflang()    { $_[0]->_data->{iflang} }
sub timezone()  { $_[0]->_data->{timezone} }

sub isAdmin()   { $::app->isAdmin($_[0]) }
sub ifLanguage  { language_name($_[0]->iflang) }

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
=section Actions
=cut

sub save()
{	my $self = shift;
	$::app->users->saveAccount($self);
}


1;
