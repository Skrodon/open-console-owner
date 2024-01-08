use ExtUtils::MakeMaker;

use 5.016;

WriteMakefile
 ( NAME	 	=> 'Owner-Console'
 , VERSION	=> '0.01'

 , PREREQ_PM    => { 
	'Crypt::PBKDF2'	=> '0',
	'Data::Dumper'	=> '0',
	'Data::UUID'	=> '0',
	'Email::Valid'  => '1.202',
	'List::Util'	=> '0',
	'Log::Report'	=> '0',
	'Mango'			=> '0',
	'Mojolicious'                      => '9.35',
	'Mojolicious::Plugin::CSRFProtect' => '0.16',
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
__POSTAMBLE
