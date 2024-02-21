package OwnerConsole::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller';

sub index()
{	my $self = shift;
	$self->render(template => 'dashboard/index');
}

sub demo()
{	my $self = shift;
	my $demo = $self->param('demo');

warn "DEMO $demo";
	$self->render(template => "demo/$demo");
}

1;
