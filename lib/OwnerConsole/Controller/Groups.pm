package OwnerConsole::Controller::Groups;
use Mojo::Base 'Mojolicious::Controller';

sub index($)
{   my $self = shift;
    $self->render(template => 'groups/index');
}

sub group($)
{   my $self = shift;
    $self->render(template => 'groups/group');
}

1;
