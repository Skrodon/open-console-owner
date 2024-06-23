# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole;
use Mojo::Base 'OpenConsole';

use Log::Report 'open-console-owner';

use feature 'state';

use Mango;
use Minion::Backend::Mango      ();

use List::Util  qw(first);

use OpenConsole::Util           qw(reseed_tokens);
use OwnerConsole::Model::Batch  ();
#use OwnerConsole::Tasks         ();

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

=method batch
The C<batch> database (M<OwnerConsole::Model::Batch>) contains run-time
information, which is localized to a single instance of the Open Console
website.  It also contains the Minion administration.

Run this on that instance itself for performance.  The data is not important enough
for expensive protection.
=cut

sub batch()
{	my $self   = shift;
	my $config = $dbconfig{batchdb};
	state $e   = OwnerConsole::Model::Batch->new(db => $self->_dbserver($config->{server})->db($config->{dbname}))->upgrade;
}

#----------------
=section Other

=method isAdmin $account
=cut

my %admins;   # emails are case insensitive
sub isAdmin($) { $admins{lc $_[1]->email} }
sub tasks() { $_[0]->{O_tasks} }

# This method will run once at server start
sub startup
{	my $self = shift;
	$self->SUPER::startup(@_);

	# Load configuration from hash returned by config file
	my $config = $self->plugin('Config');
	$config->{vhost} ||= 'https://' . $ENV{HTTP_HOST};

	### Configure the application
	$self->renderer->cache->max_keys(0);  # the forms are never the same
	%admins = map +(lc($_) => 1), @{$config->{admins} || []};

#	$self->plugin('CSRFProtect');
	$self->plugin('BootstrapAlerts');
	$self->plugin('I18NUtils');

	$dbconfig{$_}    = $config->{$_} for @databases;
	my $minion       = $config->{minion} || {};
#	$self->{O_tasks} = OwnerConsole::Tasks->start(dbserver => MONGODB_CONNECT, %$minion);

#$::app->users->db->collection('accounts')->remove({});  #XXX hack clean whole accounts table

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
