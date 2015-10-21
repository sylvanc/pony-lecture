use "collections"

actor Person
  let _name: String
  let _things: SetIs[Thing iso] = SetIs[Thing iso]

  new create(name': String) =>
    _name = name'

  be take(thing: Thing iso) =>
    _things.set(consume thing)

trait Thing
  fun tag name(): String

class CinemaTicket is Thing
  """
  A CinemaTicket provides the Thing trait.
  """
  let film: String

  new create(film': String) =>
    film = film'

  fun tag name(): String =>
  // fun ref name(): String =>
    """
    Since a CinemaTicket is a Thing, it must provide a name() function.
    """
    "cinema ticket"
