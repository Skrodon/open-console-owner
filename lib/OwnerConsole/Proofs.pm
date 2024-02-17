package OwnerConsole::Proofs;
use Mojo::Base -base;

use Log::Report 'open-console-owner';

use Scalar::Util    qw(blessed);

use OwnerConsole::Proof::EmailAddr1 ();

my %proofclass = (
	emailaddr1 => 'OwnerConsole::Proof::EmailAddr1',
);

=chapter DESCRIPTION

=chapter METHODS
=section Constructors
=cut

#------------------
=section Attributes
=cut

has owner => sub { error "Requires owner" }, weak => 1;

#------------------
=section Ownership
=cut

sub ownedByPerson() { $_[0]->owner->isa('OwnerConsole::Account') }
sub ownedByGroup()  { $_[0]->owner->isa('OwnerConsole::Group')   }

sub ownerId()       { $_[0]->{OP_id} ||= $_[0]->ownedByPerson ? $_[0]->owner->userId : $_[0]->owner->groupId }

#------------------
=section Separate Proofs

=ci_method proofFromDB $data
=cut

sub proofFromDB($)
{	my ($thing, $data) = @_;
	my $algo  = $data->{algorithm};
	my $class = $proofclass{$algo} or panic "Unknown proof algorithm $algo";
	$class->fromDB($data);
}

=method for SET
We are always loading whole sets of proofs at once, because we usually need them all and there are
usually just a few.
=cut

sub _set($)
{	my ($self, $set) = @_;
	$self->{"OP_$set"} ||= +{ map +($_->proofId => $_),  $::app->proofs->proofSearch($set, $self->ownerId) };
}

sub for($) { my $set = $_[0]->_set($_[1]); sort { $a->sort cmp $b->sort } values %$set }

sub proof($$)
{	my ($self, $set, $proofid) = @_;
	my $list = $self->_set($set);
	$list->{$proofid};
}

#------------------
=section Actions
=cut


1;
