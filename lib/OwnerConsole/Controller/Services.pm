# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Services;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Asset::Service   ();
use OpenConsole::Util             qw(:validate);

sub index()
{   my $self = shift;
	$self->render(template => 'services/index');
}

sub service(%)
{   my ($self, %args) = @_;
	my $id       = $self->param('assetid');
	my $account  = $self->account;
	my $service  = $id eq 'new'
	  ? OpenConsole::Asset::Service->create({owner => $account})
	  : $account->assets->asset(services => $id);

warn "PAGE EDIT SERVICE $id, $service.";

	$self->render(
		template  => 'services/service',
		service   => $service,
	);
}

sub _acceptService()
{	my ($self, $session, $service) = @_;

	no warnings 'uninitialized';

	my $endpoint = val_line $session->requiredParam('endpoint');
	$endpoint eq 'missing' || is_valid_url $endpoint
		or $session->addError(endpoint => __x"Invalid url.");

	$service->setData(
		name        => val_line $session->requiredParam('name'),
		description => val_text $session->optionalParam('descr'),
		endpoint    => $endpoint,
		status      => 'enabled',
	);

	#XXX here, we need to check whether the service provider owns the domain.

	if($service->isNew)
	{	$service->changeSecret(val_line $session->requiredParam('secret'));
	}
	elsif(my $secret = val_line $session->optionalParam('secret'))
	{	$service->changeSecret($secret);
	}

	$self;
}

sub configService()
{   my $self     = shift;
	my $session  = $self->ajaxSession;

	my $service  = $self->openAsset($session, 'OpenConsole::Asset::Service')
		or $session->reply;

	my $how      = $session->query;
warn "HOW=$how";
	if($how eq 'reown')
	{	my $ownerid = $session->requiredParam('new_owner');
		$service->changeOwner($session->account, $ownerid);
		$service->save;
		return $session->reply;
	}

	if($how eq 'delete')
	{	$service->delete;
		$session->notify(info => __x"Service '{name}' removed.", name => $service->name);
		$session->redirect('/dashboard/services');
	}

	$self->acceptFormData($session, $service, '_acceptService');

	if($how eq 'save' && $session->isHappy)
	{	$service->save(by_user => 1);
		$session->redirect('/dashboard/services');
	}

	$session->checkParamsUsed->reply;
}

1;
