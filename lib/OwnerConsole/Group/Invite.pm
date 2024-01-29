package OwnerConsole::Group::Invite;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Log::Report 'open-console-owner';

use List::Util   qw(first);
use DateTime     ();

use OwnerConsole::Util  qw(bson2datetime);

use constant
{	INVITE_SCHEMA => '20240122',
	SECS_IN_DAY   => 24 * 60 * 60,
};

sub fromDB($)
{	my ($class, $data) = @_;
	$data->{invited} ||= $data->{expires};   #XXX remove after restart DB
	$class->SUPER::fromDB($data);
}

=chapter DESCRIPTION

=chapter METHODS
=section Constructors
=cut

sub create($$$)
{	my ($class, $identity, $group, $email) = @_;
	my $config  = $::app->config->{groups} || {};
	my $start   = time;
    my $expires = $start + ($config->{invite_expiration} || 7) * SECS_IN_DAY;

	$class->SUPER::create({
		schema    => INVITE_SCHEMA,
        state     => 'start',
		token     => $::app->newUnique,
        invited   => Mango::BSON::Time->new($start * 1000),
        expires   => Mango::BSON::Time->new($expires * 1000),
        email     => $email,
        identid   => $identity->identityId,
        groupid   => $group->groupId,
	});
}

#-------------
=section Attributes
=cut

# Keep these attributes in sync with the OwnerConsole/Controller/Groups.pm
# method submit_group()

sub schema()     { $_[0]->_data->{schema} }
sub token()      { $_[0]->_data->{token} }
sub groupId()    { $_[0]->_data->{groupid} }
sub identityId() { $_[0]->_data->{identid} }
sub email()      { $_[0]->_data->{email} }
sub state()      { $_[0]->_data->{state} }

sub link()       { '/invite/' . $_[0]->token }

sub invited()    { $_[0]->{OGI_inv} ||= bson2datetime $_[0]->_data->{invited}, $_[0]->timezone }
sub expires()    { $_[0]->{OGI_exp} ||= bson2datetime $_[0]->_data->{expires}, $_[0]->timezone }
sub hasExpired   { $_[0]->{OGI_exp} //= $_[0]->expires < DateTime->now // 0 }
sub invitedBy    { $_[0]->{OGI_iid} ||= $::app->users->identity($_[0]->identityId) }
sub invitedTo    { $_[0]->{OGI_gid} ||= $::app->users->group($_[0]->groupId) }
sub timezone     { $_[0]->{OGI_tz}  ||= $_[0]->invitedTo->timezone }

#-------------
=section State
=cut

sub changeState($)
{	my ($self, $state) = @_;
	$self->_data->{state} = $state;
	$self->save;
}

my %state_names = (
	start  => (__"pending")->toString,
	reject => (__"rejected")->toString,
	spam   => (__"spam")->toString,
	ignore => (__"ignored")->toString,
	accept => (__"accepted")->toString,
);

sub stateName() { $state_names{$_[0]->state} || 'UNKNOWN STATE' }

#-------------
=section Actions
=cut

sub extend()
{	my $self    = shift;
	my $config  = $::app->config->{groups} || {};
    my $expires = time + ($config->{extend_invitation} || 14) * SECS_IN_DAY;
    $self->_data->{expires} = Mango::BSON::Time->new($expires * 1000);
	$self;
}

sub remove()
{	my $self = shift;
	$::app->batch->removeInvite($self);
}

sub save(%)
{	my $self = shift;
	$::app->batch->saveInvite($self);
	$self;
}

1;
