# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Group;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Log::Report 'open-console-owner';

use Scalar::Util qw(blessed);
use List::Util   qw(first);

use OwnerConsole::Util     qw(new_token);
use OwnerConsole::Proofs   ();

use constant
{	GROUP_SCHEMA => '20240112',
};

=section DESCRIPTION

=section Constructors
=cut

sub create($%)
{	my ($class, $account, %args) = @_;

	my %insert =
	  (	groupid     => 'new',
		schema      => GROUP_SCHEMA,
		language    => $account->preferredLanguage,
		timezone    => $account->timezone || 'GMT',
		members     => [],
	  );

	my $self = $class->SUPER::create(\%insert, %args);
	$self->addMember($account, $account->preferredIdentity);
	$self;
}

sub fromDB($)
{	my ($class, $data) = @_;
	$data->{timezone}   ||= 'GMT';   #XXX remove at next restart of the db
	$data->{members}[0]{is_admin} = 1;   #XXX remove at next restart of the db
	$class->SUPER::fromDB($data);
}

#-------------
=section Attributes
=cut

# Keep these attributes in sync with the OwnerConsole/Controller/Groups.pm
# method submit_group()

sub schema()     { $_[0]->_data->{schema} }
sub ownerId()    { $_[0]->groupId }

sub groupId()    { $_[0]->_data->{groupid} }
sub country()    { $_[0]->_data->{country} }
sub department() { $_[0]->_data->{department} }
sub email()      { $_[0]->_data->{email} }
sub fullname()   { $_[0]->_data->{fullname} || $_[0]->name }
sub language()   { $_[0]->_data->{language} }
sub members()    { @{$_[0]->_data->{members}} }   # HASHes
sub name()       { $_[0]->_data->{name} }
sub organization() { $_[0]->_data->{organization} }
sub phone()      { $_[0]->_data->{phone} }
sub postal()     { $_[0]->_data->{postal} }
sub timezone()   { $_[0]->_data->{timezone} }

sub link()       { '/dashboard/group/' . $_[0]->groupId }

#-------------
=section Invited Members
=cut

sub inviteMember($$%)
{	my ($self, $identity, $email, %args) = @_;
	my $invite  = OwnerConsole::Group::Invite->create($identity, $self, $email);
	$::app->batch->saveInvite($invite);
	$invite;
}

sub invite($)
{	my ($self, $token) = @_;
	defined $token or return ();
	first { lc($_->token) eq lc($token) } $self->invites;
}

sub invites()
{	my $self = shift;
	$self->{OG_invites} ||= [ $::app->batch->invitesForGroup($self) ];
	@{$self->{OG_invites}};
}

sub extendInvitation($)
{	my ($self, $token) = @_;
	my $invite = $self->invite($token) or return;
	$invite->extend;
	$invite->save;
}

sub removeInvitation($)
{	my ($self, $token) = @_;
	delete $self->{OG_invites};
	my $invite = $self->invite($token) or return 1;
	return 0 if $invite->state eq 'spam';

	$::app->batch->removeInvite($token);
	1;
}

#-------------
=section Accepted Members

Structure: ARRAY of

   { identid   => $code,    # identity identifier, required after accepted
     accepted  => date,
   }

=cut

sub addMember($$)
{	my ($self, $account, $identity) = @_;
	my $id  = blessed $identity ? $identity->identityId : $identity;
	my $aid = $account->userId;
	my $gid = $self->groupId;

	if(my $has = $self->hasMemberFrom($account))
	{	if($has->{identid} ne $id)
		{	$has->{identid} = $id;
			$self->log("Changed identity of account $aid in group $gid to $id.");
        }
	}
	else
	{	my $members = $self->_data->{members};
		push @$members, +{
			identid  => $id,
			accepted => Mango::BSON::Time->new,
			is_admin => @$members ? 0 : 1,
		};
	}
	$self->log("Added identity $id of account $aid to group $gid.");
}

