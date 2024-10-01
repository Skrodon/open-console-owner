# Programming rules

This page will list a number of coding decissions everyone adding code should understand.

First, you should read the [[https://github.com/Skrodon/open-console-core/Programming.pm|programming rules of Core]].

## HTML

### ARIA

Adds components to HTML for "Web Accessibility":

  * [[https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA|ARIA Specification]]
  * Do not use `aria-required` but `required` to form input fields: JS adds "(required)" to the placeholder.

### Mojolicious

  * In Mojo, methods can be used as getters and setters.  Getters return a value, but the setter returns the object :-( Example: `my $value = $c->stash('key')` but `$c == $c->stash(key => $value)`
