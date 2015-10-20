"""
Concepts:

* Main actor.
* Capability recovery.
"""

actor Main
  new create(env: Env) =>
    """
    Here's a program that creates one Person.
    Then we hand her a cinema ticket.
    We use `recover` to create an _isolated_ ticket.
    """
    let alice = Person("Alice")
    let ticket = recover CinemaTicket("Minions") end
    alice.take(consume ticket)
    // alice.take(ticket)
    // alice.take(CinemaTicket("Minions"))
