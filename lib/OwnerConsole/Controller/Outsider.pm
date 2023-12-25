package OwnerConsole::Controller::Outsider;
use Mojo::Base 'Mojolicious::Controller';

sub frontpage {
  my $self = shift;

  $self->render(template => 'frontpage');
}

1;
