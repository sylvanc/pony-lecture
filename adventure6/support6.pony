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
