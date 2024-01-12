package OwnerConsole::Util;
use Mojo::Base 'Exporter';

use Email::Valid  ();
use List::Util    qw(first);
use DateTime      ();

use OwnerConsole::Tables     qw(language_name gender_name timezone_names);

my @is_valid = qw(
	is_valid_gender
	is_valid_email
	is_valid_phone
	is_valid_language
	is_valid_timezone
	is_valid_date
);

our @EXPORT_OK = (@is_valid, qw(
	flat
	val_line
	val_text
	bson2datetime
));

our %EXPORT_TAGS = (
   validate => [ @is_valid, qw/val_line val_text/ ],
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

sub is_valid_gender($)   { defined gender_name($_[0]) }
sub is_valid_language($) { defined language_name($_[0]) }
sub is_valid_timezone($) { defined first { $_ eq $_[0] } @{timezone_names()} }

sub is_valid_email($)    { Email::Valid->address($_[0]) }
sub is_valid_phone($)    { $_[0] =~ m!^\+[0-9 \-]{4,}(?:/.+)?! }
sub is_valid_date($)     { $_[0] =~ s! ^\s* ([0-9]{4}) (?:[-/ ]?) ([0-9]{2}) (?:[-/ ]?)? ([0-9]{2}) \s*$ !$1-$2-$3!r }

sub bson2datetime($)
{	my $stamp = shift or return undef;
	DateTime->from_epoch(epoch => $stamp->to_epoch)->set_time_zone($::app->user->timezone);
}

1;
