package OwnerConsole;
use Mojo::Base 'Mojolicious';

use Mango;
use feature 'state';

my (%dbconfig, %dbservers);
sub dbserver($)  # server connections shared, when databases on same server
{	my $server = $_[1] || 'mongodb://localhost:27017';
	$dbservers{$server} ||= Mango->new($server);
}

sub users() {
	my $config = $dbconfig{users};
	state $u   = $_[0]->dbserver($config->{server})->db($config->{dbname} || 'users');
}

# This method will run once at server start

sub startup {
	my $self = shift;

	### Load configuration from hash returned by config file
	my $config = $self->plugin('Config');

	### Configure the application
	$self->secrets($config->{secrets});

	$self->plugin('BootstrapAlerts');

	$dbconfig{users} = $config->{users};
	$self->helper(dbserver => \&dbserver);
	$self->helper(users    => \&users);

	### Routes

	my $r = $self->routes;
	$r->get('/')->to('outsider#frontpage');
	$r->get('/login')->to('login#index');
	$r->post('/login')->to('login#tryLogin');
	$r->get('/logout')->to('login#logout');
	$r->get('/login/register')->to('login#register');
	$r->post('/login/register')->to('login#tryRegister');

	my $authorized = $r->under('/dashboard')->to('login#mustBeLoggedIn');
warn "AUTHORIZED $authorized";
	$authorized->get('/')->to('dashboard#index');
#	$r->get('/dashboard')->to('dashboard#index');
}

1;
