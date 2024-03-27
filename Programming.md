# Programming rules

This page will list a number of coding decissions everyone adding code should understand.

## Database

### Objects referencing other objects

In a clustered (MongoDB) environment, reads are rather cheap and writes are *very expensive*.
Besides, coordinating writes to two collections at the same time is hard as well.  Therefore,
changes progress partial.

For instance, when an Identity is removed from a Group, then only the Group knows.  The Account,
which lists the Group, will only register the change when it is written for some other reason.

## HTML

### ARIA

Adds components to HTML for "Web Accessibility":

  * [[https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA|ARIA Specification]]
  * Do not use `aria-required` but `required` to form input fields: JS adds "(required)" to the placeholder.

## Surprises

### Mojolicious

  * `my $value = $c->stash('key')` but `$c == $c->stash(key => $value)`
