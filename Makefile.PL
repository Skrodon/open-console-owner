# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

use ExtUtils::MakeMaker;

use 5.016;

WriteMakefile
 ( NAME     => 'Open-Console-Owner'
 , VERSION  => '0.02'

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
	'Session::Token'         => 1.503,

	# Website and database framwork
	'Mango'                  => 0,
	'Mojolicious'            => 9.35,
	'Mojolicious::Plugin::BootstrapAlerts' => 0.07,
	'Mojolicious::Plugin::CSRFProtect'     => 0.16,
	'Mojolicious::Plugin::I18NUtils'       => 0.21,
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
RAWDIR          =
DISTDIR         = /home/markov/shared/perl/public_html/open-console-owner/source

# for POD
FIRST_YEAR      = 2024
EMAIL           = mark@open-console.eu
EXTENDS         = 
WEBSITE         = http://perl.overmeer.net/open-console

css:
	sass scss/main.scss public/assets/open-console.css
__POSTAMBLE
