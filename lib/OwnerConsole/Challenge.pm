# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package OwnerConsole::Challenge;
use Mojo::Base 'OpenConsole::Mango::Object';

use Log::Report 'open-console-owner';

use OpenConsole::Util  qw(new_token :time);

=chapter NAME
OwnerConsole::Challenge - handles (email address) challenges

=chapter DESCRIPTION

=chapter METHODS
=section Constructors
=cut

sub create($$%)
{	my ($class, $account, $insert, %args) = @_;
	$insert->{purpose} or panic;
	$insert->{token}   ||= new_token 'H';
	$insert->{userid}  ||= $account->id;

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

sub schema()  { '20240216' }
sub element() { 'challenge' }
sub set()     { 'challanges' }
sub iconFA()  { 'fa-solid fa-chess-night' }
sub elemName(){ __"Challenge" }
sub setName() { __"Challenges" }

sub token()   { $_[0]->_data->{token} }
sub userId()  { $_[0]->_data->{userid} }
sub purpose() { $_[0]->_data->{purpose} }
sub payload() { $_[0]->_data->{payload} ||= {} }

sub isFor($)
{	my ($self, $account) = @_;
	$self->userId eq $account->id;
}

sub link()    { '/challenge/' . $_[0]->token }

#-------------
=section Action
=cut

sub _save(%) { $::app->batch->saveChallenge($_[0]) }

sub close()
{	my $self = shift;
	$self->_data->{closed} = timestamp;
	$self->save;
}

sub isUsed() { exists $_[0]->_data->{closed} }

1;
