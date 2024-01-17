# Programming rules

This page will list a number of coding decissions everyone adding code should understand.

## Database

### Objects referencing other objects

In a clustered (MongoDB) environment, reads are rather cheap and writes are *very expensive*.
Besides, coordinating writes to two collections at the same time is hard as well.  Therefore,
changes progress partial.

For instance, when an Identity is removed from a Group, then only the Group knows.  The Account,
which lists the Group, will only register the change when it is written for some other reason.
