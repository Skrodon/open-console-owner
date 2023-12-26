package OwnerConsole::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

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

sub logout
{	my $self = shift;
	$self->session(expires => 1);  # Kill the Session
	$self->render(template => 'login/logout');
}

sub register
{
	my $self = shift;

	# Get the user name and password from the page
	my $user     = uc $self->param('username') =~ s/\@.*//r;
	my $password = $self->param('password');
    my $confirmPassword = $self->param('confirm_password');
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

	# Get the user name and password from the page
	my $user     = uc $self->param('username') =~ s/\@.*//r;
	my $password = $self->param('password');

	# First check if the user exists
	if($validUsers{$user})
	{
		# Validating the password of the registered user
		if($validUsers{$user} eq $password) {
			# Creating session cookies
			$self->session(is_auth => 1);		# set the logged_in flag
			$self->session(username => $user);	# keep a copy of the username
			$self->session(expiration => 600);	# expire this session in 10 minutes if no activity

			# Re-direct to home page
			$self->frontpage;
		}
		else
		{	$self->index("Invalid password, please try again");
		}
	}
	else
	{	$self->stash(alert => { level => 'error', text => 'Not registered' });
		$self->index("You are not a registered user, please get the hell out of here!");
	}
}

sub mustBeLoggedIn($)
{	my $self = shift;
	return 1 if $self->session('is_auth');

	$self->index("You are not logged in, please login to access this.");
}

1;
