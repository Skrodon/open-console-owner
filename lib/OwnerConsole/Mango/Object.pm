package OwnerConsole::Mango::Object;
use Mojo::Base -base;

#------------------------
=section Constructors
=cut

use Data::Dumper;
$Data::Dumper::Indent = 1;
sub fromDB($)
{	my ($class, $data) = @_;
use Data::Dumper;
#warn "DATA=", Dumper $data;
delete $data->{logging};   #XXX remove after restart of the DBs
	$class->new(_data => $data);
}

sub create($%)
{	my ($class, $insert, %args) = @_;
	$insert->{created} = Mango::BSON::Time->new;
	$class->new(_data => $insert);
}

#------------------------
=section Attributes
=cut

sub created() { my $c = $_[0]->_data->{created}; $c ? $c->to_datetime : undef }

#------------------------
=section Data
=cut

has _data => sub { +{} };

sub toDB() { $_[0]->_data }  #XXX might become more complex later

sub changed()    { ++$_[0]->{OP_changed} }
sub hasChanged() { !! $_[0]->{OP_changed} }

sub setData($$)
{	my ($self, $field, $value) = @_;
	my $data = $self->_data;

	# NOTE: blank fields do not exist
	if(my $changed = +($data->{$field} // ' ') ne ($value // ' '))
	{	$data->{$field} = $value;
warn "CHANGED $field to $value";
		return $self->changed;
	}

	0;
}

#------------------------
=section Logging
=cut

sub logging(%)
{	my ($self, %args) = @_;
	my $after  = $args{after};
	my $before = $args{before};

	my @lines;
	foreach my $log (@{$self->_data->{logging}})
	{	my %line = %$log;
		my $when = $line{when} = $log->{timestamp}->to_datetime;
		next if defined $after  && $when < $after;
		next if defined $before && $when > $before;
		push @lines, \%line;
	}
	\@lines;
}

sub log($)
{	my ($self, $insert) = @_;
	$insert = { text => $insert } unless ref $insert eq 'HASH';
warn "LOGGING: ", $insert->{text}, "\n";
return;
	$insert->{timestamp} //= Mango::BSON::Time->new;
#	$insert->{user}      //= $::app->user->username;
	push @{$self->_data->{logging}}, $insert;
}

#------------------------
=section Actions
=cut

1;
