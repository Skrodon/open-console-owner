# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Contracts;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw();
use OpenConsole::Asset::Contract ();

sub index()
{   my $self = shift;
	$self->render(
		template      => 'contracts/index',
#	service_index => sub { $::app->assets->publicServiceIndex },
		service_index => sub { my $x = $::app->assets->publicServiceIndex;
use Data::Dumper;
warn "INDEX=", Dumper $x;
$x },
	);
}

sub contract(%)
{   my ($self, %args) = @_;
	my $contractid = $self->param('assetid');
	my $account    = $self->account;
	my $contract  = $contractid eq 'new'
	  ? OpenConsole::Asset::Contract->create({owner => $account, serviceid => $self->param('service')})
	  : $account->asset(contracts => $contractid);

warn "PAGE EDIT Contract $contractid, $contract.";

	$self->render(
		template  => 'contracts/contract',
		contract  => $contract,
	);
}

sub _acceptContract()
{	my ($self, $session, $contract) = @_;
	$self->acceptProof($session, $contract);

	my $name = $session->optionalParam('name');
	if($contract->isNew)
	{	
	}

	$contract->setData();

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
