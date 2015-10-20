"""
Concepts:

* Providing a trait.
* Function receiver capabilities.
* Receiver capability subtyping.
"""

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
