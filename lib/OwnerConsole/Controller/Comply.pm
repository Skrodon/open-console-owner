# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Comply;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';
use List::Util              qw(first);

use OpenConsole::Util       qw(:tokens);
use OpenConsole::Comply     ();

sub _from_id($$)
{	my ($self, $account, $method) = @_;
	my @choices;
	foreach my $id ($account->identities)
	{	my $f = $id->$method // '';
		push @choices, +{ value => $f, owner => $id } if length $f;
	}
	@choices;
}

sub _from_ac($$)
{	my ($self, $account, $method) = @_;
	my $f = $account->$method // '';
	length $f ? +{ value => $f, owner => $account } : ();
}

my %facts = (
	'person.fullname' => {
		default => 'please',           # alternatives: no optional please required, default=no
		label   => __"Full name",

		# Called with $self, $account
		collect => sub { $_[0]->_from_id($_[1], 'fullname') },
	},
	'person.nickname' => {
		label   => __"Nickname",
		collect => sub { $_[0]->_from_id($_[1], 'nickname') },
	},
	'person.email' => {
		label   => __"Email address",
		collect => sub { $_[0]->_from_id($_[1], 'email'), $_[0]->_from_ac($_[1], 'email') },
		can_proof => 1,
	},
	'person.gender' => {
		label   => __"Gender",
		collect => sub { $_[0]->_from_id($_[1], 'gender') },
	},
	'person.birthdate' => {
		label   => __"Date of Birth",
		collect => sub { $_[0]->_from_ac($_[1], 'birth') },
	},
	'person.phone' => {
		label   => __"Phone number",
		collect => sub { $_[0]->_from_id($_[1], 'phone'), $_[0]->_from_ac($_[1], 'phone') },
	},
	'person.timezone' => {
		label   => __"Timezone",
		collect => sub { $_[0]->_from_ac($_[1], 'timezone') },
	},
);
sub listFacts() { \%facts }

sub show_error()   # function name error() used by Log::Report
{   my $self = shift;
	my $req  = $self->req;
	$self->render(
		template => 'comply/error',
		error    => $req->param('error'),
		service  => $req->param('service'),
	);
}

sub access()
{	my ($self, $args) = @_;
	my $token     = $self->param('token');
	my $account   = $self->account;
	my $set       = token_set $token || '';

	my ($invalid_token, $service, @contracts);
	if($set eq 'contract')
	{	if(my $contract = $::app->assets->contract($token))
		{	$service = $contract->service;
			push @contracts, $contract;
		}
	}
	elsif($set eq 'service')
	{	$service   = $::app->assets->service($token);
		@contracts = $::app->assets->contractsForService($account, $service)
			if $service;
	}
	else
	{	$invalid_token = 1;
	}

	my $error
	  = ! is_valid_token $token ? 'C01'
	  : $invalid_token          ? 'C02'
      : ! defined $service      ? 'C03'
      : $service->hasExpired    ? 'C04'
	  : ! @contracts            ? 'C05'
	  : @contracts > 1          ? 'C06'
	  : undef;

	! $error or return $self->render(
		template  => 'comply/error',
		error     => $error,
		service   => $service,
		contracts => \@contracts,
	);

	my $contract = $contracts[0];

	my $comply   = $::app->connect->complyForContract(contract => $contract, account => $account)
	  || OpenConsole::Comply->create({contract => $contract, account => $account});

	my $updated  = $comply->updated;
	$error
	  = $updated && $updated < $contract->updated ? 'C07'
	  : $updated && $updated < $service->updated  ? 'C08'
	  : undef;

	! $error or return $self->render(
		template  => 'comply/error',
		error     => $error,
		service   => $service,
		contracts => \@contracts,
	);

	$self->render(
		template   => 'comply/comply',
		comply     => $comply,
		service    => $service,
		contract   => $contract,
		choices    => $self->_choices($account, $contract, $service, $comply),
	);
}

# From a list of alternatives, pick the value from the contract owner
sub _selectPreferred($$)
{	my ($self, $identity, $alts) = @_;
	my $idid = $identity->id;
	$_->{preferred} = $_->{owner}->id eq $idid for @$alts;
	first { $_->{preferred} } @$alts;
}

# From a list of alternatives, remove the duplicates
sub _removeDoubles($)
{	my ($self, $alts) = @_;
	my %seen;
	push @{$seen{$_->{value}}}, $_ for @$alts;
	return $alts if @$alts == keys %seen;

	foreach my $v (keys %seen)
	{	my $r = $seen{$v};
		@$r > 1 or next;
		$seen{$v} = [ (first { $_->{preferred} } @$r) || $r->[0] ];
	}
	[ map $_->[0], values %seen ];
}

# Select the best alternative, based on previous choice and need
sub _selectBest($$$)
{	my ($self, $need, $give, $alts) = @_;

	if(defined $give && (my $old = first { $_->{value} eq $give } @$alts))
	{	# Stick to the old value
		$old->{selected} = 1;
		return $old;
	}

	$need eq 'required' || $need eq 'please'
		or return undef;

	my $pick = (first { $_->{preferred} } @$alts) || $alts->[0];
	$pick->{selected} = 1;
	$pick;
}

# A complex 4-way join, to determine what the user will see.
sub _choices($$$)
{	my ($self, $account, $contract, $service, $comply) = @_;

	# At the moment, the owner is always an personal identity
	my $identity = $contract->identity($account);
	my $idid     = $identity->id;

	my $needs    = $service->needsFacts;
	my $gives    = $comply->giveFacts;       # previously given
	my %showing;

	foreach my $fact (keys %facts)           # all fact definitions
	{	my $conf = $facts{$fact};            # fact processing config
		my $need = $needs->{$fact} // 'no';  # skip new fact options wrt service
		next if $need eq 'no';

		my $give = $gives->{$fact} ||= {};

		my $alts = [ $conf->{collect}->($self, $account) ];
		if(@$alts)
		{	my $pref = $self->_selectPreferred($identity, $alts);
			$alts    = $self->_removeDoubles($alts);
			my $best = $self->_selectBest($need, $give, $alts);
		}

		my %show = (
			id       => $fact,
			label    => $conf->{label},
			alts     => $alts,
			proof    => 'no',
			need     => $need,
		);

		$showing{$fact} = \%show;
	}

	\%showing;
}

# A list is an ARRAY of HASHes, each representing an item.  The items
# are shown on a web-page, but also used in other ways.
sub _verifyList($$$%)
{	my ($self, $session, $field, $list, %args) = @_;

	my $min   = $list->{min_select} //= 0;
	my $max   = $list->{max_select} //= 1000;
	my $items = $list->{items} || [];

	my $selectable = $list->{selectable} //= grep $_->{select} ne 'never', @$items;
	my $selected   = $list->{selected}   //= grep $_->{select} eq 'always' || $_->{select} eq 'yes', @$items;

	if($min==1 && $max==1 && $selectable==0)
	{	$session->addEror($field => __"You must to provide this data, but it is not available yet.");
	}
	elsif($selectable < $min)
	{	$session->addError($field => __x"You will not be able to fulfill this requirement of minimal {min} selections, because you do not have collected enough facts.  Please extend.", min => $min);
	}
	elsif($selected > $max)
	{	$session->addError($field => __x"You have made more selections than the current maximum of {max}, so the list will be trimmed at save.  Please deselect {overflow} explicitly.", max => $max, overflow => $max - $selected);
    }
	elsif($selectable < $selected && $max < 100)
	{	$session->addInfo($field => __x"You may select {space} additional facts.", space => $selected - $selectable);
	}

	$list;
}


1;
