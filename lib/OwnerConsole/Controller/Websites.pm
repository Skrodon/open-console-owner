# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Websites;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw(:validate :bool new_token);
use OwnerConsole::Challenge ();

use List::Util   qw(first);
use Time::HiRes  ();

use constant
{	WK_PATH   => '/.well-known/open-console.json',
	FILE_ALGO_VERSION => '20240716',
	HTML_ALGO_VERSION => '20240717',
};

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
		return $self->render(template => 'websites/website-new', proof => $proof);
	}
	else
	{	my $proof     = $account->proof(websites => $proofid);
		my $prooftype = $proof->algorithm;
		my $prover    = $self->param('prover') || $prooftype;    # requested

		return $self->render(
			template  => 'websites/website',
			proof     => $proof,
			prover    => $prover,
			has_proof => $proof->isValid ? $prooftype : 'none',
			wk_path   => WK_PATH,
			file_algo => 'file '. FILE_ALGO_VERSION,
			html_algo => 'html '. HTML_ALGO_VERSION,
		);
	}
}

sub _acceptWebsite()
{	my ($self, $session, $proof) = @_;
	$self->acceptProof($session, $proof);

	my $url = val_line $session->optionalParam('website');

	if($proof->isNew)
	{	# otherwise simple check will fail
		my $fast = defined $url && length $url && $url !~ m!^https?://!i ? "https://$url" : $url;
		if(is_valid_url $fast)    # only a first, simple check
		{	$proof->setData(website => $url) && $proof->invalidate;
		}
		else
		{	$session->addError(website => defined $url
			  ? (__x"Invalid website address.")
			  : (__x"Website address is required."));
			return undef;
		}
	}
	elsif(defined $url && $url ne $proof->website)
	{	$session->addError(website => __x"Attempt to change website url.");
		return undef;
	}

	$self;
}

sub _checkUrlStart($$)
{	my ($self, $session, $proof, $poll) = @_;
	my $task = $::app->tasks->verifyWebsiteURL({field => 'website', website => $proof->website});
	$self->taskWait($session, $task, $poll) if $task;
	$session->reply;
}

sub _checkUrlTask($$)
{	my ($self, $session, $proof) = @_;
	my $task = $self->taskPoll($session);
	if($task && $task->finished && $session->isHappy)
	{	$proof->setData(verifyURL => $task->results, verifyURLTrace => $task->trace, challenge => new_token 'C');
		$proof->setData(website => $proof->printableURL);  # needs verifyURL set first
		$proof->save;
		$session->setData(proofid => $proof->proofId, website => $proof->website);
    	$session->setData(show_trace => $self->showTrace($task->trace));
	}

	$session->stopPolling if $task->finished;
	$session->reply;
}

sub _proofFileStart($$$)
{	my ($self, $session, $proof, $poll) = @_;
	my $task = $::app->tasks->proofWebsiteFile({
		field   => 'start-proof-button',
		website => $proof->website,
		file    => $proof->website . WK_PATH,
	});
	$self->taskWait($session, $task, $poll) if $task;
	$session->reply;
}

sub _proofHTMLStart($$$)
{	my ($self, $session, $proof, $poll) = @_;
	my $task = $::app->tasks->proofWebsiteHTML({
		field   => 'start-proof-button',
		website => $proof->website,
	});
	$self->taskWait($session, $task, $poll) if $task;
	$session->reply;
}

sub _proofFileHTMLTask($$$)
{	my ($self, $session, $proof, $algo) = @_;
	my $task  = $self->taskPoll($session);
	my @trace = @{$task->trace};

	if($task && $task->finished && $session->isHappy)
	{	my $results   = $task->results;
		my $chances   = $results->{matching_challenges} || [];
		my $fetch     = $results->{file_fetch};

		my $challenge = $proof->challenge;
		my $match     = first { $_->{challenge} eq $challenge } @$chances;

		my %study     = (
			algorithm => $algo,
			version   => $algo eq 'file' ? FILE_ALGO_VERSION : HTML_ALGO_VERSION,
			verified  => $fetch->{fetched},
			challenge => bool(defined $match),
			use_https => bool($proof->website =~ m!^https://!),
		);
		$proof->setData(proofFile => $fetch, study => \%study);

		my $now = Time::HiRes::time;

		if(defined $match)
		{	$proof->accepted;
			push @trace,
				[ $now, "The proof is accepted." ],
				[ $now, "The proof's default score is now " . $proof->score ];
		}
		else
		{	$session->addError('start-proof-button', @$chances
			  ? __x("None of the provided challenges matched.")
			  : __x("Challenge not found."));

			push @trace, [ $now, "The proof is rejected: no matching challenge" ];
			$proof->invalidate;
		}

	}

	$proof->setData(proofTrace => \@trace);
	$proof->save;

	$session->stopPolling if $task->finished;
   	$session->setData(show_trace => $self->showTrace(\@trace));
	$session->reply;
}

sub configWebsite()
{   my $self     = shift;
	my $session  = $self->ajaxSession;
	$session->ignoreParam('selected-prover');

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
		$session->notify(info => __x"Claim for Website '{url}' removed.", url => $proof->website);
		$session->redirect('/dashboard/websites');
	}

	$self->acceptFormData($session, $proof, '_acceptWebsite')
		or return $session->reply;
warn "ACCEPTED";

	return $self->_checkUrlStart($session, $proof, 'check-url-task')
		if $how eq 'check-url';

	return $self->_checkUrlTask($session, $proof)
		if $how eq 'check-url-task';

	my $prover = $session->optionalParam('prover');

	if($how eq 'start-prover')
	{
warn "PROVER = $prover";
		return $self->_proofFileStart($session, $proof, 'proof-file-task') if $prover eq 'file';
		return $self->_proofHTMLStart($session, $proof, 'proof-html-task') if $prover eq 'html';
	}

	return $self->_proofFileHTMLTask($session, $proof, 'file')
		if $how eq 'proof-file-task';

	return $self->_proofFileHTMLTask($session, $proof, 'html')
		if $how eq 'proof-html-task';

	### Wrap it up

	$session->ignoreParam('taskid');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/websites');
	}

	$session->checkParamsUsed->reply;
}

1;
