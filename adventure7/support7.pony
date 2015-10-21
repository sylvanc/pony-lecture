use "collections"

actor Place
  let _name: String
  let _people: SetIs[Person] = SetIs[Person]

  new create(name': String) =>
    _name = name'

  be arrive(who: Person, from: (Place | None) = None) =>
    _people.set(who)
