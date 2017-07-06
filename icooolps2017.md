### We Software People are not Worthy

### _All Hail the Hardware Gods_

Sylvan Clebsch

Microsoft Research

June 19th, 2017

-----

Presenting at ICOOOLPS 2017, Barcelona

<!--
Hardware has advanced leaps and bounds in the last 10 years, but software, and in particular programming languages, are failing to take advantage of this while also holding back the hardware itself. We continue to impose old abstractions on the programming model, such as coherent shared memory, we teach CS students that hash tables have O(1) search, our compilers regularly emit code with suboptimal instruction memory dependence, our memory allocators produce fragmented and unpredictable memory access, and we lean on branch prediction and hardware prefetching to solve our problems. We don't even use formal verification as much as hardware does. As we move from concurrent computing problems we haven't solved to distributed computing problems we haven't imagined, how can we do better? I'll talk about some of the ways Pony has tried to approach these problems and some of the ways it has failed to do so, I'll ask why we aren't all using FORTH, and ask the workshop the big question: are we getting it wrong, or is the hardware not solving the big problems?
-->

---

### What hardware are we talking about?

Multicore CPUs

Coprocessor packages (Phi, Single-Chip Cloud)

FPGAs

GPUs / GPGPUs

----

### What's the point?

* Software asks hardware to emulate an outdated execution model
  * Sequential execution
  * Coherent shared memory
* This makes hardware slower and less innovative
  * And yet hardware gets faster
  * And it gets "more correct"
* What could hardware do if we weren't holding it back?

---

### Instructions are not a Turing Tape

Non-sequentiality comes in many forms:

* Instruction pipelining
* Vector processing
* Parallel processors

----

### Coping with Instruction Parallelism

Compilers are getting better at vectorisation and pipelining

* But it's generally a black box: the programmer gets little to no feedback
* Compilation strategies differ by target: can languages offer mechanisms to specify the intended result? _Pony doesn't!_
* Real-world instructions per cycle tend to be much lower than ideal

----

### Coping with Instruction Parallelism II: The Instructioning

Have sequential languages resulted in an inexpressive instruction set?

* Should languages be able to express pipelined computation syntactically?
* What about branch prediction? Is it feasible to express non-dependent computation shared between branches?
* What about HT/SMT? Are there better ways to hide memory latency? Can language-level memory dependency information improve scheduling?

----

### Coping with Processor Parallelism

There's no such thing: it's a distributed system

* The hardware gods jump through rings of fire to let us pretend we still have simple shared memory architecture
* But under the hood, it's message passing
* Large amounts of transistor budget goes into maintaining the illusion

Why can't we solve this in software?

----

### Coping with Processor Parallelism II: The Paralleling

* Efficient actor-model runtimes can treat parallelism like a distributed system. _Pony tries to do this!_
* (Or CSP, of course)
* That's good, but not good enough to hand back all that transistor budget

For example, can we eliminate the need for cache coherent hardware?

----

### Coping with Co-processors: FPGA, GPU, Phi, etc.

There's no such thing: it's a distributed system

* I should have reused the other slide entirely
* The costs are more obvious with co-processors
* But even here, the hardware gods are trying to rescue us with things like heterogeneous memory management

----

### Coping with Heterogeneous Computation

We tend to write multi-language programs for GPU and FPGA: C++ with OpenCL, for example

* They don't type check together or optimise together
* Here come the hardware gods: ARM `big.LITTLE` gives us heterogeneous hardware that can cope with our homogenous languages and runtimes

----

### Coping with Heterogeneous Computation II: The Distributing

Distributed systems are also often written as a collection of programs that don't type check together or optimise together

* Datacenter computing can't emulate sequential instructions and coherent shared memory
* Are distributed operating systems hard because we lack distributed languages to express them in?

---

### Memory is not a Turing Tape

Non-uniform memory

Cache effects

Cache coherency

Prefetching

----

### It's All a Lie

Memory is message passing

* It's another distributed system
* It's non-programmable
* It tries to guess what we want
* We try to guess what it wants

