"""
Conveniences:

* Union types.
* Default arguments.
* Single vs. multiple assignment variables.
"""

use "collections"

actor Person
  let _name: String
  let _things: SetIs[Thing iso] = SetIs[Thing iso]
  var _place: Place

  new create(name: String, place: Place) =>
    _name = name
    _place = place
    _place.arrive(this, place)
    // _place.arrive(this, None)
    // _place.arrive(this)

  be arrived(who: Person, place: Place, from: (Place | None)) =>
    """
    This is a placeholder: here, we would react to someone arriving.
    In this case, we only react to our own arrival.
    """
    if this is who then
      _place = place
    end

actor Place
  let _name: String
  let _people: SetIs[Person] = SetIs[Person]

  new create(name': String) =>
    _name = name'

  be arrive(who: Person, from: (Place | None)) =>
  // be arrive(who: Person, from: Place) =>
  // be arrive(who: Person, from: (Place | None) = None) =>
    """
    When someone arrives, tell everyone present where they came from.
    This includes telling the person who has arrived.
    """
    _people.set(who)

    for person in _people.values() do
      person.arrived(who, this, from)
    end
