package OwnerConsole::Controller::Outsider;
use Mojo::Base 'Mojolicious::Controller';

sub frontpage()
{	my $self = shift;
	$self->render(template => 'frontpage');
}

sub set()
{	my $self = shift;
	if(my $lang = $self->param('language'))
	{	$self->session('iflang', $lang);
	}
	$self->frontpage;
}

1;