----

### Too Much Guessing

While the memory system tries to guess what our program wants, our program tries to guess what the memory system wants by trying to optimise for expected behaviour

* With no explicit interface, new CPUs can invalidate program assumptions
* For example: x86-64 adjacent cache line prefetch

----

### No Cache Control

Processors expose little (ARM) to no (Intel) cache interface (modulo non-temporal writes)

* Domain knowledge in the program (whether static or dynamic) cannot be used to optimise cache behaviour
* NUMA exposes more control: by moving the code to the data rather than the data to the code, we (sometimes) make big gains
* Fine grained non-processor cache control is critical to databases and many web applications

Why is processor cache a black box?

----

### Memory Models

The coherent shared memory illusion is brittle

* The C11 memory model is a huge improvement, expressing more precise behaviour
* But that behaviour remains emulated: the memory model is an API to a message passing system
* For example, a relaxed atomic exchange: what kind of messages does it generate?

----

### Memory Layout

Fine control over program memory layout can give huge performance benefits

* Leverage hardware prefetching and indirect branch prediction
* Express arrays of structs as structs of arrays
* Use allocation locality to express temporal locality: adjacent addresses are likely to be read in sequence

----

### Memory Layout vs. Code

If we could exploit domain knowledge in the program with processor instructions to guide prefetching, could we have more flexible memory layouts with the same performance?

_Is this like a database query plan?_

----

### Algorithms

Cache effects can dominate algorithm performance

* This is true for everything from L1D to network to disk
* For example, linear vs. quadratic hash table probing: careful benchmarking is needed to find the best performance for a specific use case

Could domain knowledge improve cache behaviour?

---

### Communication as well as Computation

RDMA over Ethernet

Infiniband

iWARP

100 GbE

Optical interconnect

----

### Less of a Black Box

Distributed hardware doesn't provide a shared memory abstraction

* MPI Remote Memory Access tries to provide one
* Some PGAS languages do the same
* Two-sided RDMA for message passing can outperform a memory abstraction: FaSST

We have a chance to make languages suit the hardware before the hardware gods try to suit existing languages

----

### Is this our way out?

First class language support for distribution

* Can we stop RDMA from becoming a hardware shared memory abstraction?
* Can we convince the hardware gods we know what we're doing?

_We're gonna have to prove it_

---

### Seriously: We're Gonna Have To Prove It

Formal verification for hardware is more advanced than for software

* Alastair Reid: End-to-End Verification of ARM Processors with ISA-Formal
* Intel investment following the FDIV bug
* Still much to do, particularly regarding memory models

_What can we remove from programming languages to make proofs easier?_

----

### Hardware Isolation for Software

We use hardware to isolate software faults

* Per-process virtual address spaces
* Hardware assisted OS virtualisation

Why? And at what cost?

----

### Hardware Security Features

OSes themselves are faulty software in need of isolation

* TPM
* SGX
* CHERI instruction set

----

### Example Hidden Costs: Context Switching

We rely on hardware enforced virtual address spaces to compensate for lack of software memory safety

If a cache maps over virtual addresses, it must be entirely invalidated on a virtual address space change

----

### Shared Address Spaces

What non-interference properties are necessary to avoid this?

* Memory safety, including no synthetic pointers
* Data-race freedom
* Static typing? Not needed: can be done dynamically

----

### Single Address Space Operating Systems

What properties other than non-interference are needed?

* Capabilities-security: strongly contained faults across processes
* Checkable capabilities policies: the equivalent of formal verification for capabilities

---

### Why aren't we using FORTH?

FORTH gives fine control over a stack machine

* No assumed shared memory model
* But threaded code doesn't seem to work well with modern processors
* No low level memory safety

----

### Circling Back Around

How can we leverage modern and future hardware?

How can we convince the hardware gods we can produce programming models that don't need to be lied to?

Are distributed systems a way in?

----

### Key Takeaways

Please don't tell anyone hash table lookup is O(1)

_Thanks for listening!_
