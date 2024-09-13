# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Challenge;
use Mojo::Base 'OpenConsole::Mango::Object';

use Log::Report 'open-console-owner';

use Mango::BSON::Time   ();

use OpenConsole::Util  qw(new_token);

use constant
{	CHALLENGE_SCHEMA => '20240216',
};

=chapter NAME
OwnerConsole::Challenge - handles (email address) challenges

=chapter DESCRIPTION

=chapter METHODS
=section Constructors
=cut

sub create($$%)
{	my ($class, $account, $insert, %args) = @_;
	$insert->{purpose} or panic;

	$insert->{schema}  ||= CHALLENGE_SCHEMA;
	$insert->{token}   ||= new_token 'H';
	$insert->{created} ||= Mango::BSON::Time->new;
	$insert->{userid}  ||= $account->userId;

	my $self = $class->SUPER::create($insert, %args);
	$self;
}

#sub fromDB($)
#{	my ($class, $data) = @_;
#	$class->SUPER::fromDB($data);
#	$self;
#}

#-------------
=section Attributes
=cut

sub token()   { $_[0]->_data->{token} }
sub userId()  { $_[0]->_data->{userid} }
sub purpose() { $_[0]->_data->{purpose} }
sub payload() { $_[0]->_data->{payload} ||= {} }

sub isFor($)
{	my ($self, $account) = @_;
	$self->userId eq $account->userId;
}

sub expires()
{	my $self = shift;
	return $self->{OC_exp} if exists $self->{OC_exp};

	my $exp = $self->_data->{expires};
	$self->{OC_exp} = $exp ? (bson2datetime $exp, $self->timezone) : undef;
}

sub hasExpired()
{	my $self = shift;
	return $self->{OC_dead} if exists $self->{OC_dead};
	my $exp  = $self->expires;
	$self->{OC_dead} = defined $exp ? $exp < DateTime->now : 0;
}

sub link()       { '/challenge/' . $_[0]->token }

#-------------
=section Action
=cut

sub save(%)
{   my ($self, %args) = @_;
	$self->_data->{changed} = Mango::BSON::Time->new;
    $::app->batch->saveChallenge($self);
}

sub close()
{	my $self = shift;
	$self->_data->{closed} = Mango::BSON::Time->new;
	$self->save;
}

sub isUsed() { exists $_[0]->_data->{closed} }

1;
