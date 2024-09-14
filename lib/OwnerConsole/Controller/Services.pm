# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Services;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Asset::Service   ();

sub index()
{   my $self = shift;
	$self->render(template => 'services/index');
}

sub service(%)
{   my ($self, %args) = @_;
	my $proofid  = $self->param('proofid');
	my $account  = $self->account;
	my $proof    = $proofid eq 'new'
	  ? OpenConsole::Asset::Service->create({owner => $account})
	  : $account->proof(services => $proofid);

warn "PAGE EDIT SERVICE $proofid, $proof.";

	$self->render(
		template  => 'services/service',
		proof     => $proof,
	);
}

sub _acceptService()
{	my ($self, $session, $proof) = @_;
	$self->acceptProof($session, $proof);

	no warnings 'uninitialized';

	my $name = $session->optionalParam('name');
	if($proof->isNew)
	{	
	}

	$self;
}

sub configService()
{   my $self     = shift;
	my $session  = $self->ajaxSession;

	my $proof    = $self->openProof($session, 'OpenConsole::Asset::Service')
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
		$session->notify(info => __x"Service '{name}' removed.", name => $proof->name);
		$session->redirect('/dashboard/services');
	}

	$self->acceptFormData($session, $proof, '_acceptService');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/services');
	}

	$session->checkParamsUsed->reply;
}

1;
