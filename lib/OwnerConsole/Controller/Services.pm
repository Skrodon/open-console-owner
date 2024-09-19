# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Services;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Asset::Service   ();
use OpenConsole::Util             qw(:validate);

sub _blocking_reason($$)
{	my ($account, $owner) = @_;
	!$owner->isGroup || $owner->memberIsAdmin($account)
    	or return __"You are not an administrator of this group.";

	my $emails   = $account->assetSearch('emailaddrs', min_score => 1, owner => $owner);
	my $webaddrs = $account->assetSearch('websites',   min_score => 1, owner => $owner);

	   !$emails && !$webaddrs ? __"No proven email address, no proven website."
	 : !$emails               ? __"Proven email address required."
	 : !$webaddrs             ? __"Proven website required."
	 : undef;
}

sub index()
{   my $self = shift;

	$self->render(
		template        => 'services/index',
		blocking_reason => \&_blocking_reason,
	);
}

sub service(%)
{   my ($self, %args) = @_;
	my $id       = $self->param('assetid');
	my $account  = $self->account;
	my $service  = $id eq 'new'
	  ? OpenConsole::Asset::Service->create({owner => $account->findOwner($self->param('owner'))})
	  : $account->asset(services => $id);

warn "PAGE EDIT SERVICE $id, $service.";

	$self->render(
		template  => 'services/service',
		service   => $service,
	);
}

sub _acceptService()
{	my ($self, $session, $service) = @_;

	no warnings 'uninitialized';

	my $account  = $self->account;
	my $owner    = $service->owner($account);
	my %emails   = map +($_->id => $_), $account->assetSearch('emailaddrs', min_score => 1, owner => $owner);
	my %webaddrs = map +($_->id => $_), $account->assetSearch('websites',   min_score => 1, owner => $owner);

	my $endpoint = $session->requiredParam('endpoint-website');
	$endpoint eq 'missing' || ! $webaddrs{$endpoint}
		or $session->addError(endpoint => __x"Incorrect endpoint website.");

	my $endpath  = val_line $session->optionalParam('endpoint') || '/';
	$endpath !~ m!^https?\:!
		or $session->addError(endpoint => __x"Provide only the path, no protocol or hostname.");

	$endpath = "/$endpath" if $endpath !~ m!^/!;
	$endpath !~ m!/\.\.?(?:/|$)!
		or $session->addError(endpoint => __x"No '..', '.', or empty path components.");

	$endpath !~ m/#/
		or $session->addError(endpoint => __x"No fragment permitted in the path.");

	my $contact  = $session->requiredParam('contact');
	$contact eq 'missing' || ! $emails{$contact}
		or $session->addError(contact => __x"Incorrect contact email.");

	my $info_site = $session->optionalParam('info-site');
	! $info_site || $webaddrs{$info_site}
		or $session->addError('info-site' => __x"Incorrect info website.");

	my $support  = $session->optionalParam('support') || '';
	! $support   || $emails{$support}
		or $session->addError(support => __x"Incorrect support email.");

	my (%assets, @illegal);
	foreach my $set (qw/emailaddrs websites/)
	{   my $min    = $session->optionalParam("${set}_min") // 0;
		my $max    = $session->optionalParam("${set}_max") // 100;
	 	my $status = $session->optionalParam("${set}_status") // 'proven';
		$assets{$set} = +{ min => $min, max => $max, status => $status };

		push @illegal, $min if $min !~ /^[0-9]+$/;
		push @illegal, $max if $max !~ /^[0-9]+$/;
	}
	!@illegal
		or $session->addError(assets => __x"Illegal count values {values}.", values => \@illegal);

	my $terms = val_line $session->optionalParam('terms');
	! defined $terms || $terms =~ m!^https?://!i
		or $session->addError(terms => __x"This URL must be absolute.");

	$service->setData(
		name          => val_line $session->requiredParam('name'),
		description   => val_text $session->optionalParam('descr'),
		endpoint_ws   => $endpoint,
		endpoint_path => $endpath,
		endpoint      => $endpoint . $endpath,
		contact       => $contact,
		info_ws       => $info_site,
		info_path     => val_line $session->optionalParam('info-path') || '/',
		support       => $support,
		needs_assets  => \%assets,
		terms         => $terms,
		license       => val_line $session->optionalParam('license'),
		explain_user  => val_text $session->optionalParam('explain-user'),
		explain_group => val_text $session->optionalParam('explain-group'),
		status        => 'enabled',
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
