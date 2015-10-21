"""
Concepts:

* Traits.
* Actors.
* Constructors (named, sound, non-null).
"""

use "collections"

trait Thing
  """
  A trait is a _nominal_ type.
  """
  fun tag name(): String
    """
    Any type that wants to be a Thing must provide a name() function.
    This function has no body, so there is no default implementation.
    """

actor Person
  let _name: String
  let _things: SetIs[Thing iso]

  new create(name': String) =>
    """
    All fields must be initialised by the time a constructor is done.
    Until all fields are initialised, we can't do anything that might
    try to read a field.
    """
    _name = name'
    // name()
    _things = SetIs[Thing iso].create()

  new two_names(first: String, last: String) =>
    _name = first + " " + last
    _things = SetIs[Thing iso].create()

  fun name(): String =>
    _name
