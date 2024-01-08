package OwnerConsole::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';

use OwnerConsole::AjaxAnswer ();
use Log::Report 'owner-console';

sub index($)
{	my $self = shift;
	$self->render(template => 'login/account');
}

sub index2($)
{	my $self = shift;
	$self->render(template => 'login/account2');
}

=subsection Update
=cut

sub submit($)
{   my $self = shift;
	my $answer = OwnerConsole::AjaxAnswer->new();
	$answer->addError('email', __x"no such place");
	$answer->addWarning('email', __x"are you sure?");
use Data::Dumper;
warn Dumper [ @_ ];
    $self->render(json => $answer->data);
}


1;
