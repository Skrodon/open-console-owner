package OwnerConsole::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

use Crypt::PBKDF2 ();
my $crypt = Crypt::PBKDF2->new;

#XXX $self->users->collection('users') will be move to OpenConsole::Model::Users
#XXX when this works.

use constant {
	EXPIRE_SESSION => 600,  # seconds of inactivity
};

###### Login

sub index()
{	my $self = shift;

	if($self->session('is_auth'))
	{	$self->redirect_to('/dashboard');
	}
	else
	{	$self->render(template => 'login/index');
	}
}

sub tryLogin()
{	my $self = shift;
	my $email    = $self->param('username');
	my $password = $self->param('password');

	# First check if the user exists
	my $user = $self->users->collection('users')->find_one({user => lc $email});
	unless(defined $user)
	{	$self->notify(error => "You are not a registered user");
		return $self->index;
	}

	# Validating the password of the registered user
	unless($crypt->verify($user->{password}, $password))
	{	$self->notify(error => "Invalid password, please try again");
		return $self->index;
	}

	$self->login($user);  # Creating session cookies
	$self->redirect_to('/dashboard');     # Re-direct to home page
}

sub login($)
{	my ($self, $user) = @_;
	$self->session(is_auth => 1);		# set the logged_in flag
	$self->session(username => $user);
	$self->session(expiration => EXPIRE_SESSION);
}

sub mustBeLoggedIn($)
{	my $self = shift;
warn "IS AUTH?";
	return 1 if $self->session('is_auth');
warn "NO";

	$self->notify(error => "You are not logged in, please login to access this.");
	$self->index;
}

###### Logout

sub logout()
{	my $self = shift;
	$self->session(expires => 1);  # Kill the Session
	$self->render(template => 'login/logout');
}

###### Register

sub register()
{	my $self = shift;
	$self->render(template => 'login/register');
}

sub tryRegister()
{	my $self = shift;
	my $email    = $self->param('username');
	my $password = $self->param('password');
	#XXX use Email::Valid to check email, otherwise return with notify(error)
	#XXX check password length

	my $encr_passwd = $crypt->generate($password);
	$self->users->collection('users')
		->insert({ user => lc $email, email => $email, password => $encr_passwd });

	$self->notify(warning => 'User is created successfully');
	$self->login(lc $email);
	$self->redirect_to('/dashboard');
}

1;