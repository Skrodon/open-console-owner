# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Websites;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util            qw(flat :validate new_token);
use OpenConsole::Proof::Website1 ();

use OwnerConsole::Challenge      ();
use OwnerConsole::Session::TaskResults ();

sub index()
{   my $self = shift;
	$self->render(template => 'websites/index');
}

sub website(%)
{   my ($self, %args) = @_;
	my $proofid  = $self->param('proofid');
	my $account  = $self->account;
	my $proof    = $proofid eq 'new'
	  ? OpenConsole::Proof::Website1->create({owner => $account})
	  : $account->proof(websites => $proofid);

warn "PAGE EDIT PROOF $proofid, $proof.";

	$self->render(template => 'websites/website1', proof => $proof );
}

sub _acceptWebsite1()
{	my ($self, $session, $proof) = @_;
	$self->acceptProof($session, $proof);

	my $url = val_line $session->optionalParam('url');
	if($proof->isNew)
	{	if(is_valid_url $url)    # only a first, simple check
		{	$proof->setData(url => $url) && $proof->invalidate;
		}
		else
		{	$session->addError(url => defined $url
			  ? (__x"Invalid website address.")
			  : (__x"Website address is required."));
		}
	}
	elsif(defined $url && $url ne $proof->url)
	{	$session->addError(url => __x"Attempt to change website url.");
	}

	$self;
}

sub configWebsite()
{   my $self     = shift;
	my $session  = $self->ajaxSession;

	my $proof    = $self->openProof($session, 'OpenConsole::Proof::Website1')
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
		$session->notify(info => __x"Proof for Website '{url}' removed.", url => $proof->url);
		$session->redirect('/dashboard/websites');
	}

	$self->acceptFormData($session, $proof, '_acceptWebsite1');

	if($how eq 'check-url')
	{
warn "CHECK URL ", $proof->url;
		$self->startTask($session, verifyWebsiteURL => { url => $proof->url },
			poll => 'check-url-task',
		);
		return $session->reply;
	}
	if($how eq 'check-url-task')
	{	my $jobid = $session->requiredParam('poll-token');
warn "CHECK URL POLL $jobid";
		my $results = OwnerConsole::Session::TaskResults->job($jobid);
$session->_data->{poll_results} = $results->_data;
		$self->taskEnded($session);
		return $session->reply;
	}
	$session->ignoreParam('check-url-token');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/websites');
	}

	$session->checkParamsUsed->reply;
}

1;
