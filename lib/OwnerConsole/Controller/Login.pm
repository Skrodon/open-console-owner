package OwnerConsole::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

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
	my $user     = lc $email;

	# First check if the user exists
	my $account = $self->users->account($user);
	unless(defined $account)
	{	$self->notify(error => "You are not registered.");
		return $self->index;
	}

	unless($account->correctPassword($password))
	{	$self->notify(error => "Invalid password, please try again.");
		return $self->index;
	}

	$self->login($user);
	$self->redirect_to('/dashboard');
}

sub login($)
{	my ($self, $user) = @_;

	# Create session cookie
	$self->session(is_auth => 1);		# set the logged_in flag
	$self->session(user    => $user);
	$self->session(expiration => EXPIRE_SESSION);
}

sub mustBeLoggedIn($)
{	my $self = shift;
	return 1 if $self->session('is_auth');

	$self->notify(error => "You are not logged in, please login to access this.");
	$self->redirect_to('/login');
}

###### Logout

sub logout()
{	my $self = shift;
	$self->session(expires => 1);  # Kill the Session cookie
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
	my $user     = lc $email;
	#XXX use Email::Valid to check email, otherwise return with notify(error)
	#XXX check password length

	if($self->users->account($user))
	{	$self->notify(error => 'Username already exist. Please start the password-reset procedure.');
		return $self->register;
	}

	$self->users->createAccount({ user => $user, email => $email, password => $password });

	$self->notify(warning => 'User is created successfully');
	$self->login($user);
	$self->redirect_to('/dashboard');
}

1;
