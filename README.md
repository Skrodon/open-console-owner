
# LICENSE

This software is braught to you under the EUPL-1.2 (or later) license.
The text of this license can be found in the LICENSES directory.

# Open Console

The software for Open Console is spread of multiple repositories:
  * <https://github.com/Skrodon/open-console-core> Core (required)
  * <https://github.com/Skrodon/open-console-owner> Owner Website (this repo)
  * <https://github.com/Skrodon/open-console-connect> Connection provider
  * <https://github.com/Skrodon/open-console-tasks> batch processing

# Open Console, Website Owner Interface
 
This project is part of https://open-console.eu Open Console, which is
(mainly) an initiative let website-owners communicate with service
which do something with their website, domain-name, or network.

## Installing Perl modules

  * You may be able to install most of the required Perl packages from your distribution.  (When you have tried this, please contribute that list for inclusion here.  See the `Makefile.PL` for the list of required modules.)
  * Use Perl to install it for you:
	  * in the GIT extract of this code, run "perl Makefile.PL; make install`.  (You probably need super-admin rights to do this: depends on your Perl set-up)

## Application configuration

  * Copy `owner\_console.conf.example` to `owner\_console.conf` and edit the file.
     * You <strong>MUST</strong> change the `secrets`.
     * You probably want to insert the email address of your personal Account in Open Console as `admin`, to enabled extra functionality

# Developers

## SCSS -> CSS

  * Bootstrap uses [[https://sass-lang.com/dart-sass/|Dart Sass]], so we do as well.  Run `npm install -g sass`, and then 'make css'
