package OwnerConsole::Proof;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Log::Report 'open-console-owner';

use Scalar::Util  qw(blessed);
use DateTime      ();

use OwnerConsole::Util  qw(bson2datetime new_token);

=chapter DESCRIPTION
Base class for all kinds of proofs of ownership.

=chapter METHODS
=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	$insert->{schema} or panic;
	$insert->{set}       = $class->set;
	$insert->{algorithm} = $class->algo;
	$insert->{proofid}   = 'new';
	$insert->{status}    = 'unproven';

	my $owner = delete $insert->{owner} or panic;
	$insert->{ownerid}   = $owner->isa('OwnerConsole::Account') ? $owner->userId : $owner->groupId;
	$insert->{ownerclass}= ref $owner;

	my $self = $class->SUPER::create($insert, %args);
	$self;
}

sub fromDB($)
{	my ($class, $data) = @_;
	my $self = $class->SUPER::fromDB($data);

	$self->setStatus('expired')
		if $self->status ne 'expired' && $self->hasExpired;

	$self;
}

#-------------
=section Attributes
=cut

# Must be extended
sub set()     { ... }
sub element() { ... }
sub algo()    { ... }
sub sort()    { ... }
sub _score()  { ... }

sub score()   { $_[0]->{OP_score} //= $_[0]->status eq 'proven' ? $_[0]->_score : 0 }

# Keep these attributes in sync with the OwnerConsole/Controller/Proof.pm
# method submit_group()

sub isNew()      { $_[0]->proofId eq 'new' }
sub proofId()    { $_[0]->_data->{proofid} }
sub ownerId()    { $_[0]->_data->{ownerid} }
sub ownerClass() { $_[0]->_data->{ownerclass} }
sub schema()     { $_[0]->_data->{schema} }
sub algorithm()  { $_[0]->_data->{algorithm} }
sub status()     { $_[0]->_data->{status} }

sub expires()
{	my $self = shift;
	return $self->{OP_exp} if exists $self->{OP_exp};

	my $exp = $self->_data->{expires};
	$self->{OP_exp} = $exp ? (bson2datetime $exp, $self->timezone) : undef;
}

sub hasExpired()
{	my $self = shift;
	return $self->{OP_dead} if exists $self->{OP_dead};
	my $exp  = $self->expires;
	$self->{OP_dead} = defined $exp ? $exp < DateTime->now : 0;
}

sub elemLink()   { '/dashboard/' . $_[0]->element . '/' . $_[0]->proofId }

#-------------
=section Ownership
=cut

sub owner($)
{	my ($self, $account) = @_;
	return $self->{OP_owner} if $self->{OP_owner};

	my $class = $self->ownerClass;
	if($class->isOwnedByMe)
	{	$account->userId eq $self->ownerId
			or error __x"Account does not own the proof anymore.";
		return $self->{OP_owner} = $account;
	}

	if($class->ownerClass->isa('OwnerConsole::Group'))
	{	my $group = $account->group($self->ownerId)
			or error __x"Not member of the owner group anymore.";
		return $self->{OP_owner} = $group;
	}

	panic "Unknown owner type $class";
}

sub isOwnedByMe()     { $_[0]->ownerClass->isa('OwnerConsole::Account') }
sub isOwnedByGroup($) { $_[0]->ownerId eq $_[1]->groupId }

# The identity which is related to this proof.  This may change by external
# factors.

sub identity($)
{	my ($self, $account) = @_;
	$self->isOwnedByMe ? $account->preferredIdentity : $self->owner->memberIdentityOf($account);
}

sub changeOwner($$)
{	my ($self, $account, $ownerid) = @_;
	$self->setData(ownerid => $ownerid);
	delete $self->{OP_owner};
}

#-------------
=section Status
=cut

my %status = (    # translatable name, bg-color
	unproven => [ __"Unproven",   'warning' ],
	verify   => [ __"Verifying",  'info'    ],
	refresh  => [ __"Refreshing", 'info'    ],
	proven   => [ __"Proven",     'success' ],
	expired  => [ __"Expired",    'dark'    ],
);

sub statusText(;$)
{	my $self  = shift;
	my $label = shift // $self->status;
	my $repr  = $status{$label} or return "XX${label}XX";
	$repr->[0]->toString;
}

# Returns a badge color class: https://getbootstrap.com/docs/5.3/components/badge/
sub statusBgColorClass(;$)
{	my $self  = shift;
	my $label = shift // $self->status;
	my $repr  = $status{$label} or return 'text-bg-danger';
	'text-bg-' . $repr->[1];
}

sub setStatus($)
{	my ($self, $new) = @_;
	$self->setData(status => $new);
	$self;
}

#-------------
=section Validation

Validation administration.
=cut

sub invalidate() { $_[0]->setStatus('unproven') }

sub isInvalid()  { $_[0]->status ne 'proven' }

#-------------
=section Action
=cut

sub save(%)
{   my ($self, %args) = @_;
	$self->setData(proofid => new_token 'P') if $self->proofId eq 'new';

	if($args{by_user})
    {	$self->setData(schema => $self->schema);
		$self->log('changed proof settings');
	}

    $::app->proofs->saveProof($self);
}

sub delete() { $::app->proofs->deleteProof($_[0]) }

sub accepted()
{	my $self = shift;
	$self->setData(expires => undef);
	$self->setStatus('proven');
}

1;
