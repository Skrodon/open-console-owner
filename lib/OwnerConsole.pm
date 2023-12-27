package OwnerConsole;
use Mojo::Base 'Mojolicious';

#use Mango;
#use feature 'state';
 
#sub dbserver { state $m = Mango->new('mongodb://localhost:27017') }
#sub users    { state $u = dbserver->db('users') }

# This method will run once at server start

sub startup {
	my $self = shift;

	### Load configuration from hash returned by config file
	my $config = $self->plugin('Config');

	### Configure the application
	$self->secrets($config->{secrets});

	$self->plugin('BootstrapAlerts');

	my $mongodb = $config->{mongodb};

	### Routes

	my $r = $self->routes;
	$r->get('/')->to('outsider#frontpage');
	$r->get('/login')->to('login#index');
	$r->get('/logout')->to('login#logout');
	$r->get('/login/register')->to('login#register');

	my $authorized = $r->under('/dashboard')->to('Login#mustBeLoggedIn');
	$r->post('/login')->to('login#isValidUser');
}

1;
