# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole;
use Mojo::Base 'Mojolicious';

use Log::Report 'open-console-owner';

use feature 'state';

use Mango;
use Minion::Backend::Mango      ();

use List::Util  qw(first);

use OwnerConsole::Util          qw(reseed_tokens);
use OwnerConsole::Model::Users  ();
use OwnerConsole::Model::Batch  ();
use OwnerConsole::Model::Proofs ();

use OwnerConsole::Tables qw(language_name);

my (%dbconfig, %_dbservers);
my @databases = qw/userdb batchdb proofdb/;

use constant
{	MONGODB_CONNECT => 'mongodb://localhost:27017',
};

=chapter NAME

OwnerConsole - Open Console Owner's Website

=chapter SYNOPSIS

  morbo script/owner_console &

=chapter DESCRIPTION

=chapter METHODS

=section Constructors
Standard M<Mojo::Base> constructors.

=section Databases
The application may configure different MongoDB databases (clusters), for different
characteristics of tasks.

=method users
The C<users> database (M<OwnerConsole::Model::Users>), contains generic user and group
information.  It is important data, and inconsistencies in the administration shall not
happen at any cost.

=method batch
The C<batch> database (M<OwnerConsole::Model::Batch>) contains run-time
information, which is localized to a single instance of the Open Console
website.  It also contains the Minion administration.

Run this on that instance itself for performance.  The data is not important enough
for expensive protection.

=method proofs
The C<proofs> database (M<OwnerConsole::Model::Proofs>) contains the proof
and contract administration.  Less important than the C<users> database information.
=cut

sub _dbserver($)  # server connections shared, when databases on same server
{	my $server = $_[1] || MONGODB_CONNECT;
	$_dbservers{$server} ||= Mango->new($server);
}

sub users()
{	my $self   = shift;
	my $config = $dbconfig{userdb};
	state $u   = OwnerConsole::Model::Users->new(db => $self->_dbserver($config->{server})->db($config->{dbname}))->upgrade;
}

sub batch()
{	my $self   = shift;
	my $config = $dbconfig{batchdb};
	state $e   = OwnerConsole::Model::Batch->new(db => $self->_dbserver($config->{server})->db($config->{dbname}))->upgrade;
}

sub proofs()
{	my $self   = shift;
	my $config = $dbconfig{proofdb};
	state $p   = OwnerConsole::Model::Proofs->new(db => $self->_dbserver($config->{server})->db($config->{dbname}))->upgrade;
}

#----------------
=section Other

=method isAdmin $account
=cut

my %admins;   # emails are case insensitive
sub isAdmin($) { $admins{lc $_[1]->email} }

# This method will run once at server start
sub startup
{	my $self = shift;
	$main::app = $self;  #XXX probably not the right way

	# Load configuration from hash returned by config file
	my $config = $self->plugin('Config');
	$config->{vhost} ||= 'https://' . $ENV{HTTP_HOST};

	### Configure the application
	$self->secrets($config->{secrets});
	$self->renderer->cache->max_keys(0);  # the forms are never the same
	%admins = map +(lc($_) => 1), @{$config->{admins} || []};

#	$self->plugin('CSRFProtect');
	$self->plugin('BootstrapAlerts');
	$self->plugin('I18NUtils');

	$dbconfig{$_} = $config->{$_} for @databases;

	my $minion  = $config->{minion} || {};
	my $minion_server = delete $minion->{server} || MONGODB_CONNECT;
	$self->plugin(Minion => { Mango => $minion_server });
#	$self->plugin(Minion::Admin => { });   # under /minion

#$::app->users->db->collection('accounts')->remove({});  #XXX hack clean whole accounts table

	# 'user' is the logged-in user, the admin can select to show a different 'account'
	$self->helper(user      => sub {
		my $c = shift;
		my $user;
		unless($user = $c->stash('user'))
		{	$user = $self->users->account($c->session('userid'));
			$c->stash(user => $user);
		}
		$user;
	});

	$self->helper(account   => sub {
		my $c = shift;
		my $account;
		unless($account = $c->stash('account'))
		{	my $aid = $c->session('account');
			$account = defined $aid ? $self->users->account($aid) : $c->user;
			$c->stash(account => $account);
		}
		$account;
	});

	# Run at start of each fork
	srand;
	Mojo::IOLoop->timer(0 => sub { srand; reseed_tokens });

	### Routes

	my $r = $self->routes;
	$r->get('/')->to('outsider#frontpage');
	$r->get('/set')->to('outsider#set');
	$r->get('/login')->to('login#index');
	$r->post('/login')->to('login#tryLogin');
	$r->get('/logout')->to('login#logout');
	$r->get('/login/register')->to('login#register');
	$r->post('/login/register')->to('login#tryRegister');
	$r->get('/login/reset')->to('login#startResetPassword');
	$r->post('/login/reset')->to('login#submitResetPassword');
	$r->get('/reset')->to('login#runReset');

	# All 'post' routes are ajax calls, all 'get's are returning pages.

	my $dashboard = $r->under('/dashboard')->to('login#mustBeLoggedIn');
	$dashboard->get('/')->to('dashboard#index');

	$dashboard->get('/account')->to('account#index');
	$dashboard->post('/config-account/:userid')->to('account#configAccount');

	$dashboard->get('/identities')->to('identities#index');
	$dashboard->get('/identity/:identid')->to('identities#identity');
	$dashboard->post('/config-identity/:identid')->to('identities#configIdentity');

	$dashboard->get('/groups')->to('groups#index');
	$dashboard->get('/group/:groupid')->to('groups#group');
	$dashboard->post('/config-group/:groupid')->to('groups#configGroup');
	$dashboard->post('/config-member/:groupid')->to('groups#configMember');
	$dashboard->any('/invite-accept/:token')->to('groups#inviteAccept');

	$dashboard->get('/emailaddrs')->to('emailaddrs#index');
	$dashboard->get('/emailaddr/:proofid')->to('emailaddrs#emailaddr');
	$dashboard->post('/config-emailaddr/:proofid')->to('emailaddrs#configEmailaddr');

	$dashboard->get('/websites')->to('websites#index');
	$dashboard->get('/website/:proofid')->to('websites#website');
	$dashboard->post('/config-website/:proofid')->to('websites#configWebsite');

	$dashboard->get('/contracts')->to('contracts#index');
	$dashboard->get('/contract/:proofid')->to('contracts#contract');
	$dashboard->post('/config-contract/:proofid')->to('contracts#configContract');

	$dashboard->get('/service/:demo')->to('dashboard#demo');

	my $challenge = $r->under('/challenge')->to('login#mustBeLoggedIn');
	$challenge->get('/:token')->to('emailaddrs#challenge');  #XXX may get own controller later

	$r->get('/invite/:token')->to('groups#inviteChoice');
}

1;
