"""
Concepts:

* Aliasing iso as tag.
* Recovery again.
* Destructive read again.
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

actor Person
  let _name: String
  let _things: SetIs[Thing iso] = SetIs[Thing iso]
  var _place: Place

  new create(name: String, place: Place) =>
    _name = name
    _place = place
    _place.arrive(this)

  be take(thing: Thing iso) =>
    _things.set(consume thing)

  be give(whom: Person, thing: Thing tag) =>
    try
      let thing' = _extract(thing)
      whom.take(consume thing')
    end

  fun ref _extract(thing: Thing tag): Thing iso^ ? =>
    _things.extract(thing)

  be arrived(who: Person, place: Place, from: (Place | None)) =>
    None
