"""
Concepts:

* Behaviours have sendable parameters.
* Destructive read.
"""

use "collections"

actor Person
  let _name: String
  let _things: SetIs[Thing iso] = SetIs[Thing iso]

  new create(name': String) =>
    _name = name'

  be take(thing: Thing iso) =>
  // be take(thing: Thing ref) =>
    """
    Behaviour parameters must be sendable.
    We use `consume` to perform a destructive read.
    """
    _things.set(consume thing)
    // _things.set(thing)
