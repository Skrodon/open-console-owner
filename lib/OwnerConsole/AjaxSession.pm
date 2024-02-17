package OwnerConsole::AjaxSession;
use Mojo::Base -base;

use Log::Report 'open-console-owner';

use Scalar::Util    qw(blessed);

=section Constructors
=cut

#------------------
=section Attributes

=cut

has _data => sub {  +{ warnings => [], errors => [], notifications => [], internal_errors => [] } };

has controller => sub { ... };
has account    => sub { $_[0]->controller->account };

#------------------
=section About the request
=cut

sub request() { $_[0]->{OA_request} ||= $_[0]->controller->req }

sub query()
{	my $self = shift;
	exists $self->{OA_query} or $self->{OA_query} = $self->request->url->query;
	$self->{OA_query};
}

sub about($)
{	my ($self, $idlabel) = @_;
	$self->controller->param($idlabel);
}

sub params()
{	my $self = shift;
	my $req  = $self->request;
	$self->{OA_params} ||= $req->json || $req->body_params->to_hash;
}

sub optionalParam($;$) { delete $_[0]->params->{$_[1]} // $_[2] }

sub requiredParam($) { $_[0]->optionalParam($_[1]) or panic "param $_[1] missing" }

sub checkParamsUsed()
{	my $self   = shift;
	my $params = $self->params;
	keys %$params == 0
		or warn "Unprocessed parameters: ", join ', ', sort keys %$params;
	$self;
}

#------------------
=section Collecting the answer
=cut

sub addError($$)
{	my ($self, $field, $error) = @_;
	push @{$self->_data->{errors}}, [ $field => blessed $error ? "$error" : $error ];
}

sub hasErrors() { scalar @{$_[0]->_data->{errors}} }

sub addWarning($$)
{	my ($self, $field, $warn) = @_;
	push @{$self->_data->{warnings}}, [ $field => blessed $warn ? "$warn" : $warn ];
}

sub notify($$)
{	my ($self, $level, $msg) = @_;
	# Hopefully, later we can have nicer notifications than a simple alert.
	push @{$self->_data->{notifications}}, "$level: $msg";
}

sub redirect($)
{	my ($self, $location) = @_;
	$self->_data->{redirect} = $location;
}

sub internalError($) { push @{$_[0]->_data->{internal_errors}}, $_[1]->toString }

sub hasInternalErrors() { scalar @{$_[0]->_data->{internal_errors}} }

sub isHappy() { ! $_[0]->hasErrors && ! $_[0]->hasInternalErrors }

#------------------
=section Generic code for Objects
=cut

sub openObject()
{	my ($self, $objclass, $objectid) = @_;
	...;
}

#------------------
=section Generic code for Proofs
=cut

sub openProof($$)
{	my ($self, $objclass) = @_;
	my $proofid = $self->about('proofid');

	return $objclass->create({ owner => $self->account })
	  	if $proofid eq 'new';

	my $proof = $self->account->proof($objclass->set, $proofid);
	unless($proof)
	{	$self->internalError(__x"The proof has disappeared.");
		return undef;
	}

	$proof;
}

#------------------
=section Actions
=cut

sub reply()
{	my $self = shift;
	$self->controller->render(json => $self->_data);
}

1;
