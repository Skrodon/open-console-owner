package OwnerConsole::Controller::Groups;
use Mojo::Base 'Mojolicious::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util   qw(flat :validate);

sub index($)
{   my $self = shift;
    $self->render(template => 'groups/index');
}

sub group($)
{   my ($self, %args) = @_;
	my $groupid  = $self->param('groupid');

	my $account  = $self->account;
	my $group = $groupid eq 'new' ? OwnerConsole::Group->create($account) : $account->group($groupid);
    $self->render(template => 'groups/group', group => $group);
}

### Keep this logic in sync with OwnerConsole::Group attributes

sub submit_group($)
{   my $self = shift;
	my $answer  = OwnerConsole::AjaxAnswer->new();

	my $req     = $self->req;
	my $how     = $req->url->query;

use Data::Dumper;
warn "GROUP QUERY=$how";

	my $account  = $self->account;
	my $id       = $self->param('groupid');

	my $group;
	if($id eq 'new')
	{	$group = OwnerConsole::Group->create($account);
warn "Created new $group";
	}
	else
	{	$group = $account->group($id)
			or error __x"Tried to access group '{id}'", id => $id;
	}

	if($how eq 'delete') {
		$::app->users->removeGroup($group);
		$account->removeGroup($group);
		$answer->redirect('/dashboard/groups');
    	return $self->render(json => $answer->data);
	}

	my $params = $req->json || $req->body_params->to_hash;
	my $data   = $group->_data;

warn "PARAMS=", Dumper $params;
warn "DATA IN =", Dumper $data;

	my $name = $data->{name} = val_line delete $params->{name};
	defined $name
		or $answer->addError(name => __x"The name name is required, used in the overviews.");

	$data->{fullname}     = val_line delete $params->{fullname};

	my $lang              = delete $params->{language} || '';
	$data->{language}     = length $lang ? $lang : undef;
	! length $lang || is_valid_language($lang)
		or $answer->addError(lang => __x"Unsupported language '{code}'", code => $lang);

	$data->{organization} = val_line delete $params->{organization};
	$data->{department}   = val_line delete $params->{department};

	my $email = $data->{email} = val_line(delete $params->{email});
	! defined $email || is_valid_email $email
		or $answer->addError(email => __x"Invalid email address");

	my $phone = $data->{phone} = val_line delete $params->{phone};
	! defined $phone || is_valid_phone $phone
		or $answer->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");

	my $postal = $data->{postal} = val_text delete $params->{postal};

warn "Unprocessed parameters: ", join ', ', sort keys %$params if keys %$params ;
warn "DATA OUT =", Dumper $data;

	if($how eq 'save' && ! $answer->hasErrors)
	{	$answer->redirect('/dashboard/groups');  # order browser to redirect
warn "SAVING GROUP";
warn Dumper $self->users->allGroups;
		$group->save(by_user => 1);
#warn "DONE SAVING";
#warn Dumper $self->users->allGroups;
		$account->addGroup($group);

		$self->notify(info => __x"New group created") if $id eq 'new';
	}

    $self->render(json => $answer->data);
}

1;
1;
