
# Requirements

  * mongodb package
  * perl modules
    * MongoDB
	* Mango
    * Mojolicious
    * Mojolicious::Plugin::BootstrapAlerts
    * Mojolicious::Plugin::I18NUtils
  	* Crypt::PBKDF2

# Installing MongoDB

# Installing Perl modules

  * You may be able to install most of the required Perl packages from your distribution.  (When you have tried this, please contribute that list for inclusion here.  See the `Makefile.PL` for the list of required modules.)
  * Use Perl to install it for you:
	  * in the GIT extract of this code, run "perl Makefile.PL; make install`.  (You probably need super-admin rights to do this)

# Application configuration

  * Copy `owner_console.conf.example` to `owner_console.conf` and edit the file.
     * You <strong>MUST</strong> change the `secrets`.
     * You probably want to insert the email address of your personal Account in Open Console as `admin`, to enabled extra functionality

