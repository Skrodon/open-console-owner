package OwnerConsole::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

use constant {
	EXPIRE_SESSION => 600,  # seconds of inactivity
};

sub index($)
{	my ($self, $error) = @_;
	$self->notify(error => $error) if defined $error;

	if($self->session('is_auth'))
	{	$self->frontpage;
	}
	else
	{	$self->render(template => 'login/index');
	}
}

sub logout()
{	my $self = shift;
	$self->session(expires => 1);  # Kill the Session
	$self->render(template => 'login/logout');
}

sub register()
{	my $self = shift;

	my $user     = uc $self->param('username');
	my $password = $self->param('password');
	my $confirm  = $self->param('confirm_password');

	if($password ne $confirm)
	{	$self->notify(error => "The passwords are not the same.");
		$self->render(template => 'login/register');
	}
}

sub isValidUser
{	my $self = shift;

	# List of registered users
	my %validUsers = ( "JANE" => "welcome123"
					  ,"JILL" => "welcome234"
					  ,"TOM"  => "welcome345"
					  ,"RAJ"  => "test123"
					  ,"RAM"  => "digitalocean123"
					 );

	my $user     = uc $self->param('username') =~ s/\@.*//r;
	my $password = $self->param('password');

	# First check if the user exists
	if($validUsers{$user})
	{	$self->notify(error => "You are not a registered user");
		return $self->index;
	}

	# Validating the password of the registered user
	if($validUsers{$user} ne $password)
	{	$self->notify(error => "Invalid password, please try again");
		$self->index;
	}

	$self->login($user);  # Creating session cookies
	$self->redirect_to('/dashboard');       # Re-direct to home page
}

sub login($)
{	my ($self, $user) = @_;
	$self->session(is_auth => 1);		# set the logged_in flag
	$self->session(username => $user);
	$self->session(expiration => EXPIRE_SESSION);
}

sub mustBeLoggedIn($)
{	my $self = shift;
	return 1 if $self->session('is_auth');

	$self->notify(error => "You are not logged in, please login to access this.");
	$self->index;
}

1;