package OwnerConsole::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

use constant
{
	EXPIRE_SESSION => 600,  # seconds of inactivity, now 10 minutes
};

###### Login

sub index()
{	my $self = shift;

	return $self->redirect_to('/dashboard')
		if $self->session('is_auth');

	$self->render(template => 'login/index');
}

sub tryLogin()
{	my $self = shift;
	my $email    = $self->param('email');
	my $password = $self->param('password');
warn "TRY LOGIN ($email) ($password)";

	# First check if the user exists
	my $account = $self->users->accountByEmail($email);
	unless(defined $account)
	{	$self->notify(error => "You are not registered.");
		return $self->index;
	}

	unless($account->correctPassword($password))
	{	$self->notify(error => "Invalid password, please try again.");
		return $self->index;
	}

	$self->login($account);
	$self->redirect_to('/dashboard');
}

sub login($)
{	my ($self, $account) = @_;

	# Create session cookie
	$self->session(is_auth    => 1);
	$self->session(userid     => $account->userId);
	$self->session(expiration => EXPIRE_SESSION);
}

sub mustBeLoggedIn($)
{	my $self = shift;
	return 1 if $self->session('is_auth');

	$self->notify(error => "You are not logged in, please login to access this.");
	$self->redirect_to('/login');
	undef;
}

###### Logout

sub logout()
{	my $self = shift;
	$self->session(is_auth => 0, expires => 1);  # Kill the Session cookie
	$self->render(template => 'login/logout');
}

###### Register

sub register()
{	my $self = shift;
	$self->render(template => 'login/register');
}

sub tryRegister()
{	my $self = shift;
	my $email    = $self->param('email');
	my $password = $self->param('password');
	#XXX use Email::Valid to check email, otherwise return with notify(error)
	#XXX check password length
warn "PARAM EMAIL $email";
warn "PARAM PASSWD $password";

	if($self->users->accountByEmail($email))
	{	$self->notify(error => 'Username already exist. Please start the password-reset procedure.');
		return $self->register;
	}

	my $account = $self->users->createAccount({
		email    => $email,
		password => $password,
		iflang   => $self->language,
	 });

	$self->login($account);

	$self->notify(warning => 'The user account is created.');
	$self->redirect_to('/dashboard');
}

1;
