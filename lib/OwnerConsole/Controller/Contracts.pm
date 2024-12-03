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
		service_index => sub { $::app->assets->publicServiceIndex },
	);
}

sub contract(%)
{   my ($self, %args) = @_;
	my $contract_id = $self->param('assetid');
	my $account     = $self->account;

	my $contract  = $contract_id eq 'new'
	  ? OpenConsole::Asset::Contract->create({owner => $account, service => $self->param('service')})
	  : $account->asset(contracts => $contract_id);

	my $service     = $::app->assets->service($contract->serviceId) or panic;
use Data::Dumper;
warn "PAGE EDIT Contract $contract_id, ", Dumper $contract;

	$self->render(
		template  => 'contracts/contract',
		contract  => $contract,
		service   => $service,
		facts     => OwnerConsole::Controller::Comply->listFacts,
	);
}

sub _acceptContract()
{	my ($self, $session, $contract) = @_;
	$self->acceptProof($session, $contract);

	my $account   = $self->account;
	my $serviceid = $session->requiredParam('service');
	my $service   = $::app->assets->service($serviceid) or panic;

	if($contract->isNew)
	{	
	}

	my $annex   = ($session->optionalParam('annex')   // 'off') eq 'on';
	my $terms   = ($session->optionalParam('terms')   // 'off') eq 'on';
	my $license = ($session->optionalParam('license') // 'off') eq 'on';

	my %presel;
	foreach my $set (qw/emailaddrs websites/)
	{	$presel{$set} = +{ from => $session->optionalParam($set) // 'owner' };
		# this will get more complex
	}

	$contract->setData(
		name      => $session->optionalParam('name') // $service->name,
		serviceid => $service->id,
		annex     => $annex   || 0,
		terms     => $terms   || 0,
		license   => $license || 0,
		presel    => \%presel,
	);
	$contract->changeOwner($account, $session->requiredParam('owner'));

	my $signing = $session->optionalParam('sign');
	if($annex && $terms && $license)
	{	$contract->sign($self->user) if $signing eq 'yes';
	}
	else
	{	$contract->invalidate;
	}

use Data::Dumper;
warn "COLLECTED: ", Dumper $contract->_data;
	$self;
}

sub configContract()
{   my $self     = shift;
	my $session  = $self->ajaxSession;
	my $contract = $self->openAsset($session, 'OpenConsole::Asset::Contract')
		or $session->reply;

	my $how      = $session->query;
warn "CONTRACT HOW=$how";
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
