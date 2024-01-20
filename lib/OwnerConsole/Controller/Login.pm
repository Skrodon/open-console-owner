package OwnerConsole::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use Lingua::EN::Numbers qw(num2en);

use OwnerConsole::Util  qw(val_line is_valid_email);
use OwnerConsole::Email ();

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
	$self->session(expiration => $self->config->{sessions}{expire} || 600);
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
	$self->redirect_to('/');
}

###### Reset password

sub startResetPassword()
{	my $self   = shift;
	my $random = int(rand 1000);
	$self->session(human_check => $random);
    $self->render(template => 'login/reset', human_check => num2en($random));
}

sub submitResetPassword()
{	my $self  = shift;
	my $email = val_line($self->param('email'));
	my $check = val_line($self->param('human-check')) // '';

	if($check ne $self->session('human_check'))
	{	$self->notify(error => __x"Incorrect value in challenge");
		return $self->startResetPassword;
	}

	if(! is_valid_email $email)
	{	$self->notify(error => __x"Invalid email-address.  Password reset procedure not started.");
		return $self->startResetPassword;
	}

	my $victim = $::app->users->accountByEmail($email);
	unless($victim)
	{	$self->notify(error => __x"This account is not known.  Password reset procedure not started.");
		#XXX when the account owns this address, then we may hint for the account name.
		return $self->startResetPassword;
	}

	my $token   = $::app->newUnique;

	$victim->startPasswordReset($token);
	$victim->save;

	my $vhost   = $self->config('vhost');
	$self->stash(link => "$vhost/reset?user=$email&token=$token");

	my $config  = $self->config('email');
	my $task    = OwnerConsole::Email->create(
		subject => 'Password reset requested',
       	text    => $self->render_to_string('login/mail_reset', format => 'txt'),
       	html    => $self->render_to_string('login/mail_reset', format => 'html'),
       	sender  => undef,
       	sendto  => $email,
       	purpose => 'password reset',
       	state   => 'start',
   	);

#XXX move this to minion
	$task->buildMessage($config)->send(to => $task->sendTo);

	$self->notify(info => __x"Password reset procedure started: await an email.");
	$self->startResetPassword;
}

sub runReset($)
{	my $self  = shift;
	my $email = val_line($self->param('user'));
	my $token = val_line($self->param('token'));

	my $victim = $::app->users->accountByEmail($email);
	unless($victim)
	{	$self->notify(error => __x"Cannot find account `{email}` for reset", email => $email);
	    $self->session(is_auth => 0, expires => 1);   # was accidentally still logged-in
		return $self->index;
	}

	if($victim->correctResetToken($token))
	{	$self->login($victim);
		return $self->redirect_to('/dashboard/account');
	}

	$self->notify(error => __x"Password reset procedure failed");
	$self->startResetPassword;
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

	if($check ne $self->session('human_check'))
	{	$self->notify(error => __x"Incorrect value in challenge");
		return $self->register;
	}

	unless(is_valid_email $email)
	{	$self->notify(error => __x"The email address is invalid");
		return $self->register;
	}

	if($self->users->accountByEmail($email))
	{	$self->notify(error => __x"Username already exist. Please start the password-reset procedure.");
		return $self->register;
	}

	my $account = $self->users->createAccount({
		email    => $email,
		password => $password,
		iflang   => $self->language,
	 });

	$self->login($account);
	$self->redirect_to('/dashboard');
}

1;
