### Pony: 714 Days Later

Sylvan Clebsch

Microsoft Research

June 20th, 2017

-----

Presenting at CurryOn 2017, Barcelona

---

### What is Pony?

An actor-model capabilities-secure general-purpose native language

```pony
actor Main
  new create(env: Env) =>
    env.out.print("La meva cullera és massa gran!")
```

----

<img src="img/ponylang.png" width=600 style="background-color:white;"/>

----

### Goals

Statically data-race free, with mutability

No-stop-the-world garbage collection

Formally specified

Single node performance competitive with C/C++

Eventually: Distributed computing

----

### Some good domains for Pony

Financial systems

Video games

Stream processing

Machine learning

Low-power devices (speed is energy efficiency)

Operating systems

----

### There's a lot in Pony

Today will be a short overview of just a few things: data-race freedom, native code optimisation, workstealing and message queues, and efficient no-stop-the-world GC.

Some of the things that won't get mentioned: generics, intersection types, nominal and structural subtyping, pattern matching, distributed semantics, capabilities security

----

### STOP!

Are you interested in one of the things I just said won't get mentioned?

Speak up, and I can change what I cover!

---

### Data-race freedom

> "If I can write to it, nobody else can read from it"

Corollary:

> "If I can read from it, nobody else can write to it"

----

### Existing data-race freedom work

Gordon, Parkinson, Parsons, Bromfield, Duffy: _Uniqueness and reference immutability for safe parallelism_

Östlund, Wrigstad, Clarke, Åkerblom: _Ownership, uniqueness, and immutability_

Haller, Odersky: _Capabilities for uniqueness and borrowing_

Srinivasan, Mycroft: _Kilim: Isolation-typed actors for java_

Wadler: _Linear types can change the world_

Rust: mixed static/dynamic data race freedom

----

### Deny rather than allow

Pony's _reference capabilities_ (rcaps) express what other aliases cannot exist, both locally and globally

Alias denial appears to be more fundamental than permissions

----

### Deny matrix

| Deny global | aliases | |
-----------------------|--------------|-------------|-----
__Deny local aliases__ | _Read/Write_ | _Write_     | _None_
_Read/Write_           | __*iso*__    |             |
_Write_                | __trn__      | __*val*__   |
_None_                 | __ref__      | __box__     | __*tag*__
                       | _mutable_    | _immutable_ | _opaque_

----

### Rcap compatibility

Adrian Colyer's chart from The Morning Paper

![Deny Capabilities](img/pony-deny-capabilities.png)

---

### Native Code Optimisation

Pony is a GC'd language, but not an interpreted or JIT'd language

LLVM back end, will be moving to the LLVM linker as well

----

### Leveraging Back End Optimisations

Pony programs are compiled as a single LLVM module, allowing whole-program optimisation

To generate the correct generic types and generic methods, the compiler does whole-program reachability analysis

There is no function level ABI, allowing aggressive register colouring and heap-to-stack allocation optimisation

There is community work in progress on combining this with separate compilation

----

### Reachability and Reification

Generic types and methods are fully reified, like C++ templates

LLVM function merging is used to recover code reuse where possible

Binary sizes remain relatively small: 64 bit HTTP server in 312 KB

----

### Selector Colouring

Nominal and structural typing are efficiently supported using selector colouring

Method vtable indices are constant across types: structural types have no overhead

May move to perfect hashing for method dispatch to allow for REPLs and loadable code

---

### Workstealing

Scheduler threads are pinned to cores

A scheduler thread has a queue of actors, and each actor has a queue of messages

While a scheduler thread is executing an actor behaviour, the actor uses that scheduler thread's stack: this allows for zero cost C ABI FFI

----

### Scheduling Actors

When an actor is sent a message it is either on zero or one scheduler queues

If the actor's message queue was empty when the message was sent, it needs to be scheduled: place it on the sending actor's scheduler queue, as the message is more likely to be in cache than the receiving actor

Otherwise, leave the receiving actor on its current queue: the receiver's working set may be in cache there, and we don't want to disturb it

----

### Scheduler Queues

Zero atomic operations to enqueue

CAS loop to dequeue: SPMC queue to allow for workstealing

---

### Fast Zero-Copy Message Passing

Reference capabilities allow passing and sharing pointers without copying

