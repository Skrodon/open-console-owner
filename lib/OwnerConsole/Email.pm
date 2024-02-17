package OwnerConsole::Email;
use Mojo::Base 'OwnerConsole::Mango::Object';

use Log::Report 'open-console-owner';

use Mail::Message ();
use Mail::Message::Body::String    ();
use Mail::Message::Body::Multipart ();

use OwnerConsole::Util  qw(new_token);

=section DESCRIPTION

=section Constructors
=cut

use constant MAIL_SCHEMA => '20240116';

=section DESCRIPTION

=section Constructors
=cut

sub create($%)
{   my ($class, %args) = @_;
	my $to     = $args{sendto} or panic;  # email
	my $sender = $args{sender};

	my %insert = (
    	emailid  => (new_token 'M'),
    	schema   => MAIL_SCHEMA,
    	sender   => $sender ? $sender->userId : undef,
		subject  => $args{subject} // (panic "No subject"),
		related  => $args{related} // [],
		sendto   => $to,
		purpose  => $args{purpose} // (panic "No purpose"),
		state    => 'created',
		text     => $args{text}->to_string,
		html     => $args{html}->to_string,
	);

	$class->SUPER::create(\%insert, %args);
}

#-------------
=section Attributes
=cut

sub emailId()    { $_[0]->_data->{emailid} }
sub sendTo()     { $_[0]->_data->{sendto} }
sub senderId()   { $_[0]->_data->{sender} }
sub subject()    { $_[0]->_data->{subject} }
sub relatedIds() { @{$_[0]->_data->{related}} }
sub purpose()    { $_[0]->_data->{purpose} }
sub state()      { $_[0]->_data->{state} }
sub text()       { $_[0]->_data->{text} }
sub html()       { $_[0]->_data->{html} }

sub sender() { $::app->users->user($_[0]->senderId) }
sub queue()  { $::app->batch->queueEmail($_[0]) }

#-------------
=section Task for Minion

The Minion has all the time in the world to compose and send the
email, not delaying the user's website experience.
=cut

my $CRLF = "\x0D\x0A";

sub send()
{	my $self   = shift;
	my $config = $::app->config->{email} || {};
	$self->buildMessage($config)->send(to => $self->sendTo);
}

sub buildMessage($)
{	my ($self, $config) = @_;

	my $text = Mail::Message::Body::String->new(
		charset   => 'PERL',
		mime_type => 'text/plain',
		data      => $self->text =~ s/\n/$CRLF/gr,
	);

	my $html = Mail::Message::Body::String->new(
		charset   => 'PERL',
		mime_type => 'text/html',
		data      => $self->html =~ s/\n/$CRLF/gr,
	);

	my $body = Mail::Message::Body::Multipart->new(
    	preamble  => <<'__PREAMBLE',
The contents of the text and html alternatives is the same.
__PREAMBLE
		mime_type => 'multipart/alternative',
		parts     => [ $text, $html ],
	);

	Mail::Message->buildFromBody(
		$body,
		From    => $config->{sender},
		To      => $config->{overrule_to} || $self->sendTo,
		Subject => $config->{subject_prefix} . $self->subject,
	);
}

#-------------
=section Action
=cut


1;
