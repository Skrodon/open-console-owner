package OwnerConsole;
use Mojo::Base 'Mojolicious';

use Mango;
use feature 'state';

use Data::UUID    ();
my $ug    = Data::UUID->new;

use List::Util  qw(first);

use OwnerConsole::Model::Users ();

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

sub _languageTable($)
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

	### Configure the application
	$self->secrets($config->{secrets});
	%admins = map +(lc($_) => 1), @{$config->{admins} || []};

	$self->plugin('BootstrapAlerts');
	$self->plugin('I18NUtils');

	$dbconfig{users} = $config->{users};
	$self->helper(dbserver => \&dbserver);
	$self->helper(users    => \&users);
#$self->users->db->accounts->remove({});  #XXX hack clean whole accounts table

	# 'user' is the logged-in user, the admin can select to show a different 'account'
	$self->helper(user      => sub { $self->{O_user}    ||= $_[0]->users->account($_[0]->session('userid')) });
	$self->helper(account   => sub { $self->{O_account} ||= $_[0]->users->account($_[0]->session('account') or return $_[0]->user) });
	$self->helper(newUnique => sub { $config->{instance} . ':' . $ug->create_str });

	my $iflangs = $config->{interface_languages};
	my %langs   = map +($_ => 1), @$iflangs;
	$self->helper(language    => sub { $self->_detectLanguage($_[0], \%langs, $iflangs->[0]) });
	$self->helper(ifLanguages => sub { my $l = $self->{O_langs} ||= $self->_languageTable($iflangs); @$l });

	### Routes

	my $r = $self->routes;
	$r->get('/')->to('outsider#frontpage');
	$r->get('/set')->to('outsider#set');
	$r->get('/login')->to('login#index');
	$r->post('/login')->to('login#tryLogin');
	$r->get('/logout')->to('login#logout');
	$r->get('/login/register')->to('login#register');
	$r->post('/login/register')->to('login#tryRegister');

	my $dashboard = $r->under('/dashboard')->to('login#mustBeLoggedIn');
	$dashboard->get('/')->to('dashboard#index');
	$dashboard->get('/account')->to('account#index');
	$dashboard->get('/identities')->to('identities#index');
	$dashboard->get('/identity')->to('identities#identity');
}

1;
