package OwnerConsole::Identity;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Log::Report 'open-console-owner';

use constant IDENTITY_SCHEMA => '20240111';

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
{	my ($class, $account, %args) = @_;
	my %insert  = (
		identid  => 'new',
		schema   => IDENTITY_SCHEMA,
		userid   => $account->userId,
		gender   => $account->gender,
		language => $account->preferredLanguage,
	);

	my $self = $class->SUPER::create(\%insert, %args);
}

#-------------
=section Attributes
=cut

# Keep these attributes in sync with the OwnerConsole/Controller/Identities.pm
# method submit_identity()

sub identityId() { $_[0]->_data->{identid} }
sub userId()     { $_[0]->_data->{userid} }
sub schema()     { $_[0]->_data->{schema} }

sub role()       { $_[0]->_data->{role} }
sub fullname()   { $_[0]->_data->{fullname} }
sub nickname()   { $_[0]->_data->{nickname} }
sub language()   { $_[0]->_data->{language} }
sub gender()     { $_[0]->_data->{gender} }
sub postal()     { $_[0]->_data->{postal} }

sub emailOther() { $_[0]->_data->{email} }     # Usually, the code want to get the default
sub phoneOther() { $_[0]->_data->{phone} }

sub email()      { $_[0]->emailOther // $_[0]->account->email }
sub phone()      { $_[0]->phoneOther // $_[0]->account->phone }
sub link()       { '/dashboard/identity/' . $_[0]->identityId }

sub nameInGroup() { $_[0]->fullname || $_[0]->nickname || $_[0]->role }

#-------------
=section Actions
=cut

sub remove()
{	my $self = shift;

	my $id   = $self->identityId;
	$::app->users->removeIdentity($self);
	$::app->emails->removeOutgoingRelatedTo($self->identityId);
	$self->account->removeIdentity($self);
}

sub usedForGroups() { $::app->users->groupsUsingIdentity($_[0]) }

sub save(%)
{   my ($self, %args) = @_;
	$self->_data->{identid} = $::app->newUnique if $self->identityId eq 'new';
	if($args{by_user})
    {	$self->_data->{schema} = IDENTITY_SCHEMA;
		$self->log('changed identity settings');
	}
    $::app->users->saveIdentity($self);
}

1;
