## Actor-Model Programming

----

What's a programming model?

<!-- .element: class="fragment"--> What's an actor?

<!-- .element: class="fragment"--> Why would I want one?

---

## Programming Models

----

First, there was a big sequence of instructions.

----

Assembly

```x86asm
section .data
str:     db 'Hello world!', 0Ah
str_len: equ $ - str

section .text
global _start
_start:
  mov eax, 4
  mov ebx, 1
  mov ecx, str
  mov edx, str_len
  int 80h
  mov eax, 1
  mov ebx, 0
  int 80h
```

----

Big sequences of instructions.

* Like a "tape" of information.
* No functions, no data structures, nothing.
* Assembly language, Turing machines.

----

Let's add data structures.

----

COBOL

```js
IDENTIFICATION DIVISION.
PROGRAM-ID. HELLO.

DATA DIVISION.
   WORKING-STORAGE SECTION.
   01 WS-DESCRIPTION.
   05 WS-DATE1 VALUE '20140831'.
   10 WS-YEAR PIC X(4).
   10 WS-MONTH PIC X(2).
   10 WS-DATE PIC X(2).
   05 WS-DATE2 REDEFINES WS-DATE1 PIC 9(8).

PROCEDURE DIVISION.
   DISPLAY "WS-DATE1 : "WS-DATE1.
   DISPLAY "WS-DATE2 : "WS-DATE2.

STOP RUN.
```

----

Data structures.

* We had them in assembly, but they were ad hoc.
* Early FORTRAN, COBOL, etc.
* Sometimes called imperative programming.

----

Let's add functions.

----

FORTRAN

```fortran
SUBROUTINE SUB1(X,DUMSUB)
INTEGER N, X
EXTERNAL DUMSUB
COMMON /GLOBALS/ N
IF(X .LT. N)THEN
  X = X + 1
  PRINT *, 'x = ', X
  CALL DUMSUB(X,DUMSUB)
END IF
END
```

----

Functions.

* Subroutines, procedures, etc.
* ALGOL, later FORTRAN, etc.
* Sometimes called structured programming.

----

The key here is that we have two fundamental concepts:

* Data structures.
* Functions.

----

So let's combine them!

----

One way to think about Object-Oriented Programming:

* A single concept that combines a data structure with the functions that act on it.
* An _object_!

----

Java

```java
class Point2d {
  private double x;
  private double y;

  public double distance(Point2d pt) {
    double dx = x - pt.x;
    double dy = y - pt.y;
    return Math.sqrt((dx * dx) + (dy * dy));
  }
}
```

----

In this view of OOP, the data structure determines which function gets called.

This is sometimes called _dynamic dispatch_.

----

One way to think about Functional Programming:

* A function can act on any data structure that fits some _pattern_.
* Or even a set of patterns.

----

Haskell

```hs
data Point2 = Point2 Float Float

distance (Point2 x1 y1) (Point2 x2 y2) = 
  sqrt (dx * dx + dy * dy)
  where 
    dx = x1 - x2
    dy = y1 - y2
```

----

In this view of FP, the data structure determines which function gets called.

This is sometimes called _pattern matching_.

----

What about parallelism?

* <!-- .element: class="fragment"--> All of these examples treat a program as _sequential_.
* <!-- .element: class="fragment"--> But modern hardware is _parallel_.
* <!-- .element: class="fragment"--> A real program has data structures, functions, and _units of execution_.

----

Q: Wait, what? Why did you call it a _unit of execution_ instead of a _thread_?

<!-- .element: class="fragment"--> A: Because threads are just one expression of the idea of concurrent execution.

----

What if we could combine data structures, functions, and units of execution into a single concept?

----

That's an actor!

---

## Actors

----

An actor has:

* <!-- .element: class="fragment"--> State.
* <!-- .element: class="fragment"--> Behaviours.

<!-- .element: class="fragment"--> That's it!

----

Here's an actor in Pony, with some state and some behaviours.

```pony
actor PingPong
  var pings: U32 = 0 // 'var' is a variable
  var pongs: U32 = 0 // In a type, a 'var' is a field
  var partner: PingPong

  new create() => ... // Constructors have names

  new partner(that: PingPong) => ...

  be ping() => ... // 'be' is for 'behaviour'

  be pong() => ...
```

