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

