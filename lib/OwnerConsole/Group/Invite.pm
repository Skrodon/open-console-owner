# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Group::Invite;
use Mojo::Base 'OpenConsole::Mango::Object';

use Log::Report 'open-console-owner';

use List::Util   qw(first);
use DateTime     ();

use OpenConsole::Util  qw(:time new_token);

=chapter NAME
OwnerConsole::Group::Invite - handle group invites

=chapter DESCRIPTION
A group administrator can invite new members to the group.

=chapter METHODS

=section Constructors
=cut

#sub fromDB($)
#{	my ($class, $data) = @_;
#	$class->SUPER::fromDB($data);
#}

sub create($$$)
{	my ($class, $identity, $group, $email) = @_;
	my $config  = $::app->config->{groups} || {};

	$class->SUPER::create({
        state      => 'start',
		token      => (new_token 'N'),
        expiration => $config->{invite_expiration} || 'P7D',
        email      => $email,
        identid    => $identity->id,
        groupid    => $group->id,
	});
}

#-------------
=section Attributes
=cut

# Keep these attributes in sync with the OwnerConsole/Controller/Groups.pm
# method submit_group()

sub schema()     { '20240122' }
sub element()    { 'invite' }
sub set()        { 'invites' }
sub iconFA()     { 'fa-solid fa-users-viewfinder' }
sub elemName()   { __"Group invite" }
sub setName()    { __"Group invites" }

sub token()      { $_[0]->_data->{token} }
sub groupId()    { $_[0]->_data->{groupid} }
sub identityId() { $_[0]->_data->{identid} }
sub email()      { $_[0]->_data->{email} }
sub state()      { $_[0]->_data->{state} }

sub link()       { '/invite/' . $_[0]->token }

sub invitedBy    { $_[0]->{OGI_iid} ||= $::app->users->identity($_[0]->identityId) }
sub invitedTo    { $_[0]->{OGI_gid} ||= $::app->users->group($_[0]->groupId) }
sub timezone     { $_[0]->{OGI_tz}  ||= $_[0]->invitedTo->timezone }

#-------------
=section State
=cut

sub changeState($)
{	my ($self, $state) = @_;
	$self->setData(state => $state);
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

=method extend
Extend the invitation with the pre-configured amount of time
=cut

sub extend()
{	my $self   = shift;
	my $config = $::app->config->{groups} || {};
	my $extra  = $self->{OGI_extend} ||= duration($config->{extend_invitation} || 'P14D');
    $self->setData(expires => timestamp(now + $extra));
	$self;
}

sub _remove() { $::app->batch->removeInvite($_[0]) }
sub _save()   { $::app->batch->saveInvite($_[0]) }

1;
