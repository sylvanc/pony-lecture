"""
Concepts:

* Using `val` for sharing.
"""

use "collections"

trait Thing

trait EThing

actor Person
  let _name: String
  let _things: SetIs[Thing iso] = SetIs[Thing iso]
  let _ethings: SetIs[EThing val] = SetIs[EThing val]
  var _place: Place

  new create(name: String, place: Place) =>
    _name = name
    _place = place
    _place.arrive(this)

  be download(ething: EThing val) =>
    """
    EThings can be shared. No need to consume.
    """
    _ethings.set(ething)

  be take(thing: Thing iso) =>
    _things.set(consume thing)
