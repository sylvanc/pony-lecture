use "collections"

actor Person
  let _name: String
  let _things: SetIs[Thing iso] = SetIs[Thing iso]

  new create(name': String) =>
    _name = name'

  be take(thing: Thing iso) =>
    _things.set(consume thing)
