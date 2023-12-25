package OwnerConsole;
use Mojo::Base 'Mojolicious';

# This method will run once at server start

sub startup {
	my $self = shift;

	### Load configuration from hash returned by config file
	my $config = $self->plugin('Config');

	### Configure the application
	$self->secrets($config->{secrets});

	$self->plugin('BootstrapAlerts');

	my $mongodb = $config->{mongodb};
	$self->plugin('Mango', { mango => $mongodb, default_db => 'oc' });

	### Routes

	my $r = $self->routes;
	$r->get('/')->to('outsider#frontpage');
	$r->get('/login')->to('login#index');
	$r->get('/logout')->to('login#logout');

	my $authorized = $r->under('/dashboard')->to('Login#mustBeLoggedIn');
	$r->post('/login')->to('login#isValidUser');
}

1;
