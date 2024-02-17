package OwnerConsole::Controller::Identities;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util   qw(flat :validate);

sub index()
{   my ($self, %args) = @_;
    $self->render(template => 'identities/index');
}

sub identity()
{   my ($self, %args) = @_;
	my $identid  = $self->param('identid');

	my $account  = $self->account;
	my $identity = $identid eq 'new' ? OwnerConsole::Identity->create($account) : $account->identity($identid);
    $self->render(template => 'identities/identity', identity => $identity);
}

### Keep this logic in sync with OwnerConsole::Identity attributes

sub configIdentity($)
{   my $self = shift;
	my $answer  = OwnerConsole::AjaxAnswer->new();

	my $req     = $self->req;
	my $how     = $req->url->query;

#use Data::Dumper;
#warn "IDENTITY QUERY=$how";

	my $account  = $self->account;
	my $id       = $self->param('identid');

	my $identity;
	if($id eq 'new')
	{	$identity = OwnerConsole::Identity->create($account);
#warn "Created new $identity";
	}
	else
	{	$identity = $account->identity($id)
			or error __x"Tried to access identity '{id}'", id => $id;
	}

	if($how eq 'delete') {
		$identity->remove;
		$answer->redirect('/dashboard/identities');
    	return $self->render(json => $answer->data);
	}

	my $params = $req->json || $req->body_params->to_hash;
	my $data   = $identity->_data;

#warn "PARAMS=", Dumper $params;
#warn "DATA IN =", Dumper $data;

	my $role = $data->{role} = val_line delete $params->{role};
	defined $role
		or $answer->addError(role => __x"The role name is required, used in the overviews.");

	$data->{fullname} = val_line delete $params->{fullname};
	$data->{nickname} = val_line delete $params->{nickname};

	my $email = $data->{email} = val_line(delete $params->{email});
	! defined $email || is_valid_email $email
		or $answer->addError(email => __x"Invalid email address");

	my $gender = $data->{gender} = delete $params->{gender} || '';
	! length $gender || is_valid_gender $gender
		or $answer->addError(gender => __x"Unknown gender type '{gender}'", gender => $gender);

#XXX Avatar

	my $phone = $data->{phone} = val_line delete $params->{phone};
	! defined $phone || is_valid_phone $phone
		or $answer->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");

	my $postal = $data->{postal} = val_text delete $params->{postal};

warn "Unprocessed parameters: ", join ', ', sort keys %$params if keys %$params ;
#warn "DATA OUT =", Dumper $data;

	if($how eq 'save' && ! $answer->hasErrors)
	{	$answer->redirect('/dashboard/identities');  # order browser to redirect
#warn "SAVING IDENTITY";
#warn Dumper $self->users->allIdentities;
		$identity->save(by_user => 1);
#warn "DONE SAVING";
#warn Dumper $self->users->allIdentities;
		$account->addIdentity($identity);

		$self->notify(info => __x"New identity created") if $id eq 'new';
	}

    $self->render(json => $answer->data);
}

1;
