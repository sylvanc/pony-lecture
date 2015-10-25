## Deny Capabilities for Safe, Fast Actors

Sylvan Clebsch, Sophia Drossopoulou

Sebastian Blessing, Andy McNeil

Imperial College London, Causality Ltd

---

### Motivation

* <!-- .element: class="fragment"--> Combining the actor-model with shared memory eliminates the need to copy all messages between actors.
* <!-- .element: class="fragment"--> This improves performance, but results in the possiblity of data races.
* <!-- .element: class="fragment"--> Dynamic data-race prevention (via locks or lock-free algorithms) is error-prone and carries a run-time cost.
* <!-- .element: class="fragment"--> A static approach could eliminate all data-races with no run-time cost.

---

### Goals

* <!-- .element: class="fragment"--> Statically checked data-race freedom.
* <!-- .element: class="fragment"--> Ability to pass both mutable and immutable data in messages safely.
* <!-- .element: class="fragment"--> No restriction on message shape (e.g. trees).
* <!-- .element: class="fragment"--> Apply our system to a real-world actor-model programming language: Pony.

---

### What can be safely sent in a message by reference?

* <!-- .element: class="fragment"--> Actor references that allow sending messages, but not reading from oor writing to the actor's state.
* <!-- .element: class="fragment"--> Opaque references that allow neither reading from nor writing to the object.
* <!-- .element: class="fragment"--> Immutable objects.
* <!-- .element: class="fragment"--> Mutable objects, as long as the sending actor is guaranteed not to retain a reference to the object that allows either reading from it or writing to it.
    - <!-- .element: class="fragment"--> That is, _isolated_ objects.

----

### What permissions have to be expressed?

* <!-- .element: class="fragment"--> Writeability.
* <!-- .element: class="fragment"--> Readability.
* <!-- .element: class="fragment"--> Aliasing.
    - <!-- .element: class="fragment"--> Track writeable aliases to determine immutability.
    - <!-- .element: class="fragment"--> Track readable and writeable aliases to determine isolation.

----

Expressing writeability and readability on a reference is easy.

<!-- .element: class="fragment"--> Statically tracking all possible aliases it tricker.

<!-- .element: class="fragment"--> For example, in C++ a `const` reference is _locally_ immutable, but has no guarantee of _global_ immutability.

---

### Let's concentrate on those aliases.

----

Let's call a read/write-unique mutable reference to an object __iso__, to indicate an _isolated type_.

----

An __iso__ reference to an object must guarantee that there are no readable or writeable aliases to the object, anywhere in the program.

<!-- .element: class="fragment"--> If such aliases existed, and we sent the object to another actor, we couldn't guarantee the __iso__ object and those aliases were held by the _same_ actor.

----

This is ok.

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=iso]
  Bob -> Data [label="no permissions"]
}
```

----

But this is bad!

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=iso]
  Bob -> Data [label=readable]
}
```

<!-- .element: class="fragment"--> Bob can be trying to read the data while Alice is modifying it, which can cause data races.

----

And this is bad too!

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=iso]
  Alice -> Data [label=readable]
  Bob
}
```

<!-- .element: class="fragment"--> Alice could _send_ the __iso__ Data to Bob, but retain a readable reference.

----

The existence of an __iso__ reference to an object must _deny_ the existence of any local or global readable or writeable alias to the same object.

----

Let's call a globally immutable reference to an object __val__, to indicate a _value type_.

----

A __val__ reference to an object must guarantee that there are no writeable aliases to the object, anywhere in the program.

<!-- .element: class="fragment"--> It's ok for readable references to exist, since we won't write to the object.

----

This is ok.

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=val]
  Alice -> Data [label=readable]
  Bob -> Data [label=readable]
  Bob
}
```

----

But this is bad!

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=val]
  Bob -> Data [label=writeable]
  Bob
}
```

<!-- .element: class="fragment"--> Alice can read while Bob writes.

----

And this is bad too!

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=val]
  Alice -> Data [label=writeable]
  Bob
}
```

<!-- .element: class="fragment"--> Alice could _send_ the __val__ Data to Bob, but retain a writeable reference.

----

The existence of a __val__ reference to an object must _deny_ the existence of any local or global writeable alias to the same object.

<!-- .element: class="fragment"--> But readable aliases are fine.

----

Let's call an opaque reference to an object that allows neither reading nor writing __tag__, to indicate a _tag type_.

----

A __tag__ reference to an object doesn't have to make any guarantees about aliases.

<!-- .element: class="fragment"--> It's ok for both writeabla and readable aliases to exist, since we won't read from the object.

----

