package OwnerConsole::Controller::Register;
use Mojo::Base 'Mojolicious::Controller';

sub index($)
{	my ($self, $error) = @_;
	$self->notify(error => $error) if defined $error;

	if($self->session('is_auth'))
	{	$self->frontpage;
	}
	else
	{	$self->render(template => 'register/index');
	}
}

sub Register
{	my $self = shift;

	# Get the user name and password from the page
	my $user     = uc $self->param('username') =~ s/\@.*//r;
	my $password = $self->param('password');
    my $confirmPassword = $self->param('confirm_password');

}

1;
