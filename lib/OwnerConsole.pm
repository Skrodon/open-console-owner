package OwnerConsole;
use Mojo::Base 'Mojolicious';

use Mango;
use feature 'state';

use Session::Token ();
my $token_generator = Session::Token->new;

use List::Util  qw(first);

use OwnerConsole::Model::Users  ();
use OwnerConsole::Model::Emails ();

use OwnerConsole::Tables qw(language_name);

use Log::Report 'owner-console';

my (%dbconfig, %dbservers);
sub dbserver($)  # server connections shared, when databases on same server
{	my $server = $_[1] || 'mongodb://localhost:27017';
	$dbservers{$server} ||= Mango->new($server);
}

sub users()
{	my $config = $dbconfig{users};
	state $u   = OwnerConsole::Model::Users->new(db =>
		$_[0]->dbserver($config->{server})->db($config->{dbname} || 'users'))->upgrade;
}

sub emails()
{	my $config = $dbconfig{emails};
	state $e   = OwnerConsole::Model::Emails->new(db =>
		$_[0]->dbserver($config->{server})->db($config->{dbname} || 'emails'))->upgrade;
}

sub _languageTable($)   #XXX probably better remove this
{	my $langs = $_[1];
	[ map +[ $_ => language_name($_) ], @$langs ];
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

	$dbconfig{users} = $config->{users};
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

	$self->helper(newUnique => sub { $config->{instance} . ':' . $token_generator->get });

	srand;

	my $iflangs = $config->{interface_languages};
	my %langs   = map +($_ => 1), @$iflangs;
	$self->helper(language    => sub { $self->_detectLanguage($_[0], \%langs, $iflangs->[0]) });
	$self->helper(ifLanguages => sub { my $l = $self->{O_langs} ||= $self->_languageTable($iflangs); @$l });

	# Run at start of each fork
	Mojo::IOLoop->timer(0 => sub {
		$token_generator = Session::Token->new;
	});

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

	my $dashboard = $r->under('/dashboard')->to('login#mustBeLoggedIn');
	$dashboard->get('/')->to('dashboard#index');

	$dashboard->get('/account')->to('account#index');
	$dashboard->post('/config_account/:userid')->to('account#submit');

	$dashboard->get('/identities')->to('identities#index');
	$dashboard->get('/identity/:identid')->to('identities#identity');
	$dashboard->post('/config_identity/:identid')->to('identities#submit_identity');

	$dashboard->get('/groups')->to('groups#index');
	$dashboard->get('/group/:groupid')->to('groups#group');
	$dashboard->post('/config_group/:groupid')->to('groups#submit_group');
	$dashboard->post('/config_member/:groupid')->to('groups#submit_member');
}

1;
