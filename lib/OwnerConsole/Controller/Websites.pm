# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Controller::Websites;
use Mojo::Base 'OwnerConsole::Controller';

use Log::Report 'open-console-owner';

use OpenConsole::Util       qw(:validate :bool new_token domain_suffix);
use OwnerConsole::Challenge ();

use List::Util   qw(first);
use Time::HiRes  ();

use constant
{	WELL_KNOWN_PATH => '/.well-known/open-console.json',
	MAX_DNS_LABEL   => 63,  # rfc1035 2.3.4
};

my %algo_version = (
	file => '20240716',
	html => '20240717',
	dns  => '20240718',
);

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
			file_algo => 'file '. $algo_version{file},
			html_algo => 'html '. $algo_version{html},
			dns_algo  => 'dns ' . $algo_version{dns},
			well_known_path => WELL_KNOWN_PATH,
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
	$self->taskWait($session, $task, $poll);
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
		file    => $proof->website . WELL_KNOWN_PATH,
	});
	$self->taskWait($session, $task, $poll);
	$session->reply;
}

sub _proofHTMLStart($$$)
{	my ($self, $session, $proof, $poll) = @_;
	my $task = $::app->tasks->proofWebsiteHTML({
		field   => 'start-proof-button',
		website => $proof->website,
	});
	$self->taskWait($session, $task, $poll);
	$session->reply;
}

sub _proofDNSStart($$$)
{	my ($self, $session, $proof, $poll) = @_;
	my ($dnshost, $dnszone) = $self->_dnsRecord($proof);

	my $task = $::app->tasks->proofWebsiteDNS({
		field   => 'start-proof-button',
		record  => "$dnshost.$dnszone",
	});
	$self->taskWait($session, $task, $poll);
	$session->reply;
}

sub _dnsRecord($)
{	my ($self, $proof) = @_;

	my ($host, $registered, $suffix) = domain_suffix $proof->hostUTF8;
	my $zone = $registered ? "$registered.$suffix" : $suffix;  # will we see suffix owners?
warn "($host, $registered, $suffix) = ", $proof->hostUTF8;

	$host
		or return ("open-console-challenge", $zone);

	my $hostp = (split /\./, $proof->hostPunicode, 2)[0];
	my $name
	  = length $hostp + length('-open-console') <= MAX_DNS_LABEL ? "$host-open-console"
	  : length $hostp + length('-oc') <= MAX_DNS_LABEL           ? "$host-oc"
	  :   substr($host, 0, MAX_DNS_LABEL-3) . '-oc';

	$name .= '-challenge'
		if length($name) + length('-challenge') <= MAX_DNS_LABEL;

warn "WITH HOST ($name, $zone)";
	($name, $zone);
}

sub _proofAnyTask($$$)
{	my ($self, $session, $proof, $algo) = @_;
	my $task  = $self->taskPoll($session);
	my @trace = @{$task->trace};

	if($task && $task->finished && $session->isHappy)
	{	my $results   = $task->results;
		my $chances   = $results->{matching_challenges} || [];
		my $fetch     = $results->{fetch};

		my $challenge = $proof->challenge;
		my $match     = first { $_->{challenge} eq $challenge } @$chances;

		my %study     = (
			algorithm => $algo,
			version   => $algo_version{$algo},
			verified  => $fetch->{start},
			challenge => bool(defined $match),
		);
		if($algo eq 'dns')
		{	$study{txt_dnssec} = $fetch->{txt_dnssec};
		}
		else
		{	$study{use_https} = bool($proof->website =~ m!^https://!);
		}

		$proof->setData(fetch => $fetch, study => \%study);

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
	if($how eq 'reown')
	{	my $ownerid = $session->requiredParam('new_owner');
		$proof->changeOwner($session->account, $ownerid);
		$proof->save;
		return $session->reply;
	}

	if($how eq 'delete')
	{	$proof->delete;

        my $msg = $proof->isValid
          ? __x("Proof for website '{url}' removed.", url => $proof->website)
          : __x("Incomplete claim for website '{url}' removed.", url => $proof->website);

		$session->notify(info => $msg);
		$session->redirect('/dashboard/websites');
	}

	$self->acceptFormData($session, $proof, '_acceptWebsite')
		or return $session->reply;

	### Checking the website address

	return $self->_checkUrlStart($session, $proof, 'check-url-task')
		if $how eq 'check-url';

	return $self->_checkUrlTask($session, $proof)
		if $how eq 'check-url-task';

	### The three ways to prove

	my $prover = $session->optionalParam('prover');

	if($how eq 'start-prover')
	{	return
		    $prover eq 'file' ? $self->_proofFileStart($session, $proof, 'proof-file-task')
		  : $prover eq 'html' ? $self->_proofHTMLStart($session, $proof, 'proof-html-task')
		  : $prover eq 'dns'  ? $self->_proofDNSStart ($session, $proof, 'proof-dns-task' )
		  : panic "Unknown prover $prover";
	}

	return $self->_proofAnyTask($session, $proof, 'file')
		if $how eq 'proof-file-task';

	return $self->_proofAnyTask($session, $proof, 'html')
		if $how eq 'proof-html-task';

	return $self->_proofAnyTask($session, $proof, 'dns')
		if $how eq 'proof-dns-task';

	### Wrap it up

	$session->ignoreParam('taskid');

	if($how eq 'save' && $session->isHappy)
	{	$proof->save(by_user => 1);
		$session->redirect('/dashboard/websites');
	}

	$session->checkParamsUsed->reply;
}

1;
