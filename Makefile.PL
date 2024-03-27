# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

use ExtUtils::MakeMaker;

use 5.016;

WriteMakefile
 ( NAME     => 'Owner-Console'
 , VERSION  => '0.01'

 , PREREQ_PM    => { 
	'Crypt::PBKDF2'          => 0,
	'Data::Dumper'           => 0,
	'DateTime'               => 1.50,
	'Email::Valid'           => 1.202,
	'Lingua::EN::Numbers'    => 2.03,
	'List::Util'             => 0,
	'Log::Report'            => 0,
	'Mail::Message'          => 3.00,
	'Mango'                  => 0,
	'Minion'                 => 10.28,
	'Minion::Backend::Mango' => 1.02,
	'Mojolicious'            => 9.35,
	'Mojolicious::Plugin::CSRFProtect' => 0.16,
	'Net::LibIDN2'           => 0.12,
	'Session::Token'         => 1.503,

	'Net::DNS'               => 1.44,
	'Net::DNS::SEC'          => 1.23,
   }
 , EXE_FILES    => []
 , AUTHOR       => 'Open Console <team@open-console.eu>'
 , ABSTRACT     => 'XML Canonicalization'
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
RAWDIR          = /tmp/Owner-Console/raw
DISTDIR         = /tmp/Owner-Console/source

# for POD
FIRST_YEAR      = 2024
EMAIL           = mark@open-console.eu
EXTENDS         = 
WEBSITE         = http://perl.overmeer.net/owner-console

css:
	sass scss/main.scss public/assets/open-console.css
__POSTAMBLE
