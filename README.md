
# Open Console, Website Owner Interface
 
This project is part of https://open-console.eu Open Console, which is
(mainly) an initiative let website-owners communicate with service
which do something with their website, domain-name, or network.

For instance, the EU initiative https://OpenWebSearch.EU OpenWebSearch.EU
(which crawls websites for research and Google alternatives) uses this
interface to implement the (EU) legal requirements for correction rights
(take-downs).  Besides, it shows which parts of your site it collected,
and what information it extracted.

Open Console is a larger project: this sub-project only focusses on the
owner-to-service communication.  Other sub-projects focus on the exchange
of website information between parties who have information about websites,
and parties who need to know.  For instance, lists of phishing sites.

# Installing MongoDB

# Installing Perl modules

  * You may be able to install most of the required Perl packages from your distribution.  (When you have tried this, please contribute that list for inclusion here.  See the `Makefile.PL` for the list of required modules.)
  * Use Perl to install it for you:
	  * in the GIT extract of this code, run "perl Makefile.PL; make install`.  (You probably need super-admin rights to do this: depends on your Perl set-up)

# Application configuration

  * Copy `owner_console.conf.example` to `owner_console.conf` and edit the file.
     * You <strong>MUST</strong> change the `secrets`.
     * You probably want to insert the email address of your personal Account in Open Console as `admin`, to enabled extra functionality

