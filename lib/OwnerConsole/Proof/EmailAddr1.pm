package OwnerConsole::Proof::EmailAddr1;
use Mojo::Base 'OwnerConsole::Proof';

use Log::Report 'open-console-owner';

use constant {
	ADDR1_SCHEMA => '20240210',
};

=section DESCRIPTION

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	$insert->{schema}  ||= ADDR1_SCHEMA;
	$insert->{sub_addressing} //= 0;

	my $self = $class->SUPER::create($insert, %args);
	$self;
}

#sub fromDB($)
#{	my ($class, $data) = @_;
#	$class->SUPER::fromDB($data);
#}

#-------------
=section Attributes
=cut

sub set()    { 'emailaddrs' }
sub element(){ 'emailaddr'  }
sub algo()   { 'emailaddr1' }
sub sort()   { lc $_[0]->_data->{email} }
sub _score() { 50 }

sub schema() { ADDR1_SCHEMA }

sub email()  { $_[0]->_data->{email} }
sub supportsSubAddressing() { $_[0]->_data->{sub_addressing} }

1;
