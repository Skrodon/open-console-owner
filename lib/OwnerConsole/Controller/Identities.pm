package OwnerConsole::Controller::Identities;
use Mojo::Base 'Mojolicious::Controller';

sub index($)
{   my $self = shift;
    $self->render(template => 'identities/index');
}

sub identity($)
{   my $self = shift;
    $self->render(template => 'identities/identity');
}

1;
