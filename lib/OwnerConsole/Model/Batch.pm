# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Model::Batch;
use Mojo::Base -base;

use Mango::BSON ':bson';

use OwnerConsole::Email         ();
use OwnerConsole::Group::Invite ();
use OwnerConsole::Challenge     ();

=chapter NAME
OwnerConsole::Model::Batch - database with only temporary information

=chapter DESCRIPTION
Collections which are located in this database do rapidly change, which makes
the database (cluster) slower.  The data stored inhere is also less critical
than in the user's database, so need less or no redundancy.

collections:
=over 4
=item * 'emails': outgoing emails
=item * 'invites': group invites
=item * 'challenges': state machine for challenges
=back

=chapter METHODS
=cut

has db         => undef;
has emails     => sub { $_[0]->{OMB_emails}  ||= $_[0]->db->collection('emails')};
has invites    => sub { $_[0]->{OMB_invites} ||= $_[0]->db->collection('invites')};
has challenges => sub { $_[0]->{OMB_chall}   ||= $_[0]->db->collection('challenges')};

sub upgrade
{	my $self = shift;

	$self->_upgrade_emails
		->_upgrade_invites
		->_upgrade_challenges;

	$self;
}

#---------------------
=section Email, the "outgoing" table

The document is maintained by M<OwnerConsole::Email> objects.
=cut

sub _upgrade_emails()
{	my $self = shift;
	$self->emails->ensure_index({ id => 1 }, { unique => bson_true });
	$self->emails->ensure_index({ sender  => 1 }, { unique => bson_true });

	$self->emails->ensure_index({ sendto  => 1 }, {
		unique    => bson_true,
		collation => { locale => 'en', strength => 2 },  # address is case-insensitive
	});

	$self;
}

sub email($)
{	my ($self, $emailid) = @_;
	my $data = $self->emails->find_one({id => $emailid})
		or return;
 
	OwnerConsole::Email->fromDB($data);
}
 
sub emailByAddress($)
{	my ($self, $email) = @_;
	my $data = $self->emails->find_one({email => $email})
		or return;
 
	OwnerConsole::Email->fromDB($data);
}
 
sub removeEmail($)
{	my ($self, $emailid) = @_;
	my $result = $self->emails->remove({id => $emailid}, {single => 1});
	my $count  = $result->{deleteCount};
	$self->log($count ? "could not find email $emailid to remove" : "removed email $emailid");
	$count;
}
 
sub removeEmailsRelatedTo($)
{	my ($self, $relid) = @_;
	my $result = $self->emails->remove({related => $relid});
use Data::Dumper;
warn "RESULT ", Dumper $result;
	my $count  = $result->{deleteCount};
	$self->log("removed $count outgoing emails related to $relid");
	$count;
}
 
sub queueEmail($)
{	my ($self, $email) = @_;

#XXX this should move to a Minion task
	$email->buildMessage($::app->config->{email})->send(to => $email->sendTo);
}
 
sub allEmails()
{	my $self = shift;
	$self->emails->find->all;
}

#---------------------
=section Invites

The document is maintained by M<OwnerConsole::Group::Invite> objects.
=cut

sub _upgrade_invites()
{	my $self = shift;
	$self->invites->ensure_index({ token => 1 }, { unique => bson_true });

	my $autoclean = $::app->config('groups')->{cleanup_invitation} || 30;
	$self->invites->ensure_index({ expires => 1 }, { expireAfterSeconds => int($autoclean * 86400) } );
	$self;
}

sub invitesForGroup($)
{	my ($self, $group) = @_;
	my $data = $self->invites->find({groupid => $group->id})->all;
	map OwnerConsole::Group::Invite->fromDB($_), @$data;
}

sub saveInvite($)
{	my ($self, $invite) = @_;
	$self->invites->save($invite->toDB);
}

sub removeInvite($)
{	my ($self, $token) = @_;
	$self->invites->remove({ token => $token });
}

sub invite($)
{	my ($self, $token) = @_;
	my $data = $token ? $self->invites->find_one({token => $token}) : undef;
	$data ? OwnerConsole::Group::Invite->fromDB($data) : undef;
}

#---------------------
=section Challenges

The challenges table hides internal states and ids from the outside, by only
showing a token.
=cut

sub _upgrade_challenges()
{	my $self = shift;
	$self->challenges->ensure_index({ token => 1 }, { unique => bson_true  });

	my $expire_challenges = $::app->config('proofs')->{expire_challenge} || 30;  # days
	$self->challenges->ensure_index({ changed => 1 }, { expireAfterSeconds => int($expire_challenges * 86400) });
	$self;
}

sub saveChallenge($)
{	my ($self, $challenge) = @_;
	$self->challenges->save($challenge->toDB);
}

sub challenge($)
{	my ($self, $token) = @_;
	my $data = $self->challenges->find_one({token => $token});
	$data ? OwnerConsole::Challenge->fromDB($data) : undef;
}

1;
