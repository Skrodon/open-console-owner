package OwnerConsole::Model::Emails;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, $class;
    return $self;
}

1;
