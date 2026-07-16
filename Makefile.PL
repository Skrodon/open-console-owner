# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

use ExtUtils::MakeMaker;

use 5.016;

# Use command 'oodist' to produce your whole software release.
my $git      = "https://github.com/Skrodon/open-console-owner";
my $publish  = "/home/markov/shared/perl/public_html/open-console-owner";
my $homepage = "https://perl.overmeer.net/open-console";

my %oodist   = (
	oodoc_version => 3.06,
	first_year    => 2024,
	email         => "team\@open-console.eu",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
		],
		pmhead         => undef,
	},

	tests    => {
	},

	release  => {
		publish        => "$publish/source",
	},

	generate => [ { }, ],
);

my %requires = (
	# Common purpose modules
	'Crypt::PBKDF2'          => 0,
	'Data::Dumper'           => 0,
	'DateTime'               => 1.50,
	'Devel::GlobalDestruction' => 0,
	'Email::Valid'           => 1.202,
	'HTML::Entities'         => 0,
	'Lingua::EN::Numbers'    => 2.03,
	'List::Util'             => 0,
	'Log::Report'            => 0,
	'Mail::Message'          => 3.00,
	'Session::Token'         => 1.503,

	# Website and database framwork
	'Mango'                  => 0,
	'Mojolicious'            => 9.35,
	'Mojolicious::Plugin::BootstrapAlerts' => 0.07,
	'Mojolicious::Plugin::CSRFProtect'     => 0.16,
	'Mojolicious::Plugin::I18NUtils'       => 0.21,
);

WriteMakefile
	NAME     => 'Open::Console::Owner',
	VERSION  => '0.04',

	EXE_FILES    => [],
	AUTHOR       => 'Open Console <team@open-console.eu>',
	ABSTRACT     => 'Open Console Owners Website',
	LICENSE      => 'perl_5',

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => "$git.git",
				web  => $git,
			},
			bugtracker => {
				web  => "$git/issues",
			},
			homepage => $homepage,
			license  => [ 'https://dev.perl.org/licenses/' ],
		},
		prereqs => {
			runtime => {
				requires => \%requires,
				recommends => {},
				suggests   => {},
			},
			develop => {
				requires => {
					'OODoc' => '3.00',
				},
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				},
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

css:
	sass --silence-deprecation mixed-decls scss/main.scss public/assets/open-console.css
__POSTAMBLE
