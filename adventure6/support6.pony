use "collections"

trait Thing
  fun tag name(): String

actor Place
  let _name: String
  let _people: SetIs[Person] = SetIs[Person]

  new create(name': String) =>
    _name = name'

  be arrive(who: Person, from: (Place | None) = None) =>
    _people.set(who)

    for person in _people.values() do
      person.arrived(who, this, from)
    end

class CinemaTicket is Thing
  let _film: String

  new create(film': String) =>
    _film = film'

  fun tag name(): String =>
    "cinema ticket"

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
