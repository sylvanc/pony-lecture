"""
Concepts:

* Actor constructors are asynchronous.
* Causality.
"""

use "collections"
use "debug"

actor Main
  new create(env: Env) =>
    """
    Now we have a pub, and we want to put Alice in the pub.
    Because of causality, the first message Alice will ever send is to tell
    the pub she has arrived.
    And that message is a cause of every message Alice ever sends.
    """
    let pub = Place("Pub")
    let alice = Person("Alice", pub)

    // Are actors constructed in order?
    // let bob = Person("Bob", pub)
    // let charlotte = Person("Charlotte", pub)
    // let dave = Person("Dave", pub)
    // let elspeth = Person("Elspeth", pub)

actor Person
  let _name: String
  let _things: SetIs[Thing iso] = SetIs[Thing iso]
  let _place: Place

  new create(name: String, place: Place) =>
    _name = name
    _place = place

    // What if the Place has not yet run its constructor?
    _place.arrive(this, place)
    Debug(["constructed Person", name])

  be arrived(who: Person, place: Place, from: Place) =>
    """
    This is a placeholder: here, we would react to someone arriving.
    """
    None

actor Place
  let _name: String
  let _people: SetIs[Person] = SetIs[Person]

  new create(name': String) =>
    _name = name'
    Debug(["constructed Place", name'])

  be arrive(who: Person, from: Place) =>
    """
    When someone arrives, tell everyone present where they came from.
    This includes telling the person who has arrived.
    """
    _people.set(who)

    for person in _people.values() do
      person.arrived(who, this, from)
    end
