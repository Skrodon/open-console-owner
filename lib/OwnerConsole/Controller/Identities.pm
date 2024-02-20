package OwnerConsole::Controller::Identities;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util   qw(:validate);

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

sub _acceptIdentity($$)
{	my ($self, $session, $identity) = @_;

	$identity->setData(
		role     => val_line $session->requiredParam('role'),
		fullname => val_line $session->optionalParam('fullname'),
		nickname => val_line $session->optionalParam('nickname'),
		postal   => val_text $session->optionalParam('postal'),
	);

	my $email = val_line $session->optionalParam(email => undef);
	! defined $email || is_valid_email $email
		or $session->addError(email => __x"Invalid email address");
	$identity->setData(email => $email);

	my $gender = $session->optionalParam(gender => '');
	is_valid_gender $gender
		or $session->addError(gender => __x"Unknown gender type '{gender}'", gender => $gender);
	$identity->setData(gender => $gender);

#XXX Avatar

	my $phone = val_line $session->optionalParam(phone => undef);
	! defined $phone || is_valid_phone $phone
		or $session->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");
	$identity->setData(phone => $phone);

	$self;
}

sub configIdentity($)
{   my $self    = shift;
	my $session = $self->ajaxSession;
	my $how     = $session->query || 'validate';

	my $account  = $self->account;
	my $identity = $session->openObject('OwnerConsole::Identity', identid => sub { $account->identity($_[0]) })
		or error __x"Identity has disappeared.";

	if($how eq 'delete') {
		$identity->remove;
		$session->redirect('/dashboard/identities');
		return $session->reply;
	}

	$self->acceptFormData($session, $identity, '_acceptIdentity');

	if($how eq 'save' && ! $session->hasErrors)
	{	my $is_new = $identity->identityId eq 'new';
		$identity->save(by_user => 1);

		if($is_new)
		{	$account->addIdentity($identity);
			$account->save;
			$session->notify(info => __x"New identity created");
		}
		$session->redirect('/dashboard/identities');
	}

	$session->checkParamsUsed->reply;
}

1;
