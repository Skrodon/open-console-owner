# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Model::Batch;
use Mojo::Base -base;

use Mango::BSON ':bson';

use OwnerConsole::Email         ();
use OwnerConsole::Group::Invite ();

=section DESCRIPTION
Collections which are located in this database do rapidly change, which makes
the database (cluster) slower.  The data stored inhere is also less critical
than in the user's database, so need less or no redundancy.

collections:
=over 4
=item * 'emails': outgoing emails
=item * 'invites': group invites
=back

=cut

has db      => undef;
has emails  => sub { $_[0]->{OMB_emails}  ||= $_[0]->db->collection('emails')};
has invites => sub { $_[0]->{OMB_invites} ||= $_[0]->db->collection('invites')};

sub upgrade
{	my $self = shift;

    #### Indices
	# We can run "ensure_index()" as often as we want.

#$self->emails->drop_index('emailid');
	$self->emails->ensure_index({ emailid => 1 }, { unique => bson_true });
	$self->emails->ensure_index({ sender  => 1 }, { unique => bson_true });

	$self->emails->ensure_index({ sendto  => 1 }, {
		unique    => bson_true,
		collation => { locale => 'en', strength => 2 },  # address is case-insensitive
	});

	$self->invites->ensure_index({ token => 1 }, { unique => bson_true });
	my $autoclean = $::app->config('groups')->{cleanup_invitation} || 30;
	$self->invites->ensure_index({ expires => 1 }, { expireAfterSeconds => int($autoclean * 86400) } );

	$self;
}

#---------------------
=section Email, the "outgoing" table

The document is maintained by M<OwnerConsole::Email> objects.
=cut

sub email($)
{	my ($self, $emailid) = @_;
	my $data = $self->emails->find_one({emailid => $emailid})
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
	my $result = $self->emails->remove({emailid => $emailid}, {single => 1});
	my $count  = $result->{deleteCount};
	$self->log($count ? "could not find email $emailid to remove" : "removed email $emailid");
	$count;
}
 
sub removeEmailsRelatedTo($)
{	my ($self, $relid) = @_;
	my $result = $self->emails->remove({related => $relid});
use Data::Dumper ();
warn "RESULT $result";
	my $count  = $result->{deleteCount};
	$self->log("removed $count outgoing emails related to $relid");
	$count;
}
 
sub queueEmail($)
{	my ($self, $email) = @_;

#XXX this should move to a Minion task
	$email->buildMessage($::app->config->{email})->send(to => $email->sendTo);
#	$self->emails->save($email->toDB);
}
 
sub allEmails()
{	my $self = shift;
	$self->emails->find->all;
}

#---------------------
=section Invites

The document is maintained by M<OwnerConsole::Group::Invite> objects.
=cut

sub invitesForGroup($)
{	my ($self, $group) = @_;
	my $data = $self->invites->find({groupid => $group->groupId})->all;
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

1;
