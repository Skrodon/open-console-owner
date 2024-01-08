package OwnerConsole::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';

use OwnerConsole::AjaxAnswer ();
use Log::Report 'owner-console';

use Email::Valid             ();

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
	my $data   = $self->account->_data;

	my $req    = $self->req;
	my $params = $req->json || $req->body_params->to_hash;
use Data::Dumper;
warn "PARAMS=", Dumper $params;
warn "DATA IN =", Dumper $data;

	if(my $email = delete $params->{email})
	{	if(not Email::Valid->address($email))
		{	$answer->addError('email', __x"Invalid email-address");
		}
		elsif($data->{email} ne $email)
		{	#XXX start validate email process
			$data->{email} = $email;
		}
	}

warn "DATA OUT =", Dumper $data;
    $self->render(json => $answer->data);
}

1;
