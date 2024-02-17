package OwnerConsole::AjaxAnswer;
use Mojo::Base -base;

use Log::Report 'open-console-owner';

use Scalar::Util    qw(blessed);

=section Constructors
=cut

#------------------
=section Attributes
=cut

has data => sub {  +{ warnings => [], errors => [], notifications => [] } };

#------------------
=section Actions
=cut

sub addError($$)
{	my ($self, $field, $error) = @_;
	push @{$self->data->{errors}}, [ $field => blessed $error ? "$error" : $error ];
}

sub hasErrors()
{	my $self = shift;
	scalar @{$self->data->{errors}};
}

sub addWarning($$)
{	my ($self, $field, $warn) = @_;
	push @{$self->data->{warnings}}, [ $field => blessed $warn ? "$warn" : $warn ];
}

sub notify($)
{	my ($self, $text) = @_;
	push @{$self->data->{notifications}}, $text->toString;
}

sub redirect($)
{	my ($self, $location) = @_;
	$self->data->{redirect} = $location;
}

1;
