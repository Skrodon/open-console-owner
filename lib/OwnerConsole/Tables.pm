package OwnerConsole::Tables;
use Mojo::Base 'Exporter';

our @EXPORT_OK = qw(language_name language_table);

my %language_names = (
	'en'    => 'English',
	'en-US' => 'American',
	'gr'    => 'Ελληνικά',
	'nl'    => 'Nederlands',
	'nl-BE' => 'Vlaams',
	'pt'    => 'Português',
	'pt-BR' => 'Brasileiro',
	'pt-PT' => 'Português',
	'ru'    => 'Русский язык',
	'vi'    => 'Tiếng Việt',
);

sub language_name($)
{	my $code = shift;
	$language_names{$code} || $code;
}

my @language_table = sort { $a->[1] cmp $b->[1] } map +[ $_ => $language_names{$_} ], keys %language_names;
sub language_table() { \@language_table }

1;