One atomic exchange (no loops) to enqueue

Zero atomic operations to dequeue

----

### Enqueue

```c
bool ponyint_messageq_push(messageq_t* q, pony_msg_t* m)
{
  atomic_store_explicit(&m->next, NULL, memory_order_relaxed);

  pony_msg_t* prev = atomic_exchange_explicit(&q->head, m,
    memory_order_relaxed);

  bool was_empty = ((uintptr_t)prev & 1) != 0;
  prev = (pony_msg_t*)((uintptr_t)prev & ~(uintptr_t)1);

#ifdef USE_VALGRIND
  ANNOTATE_HAPPENS_BEFORE(&prev->next);
#endif
  atomic_store_explicit(&prev->next, m, memory_order_release);

  return was_empty;
}
```

----

### Dequeue

```c
pony_msg_t* ponyint_messageq_pop(messageq_t* q)
{
  pony_msg_t* tail = q->tail;
  pony_msg_t* next = atomic_load_explicit(&tail->next, memory_order_relaxed);

  if(next != NULL)
  {
    q->tail = next;
    atomic_thread_fence(memory_order_acquire);
#ifdef USE_VALGRIND
    ANNOTATE_HAPPENS_AFTER(&tail->next);
    ANNOTATE_HAPPENS_BEFORE_FORGET_ALL(tail);
#endif
    ponyint_pool_free(tail->index, tail);
  }

  return next;
}
```

---

### Garbage collection

How can we leverage the actor-model and data-race freedom to build a highly efficient, no-stop-the-world GC?

----

### Per-actor heaps

Start with a separate heap per actor, like Erlang

Use a mark-and-don't-sweep, non-generational, non-copying collector

No read or write barriers, no card table marking, no pointer fixups

Don't touch unreachable memory, avoiding cache pollution

Handle fragmentation with a size-classed pooled memory allocator

----

### Sharing references across actors

Data-race freedom allows zero-copy messaging

How do we prevent premature collection of objects sent to other actors?

With no synchronisation, including no round-trip message passing?

---

### ORCA: fully concurrent object GC for actors

A variant of deferred distributed weighted reference counting

Ref counts do not depend on the shape of the heap, only on how many times an object has been sent or received by an actor

----

### How it works

1. When an actor sends a reference to an object in a message, it increments its own reference count for that object
2. When an actor receives a reference to an object in a message, it decrements its own reference count for that object
3. Increments and decrements are reversed if the object was not allocated on the actor's heap

----

### ORCA messages: inventing and discarding reference counts

When an actor does local GC and discovers it can no longer reach an object allocated on another actor's heap, the GC'ing actor sends a decrement message to the object's allocating actor

When an actor wants to send a reference to an object allocated on another actor's heap but has only 1 RC for that object, it sends an increment message to the object's allocating actor

No confirmation or round-trip is required for either operation

---

### The Pony Community

Two sub-communities: industry and academia.

Rather than being separate, they interact and encourage each other.

----

### Some Pony Work from Industry

* Type-based function and expression specialisation: `iftype`
* `Itertools` for lazy FP over mutable and immutable collections
* Type-based alias analysis
* Exhaustive pattern match detection
* Network back-pressure handling
* Custom (de)serialisation
* The beginnings of a self-hosted compiler
* JIT for compiler test cases (and later for more?)
* Cross-platform build system and installer work
* Package management
* Alternate arithmetic operators that allow undefined results
* Smalltalk-style cascading operator
* Lots of standard library work, documentation, and bug fixes

----

### Some Pony Work from Academia

* Continued formalisation work in cooperation with Sophia Drossopoulou, Imperial College London
* Formalise ORCA protocol for collecting passive objects shared across heaps (Juliana Franco, ICL)
* Formalise rcap interaction with algebraic and types (George Steed, ICL)
* Value-dependent types and compile-time expressions (Luke Cheeseman, ICL)
* Formal model of generics including a Coq proof (Paul Liétar, ICL)
* Persistent collections (Theo Butler, Drexel University)
* Working with the Encore team, another concurrent language built on the Pony runtime

---

### Come get involved!

Join our community of students, hobbyists, industry developers, tooling developers, library writers, compiler hackers, and type system theorists.

------

@ponylang

Freenode: #ponylang

http://ponylang.org
