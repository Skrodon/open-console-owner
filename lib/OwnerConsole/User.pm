# Abstract one User away from storage issues
package OwnerConsole::User;
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

	$self->log("created user");
	$self->changePassword($password);
	$self;
}

=section Attributes
=cut

sub user()   { $_[0]->_data->{user} }      # lower-cased email

=section Actions
=cut

sub encryptedPassword {
#XXX workaround to upgrade
my $p = $_[0]->_data->{password};
$_[0]->_data->{password} = { encrypted => $p, algorithm => 'PBKDF2' };

	 $_[0]->_data->{password}{encrypted};
}

sub correctPassword($)
{	my ($self, $password) = @_;
	$crypt->validate($self->encryptedPassword, $password);
}

sub changePassword($)
{	my ($self, $password) = @_;
	$self->data->{password} = +{
		encrypted => $crypt->generate($password),
		algorithm => 'PBKDF2',
	};
	$self->log("changed password");
	$self;
}

1;
