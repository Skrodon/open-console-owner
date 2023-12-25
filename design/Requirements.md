# Implementation Plan

At the moment, this is just a poorly organized dump of ideas.

## Terminology

  * "Person": a human
  * "Identity": one of the identifications for a single Person or Association
  * "Association": a group of people, represented as a single identity. For instance, a company department, an foundation board, or your family members.
  * "Producer": (requires a better name) a company which wants to interact with the website owner
  * "Dashboard": the central webpage in the Open Console Owner's website, for people who are logged-in.
 
## Identities

A person registers at the website
  * register / recover
  * login / logout
  * delete (for real)

When registered, the person get a first "Identity"

A person can create multiple Identies. For instance for different roles: private, work, board membership, etc.
  * name

Each Identity MAY differ in contained data.  For instance, different phone numbers and postal addresses.
  * phone(s)
  * postal / visit addresses
  * email address
  * time-zone

Producers will not be able to link different identities of the same person: they get different authentication tokens.

A person can start an Association: combine a group of people to share ownership
  * add / remove association
  * add / remove people
  * different rights for people.  For instance: right to change, right to use

## Ownership proof

You can have ownership over
  * a domain-name.  For instance "example.com"
  * a website / sub-domain.  For instance, "www.example.com"
  * an IPv4-address range.  For instance, "12.34.123/24"
  * an IPv6-address range.  For instance, "2a6b::1/128"

There may be different ways to proof ownership
  * DNS, see RFC https://datatracker.ietf.org/doc/draft-ietf-dnsop-domain-verification-techniques
  * put file on certain spot in website
  * website (https) certificate
  * unproven (by declaration only)

Proofs may come in different levels
  * proven via DNS with or without DNSSEC
  * pending / unproven

One proof MAY include equivalence.  For instance, www.example.com could be the same as www.example.nl.  They may need to be tested in one go.

A person links the proof to one of his Identities or Associations.
  * add / refresh / remove proof
  * can be moved between Identities or Associations

## Producers

("Producer" is not a good name here... but used until we decide for something
better)

A producer is a registered Association Identity, so belongs to registered
people.

When a Person (with a personal or associated Identity) wants to communicate with a producer, he will go to the website of the Producer, and agree to a license.  Then, the Producer can verify the Identity via OAuth2.

Once the connection is accepted, the Person will see the Producer in the Dashboard.

The Producer MAY offer more than one Service per registration.

The Person can organize the Producers he registered for: there can be many.

The Producer can send messages to the Identities.
  * message have an urgency
  * plain text / html / referring to Producer's website

The Person can configure how to receive the messages, dependent on urgency
  * unbundled
  * bundled per hour / day / week
  * bundled over Producers
  * ignored

## Dashboard


