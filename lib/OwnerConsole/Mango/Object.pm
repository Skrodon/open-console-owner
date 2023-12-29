package OwnerConsole::Mango::Object;
use Mojo::Base -base;

has '_data';

=section Constructors
=cut

sub fromDB($)
{	my ($class, $data) = @_;
	$class->new(_data => $data);
}

sub create($%)
{	my ($class, $insert, %args) = @_;
	$class->new(_data => $insert, logging => []);
}

sub toDB() { $_[0]->_data }  #XXX might become more complex later

=section Attributes
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

=section Actions
=cut

sub log($)
{	my ($self, $insert) = @_;
	$insert = { text => $insert } unless ref $insert eq 'HASH';
	$insert->{timestamp} //= Mango::BSON::Time->new;
	push @{$self->_data->{logging}}, $insert;
}

1;