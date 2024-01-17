package OwnerConsole::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use Lingua::EN::Numbers qw(num2en);

use OwnerConsole::Util  qw(val_line is_valid_email);

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
	my $email    = val_line($self->param('email'));
	my $password = val_line($self->param('password'));

	my $account = $self->users->accountByEmail($email);
	unless(defined $account && $account->correctPassword($password))
	{	$self->notify(error => __x"Invalid login, please try again.");
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
	my $random  = int(rand 1000);
	$self->session(human_check => $random);
	$self->render(template => 'login/register', human_check => num2en($random));
}

sub tryRegister()
{	my $self = shift;
	my $email    = val_line($self->param('email'));
	my $password = val_line($self->param('password'));
	my $check    = val_line($self->param('human-check')) // '';

	# I do not care what the value of the "confirm password" is.

warn "CHECK($check) = ", $self->session('human_check');
	if($check ne $self->session('human_check'))
	{	$self->notify(error => __x"Incorrect value in challenge");
		return $self->register;
	}

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

	$self->notify(warning => __x"The user account is created.");
	$self->redirect_to('/dashboard');
}

1;
