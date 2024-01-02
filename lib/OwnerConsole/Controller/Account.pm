package OwnerConsole::Controller::Account;
use Mojo::Base 'Mojolicious::Controller';
use Mojolicious::Plugin::I18NUtils;

sub index($) {
    my $self = shift;

    my $preferred_languages = $self->get_preferred_languages || ['default'];
    my $long_language_names = $self->get_long_language_names($preferred_languages);
    $self->render(
        template            => 'login/account',
        account             => $self->account,
        preferred_languages => $preferred_languages,
        long_language_names => $long_language_names,
    );
}

sub get_preferred_languages {
    my $self = shift;

    my $accept_languages = $self->req->headers->accept_language;
    my @preferred_languages;

    if ($accept_languages) {
        if (ref $accept_languages eq 'Mojo::Headers::AcceptLanguage') {
            @preferred_languages = map { /^([^;]+)/ } $accept_languages->languages;
        } else {
            @preferred_languages = map { /^([^;]+)/ } split /,/, $accept_languages;
        }
    }

    return \@preferred_languages;
}

sub get_long_language_names {
    my ($self, $languages) = @_;

    # Need to add all languages in EU
    my %language_names = (
        'nl-NL' => 'Nederlands',
        'nl'    => 'Nederlands',
        'en'    => 'English',
		'vi'    => 'Tiếng Việt',
    );

    my %seen;
    my @long_language_names = map {
        my $lang_code      = $_;
        my $primary_lang   = ($lang_code =~ /^([a-zA-Z]+)/)[0];    # Extract primary language code
        my $long_name      = $language_names{$primary_lang} // 'Unknown Language';
        print "Language Code: $lang_code, Long Name: $long_name\n";
        $long_name eq 'Unknown Language' ? () : ($seen{$long_name}++ ? () : $long_name);
    } @$languages;

    return \@long_language_names;
}


1;
