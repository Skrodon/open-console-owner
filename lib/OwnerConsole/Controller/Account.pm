package OwnerConsole::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';

use OwnerConsole::AjaxAnswer ();
use Log::Report 'open-console-owner';

use OwnerConsole::Util       qw(flat :validate);

sub index($)
{	my $self = shift;
	$self->render(template => 'account/index');
}

=subsection Update
=cut

### Keep this logic in sync with OwnerConsole::Account attributes

sub submit($)
{   my $self = shift;
	my $answer  = OwnerConsole::AjaxAnswer->new();
	my $account = $self->account;
	my $data    = $account->_data;

	my $req     = $self->req;
	my $how     = $req->url->query;
	my $params  = $req->json || $req->body_params->to_hash;

	my $id      = $self->param('userid');
	$self->user->isAdmin || $id eq $account->userId
		or error __x"You cannot modify the account of someone else.";
#use Data::Dumper;
#warn "QUERY=$how";
#warn "PARAMS=", Dumper $params;
#warn "DATA IN =", Dumper $data;

	if($how eq 'delete')
	{	$account->remove;
		$self->notify(__x"Your account has been removed.");
		$answer->redirect('/');
        return $self->render(json => $answer->data);
	}

	if(my $email = $data->{email} = delete $params->{email})
	{	if(not is_valid_email $email)
		{	$answer->addError(email => __x"Invalid email-address");
		}
		elsif($data->{email} ne $email)
		{	#XXX start validate email process
		}
	}

	my $passwd  = delete $params->{password} || '';
	my $confirm = delete $params->{confirm}  || '';

	if(length $passwd && length $confirm)
	{	if($passwd ne $confirm)
		{	$answer->addError(confirm => __x"The passwords do not match.");
		}
		if(length $passwd < 6)
		{	$answer->addError(password => __x"The passwords is too short.");
		}
		$account->changePassword($passwd);
	}

	my @langs;
	my $langs = delete $params->{languages} || '';
	foreach my $lang (split /\,/, $langs)
	{	is_valid_language $lang
			or $answer->addWarning(languages => __x"Ignoring unsupported language-code '{code}'", code => $lang);
		push @langs, $lang;
	}
	@langs = ('en') unless @langs;
	$data->{languages} = \@langs;

	my $iflang = $data->{iflang} = delete $params->{language} || '';
	(grep $iflang eq $_->[0], $self->ifLanguages)
		or $answer->addError(iflang => __x"Unsupported interface language '{code}'", code => $iflang);

	my $tz = $data->{timezone} = delete $params->{timezone};
	! defined $tz || is_valid_timezone($tz)
		or $answer->addError(timezone => __x"Unsupported time-zone '{timezone}'", timezone => $tz);

	my $birth = delete $params->{birth} || '';
	$data->{birth_date} = length $birth
	  ? (is_valid_date $birth or $answer->addError(birth => __x"Illegal date format, use YYYY-MM-DD."))
	  : undef;

	my $gender = $data->{gender} = delete $params->{gender} || '';
	! length $gender || is_valid_gender $gender
		or $answer->addError(gender => __x"Unknown gender type '{gender}'", gender => $gender);

	my $phone = $data->{phone} = val_line delete $params->{phone};
    ! defined $phone || is_valid_phone $phone
        or $answer->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");

warn "Unprocessed parameters: ", join ', ', sort keys %$params if keys %$params ;
#warn "DATA OUT =", Dumper $data;

	if($how eq 'save' && ! $answer->hasErrors)
	{	$answer->redirect('/dashboard');
#warn "SAVING";
		$account->save(by_user => 1);
	}

    $self->render(json => $answer->data);
}

1;