sub isMember($)
{	my ($self, $identid) = @_;
	defined first { $_->{identid} eq $identid } $self->members;
}

sub removeMember($)
{	my ($self, $id) = @_;
	$self->_data->{members} = [ grep { $_->{identid} ne $id } $self->members ];
}

sub _import_member($)
{	my %member = %{$_[1]};
	$member{invited}  = $member{invited}->to_datetime if $member{invited};
	$member{accepted} = $member{accepted}->to_datetime;
	\%member;
}

sub member($)
{	my ($self, $identid) = @_;
	defined $identid or return ();

	my $data = first { $_->{identid} eq $identid } $self->members;
	defined $data ? $self->_import_member($data) : undef;
}

sub allMembers(%)
{	my ($self, %args) = @_;
	my $load  = $args{get_identities};

	my $gid   = $self->groupId;
	my $users = $::app->users;

	my @members;
  MEMBER:
	foreach my $info (map $self->_import_member($_), $self->members)
	{	my $identid = $info->{identid};
		if($load)
		{	unless($info->{identity} = $users->identity($identid))
			{	$self->log("Identity $identid disappeared from group $gid.");
				$self->removeMember($identid);
				next MEMBER;
			}
		}
		push @members, $info;
	}

	# There must be at least one admin left
	if(@members && ! grep $_->{is_admin}, @members)
	{	$members[0]->{is_admin} = 1;
		$self->log("Member ". $members[0]->{identid} ." in group $gid promoted to admin.");
	}

	@members;
}

sub hasMemberFrom($)
{	my ($self, $account) = @_;
	my %ids  = map +($_->identityId => 1), $account->identities;
use Data::Dumper;
warn "MISSING IDENTID ", Dumper [ $self->members ] if grep ! $_->{identid}, $self->members;
    my $data = first { $ids{$_->{identid}} } $self->members;
    defined $data ? $self->_import_member($data) : undef;
}

sub memberIdentityOf($)
{	my ($self, $account) = @_;
	my %memids = map +($_->{identid} => $_), $self->members;
	first { exists $memids{$_->identityId}} $account->identities;
}

sub changeIdentity($$)
{	my ($self, $account, $identity) = @_;
	my $identid = blessed $identity ? $identity->identityId : $identity;
	my %memids  = map +($_->{identid} => $_), $self->members;
	foreach my $identity ($account->identities)
	{	my $had = $memids{$identity->identityId} or next;
		$had->{identid} = $identid;
	}
	1;
}

sub memberIsAdmin($)
{	my ($self, $account) = @_;
	my $member = $self->hasMemberFrom($account) or return 0;
	$member->{is_admin};
}

sub nrAdmins() { scalar grep $_->{is_admin}, $_[0]->members }

sub findMemberWithEmail($)
{	my ($self, $email) = @_;

	#TODO probably we should look through the other identities of
	#TODO the member, to see whether someone has used that one to
    #TODO link.  On the other hand, the invitee can flag this as well.

	foreach my $member ($self->allMembers(get_identities => 1))
	{	my $identity = $member->{identity};
		return $identity if $identity->email eq $email;
	}

	undef;
}

#-------------
=section Proofs
=cut

sub proofs() { $_[0]->{OG_proofs} ||= OwnerConsole::Proofs->new(owner => $_[0]) }

#-------------
=section Actions
=cut

sub remove()
{	my $self = shift;
	$::app->batch->removeEmailsRelatedTo($self->accountId);
#XXX Check ownerships which have to be reassigned
}

sub save(%)
{   my ($self, %args) = @_;
	$self->_data->{groupid} = new_token 'G' if $self->groupId eq 'new';
	if($args{by_user})
    {	$self->_data->{schema} = GROUP_SCHEMA;
		$self->log('changed group settings');
	}
    $::app->users->saveGroup($self);
}

1;
