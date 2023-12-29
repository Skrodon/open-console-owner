package OwnerConsole::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';

sub index($)
{	my $self = shift;
	$self->render(template => 'login/account', account => $self->account);
}

1;