----

An actor can:

* <!-- .element: class="fragment"--> Send messages to itself or to other actors.
* <!-- .element: class="fragment"--> Create new actors.
* <!-- .element: class="fragment"--> Change its own state.

<!-- .element: class="fragment"--> That's it!

----

Let's play Ping Pong!

----

```pony
actor PingPong
  "We have state, which we can change."
  var pings: U32 = 0 // 'var' is a variable
  var pongs: U32 = 0 // In a type, a 'var' is a field
  var partner: PingPong
```

```pony
  new create() => // Constructors have names
    "A new PingPong, which creates its own partner."
    partner = PingPong.partner(this) // Create a new actor
    partner.ping() // Send a message

  new partner(that: PingPong) =>
    "A new PingPong, with a partner supplied."
    partner = that
```
<!-- .element: class="fragment"-->

```pony
  be ping() => // 'be' is for 'behaviour'
    "A behaviour: we've received a ping."
    pings = pings + 1 // Chang our state
    partner.pong() // Send a message
```
<!-- .element: class="fragment"-->

```pony
  be pong() =>
    "A behaviour: we've received a pong."
    pongs = pongs + 1 // Change our state
```
<!-- .element: class="fragment"-->

----

What's a message?

<!-- .element: class="fragment"--> A message is a uni-directional asynchronous method call.

----

No, seriously, what's a message?

