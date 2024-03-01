# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Model::Proofs;
use Mojo::Base -base;

use Mango::BSON ':bson';

use OwnerConsole::Proofs         ();
use OwnerConsole::Challenge      ();

=chapter DESCRIPTION

collections:
=over 4
=item * 'proofs'
=item * 'challenges': state machine for challenges
=back

=cut

=chapter METHODS

#---------------------
=section Attributes
=cut

has db         => undef;
has proofs     => sub { $_[0]->{OMB_proofs}  ||= $_[0]->db->collection('proofs')};
has challenges => sub { $_[0]->{OMB_chall}   ||= $_[0]->db->collection('challenges')};

sub upgrade
{	my $self = shift;

	$self->proofs->ensure_index({ proofid => 1 }, { unique => bson_true  });
	$self->proofs->ensure_index({ ownerid => 1 }, { unique => bson_false });

	$self->challenges->ensure_index({ token => 1 }, { unique => bson_true  });

	my $expire_challenges = $::app->config('proofs')->{expire_challenge} || 30;  # days
	$self->challenges->ensure_index({ changed => 1 }, { expireAfterSeconds => int($expire_challenges * 86400) });

	$self;
}

#---------------------
=section Proofs

All kinds of proofs are moved to the same table.
=cut

sub proofSearch($$)
{	my ($self, $set, $ownerid) = @_;
	my $proofs = $self->proofs->find({ownerid => $ownerid, set => $set})->all;
	map OwnerConsole::Proofs->proofFromDB($_), @$proofs;
}

sub saveProof($)
{	my ($self, $proof) = @_;
	$self->proofs->save($proof->toDB);
}

sub proof($)
{	my ($self, $proofid) = @_;
	my $data = $self->proofs->find_one({proofid => $proofid})
		or return;

	OwnerConsole::Proofs->proofFromDB($data);
}

sub deleteProof($)
{	my ($self, $proof) = @_;
	$self->proofs->remove({ proofid => $proof->proofId });
}

#---------------------
=section Challenges

The challenges table hides internal states and ids from the outside, by only
showing a token.
=cut

sub saveChallenge($)
{	my ($self, $challenge) = @_;
	$self->challenges->save($challenge->toDB);
}

sub challenge($)
{	my ($self, $token) = @_;
	my $data = $self->challenges->find_one({token => $token})
		or return;

	OwnerConsole::Challenge->fromDB($data);
}

1;
