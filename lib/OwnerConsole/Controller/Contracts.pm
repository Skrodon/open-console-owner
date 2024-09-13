# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Contracts;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw();
use OpenConsole::Contract   ();

sub index()
{   my $self = shift;
	$self->render(template => 'contracts/index');
}

sub _identityPicker($)
{	my ($self, $account) = @_;
	my @table   = +[ $account->id => 'Account' ];

	my %ingroups;
	push @{$ingroups{$_->memberIdentityOf($account)->id}}, $_ for $account->groups;
	foreach my $personal ($account->identities)
	{	my $name = $personal->nickname // $personal->role;
		if(my $groups = $ingroups{$personal->id})
		{	push @table, [ $_->id => "$name @ " . $_->name ] for @$groups;
		}
		else
		{	push @table, [ $personal->id => $name ];
		}
	}

	[ sort { $a->[1] cmp $b->[1] } @table ];
}

sub contract(%)
{   my ($self, %args) = @_;
	my $proofid  = $self->param('proofid');
	my $account  = $self->account;
	my $proof    = $proofid eq 'new'
	  ? OpenConsole::Contract->create({owner => $account})
	  : $account->proof(contracts => $proofid);

warn "PAGE EDIT PROOF $proofid, $proof.";

	$self->render(
		template  => 'contracts/contract',
		proof     => $proof,
		id_picker => $self->_identityPicker($account),
	);
}

sub _acceptContract()
{	my ($self, $session, $proof) = @_;
	$self->acceptProof($session, $proof);

	no warnings 'uninitialized';

	my $name = $session->optionalParam('name');
	if($proof->isNew)
	{	
	}

	$self;
}

sub configContract()
{   my $self     = shift;
	my $session  = $self->ajaxSession;

	my $proof    = $self->openProof($session, 'OpenConsole::Contract')
		or $session->reply;

	my $how      = $session->query;
warn "HOW=$how";
	if($how eq 'reown')
	{	my $ownerid = $session->requiredParam('new_owner');
		$proof->changeOwner($session->account, $ownerid);
		$proof->save;
		return $session->reply;
	}

	if($how eq 'delete')
	{	$proof->delete;
		$session->notify(info => __x"Contract '{name}' removed.", name => $proof->name);
		$session->redirect('/dashboard/contracts');
	}

	$self->acceptFormData($session, $proof, '_acceptContract');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/contracts');
	}

	$session->checkParamsUsed->reply;
}

1;
