# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Websites;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw(flat :validate new_token);

use OwnerConsole::Challenge ();

sub index()
{   my $self = shift;
	$self->render(template => 'websites/index');
}

sub website(%)
{   my ($self, %args) = @_;
	my $proofid  = $self->param('proofid');
	my $account  = $self->account;

	if($proofid eq 'new')
	{	my $proof = OpenConsole::Proof::Website->create({owner => $account});
		return $self->render(template => 'websites/website-new', proof => $proof );
	}
	else
	{	my $proof  = $account->proof(websites => $proofid);
		my $prover = $self->param('prover') || 'none';
		return $self->render(template => 'websites/website', proof => $proof, prover => $prover);
	}
}

sub _acceptWebsite()
{	my ($self, $session, $proof) = @_;
	$self->acceptProof($session, $proof);

	my $url = val_line $session->optionalParam('url');

	if($proof->isNew)
	{	# otherwise simple check will fail
		my $fast = defined $url && length $url && $url !~ m!^https?://!i ? "https://$url" : $url;
		if(is_valid_url $fast)    # only a first, simple check
		{	$proof->setData(url => $url) && $proof->invalidate;
		}
		else
		{	$session->addError(url => defined $url
			  ? (__x"Invalid website address.")
			  : (__x"Website address is required."));
			return undef;
		}
	}
	elsif(defined $url && $url ne $proof->url)
	{	$session->addError(url => __x"Attempt to change website url.");
		return undef;
	}

	$self;
}

sub configWebsite()
{   my $self     = shift;
	my $session  = $self->ajaxSession;

	my $proof    = $self->openProof($session, 'OpenConsole::Proof::Website')
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
		$session->notify(info => __x"Claim for Website '{url}' removed.", url => $proof->url);
		$session->redirect('/dashboard/websites');
	}

	$self->acceptFormData($session, $proof, '_acceptWebsite')
		or return $session->reply;
warn "ACCEPTED";

	if($how eq 'check-url')
	{
warn "CHECK URL ", $proof->url;
		my $task = $::app->tasks->verifyWebsiteURL({field => 'url', url => $proof->url});
		$session->startPoll('check-url-task' => $task) if $task;
		$session->mergeTaskResults($task);
		return $session->reply;
	}

	if($how eq 'check-url-task')
	{	my $taskid = $session->requiredParam('task');
warn "CHECK URL POLL $taskid";
		my $task = $::app->tasks->ping($taskid);
		$session->mergeTaskResults($task);

		if($task->finished)
		{	$session->stopPolling;
			if($session->isHappy)
			{	$proof->setData(verifyURL      => $task->results);
				$proof->setData(verifyURLTrace => $task->trace);
				my $norm = $proof->printableURL;
				$proof->setData(url => $norm);
use Data::Dumper;
warn "SAVE PROOF=", Dumper $proof->_data;
				$proof->save;

				$session->setData(proofid => $proof->proofId);
				$session->setData(url => $norm);
			}
		}

		$session->setData(show_trace => $session->showTrace($task->trace));
		return $session->reply;
	}
	else
	{	$session->ignoreParam('taskid');
	}

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/websites');
	}

	$session->checkParamsUsed->reply;
}

1;
