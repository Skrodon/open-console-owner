
you have to define `OWNER_WEBSITE` as location where the test version
of the website is generated.  Create an httpd virtual host of which the
`DOCUMENT_ROOT` points to that directory.

You also have to configure `SKRODON_PUBLISH` when you are permitted to
upload new releases of this website.  When you have no permission, please
create a pull requests for us.

# Requirements

  * mongodb package
  * perl modules
    * MongoDB
	* Mango
    * Mojolicious
    * Mojolicious::Plugin::BootstrapAlerts
    * Mojolicious::Plugin::Mango
  