* <!-- .element: class="fragment"--> Sending a message to an actor is like making a method call on an object.
* <!-- .element: class="fragment"--> But it doesn't return a value to the caller (i.e. it's uni-directional).
* <!-- .element: class="fragment"--> And the actor only promises to eventually respond to the message (i.e. it's  asynchronous).
* <!-- .element: class="fragment"--> So a message is "fire and forget": when you send a message, you know something will happen... later.

----

Sending a message is as simple as calling a method.

```pony
actor PingPong
  ...

  be ping() =>
    "A behaviour: we've received a ping."
    pings = pings + 1
    partner.pong() // <-- Here it is!
```

<!-- .element: class="fragment"--> Here, the name of the message is `pong` and it has no arguments. Notice that it can't return a value (unidirectional), and that the `partner` won't necessarily respond to the message immediately (asynchronous).

----

How do actors respond to messages?

* <!-- .element: class="fragment"--> One actor handles one message at a time.
* <!-- .element: class="fragment"--> But many actors can be handling messages simultaneously.
* <!-- .element: class="fragment"--> So actors are individually _sequential_...
* <!-- .element: class="fragment"--> ...but collectively _parallel._

----

Responding to a message is as simple as writing a method body.

```pony
actor PingPong
  ...

  be pong() =>
    "A behaviour: we've received a pong."
    pongs = pongs + 1 // We change our state!
```

<!-- .element: class="fragment"--> Here, we respond to a `pong` message by incrementing our `pongs` count. We won't handle any other message until we've finished handling this one.

----

Actors are a paradigm.

* <!-- .element: class="fragment"--> You can write actors in nearly any language.
* <!-- .element: class="fragment"--> Some languages have actors as a _first class_ concept.
* <!-- .element: class="fragment"--> This includes Erlang, Elixir, Scala/Akka, and JavaScript.
* <!-- .element: class="fragment"--> Yes, JavaScript! More on that later.

----

We're going to use Pony.

* <!-- .element: class="fragment"--> Pony has first class actors.
* <!-- .element: class="fragment"--> Pony is fast: comparable to C/C++.
* <!-- .element: class="fragment"--> Pony is safe: type safe, memory safe, data-race safe.
* <!-- .element: class="fragment"--> Pony is ours: the result of Imperial College research.

----

Pony is open source: get involved!

http://ponylang.org

----

Code along in your browser!

http://sandbox.ponylang.org

---

## Why would I want an actor?

----

Actors make concurrency easy.

<!-- .element: class="fragment"--> You don't want _one_, you want _lots_.

<!-- .element: class="fragment"--> And that's ok, because unlike threads, actors are cheap.

----

How cheap are actors (in Pony)?

* <!-- .element: class="fragment"--> An actor has a memory overhead of 240 bytes.
* <!-- .element: class="fragment"--> And no time overhead: if it isn't doing useful work, it takes no CPU time.
* <!-- .element: class="fragment"--> Compare that to a thread: typically 8 megabytes or so of memory, plus context switching overhead.
* <!-- .element: class="fragment"--> So you can use lots of actors.

----

Use actors to express things that must be done in sequence.

<!-- .element: class="fragment"--> Send messages to trigger those sequences.

<!-- .element: class="fragment"--> Now you have a massively parallel program.

----

How cheap are messages (in Pony)?

* <!-- .element: class="fragment"--> A single atomic operation to send.
* <!-- .element: class="fragment"--> Zero atomic operations to receive.
* <!-- .element: class="fragment"--> With no loops in either case.
* <!-- .element: class="fragment"--> That's really cheap.
* <!-- .element: class="fragment"--> So you can send lots of messages.

----

Actors are like small independent programs.

<!-- .element: class="fragment"--> Each actor keeps track of only what it has to.

<!-- .element: class="fragment"--> And responds to events as they are notified of them.

<!-- .element: class="fragment"--> This is sometimes called _communicating event loops_.

----

Actors are composable, like objects and functions.

* <!-- .element: class="fragment"--> When you add threads to a program, you can easily accidentally change existing behaviour.
* <!-- .element: class="fragment"--> When you add actors to a program, you know you are extending behaviour only.
* <!-- .element: class="fragment"--> Actors give you composable concurrency.

---

## An Example: Adventure!

----

Adventure games often have a `World`.

* <!-- .element: class="fragment"--> The `World` keeps track of all the people, places, and things.
* <!-- .element: class="fragment"--> Taking advantage of parallel computing requires _synchronised_ access to the `World`.
* <!-- .element: class="fragment"--> Synchronisation introduces fun things like lock-contention and deadlock.
* <!-- .element: class="fragment"--> Those things are not fun.

----

Let's use actors to make an adventure game with no centralised `World`.

* <!-- .element: class="fragment"--> What needs to be done sequentially?
* <!-- .element: class="fragment"--> A `World` typically tracks people, places, and things.
* <!-- .element: class="fragment"--> Could all of those be actors?

----

A person has a name. Let's start there.

```pony
actor Person
  let _name: String // We have fields, just like a class does.

  new create(name: String) => // Constructors are named.
    _name = name // All our fields have to be initialised.
```

----

A person is also _somewhere_. 

Let's keep track of where we are.

```pony
actor Person
  let _name: String // We have fields, just like a class does.
  let _place: Place // A lead _ means a private field or method.

  new create(name: String, place: Place) => // Constructors are named.
    _name = name // All our fields have to be initialised.
    _place = place
```

----

Let's define a place now.

```pony
actor Place
  let _name: String // A place has a name.
  let _people: SetIs[Person] // And a set of persons.

  new create(name: String) =>
    _name = name
    _people = SetIs[Person] // We start with nobody here.
```

----

Let's add a behaviour: moving a `Person` to a new `Place`.

----

We'll add this to `Place`:

```pony
actor Place
  ...

  be depart(who: Person) => // A behaviour - async!
    _people.unset(who) // Add to the set of present persons.
    for person in _people.values() do person.departed(who, this) end

  be arrive(who: Person) => // Another behaviour.
    _people.set(who) // Remove from the set.
    for person in _people.values() do person.arrived(who, this) end
```

----

We'll add this to `Person`:

```pony
actor Person
  ...

  be move(to: Place) =>
    _place.depart(this) // Send a depart message to our old place.
    to.arrive(this) // Send an arrive message to our new place.
    _place = to // Keep track of where we are.
```

----

Is that safe?

```pony
actor Person
  ...

  be move(to: Place) =>
    _place.depart(this) // Send a depart message to our old place.
    to.arrive(this) // Send an arrive message to our new place.
    _place = to // Keep track of where we are.
```

* <!-- .element: class="fragment"--> What if `move` is called while `move` is executing?
* <!-- .element: class="fragment"--> If Alice is told to move to the cinema and to the pub at the same time, could she depart her current `_place` twice?
* <!-- .element: class="fragment"--> Could Alice send arrive messages to both places, and randomly store one of them as her current `_place`?

----

It's safe!

* <!-- .element: class="fragment"--> Behaviours are _atomic_: they are uninterrupted and data doesn't change out from under them. 
* <!-- .element: class="fragment"--> We know Alice will `move` all in one step.
* <!-- .element: class="fragment"--> If she's told to move to the cinema and the pub at the same time, she'll do that...
* <!-- .element: class="fragment"--> ...in the order that the messages arrive.

----

Is that consistent?

```pony
actor Person
  ...

  be move(to: Place) =>
    _place.depart(this) // Send a depart message to our old place.
    to.arrive(this) // Send an arrive message to our new place.
    _place = to // Keep track of where we are.
```

* <!-- .element: class="fragment"--> If Alice leaves the cinema and goes to the pub, can someone see her in the pub and the cinema at the same time?
* <!-- .element: class="fragment"--> If Bob sees Alice leave the cinema and follows her to the pub, will she already be at the pub?

----

Message ordering #1: seems to work

```seq
participant Alice
participant Cinema
participant Pub
participant Bob
Alice->Cinema: depart(alice)
Note over Cinema: depart(alice)
Cinema->Bob: departed(alice)
Note over Bob: departed(alice)
Alice->Pub: arrive(alice)
Note over Pub: arrive(alice)
Pub->Bob: arrived(alice)
Note over Bob: arrived(alice)
```

----

Message ordering #2: Heisen-Alice

```seq
participant Alice
participant Cinema
participant Pub
participant Bob
Alice->Cinema: depart(alice)
Alice->Pub: arrive(alice)
Note over Pub: arrive(alice)
Pub->Bob: arrived(alice)
Note over Bob: arrived(alice)
Note right of Bob: Bob sees Alice in two places!
Note over Cinema: depart(alice)
Cinema->Bob: departed(alice)
Note over Bob: departed(alice)
```

----

What's our message order guarantee?

* <!-- .element: class="fragment"--> Messages are _causally ordered_.
* <!-- .element: class="fragment"--> Every message an actor has ever received or sent is a _cause_ of any messages it sends.
* <!-- .element: class="fragment"--> A message will always arrive _after_ any of its causes that are sent to the same destination.

----

What are the causes now?

* <!-- .element: class="fragment"--> Arriving is a cause of of departing.
* <!-- .element: class="fragment"--> Arriving is a cause of arrival notifications.
* <!-- .element: class="fragment"--> Departing is a cause of departure notifications.
* <!-- .element: class="fragment"--> Since causality is transitive, arriving is a cause of departure notifications.
* <!-- .element: class="fragment"--> But arrival notifications are not a cause of departure notifications!

----

Let's use causality to make it consistent.

```pony
actor Person
  ...
  be move(to: Place) =>
    _place.depart(this, to) // Depart takes an extra argument.
    _place = to // We don't send an arrive message!

actor Place
  ...
  be depart(who: Person, to: Place) => // Depart has an extra parameter.
    _people.unset(who)
    for person in _people.values() do person.departed(who, this) end
    to.arrive(who) // The place we're departing sends the arrive message!
```

<!-- .element: class="fragment"--> Now, departure notifications are a cause of arriving, so departure notifications are also a cause of arrival notifications.

----

Message ordering #3: causal order

```seq
participant Alice
participant Cinema
participant Pub
participant Bob
Alice->Cinema: depart(alice, pub)
Note over Cinema: depart(alice, pub)
Cinema->Bob: departed(alice, cinema)
Cinema->Pub: arrive(alice)
Note over Pub: arrive(alice)
Pub->Bob: arrived(alice, cinema)
Note over Bob: departed(alice, pub)
Note over Bob: arrived(alice, cinema)
```

----

It's consistent!

* <!-- .element: class="fragment"--> Bob will always be notified of Alice's departure before her arrival: no more Heisen-Alice.
* <!-- .element: class="fragment"--> When Bob follows Alice to the pub, she will already be there.
* <!-- .element: class="fragment"--> Causal messaging has no runtime cost, so we can make these guarantees for free.

---

## Objects in an Actor-Model System

----

What can a message contain?

* <!-- .element: class="fragment"--> References to actors.
* <!-- .element: class="fragment"--> References to data structures.

<!-- .element: class="fragment"--> That's it!

----

Is it safe to send actors in messages?

<!-- .element: class="fragment"--> Yes!

<!-- .element: class="fragment"-->We've already seen that with Alice, Bob, the pub and the cinema.

----

Is it safe to send data structures in messages?

* <!-- .element: class="fragment"--> What if two actors try to write to the data structure at the same time?
* <!-- .element: class="fragment"--> We could end up with some writes from each actor, resulting in inconsistent state.
* <!-- .element: class="fragment"--> This is sometimes called a _data race_.
* <!-- .element: class="fragment"--> It's definitely not safe.

----

Example: data race

```pony
class Data
  var x: U32 = 0
  var y: U32 = 0
```

Let's say Alice does this:

```pony
let x' = data.x
data.y = 1
```

And Bob does this:

```pony
let y' = data.y
data.x = 2
```

<!-- .element: class="fragment"--> Can `x' == 2` and `y' == 1` ?

----

Data race ordering #1: sequential, seems to work

```pony
class Data
  var x: U32 = 0
  var y: U32 = 0
```

```seq
Alice->Data: let x' = data.x
Note over Alice: x' == 0
Alice->Data: data.y = 1
Bob->Data: let y' = data.y
Note over Bob: y' == 1
Bob->Data: data.x = 2
```

----

Data race ordering #2: interleaved, might be broken

```pony
class Data
  var x: U32 = 0
  var y: U32 = 0
```

```seq
Alice->Data: let x' = data.x
Note over Alice: x' == 0
Bob->Data: let y' = data.y
Note over Bob: y' == 0
Alice->Data: data.y = 1
Bob->Data: data.x = 2
```

----

Data race ordering #3: wait, what?!

```pony
class Data
  var x: U32 = 0
  var y: U32 = 0
```

```seq
Alice->Data: data.y = 1
Bob->Data: let y' = data.y
Note over Bob: y' == 1
Bob->Data: data.x = 2
Alice->Data: let x' = data.x
Note over Alice: x' == 2
```

<!-- .element: class="fragment"--> This can really happen.

----

Data races can be surprising.

<!-- .element: class="fragment"--> They cause a lot of hard-to-find bugs.

----

Can we make it safe to send data structures in messages?

----

We could copy the data structure when we send it.

* <!-- .element: class="fragment"--> Copying is expensive, in both time and memory.
* <!-- .element: class="fragment"--> A copy doesn't have the same _identity_ as the original data structure.
* <!-- .element: class="fragment"--> Some actor-model languages do this, but Pony doesn't.

----

We could send _immutable_ data structures.

* <!-- .element: class="fragment"--> Actors can read from, but not write to, the data structure.
* <!-- .element: class="fragment"--> Is it safe for two actors to read from the data structure at the same time?
* <!-- .element: class="fragment"--> Yes! The data structure stays consistent, so it's safe.

----

Example: immutable data

```pony
actor Place
  ...

  be speak(words: List[String] val) => // val means immutable
    for person in _people.values() do
      person.hear(words)
    end
```

* <!-- .element: class="fragment"--> When we speak, we can send the same list of words to everyone in a place.
* <!-- .element: class="fragment"--> Everyone hears the same words, and nobody can modify them.

----

We could send _isolated, mutable_ data structures.

* <!-- .element: class="fragment"--> Only one actor at a time can have a reference to an isolated data structure.
* <!-- .element: class="fragment"--> Is it safe for the actor with the reference to read from and write to the data structures?
* <!-- .element: class="fragment"--> Yes! There's no interference from other actors, so it's safe.

----

Example: isolated data

```pony
trait Thing
  ...

actor Person
  ...
  var stuff: SetIs[Thing iso] // iso means isolated

  ...
  be take(thing: Thing iso) => stuff.set(consume thing)
```

* <!-- .element: class="fragment"--> We represent our stuff with a set of isolated `Thing`s.
* <!-- .element: class="fragment"--> When we're told to take something, we put it in our set.
* <!-- .element: class="fragment"--> We use `consume` to destroy the old _alias_, so we can be sure it doesn't get used more than once.

----

Example: modifying isolated data

```pony
class Notebook is Thing
  var _notes: List[String val] // val means immutable

  ...
  fun ref write(words: String val) => _notes.push(words)

actor Person
  ...

  be sign_and_return(book: Notebook iso, to: Person) =>
    book.write(_name) // The book stays isolated
    to.take(consume book)
```

* <!-- .element: class="fragment"--> When we're told to sign a notebook and return it, we add our name to it, and then give it away.
* <!-- .element: class="fragment"--> The book stays isolated because we put something _immutable_ into it.

----

Use isolation for _ownership_.

<!-- .element: class="fragment"--> Use immutability for _sharing_.

---

## Next time...

<!-- .element: class="fragment"--> JavaScript as an actor-model language!

<!-- .element: class="fragment"--> Type systems for correctness and performance!

<!-- .element: class="fragment"--> No more null pointers or unchecked exceptions!

<!-- .element: class="fragment"--> http://ponylang.org

---

## Actor-Model Variations

----

Pure actors

* Messages are guaranteed to be delivered, but in no particular order.
* When a message arrives, the actor executes its _next behaviour_.
* It acts on the data in the message, plus any data encoded in the behaviour (perhaps static data, perhaps as a closure).
* It then specifies the _next behaviour_, which will be executed when the next message arrives.

----

Pure actors can be an uncomfortable programming paradigm.

* Unordered messaging is tricky for the programmer.
* Deciding the next behaviour is non-trivial, and tends to result in actors with a single behaviour that pattern matches on the message contents as a form of dispatching.
* A pattern matching behaviour sounds a lot like FP!

----

Actors as functions: Erlang, Elixir

* Messages are guaranteed to be delivered.
* Messages will be _enqueued_ in order when sending to a single actor on the same node.
* The actor is a single function that must choose when to wait for a message.
* Messages might be _handled_ in any order: the actor can wait for a particular kind of message (that is, the actor can _pattern match on its message queue_).
* All data is immutable, so no race conditions.
* Actors are not garbage collected, and can crash, so actor references can be invalid.

----

Erlang

```erl
pingpong(Pings, Pongs) ->
  receive % We are looking for a message.
    {ping, That} ->
      % This is our ping behaviour.
      That ! pong, % Sending a message.
      pingpong(Pings + 1, Pongs); % Changing state.
    pong ->
      % This is our pong behaviour.
      pingpong(Pings, Pongs + 1); % Changing state.
    exit ->
      % Erlang actors must be manually terminated.
      ok
  end.
```

----

Actors as objects: Scala, Akka

* Messages are guaranteed to be delivered, but in no particular order.
* The actor is an object, with state.
* It has a special `receive` method that pattern matches on messages.
* Different from Erlang: the actor pattern matches on a single message, _not its message queue_.
* Mutable data types result in race conditions.
* Actors are not garbage collected, and can crash, so actor references can be invalid.

----

Akka

```scala
class PingPong() extends Actor {
  var pings = 0 // State.
  var pongs = 0

  def receive = {
    case PingMessage(that) => // This is our ping behaviour.
      pings += 1 // Changing state.
      that ! PongMessage(this) // Sending a message.
    case PongMessage(that) => // This is our pong behaviour.
      pongs += 1 // Changing state.
    case StopMessage => // Akka actors must be manually terminated.
      context.stop(self)
  }
}
```

----

Actors as objects: Pony

* Messages are guaranteed to be delivered in causal order.
* The actor is an object, with state.
* Behaviours are written like methods, and are statically type safe.
* Reference capability type system allows mutable data with no race conditions.
* Actors are garbage collected, and don't crash, so actor references are never invalid.

----

Pony

```pony
actor PingPong
  var pings: U32 = 0 // State.
  var pongs: U32 = 0

  be ping(that: PingPong) => // Our ping behaviour.
    pings = pings + 1 // Changing state.
    that.pong(this) // Sending a message.

  be pong(that: PingPong) => // Our pong behaviour.
    pongs = pongs + 1 // Changing state.
```

----

Actors as object: JavaScript

* Seriously! A JavaScript program responds to events (behaviour) in sequence.
* Typically, there is only one actor, but with WebWorkers, you can have more!
* Messages are copied, so there are no data races.
* Actors are not garbage collected, and can terminate, so actor references can be invalid.

----

JavaScript

```js
var pings = 0
var pongs = 0

onmessage = function(e) {
  if(e.type == "ping") { // Our ping behaviour.
    pings += 1 // Changing state.
    e.sender.postMessage({type: "pong", sender: this})
  } else if(e.type == "pong") { // Our pong behaviour.
    pongs += 1 // Changing state.
  }
}
```
