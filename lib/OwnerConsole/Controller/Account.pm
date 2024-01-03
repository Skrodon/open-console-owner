package OwnerConsole::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';

sub index($)
{	my $self = shift;
	$self->render(template => 'login/account');
}

sub index2($)
{	my $self = shift;
	$self->render(template => 'login/account2');
}

1;
