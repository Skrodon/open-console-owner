# Abstract one User away from storage issues
package OwnerConsole::User;
use Mojo::Base 'OwnerConsole::Mango::Object';

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	$insert->{user} //= lc $insert->{email};
	my $self = $class->SUPER::create($insert, %args);
	$self->log("created user");
	$self;
}

=section Attributes
=cut

sub user()   { $_[0]->_data->{user} }      # lower-cased email

sub password { $_[0]->_data->{password} }

=section Actions
=cut

sub changePassword($)
{	my ($self, $password) = @_;
	$self->data->{password} = $password;
	$self->log("changed password");
	$self;
}

1;
