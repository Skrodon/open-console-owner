package OwnerConsole::Group;
use Mojo::Base 'OwnerConsole::Mango::Object';

=section DESCRIPTION

A personal identity can be affectuated within a group:
an organization, company, or any other collection of
people.

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	my $groupid = $insert->{group_id} = $::app->newUnique;
	my $self = $class->SUPER::create($insert, %args);

	$self->log("created group $groupid");
	$self;
}

#-------------
=section Attributes
=cut

sub groupId() { $_[0]->_data->{group_id} }

#-------------
=section Actions
=cut

1;
