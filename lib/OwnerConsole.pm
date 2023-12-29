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
sub startup
{	my $self = shift;
	$main::app = $self;  #XXX probably not the right way

	### Load configuration from hash returned by config file
	my $config = $self->plugin('Config');

	### Configure the application
	$self->secrets($config->{secrets});

	$self->plugin('BootstrapAlerts');

	$dbconfig{users} = $config->{users};
	$self->helper(dbserver => \&dbserver);
	$self->helper(users    => \&users);
#$self->users->db->collection('accounts')->remove({});  #XXX hack clean whole accounts table

	# 'user' is the logged-in user, the admin can select to show a different 'account'
	$self->helper(user     => sub { state $u = $_[0]->users->account($_[0]->session('user')) });
	$self->helper(account  => sub { state $a = $_[0]->users->account($_[0]->session('account') or return $_[0]->user) });

	### Routes

	my $r = $self->routes;
	$r->get('/')->to('outsider#frontpage');
	$r->get('/login')->to('login#index');
	$r->post('/login')->to('login#tryLogin');
	$r->get('/logout')->to('login#logout');
	$r->get('/login/register')->to('login#register');
	$r->post('/login/register')->to('login#tryRegister');

	my $dashboard = $r->under('/dashboard')->to('login#mustBeLoggedIn');
	$dashboard->get('/')->to('dashboard#index');
	$dashboard->get('/account')->to('account#index');
}

1;
