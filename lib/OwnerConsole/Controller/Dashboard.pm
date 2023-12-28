package OwnerConsole::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller';

sub index($)
{	my $self = shift;
	$self->render(template => 'dashboard/index');
}

1;
