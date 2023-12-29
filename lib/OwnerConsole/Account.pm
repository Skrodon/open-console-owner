package OwnerConsole::Account;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Crypt::PBKDF2 ();
my $crypt = Crypt::PBKDF2->new;

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	$insert->{user} //= lc $insert->{email};
	my $password      = delete $insert->{password};

	my $self = $class->SUPER::create($insert, %args);

	$self->log("created account");
	$self->changePassword($password);
	$self;
}

=section Attributes
=cut

sub user()   { $_[0]->_data->{user}  }      # lower-cased email
sub email()  { $_[0]->_data->{email} }

=section Actions
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

1;
