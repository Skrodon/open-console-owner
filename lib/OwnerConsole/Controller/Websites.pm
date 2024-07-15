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
		return $self->render(
			template => 'websites/website',
			proof  => $proof,
			prover => $prover,
		);
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

sub _checkUrlStart($$)
{	my ($self, $session, $proof) = @_;
warn "CHECK URL ", $proof->url;
	my $task = $::app->tasks->verifyWebsiteURL({field => 'url', url => $proof->url});
	$session->startPoll('check-url-task' => $task) if $task;
	$session->mergeTaskResults($task);
	$session->reply;
}

sub _checkUrlTask($$)
{	my ($self, $session, $proof) = @_;
warn "CHECK URL POLL $taskid";
	my $taskid = $session->requiredParam('task');
	my $task = $::app->tasks->ping($taskid);
	$session->mergeTaskResults($task);
	$session->setData(show_trace => $self->showTrace($task->trace));

	$task->finished
		or return $session->reply;

	$session->stopPolling;
	$session->isHappy
		or return $session->reply;

	$proof->setData(verifyURL => $task->results, verifyURLTrace => $task->trace, url => $proof->printableURL);
	$proof->save;

	$session->setData(proofid => $proof->proofId, url => $proof->url);
	$session->reply;
}

sub _proofFileStart($$)
{	my ($self, $session, $proof) = @_;
warn "proofFile ", $proof->url;
	my $task = $::app->tasks->proofWebsiteFile({field => 'url', url => $proof->url});
	$self->taskWait($session, $task, 'proof-file-task');
	$session->reply;
}

sub _proofFileTask($$)
{	my ($self, $session, $proof) = @_;
	my $task   = $self->taskPoll($session);
	if($task && $task->finished && $session->isHappy)
	{	$proof->setData(proofFile => $task->results, proofTrace => $task->trace);
		$proof->save;
	}

	$session->reply;
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

	return $self->_checkUrlStart($session, $proof)
		if $how eq 'check-url';

	return $self->_checkUrlTask($session, $proof)
		if $how eq 'check-url-task';

	return $self->_proofFileStart($session, $proof)
		if $how eq 'proof-file';

	return $self->_proofFileTask($session, $proof)
		if $how eq 'proof-file-task';

	### Wrap it up

	$session->ignoreParam('taskid');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/websites');
	}

	$session->checkParamsUsed->reply;
}

1;
