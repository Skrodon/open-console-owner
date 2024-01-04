package OwnerConsole::Identity;
use Mojo::Base 'OwnerConsole::Mango::Object';

=section DESCRIPTION

An Identity represents one of the ways a person wants to present
him/herself.  See it as: one of the roles a person plays in
society.

A person may decide to make an identity which has very few personal
facts, and one with many detailed information.  Identities may be
validated by organizations.

The Identity should probably support the data in
https://openid.net/specs/openid-connect-basic-1_0-23.html
section 2.4.2.  At least, one method MUST be implemented which produces
these facts.  Work in progress.

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	my $identid = $insert->{ident_id} = $::app->newUnique;
	my $self = $class->SUPER::create($insert, %args);

	$self->log("created identity $identid");
	$self;
}

#-------------
=section Attributes
=cut

sub identityId() { $_[0]->_data->{ident_id} }

#-------------
=section Actions
=cut

1;
