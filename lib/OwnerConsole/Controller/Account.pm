package OwnerConsole::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';

use OwnerConsole::AjaxAnswer ();
use Log::Report 'owner-console';

use Email::Valid             ();
use OwnerConsole::Tables     qw(language_name timezone_names);
use OwnerConsole::Util       qw(flat);

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

### Keep this logic in sync with OwnerConsole::Account attributes

my %known_genders = map +($_ => 1), qw(female male they none);

sub submit($)
{   my $self = shift;
	my $answer  = OwnerConsole::AjaxAnswer->new();
	my $account = $self->account;
	my $data    = $account->_data;

	my $req     = $self->req;
	my $how     = $req->url->query;
	my $params  = $req->json || $req->body_params->to_hash;
use Data::Dumper;
warn "QUERY=$how";
warn "PARAMS=", Dumper $params;
warn "DATA IN =", Dumper $data;

	if(my $email = delete $params->{email})
	{	if(not Email::Valid->address($email))
		{	$answer->addError(email => __x"Invalid email-address");
		}
		elsif($data->{email} ne $email)
		{	#XXX start validate email process
			$data->{email} = $email;
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
	foreach my $lang (flat(delete $params->{languages}))
	{	if(defined language_name($lang))
		{   push @langs, $lang;
			next;
		}
		$answer->addWarning(languages => __x"Ignoring unsupported language-code '{code}'", code => $lang);
	}
	@langs = ('en') unless @langs;
	$data->{languages} = \@langs;

	my $iflang = delete $params->{iflang} || '';
	if(grep $iflang eq $_->[0], $self->ifLanguages)
	{	$data->{iflang} = $iflang;
    }
	else
	{	$answer->addError(iflang => __x"Unsupported interface language '{code}'", code => $iflang);
	}

	my $tz = delete $params->{timezone} || 'Europe/Amsterdam';
	if(grep $tz eq $_, @{timezone_names()})
	{	$data->{timezone} = $tz;
	}
	else
	{	$answer->addError(timezone => __x"Unsupported time-zone '{timezone}'", timezone => $tz);
	}

	my $birth = delete $params->{birth} || '';
	if(length $birth)
	{	if($birth =~ m!^\s*([0-9]{4})(?:[-/ ]?)([0-9]{2})(?:[-/ ]?)?([0-9]{2})\s*$!)
		{	$data->{birth_date} = "$1-$2-$3";
		}
		else
		{	$answer->addError(birth => __x"Illegal date format, use YYYY-MM-DD.");
		}
	}

	my $gender = delete $params->{gender} || '';
	if(! length $gender || $known_genders{$gender})
	{	$data->{gender} = $gender;
	}
	else
	{	$answer->addError(gender => __x"Unknown gender type '{gender}'", gender => $gender);
	}

warn "Unprocessed parameters: ", join ', ', sort keys %$params if keys %$params ;
#warn "DATA OUT =", Dumper $data;

	if($how eq 'save' && ! $answer->hasErrors)
	{	$answer->redirect('/dashboard');
warn "SAVING";
$self->users->allAccounts;
		$account->save;
warn "DONE SAVING";
$self->users->allAccounts;
	}

    $self->render(json => $answer->data);
}

1;
