# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Account;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util       qw(flat :validate);

sub index($)
{	my $self = shift;
	$self->render(template => 'account/index');
}

=subsection Update
=cut

### Keep this logic in sync with OwnerConsole::Account attributes

sub _acceptAccount($$)
{	my ($self, $session, $victim) = @_;
	$self->acceptObject($session, $victim);

	my $email = is_valid_email $session->requiredParam('email')
		or $session->addError(email => __x"Invalid email address");
	$victim->setData(email => $email);

	my $passwd  = $session->optionalParam(password => '');
	my $confirm = $session->optionalParam(confirm  => '');

	if(length $passwd && length $confirm)
	{	if($passwd ne $confirm)
		{	$session->addError(confirm => __x"The passwords do not match.");
		}
		if(length $passwd < 6)
		{	$session->addError(password => __x"The password is too short.");
		}
		$victim->changePassword($passwd);
		$session->changed;
	}

	my $langs = $session->optionalParam(languages => '');
	my @langs;
	foreach my $lang (split /\,/, $langs)
	{	is_valid_language $lang
			or $session->addWarning(languages => __x"Ignoring unsupported language-code '{code}'", code => $lang);
		push @langs, $lang;
	}
	$victim->setData(languages => @langs ? \@langs : [ 'en' ]);

	my $iflangs = $::app->config->{interface_languages};
	my $iflang  = $session->optionalParam(iflang => $iflangs->[0]);
	grep $iflang eq $_, @$iflangs
		or $session->addError(iflang => __x"Unsupported interface language '{code}'", code => $iflang);
	$victim->setData(iflang => $iflang);

	my $tz = $session->optionalParam(timezone => 'Europe/Amsterdam');
	is_valid_timezone($tz)
		or $session->addError(timezone => __x"Unsupported time-zone '{tz}'", tz => $tz);
	$victim->setData(timezone => $tz);

	my $birth = val_line $session->optionalParam('birth');
	! defined $birth || is_valid_date $birth
		or $session->addError(birth => __x"Invalid date format, use YYYY-MM-DD.");
	$victim->setData(birth_date => $birth);

	my $gender = $session->optionalParam('gender');
	! defined $gender || is_valid_gender $gender
		or $session->addError(gender => __x"Unknown gender type '{gender}'", gender => $gender);
	$victim->setData(gender => $gender);

	my $phone = val_line $session->optionalParam('phone');
	! defined $phone || is_valid_phone $phone
	    or $session->addError(phone => __x"Invalid phone number, use '+<country><net>/<extension>'");
	$victim->setData(phone_number => $phone);

	$self;
}

sub configAccount($)
{   my $self    = shift;
	my $session = $self->ajaxSession;
	my $how     = $session->query || 'validate';

	my $victim  = $session->openObject('OwnerConsole::Account', userid => sub { $::app->users->account($_[0]) })
		or error __x"Account disappeared.";

	$self->user->isAdmin || $victim->userId eq $self->account->userId
		or error __x"You cannot modify the account of someone else.";

	if($how eq 'delete')
	{	$victim->remove;
		$session->notify(info => __x"Your account has been removed.");
		$session->redirect('/');
	    return $session->reply;
	}

	$self->acceptFormData($session, $victim, '_acceptAccount');

	if($how eq 'save' && $session->isHappy)
	{	$session->redirect('/dashboard');
		$victim->save(by_user => 1);
	}

	$session->checkParamsUsed->reply;
}

1;
