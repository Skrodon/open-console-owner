package OwnerConsole::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

sub index($)
{	my $self = shift;

	$self->render(template => 'login/user');
}

1;
