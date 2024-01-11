package OwnerConsole::Util;
use Mojo::Base 'Exporter';

use Email::Valid             ();

our @EXPORT_OK = qw(
	flat
	is_valid_gender
	is_valid_email
	is_valid_phone
	val_line
	val_text
);

our %EXPORT_TAGS = (
   validate => [ qw/is_valid_gender is_valid_email is_valid_phone val_line val_text/ ],
);

sub flat(@) { grep defined, map ref eq 'ARRAY' ? @$_ : $_, @_ }

sub val_line($)
{	my $line = shift;
	defined $line && $line =~ /\S/ or return undef;
	$line =~ s/\s{2,}/ /gr =~ s/^ //r =~ s/ $//gr;
}

sub val_text($)
{	my $text = shift;
	defined $text && $text =~ /\S/ or return undef;
	$text =~ s/\s{2,}/ /gr =~ s/ $//gmr =~ s/\n{2,}/\n/gr;
}

my %known_genders = map +($_ => 1), qw(female male they none);
sub is_valid_gender($) { $_[0] eq '' || $known_genders{$_[0]} }

sub is_valid_email($) {	Email::Valid->address($_[0]) }

sub is_valid_phone($) { $_[0] =~ m!^\+[0-9 \-]{4,}(?:/.+)?! }

1;
