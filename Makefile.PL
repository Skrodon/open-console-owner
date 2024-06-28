# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

use ExtUtils::MakeMaker;

use 5.016;

WriteMakefile
 ( NAME     => 'Open-Console-Owner'
 , VERSION  => '0.01'

 , PREREQ_PM    => { 
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
	'Net::DNS'               => 1.44,
	'Net::DNS::SEC'          => 1.23,
	'Net::LibIDN2'           => 0.12,
	'Session::Token'         => 1.503,

	# Website and database framwork
	'Mango'                  => 0,
	'Mojolicious'            => 9.35,
	'Mojolicious::Plugin::CSRFProtect' => 0.16,

    # Required for the Minion task manager
	'Mojolicious::Plugin::Minion'        => 0,
    'Mojolicious::Plugin::Minion::Admin' => 0,
	'Minion'                 => 10.28,
	'Minion::Backend::Pg'    => 1.02,
    'Mojo::Pg'               => 0,
   }
 , EXE_FILES    => []
 , AUTHOR       => 'Open Console <team@open-console.eu>'
 , ABSTRACT     => 'Open Console Owners Website'
 , LICENSE      => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/Skrodon/open-console-owner.git'
              , web  => 'https://github.com/Skrodon/open-console-owner'
              }
          , homepage => 'http://open-console.eu'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = /tmp/OwnerConsole/raw
DISTDIR         = /tmp/OwnerConsole/source

# for POD
FIRST_YEAR      = 2024
EMAIL           = mark@open-console.eu
EXTENDS         = 
WEBSITE         = http://perl.overmeer.net/open-console

css:
	sass scss/main.scss public/assets/open-console.css
__POSTAMBLE
