"""
Concepts:

* Aliasing `iso` as `tag`.
"""

use "collections"

actor Main
  new create(env: Env) =>
    """
    We start by putting Alice and Bob in the pub.
    We give Alice a cinema ticket.
    Then we tell Alice to give her cinema ticket to Bob.
    """
    let pub = Place("Pub")
    let alice = Person("Alice", pub)
    let bob = Person("Bob", pub)

    let ticket = recover CinemaTicket("Minions") end
    let ticket_id = ticket

    alice.take(consume ticket)
    // alice.take(ticket)
    alice.give(bob, ticket_id)
    // alice.give(bob, ticket)
