# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Contracts;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OwnerConsole::Util            qw(flat :validate new_token);
use OwnerConsole::Proof::Contract1 ();
use OwnerConsole::Challenge       ();

sub index()
{   my $self = shift;
	$self->render(template => 'contracts/index');
}

sub contract(%)
{   my ($self, %args) = @_;
	my $proofid  = $self->param('proofid');
	my $account  = $self->account;
	my $proof    = $proofid eq 'new'
	  ? OwnerConsole::Proof::Contract1->create({owner => $account})
	  : $account->proof(contracts => $proofid);

warn "PAGE EDIT PROOF $proofid, $proof.";

	$self->render(template => 'contracts/contract1', proof => $proof );
}

sub _acceptContract1()
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

	my $proof    = $session->openProof('OwnerConsole::Proof::Contract1')
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

	$self->acceptFormData($session, $proof, '_acceptContract1');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/contracts');
	}

	$session->checkParamsUsed->reply;
}

1;