This is ok.

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=tag]
  Alice -> Data [label=writeable]
  Bob
}
```

----

And this is ok, too.

```viz
digraph {
  Data [shape=box]
  Alice -> Data [label=tag]
  Bob -> Data [label=writeable]
  Bob
}
```

----

The existence of a __tag__ reference to an object doesn't _deny_ the existence of any other aliases to the same object.

----

An actor reference doesn't have to make any guarantees about aliases.

<!-- .element: class="fragment"--> Since we interact with the actor asynchronously, an actor reference doesn't have to make any more guarantees than an opaque reference.

<!-- .element: class="fragment"--> So we can type actors as __tag__ references.

---

### Deny Properties

----

Let's build a matrix of these deny properties.

----

An __iso__ reference denies local and global read and write aliases.

| Deny global | aliases | |
-----------------------|--------------|-----------|-----
__Deny local aliases__ | _Read/Write_ | _Write_   | _None_
_Read/Write_           | __iso__      |           |
_Write_                |              |           |
_None_                 |              |           |

----

A __val__ reference denies local and global write aliases.

| Deny global | aliases | |
-----------------------|--------------|-----------|-----
__Deny local aliases__ | _Read/Write_ | _Write_   | _None_
_Read/Write_           | __iso__      |           |
_Write_                |              | __val__   |
_None_                 |              |           |

----

A __tag__ reference denies nothing.

| Deny global | aliases | |
-----------------------|--------------|-----------|-----
__Deny local aliases__ | _Read/Write_ | _Write_   | _None_
_Read/Write_           | __iso__      |           |
_Write_                |              | __val__   |
_None_                 |              |           | __tag__

----

That's interesting! A type is _sendable_ when it guarantees locally what it guarantees globally.

| Deny global | aliases | |
-----------------------|--------------|-----------|-----
__Deny local aliases__ | _Read/Write_ | _Write_   | _None_
_Read/Write_           | __iso__      |           |
_Write_                |              | __val__   |
_None_                 |              |           | __tag__

----

What other properties can we derive from this matrix?

----

Any reference that denies _global_ read/write aliases is _mutable_. You can use _that_ reference to read from or write to the object, because no other actor can read from or write to the object.

| Deny global | aliases | |
-----------------------|--------------|-----------|-----
__Deny local aliases__ | _Read/Write_ | _Write_   | _None_
_Read/Write_           | __iso__      |           |
_Write_                |              | __val__   |
_None_                 |              |           | __tag__
                       | _mutable_    |           |

----

Any reference that denies _global_ write aliases is _immutable_. You can use _that_ reference to read from the object, because no other actor can read from write to the object. You _can't_ use that reference to write to the object, because some other actor might read from it.

| Deny global | aliases | |
-----------------------|--------------|-------------|-----
__Deny local aliases__ | _Read/Write_ | _Write_     | _None_
_Read/Write_           | __iso__      |             |
_Write_                |              | __val__     |
_None_                 |              |             | __tag__
                       | _mutable_    | _immutable_ |

----

Any reference that denies nothing is _opaque_. You can't use _that_ reference to read from or write to the object, because some other actor might read from write to the object.

| Deny global | aliases | |
-----------------------|--------------|-------------|-----
__Deny local aliases__ | _Read/Write_ | _Write_     | _None_
_Read/Write_           | __iso__      |             |
_Write_                |              | __val__     |
_None_                 |              |             | __tag__
                       | _mutable_    | _immutable_ | _opaque_

---

### What goes in the empty cells of the matrix?

----

If we deny global read/write aliases, but allow _any_ local alias, we have a reference that is _mutable_ but not _sendable_.

<!-- .element: class="fragment"--> It behaves like an object in most object oriented languages: you can have lots of aliases to it, and you can mutate it

<!-- .element: class="fragment"--> But you have a guarantee: you know no other actor will read from or write to the object.

----

Let's call a non-unique mutable reference to an object __ref__, to indicate a _reference type_.

| Deny global | aliases | |
-----------------------|--------------|-------------|-----
__Deny local aliases__ | _Read/Write_ | _Write_     | _None_
_Read/Write_           | __iso__      |             |
_Write_                |              | __val__     |
_None_                 | __ref__      |             | __tag__
                       | _mutable_    | _immutable_ | _opaque_

----

If we deny global write aliases, but allow _any_ local alias, we have a reference that is _immutable_ but not _sendable_.

<!-- .element: class="fragment"--> In other words, it is _locally_ immutable as opposed to _globally_ immutable.

<!-- .element: class="fragment"--> This is analogous to a C++ `const` type.

----

Let's call a locally immutable reference to an object __box__, to indicate a _black box type_.

| Deny global | aliases | |
-----------------------|--------------|-------------|-----
__Deny local aliases__ | _Read/Write_ | _Write_     | _None_
_Read/Write_           | __iso__      |             |
_Write_                |              | __val__     |
_None_                 | __ref__      | __box__     | __tag__
                       | _mutable_    | _immutable_ | _opaque_

----

If we deny global read/write aiases, but allow local read aliases (but not write aliases), we have a reference that is write-unique, but not read-unique.

<!-- .element: class="fragment"--> We can read from it and write from it through this reference, because we know only the same actor can read from it.

<!-- .element: class="fragment"--> We can also _freeze_ it as a __val__ (globally immutable) type in the future, because we know the object is only writeable through this reference.

<!-- .element: class="fragment"--> Or we can give up our write-uniqueness and allow local writeable aliases, and become a __ref__ (non-unique mutable) type.

----

Let's call a write-unique mutable reference to an object __trn__, to indicate a _transition type_.

| Deny global | aliases | |
-----------------------|--------------|-------------|-----
__Deny local aliases__ | _Read/Write_ | _Write_     | _None_
_Read/Write_           | __iso__      |             |
_Write_                | __trn__      | __val__     |
_None_                 | __ref__      | __box__     | __tag__
                       | _mutable_    | _immutable_ | _opaque_

----

That's it!

----

The other spaces in the matrix stay empty, because we can't _locally deny_ aliases that we don't _globally deny_.

| Deny global | aliases | |
-----------------------|--------------|-------------|-----
__Deny local aliases__ | _Read/Write_ | _Write_     | _None_
_Read/Write_           | __iso__      |             |
_Write_                | __trn__      | __val__     |
_None_                 | __ref__      | __box__     | __tag__
                       | _mutable_    | _immutable_ | _opaque_

---

### Reference Capabilities

----

We call this system of annotations _reference capabilities_ (rcap).

<!-- .element: class="fragment"--> It is inspired by _object capabilities_ (ocap), a system for building secure, principle of least authority code in object-oriented languages.

<!-- .element: class="fragment"--> Existing ocap actor-model languages, such as E, AmbientTalk, and SES JavaScript, are the inspiration for Pony.

<!-- .element: class="fragment"--> Pony is an rcap, ocap, statically typed, ahead-of-time compiled, native language.

----

Reference capabilities have a subtype relationship.

```viz
digraph {
  rankdir = LR
  iso -> trn
  trn -> ref
  trn -> val
  ref -> box
  val -> box
  box -> tag
}
```

<!-- .element: class="fragment"--> In other words, an rcap is a subtype of another rcap if it denies _more_.

---

### Is this too complicated for a programmer to use?

----

Theoretically: it's fine!

<!-- .element: class="fragment"--> When programming in languages that aren't provably data-race free, programmers already keep a model of isolated, globally immutable and opaque data in their heads.

<!-- .element: class="fragment"--> These types _reify_ for the compiler a concept that is already pervasive in real world code.

----

Empirically: it's fine!

<!-- .element: class="fragment"--> When programmers learn Pony, it appears to take them around two weeks to get the hang of how to use reference capabilities to express their _existing_ ideas about ownership and sharing.

---

### How do reference capabilities compose?

----

Alice has a bicycle, which has brakes, which might be engaged.

```viz
digraph {
  rankdir=LR
  Bicycle [shape=box]
  Brakes [shape=box]
  "engaged: Bool" [shape=box]
  Alice -> Bicycle [label=iso]
  Bicycle -> Brakes [label=ref]
  Brakes -> "engaged: Bool" [label=val]
}
```

<!-- .element: class="fragment"--> How does Alice see these different objects?

<!-- .element: class="fragment"--> We call this _viewpoint adaptation_.

<!-- .element: class="fragment"--> We write viewpoint adaptation as: object ▷ field = result.

----

The brakes see their engaged status as __val__.

```viz
digraph {
  rankdir=LR
  Bicycle [shape=box]
  Brakes [shape=box]
  "engaged: Bool" [shape=box]
  Alice -> Bicycle [label=iso]
  Bicycle -> Brakes [label=ref]
  Brakes -> "engaged: Bool" [label=val]
}
```

<!-- .element: class="fragment"--> How does the bicycle see the engaged status?

<!-- .element: class="fragment"--> Global immutability is _deep_: __ref__ ▷ __val__ = __val__

<!-- .element: class="fragment"--> Similarly, Alice sees the engaged status as __val__, because viewpoint adaptation is right-to-left: __iso__ ▷ (__ref__ ▷ __val__) = __val__

----

The bicycle sees its brakes as __ref__.

```viz
digraph {
  rankdir=LR
  Bicycle [shape=box]
  Brakes [shape=box]
  "engaged: Bool" [shape=box]
  Alice -> Bicycle [label=iso]
  Bicycle -> Brakes [label=ref]
  Brakes -> "engaged: Bool" [label=val]
}
```

<!-- .element: class="fragment"--> How does Alice see the brakes?

<!-- .element: class="fragment"--> The uniqueness guarantees of __iso__ can't be violated, so __iso__ ▷ __ref__ = __tag__.

<!-- .element: class="fragment"--> In other words, an alias of the brakes from _outside_ the bicycle has to be a __tag__ to prevent the bicycle's _isolation_ from being violated.

<!-- .element: class="fragment"--> If Alice _sends_ her bicycle to Bob, we have to be sure she doesn't keep any readable or writeable references to the bicycle _or to any mutable state the bicycle can reach_.

----

There are rules for how each rcap sees each other rcap.

<!-- .element: class="fragment"--> Each rule is simply the application of the deny properties of the object's rcap to the field's rcap.

----

(This table is simpler than it looks.)

▷          | Field   |         |         |         |         |       |
-----------|---------|---------|---------|---------|---------|-------|
__Object__ | __iso__ | __trn__ | __ref__ | __val__ | __box__ | __tag__
__iso__    | iso     | tag     | tag     | val     | tag     | tag
__trn__    | iso     | trn     | box     | val     | box     | tag
__ref__    | iso     | trn     | ref     | val     | box     | tag
__val__    | val     | val     | val     | val     | val     | tag
__box__    | tag     | box     | box     | val     | box     | tag
__tag__    | ⊥       | ⊥       | ⊥       | ⊥       | ⊥       | ⊥

----

Similarly, there are rules as to what rcaps can be written into the fields of an object without violating it's rcap.

<!-- .element: class="fragment"--> This means not violating read/write uniqueness for an __iso__ and not violating write uniqueness for a __trn__.

<!-- .element: class="fragment"--> We call this _safe-to-write_.

<!-- .element: class="fragment"--> We write safe-to-write as: object ◁ input.

----

◁          | Input   |         |         |         |         |       |
-----------|---------|---------|---------|---------|---------|-------|
__Object__ | __iso__ | __trn__ | __ref__ | __val__ | __box__ | __tag__
__iso__    | ✓       |         |         | ✓       |         | ✓  
__trn__    | ✓       | ✓       |         | ✓       |         | ✓  
__ref__    | ✓       | ✓       | ✓       | ✓       | ✓       | ✓  
__val__    |         |         |         |         |         |
__box__    |         |         |         |         |         |
__tag__    |         |         |         |         |         |

<!-- .element: class="fragment"--> Sendable and read/write-unique types are ok to write into an __iso__.

<!-- .element: class="fragment"--> Sendable and write-unique types are ok to write into a __trn__.

<!-- .element: class="fragment"--> Sendable and non-unique types (i.e. all types) are ok to write into a __ref__.

<!-- .element: class="fragment"--> The other types aren't mutable, so it's not ok to write any type into them.

---

### Non-reflexive aliasing and ephemerality

----

Is this legal?

```pony
let x: Something iso = ...
let y: Something iso = x
```

<!-- .element: class="fragment"--> No! We would have two __iso__ references to the same object. That's bad.

----

The alias of an rcap is the rcap that has the _most_ deny properties, but which is _compatible_ with the original rcap.

<!-- .element: class="fragment"--> In other words, the original rcap doesn't deny the alias.

----

Original | Alias
---------|------
iso      | tag
trn      | box
ref      | ref
val      | val
box      | box
tag      | tag

----

We have to destroy an __iso__ reference in order to assign the underlying object to another __iso__ reference.

```pony
let x: Something iso = ...
let y: Something iso = consume x
```

<!-- .element: class="fragment"--> We use `consume` to indicate a destructive read. The object isn't destroyed - but the alias (in this case `x`) is removed from the lexical scope.

----

What's the type of `consume x` where `x: Something iso`?

<!-- .element: class="fragment"--> `Something iso^`

<!-- .element: class="fragment"--> The `^` means an _ephemeral_ (or _unaliased_ ) type.

----

An _ephemeral_ type has had one alias removed.

<!-- .element: class="fragment"--> Since an __iso__ denies local and global read/write aliases, an __iso^__ is not reachable by any readable or writeable aliases.

<!-- .element: class="fragment"--> Which means it is safe to assign it to an __iso__, thereby establishing _one_ reachable read/write alias.

----

Destructive read and non-reflexive aliasing give us static alias tracking with no runtime cost.

---

### Future Work

----

Pony uses reference capabilities in the presence of generic types, generic methods, algebraic data types, and a non-null type system.

<!-- .element: class="fragment"--> We hope to extend the formalisation of reference capabilities to cover these cases.

----

Pony uses reference capabilities to help optimise garbage collection.

<!-- .element: class="fragment"--> We hope to formalise this too.

---

## Come get involved!

Join our community of students, hobbyists, industry developers, tooling developers, library writers, compiler hackers, and type system theorists.

Why not you?

http://ponylang.org
