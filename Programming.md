# Programming rules

This page will list a number of coding decissions everyone adding code should understand.

First, you should read the [[https://github.com/Skrodon/open-console-core/Programming.pm|programming rules of Core]].

## HTML

### ARIA

Adds components to HTML for "Web Accessibility":

  * [[https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA|ARIA Specification]]
  * Do not use `aria-required` but `required` to form input fields: JS adds "(required)" to the placeholder.

## Mojolicious

  * In Mojo, methods can be used as getters and setters.  Getters return a value, but the setter returns the object :-( Example: `my $value = $c->stash('key')` but `$c == $c->stash(key => $value)`

### Tracking form changes

It would be nice if form libraries, like bootstrap, support forms with changes: extra
hints for people who edit the form based on old data.

This needs to be documented better, but for now we do with an example:
```
  <div class="history history-new" for="email" data-schema="20240101" data-reason="new">
    First test, just because I can. 
  </div>
  <div class="history history-change" for="email" data-schema="20240102" data-reason="change"> 
    The possibilities of this field have been extended.  Also, the email address gets a more
    strict validation.
  </div>
  <div class="history history-deprecate" for="email" data-schema="20240102" data-reason="deprecated">
    This field will disappear soon.  Messages will be send via WhatsApp from now on.
  </div>

  <div class="history history-new" for="avatar" data-schema="20230101">
    Don't show this.
  </div>
```
