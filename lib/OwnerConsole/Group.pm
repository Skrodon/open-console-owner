package OwnerConsole::Group;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Log::Report 'open-console-owner';

use constant GROUP_SCHEMA => '20240112';

=section DESCRIPTION

=section Constructors
=cut

sub create($%)
{	my ($class, $account, %args) = @_;
	my %insert  = (
		groupid  => 'new',
		schema   => GROUP_SCHEMA,
		userid   => $account->userId,
		language => $account->preferredLanguage,
	);

	my $self = $class->SUPER::create(\%insert, %args);
}

#-------------
=section Attributes
=cut

# Keep these attributes in sync with the OwnerConsole/Controller/Groups.pm
# method submit_group()

sub groupId()    { $_[0]->_data->{groupid} }
sub userId()     { $_[0]->_data->{userid} }
sub schema()     { $_[0]->_data->{schema} }

sub identId()    { $_[0]->_data->{identid} }
sub name()       { $_[0]->_data->{name} }
sub fullname()   { $_[0]->_data->{fullname} }
sub timezone()   { $_[0]->_data->{timezone} }
sub department() { $_[0]->_data->{department} }
sub country()    { $_[0]->_data->{country} }
sub organization() { $_[0]->_data->{organization} }
sub language()   { $_[0]->_data->{language} }
sub postal()     { $_[0]->_data->{postal} }

sub emailOther() { $_[0]->_data->{email} }     # Usually, the code want to get the default
sub phoneOther() { $_[0]->_data->{phone} }

sub email()      { $_[0]->emailOther // $_[0]->account->email }
sub phone()      { $_[0]->phoneOther // $_[0]->account->phone }


#-------------
=section Actions
=cut

sub save(%)
{   my ($self, %args) = @_;
	$self->_data->{groupid} = $::app->newUnique if $self->groupId eq 'new';
	if($args{by_user})
    {	$self->_data->{schema} = GROUP_SCHEMA;
		$self->log('changed group settings');
	}
    $::app->users->saveGroup($self);
}

1;
