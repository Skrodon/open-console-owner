package OwnerConsole::Model::Batch;
use Mojo::Base -base;

use Mango::BSON ':bson';

use OwnerConsole::Email  ();

=section DESCRIPTION
Collections which are located in this database do rapidly change, which makes
the database (cluster) slower.  The data stored inhere is also less critical
than in the user's database, so need less or no redundancy.

collections:
=over 4
=item * 'outgoing':
=back

=cut

has db  => undef;
has out => sub { $_[0]->{OME_outgoing} ||= $_[0]->db->collection('outgoing')   };

sub upgrade
{	my $self = shift;

    #### Indices
	# We can run "ensure_index()" as often as we want.

#$self->out->drop_index('email');
	$self->out->ensure_index({ emailid => 1 }, { unique => bson_true });
	$self->out->ensure_index({ sender  => 1 }, { unique => bson_true });

	$self->out->ensure_index({ sendto  => 1 }, {
		unique    => bson_true,
		collation => { locale => 'en', strength => 2 },  # address is case-insensitive
	});
}

#---------------------
=section Email, the "outgoing" table

The document is maintained by M<OwnerConsole::Email> objects.
=cut

sub createOutgoing($%)
{	my ($self, $insert, %args) = @_;
	$insert or return;

	my $outgoing = OwnerConsole::Email->create($insert);
	$self->out->insert($outgoing->toDB);
	$outgoing;  # Does not contain all info, like db object_id
}
 
sub outgoing($)
{	my ($self, $emailid) = @_;
	my $data = $self->out->find_one({emailid => $emailid})
		or return;
 
	OwnerConsole::Email->fromDB($data);
}
 
sub outgoingByEmail($)
{	my ($self, $email) = @_;
	my $data = $self->out->find_one({email => $email})
		or return;
 
	OwnerConsole::Email->fromDB($data);
}
 
sub removeOutgoing($)
{	my ($self, $emailid) = @_;
	my $result = $self->out->remove({emailid => $emailid}, {single => 1});
	my $count  = $result->{deleteCount};
	$self->log($count ? "could not find email $emailid to remove" : "removed email $emailid");
	$count;
}
 
sub removeOutgoingRelatedTo($)
{	my ($self, $relid) = @_;
	my $result = $self->out->remove({related => $relid});
use Data::Dumper ();
warn "RESULT $result";
	my $count  = $result->{deleteCount};
	$self->log("removed $count outgoing emails related to $relid");
	$count;
}
 
sub saveOutgoing($)
{	my ($self, $outgoing) = @_;
	$self->out->save($outgoing->toDB);
}
 
sub allOutgoings()
{	my $self = shift;
	$self->out->find->all;
}

1;
