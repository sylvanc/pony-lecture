"""
Conveniences:

* Inline field initialisation.
* Implicit constructors.
"""

use "collections"

trait Thing
  fun tag name(): String

actor Person
  """
  When we initialise a field here, it's initialised the same way in every
  constructor.

  Specifying a type without a constructor as an expression implicitly uses the
  default constructor, which is create().
  """
  let _things: SetIs[Thing iso] = SetIs[Thing iso]
  let _name: String

  new create(name': String) =>
    _name = name'

  new two_names(first: String, last: String) =>
    _name = first + " " + last
