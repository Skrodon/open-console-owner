package OwnerConsole;
use Mojo::Base 'Mojolicious';

use Mango;
use feature 'state';

use OwnerConsole::Model::Users ();

my (%dbconfig, %dbservers);
sub dbserver($)  # server connections shared, when databases on same server
{	my $server = $_[1] || 'mongodb://localhost:27017';
	$dbservers{$server} ||= Mango->new($server);
}

sub users() {
	my $config = $dbconfig{users};
	state $u   = OwnerConsole::Model::Users->new(db =>
		$_[0]->dbserver($config->{server})->db($config->{dbname} || 'users'));
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

	# route for user page test - must be checked with login later
	$r->get('/dashboard/user')->to('user#index');

	my $dashboard = $r->under('/dashboard')->to('login#mustBeLoggedIn');
	$dashboard->get('/')->to('dashboard#index');
}

1;
