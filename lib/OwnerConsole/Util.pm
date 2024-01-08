package OwnerConsole::Util;
use Mojo::Base 'Exporter';

our @EXPORT_OK = qw(
	flat
);

sub flat(@) { grep defined, map ref eq 'ARRAY' ? @$_ : $_, @_ }

1;
