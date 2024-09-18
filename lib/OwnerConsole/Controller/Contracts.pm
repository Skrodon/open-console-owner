# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Contracts;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw();
use OpenConsole::Asset::Contract ();

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
	my $proofid  = $self->param('assetid');
	my $account  = $self->account;
	my $proof    = $proofid eq 'new'
	  ? OpenConsole::Asset::Contract->create({owner => $account})
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
	my $contract = $self->openAsset($session, 'OpenConsole::Asset::Contract')
		or $session->reply;

	my $how      = $session->query;
warn "HOW=$how";
	if($how eq 'reown')
	{	my $ownerid = $session->requiredParam('new_owner');
		$contract->changeOwner($session->account, $ownerid);
		$contract->save;
		return $session->reply;
	}

	if($how eq 'delete')
	{	$contract->delete;
		$session->notify(info => __x"Contract '{name}' removed.", name => $contract->name);
		$session->redirect('/dashboard/contracts');
	}

	$self->acceptFormData($session, $contract, '_acceptContract');

	if($how eq 'save' && $session->isHappy)
	{	$contract->save(by_user => 1);
		$session->redirect('/dashboard/contracts');
	}

	$session->checkParamsUsed->reply;
}

1;
