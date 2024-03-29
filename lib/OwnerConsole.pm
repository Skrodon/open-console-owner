# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole;
use Mojo::Base 'Mojolicious';

use Mango;
use feature 'state';

use List::Util  qw(first);

use OwnerConsole::Util          qw(reseed_tokens);
use OwnerConsole::Model::Users  ();
use OwnerConsole::Model::Batch  ();
use OwnerConsole::Model::Proofs ();

use OwnerConsole::Tables qw(language_name);

use Log::Report 'open-console-owner';

my (%dbconfig, %dbservers);
my @databases = qw/userdb batchdb proofdb/;

sub dbserver($)  # server connections shared, when databases on same server
{	my $server = $_[1] || 'mongodb://localhost:27017';
	$dbservers{$server} ||= Mango->new($server);
}

sub users()
{	my $config = $dbconfig{userdb};
	state $u   = OwnerConsole::Model::Users->new(db => $_[0]->dbserver($config->{server})->db($config->{dbname}))->upgrade;
}

sub batch()
{	my $config = $dbconfig{batchdb};
	state $e   = OwnerConsole::Model::Batch->new(db => $_[0]->dbserver($config->{server})->db($config->{dbname}))->upgrade;
}

sub proofs()
{	my $config = $dbconfig{proofdb};
	state $p   = OwnerConsole::Model::Proofs->new(db => $_[0]->dbserver($config->{server})->db($config->{dbname}))->upgrade;
}

sub _detectLanguage($$)
{	my ($self, $c, $accepted, $default) = @_;
	if(my $if = $c->session('iflang')) { return $if }

	my @wants = $c->browser_languages;
	my $code  = first { exists $accepted->{$_} } @wants;

	unless($code)
	{	my @langs = map language_name($_), @wants;
#XXX notify is not shows
		$c->notify(warning => __x("None of the languages configured in your browser ({langs}) is supported for the Open Console interface at the moment.", langs => \@langs));
		$code = $default;
	}

	$c->session(iflang => $code);
	$code;
}


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

#	my $minion  = $config->{batch} or panic "Config for batch missing";
#	$minion->{backend} = Minion::Backend::Mango->new(delete $minion->{server});
#	$minion->{prefix}  = delete $minion->{dbname} || 'batch';
#	$self->plugin(Minion => $minion);

#	$self->plugin(Minion => { Mango => $minion->{server} });
#	$self->plugin(Minion::Admin => { });   # under /minion

	$dbconfig{$_} = $config->{$_} for @databases;

	$self->helper(dbserver => \&dbserver);
	$self->helper(users    => \&users);
#$self->users->db->collection('accounts')->remove({});  #XXX hack clean whole accounts table

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

	my $iflangs = $config->{interface_languages};
	my %langs   = map +($_ => 1), @$iflangs;
	$self->helper(language    => sub { $self->_detectLanguage($_[0], \%langs, $iflangs->[0]) });

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
