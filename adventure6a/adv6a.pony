"""
Concepts:

* Ephemeral results.
* Partial functions.
* Exception handling.
"""

use "collections"

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
    """
    If we have the `thing` we're being asked to give away, extract it from our
    set of things and tell the recipient to take it.
    """
    try
      let thing' = _extract(thing)
      whom.take(consume thing')
    end

  fun ref _extract(thing: Thing tag): Thing iso^ ? =>
  // fun ref _extract(thing: Thing tag): Thing iso^ =>
    """
    Extract the `thing` from our set, returning an ephemeral type.
    What if it isn't there? What value can we return?
    """
    _things.extract(thing)

  be arrived(who: Person, place: Place, from: (Place | None)) =>
    None
