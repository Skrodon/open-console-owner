package OwnerConsole::Mango::Object;
use Mojo::Base -base;

has '_data';

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

sub toDB() { $_[0]->_data }  #XXX might become more complex later

=section Attributes
=cut

sub created() { my $c = $_[0]->_data->{created}; $c ? $c->to_datetime : undef }

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
warn "LOGGING: ", $insert->{text}, "\n";
return;
	$insert->{timestamp} //= Mango::BSON::Time->new;
#	$insert->{user}      //= $::app->user->username;
	push @{$self->_data->{logging}}, $insert;
}

1;
