package OwnerConsole::Group;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Log::Report 'open-console-owner';

use Scalar::Util qw(blessed);
use List::Util   qw(first);

use OwnerConsole::Util  qw(bson2datetime);

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

		members     => [],
		invitations => [], 
	);

	my $self = $class->SUPER::create(\%insert, %args);
	$self->addMember($account->preferredIdentity);
	$self;
}

#-------------
=section Attributes
=cut

# Keep these attributes in sync with the OwnerConsole/Controller/Groups.pm
# method submit_group()

sub groupId()    { $_[0]->_data->{groupid} }
sub userId()     { $_[0]->_data->{userid} }
sub schema()     { $_[0]->_data->{schema} }

sub name()       { $_[0]->_data->{name} }
sub fullname()   { $_[0]->_data->{fullname} }
sub timezone()   { $_[0]->_data->{timezone} }
sub department() { $_[0]->_data->{department} }
sub country()    { $_[0]->_data->{country} }
sub organization() { $_[0]->_data->{organization} }
sub language()   { $_[0]->_data->{language} }
sub postal()     { $_[0]->_data->{postal} }
sub members()    { @{$_[0]->_data->{members}     ||= []} }   # HASH
sub invitations  { @{$_[0]->_data->{invitations} ||= []} }   # HASH

sub emailOther() { $_[0]->_data->{email} }     # Usually, the code want to get the default
sub phoneOther() { $_[0]->_data->{phone} }

sub email()      { $_[0]->emailOther // $_[0]->account->email }
sub phone()      { $_[0]->phoneOther // $_[0]->account->phone }
sub link()       { '/dashboard/group/' . $_[0]->groupId }

#-------------
=section Invited Members

Structure: ARRAY of

   { email     => $email,
     invited   => date,
     expires   => date,
     token     => $secret
   }

=cut

sub inviteMember($%)
{	my ($self, $email, %args) = @_;
	my $now        = time;
	my $expiration = $args{expiration} // 86400;

	my $invitation = +{
		email    => $email,
		invited  => Mango::BSON::Time->new($now * 1000),
		expires  => Mango::BSON::Time->new(($now + $expiration) * 1000),
		token    => $::app->newUnique,
	};
	push @{$self->_data->{invitations}}, $invitation;
	$self->_invitation($invitation);
}

sub _invitation($)
{	my %invite = %{$_[1]};
	$invite{invited} = bson2datetime $invite{invited};
	$invite{expires} = bson2datetime $invite{expires};
	\%invite;
}

sub invitation($)
{	my ($self, $email) = @_;
	defined $email or return ();

	my $invite = first { lc($_->{email}) eq lc($email) } $self->invitations;
warn "INVITE $email $invite";
	$invite ? $self->_invitation($invite) : undef;
}

sub extendInvitation($$)
{	my ($self, $email, $seconds) = @_;
	my $invitation = first { lc($_->{email}) eq lc($email) } $self->invitations or return;

	my $expires = time + $seconds;
	$invitation->{expires} = Mango::BSON::Time->new($expires * 1000);
	$self->_invitation($invitation);
}

sub removeInvitation($)
{	my ($self, $email) = @_;
	$self->_data->{invitations} = [ grep { $_->{email} ne $email } $self->invitations ];
	$email;
}

sub allInvitations() { map $_[0]->_invitation($_), $_[0]->invitations }

#-------------
=section Accepted Members

Structure: ARRAY of

   { identid   => $code,    # identity identifier, required after accepted
     invited   => date,
     accepted  => date,
   }

=cut

sub addMember($)
{	my ($self, $id) = @_;
	$id = $id->identityId if blessed $id;
	my $gid = $self->groupId;

	my $account = $::app->account;
	my $aid     = $account->userId;

	if(my $has = $self->hasMemberFrom($account))
	{	if($has->{identid} ne $id)
		{	$has->{identid} = $id;
			$self->log("Changed identity of account $aid in group $gid to $id.");
        }
	}
	else
	{	push @{$self->_data->{members}}, +{
			identid  => $id,
			accepted => Mango::BSON::Time->new,
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
	unless(grep $_->{is_admin}, @members)
	{	$members[0]->{is_admin} = 1;
		$self->log("Member ". $members[0]->{identid} ." in group $gid promoted to admin.");
	}

	@members;
}

sub hasMemberFrom($)
{	my ($self, $account) = @_;
	my %ids  = map +($_->identityId => 1), $account->identities;
use Data::Dumper;
warn "HAS MEMBER: ", Dumper \%ids, $self->_data;
    my $data = first { $ids{$_->{identid}} } $self->members;
    defined $data ? $self->_import_member($data) : undef;
}

#-------------
=section Actions
=cut

sub remove()
{	my $self = shift;
	$::app->emails->removeOutgoingRelatedTo($self->accountId);
#XXX Check ownerships which have to be reassigned
}

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
