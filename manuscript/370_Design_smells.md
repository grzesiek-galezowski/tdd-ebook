# Design smells visible in the Specification

In earlier chapters, I stressed multiple times how mock objects can and should be used as design tools, helping flesh out the protocols between collaborating objects. There is a principle beneath that that I call *Test-design approach mismatch*. And it goes like this:

"Test automation approach and design approach need to live in symbiosis, i.e. build on a similar sets of assumptions. If they do, they reinforce each other. If they don't, they cause friction."

I find this to be universally true. For example, if I test an asynchronous application as if I was testing a synchronous application or if I try to test JSON web API using a clicking tool, my code will either not work correctly or look weird. I will probably need to put extra work to compensate for the mismatch in paradigms between my testing approach and my design approach. For this reason some who prefer much different design approaches [consider mock objects a smell](https://medium.com/javascript-scene/mocking-is-a-code-smell-944a70c90a6a).

I am seeing it on the unit level as well. In this book, I am using the specification terminology instead of testing terminology. Thus I can say that by writing my Specification on unit level and using mock objects in my Statements, I am assuming the design has certain properties. If it doesn't , I will have a harder time reading the Specification and maintaining it.

TODO write something more

Sometimes, when writing the Specification, certain code patterns occur that make the individual Statements hard to write, read or maintain. This may mean that the Specification code should be improved, maybe by extracting the common part into a method, or maybe by using a testing tool's feature. Before I reach that conclusion, however, I try to XXXXXXXXXXXXXXXXX


## Design smells' catalog

### Specifying the same behavior in many places

Sometimes, when I write a Statement, I have a deja vu and start thinking "I remember specifying a behavior like this already". I will feel this especially when that other time is not so long ago, maybe even a couple of minutes.

TODO: an example where I have two implementations of the same interfaces and they contain partially the same behavior (e.g. one method needs to be implemented in each and the implementation is the same).

I then find my motivation to specify the same behavior for the second or third time dropping. This may be a signal that maybe I should extract the common behavior to a separate role or maybe introduce a value object and use it in both the Statement and the implementation.

One way or another, it's a sign of redundancy creeping in.

#### When this is not a problem

TODO: decoupling of different contexts, no real redundancy
TODO: Not a real redundancy

### Many mocks

Sometimes, when writing a Statement I find myself creating many mock objects. I don't think there's a good specific number, but the situation I'm looking for is when a fatigue sets in: "oh, ANOTHER mock..?".

Having many mocks can be a result of multiple design issues:

#### Too fine-grained role separation

can we introduce too many roles? Probably.

For example, we might have a cache class playing three roles: `ItemWriter` for saving items, `ItemReader` for reading items and `ExpiryCheck` for checking if a specific item is expired. While I consider striving for more fine-grained roles to be a good idea, if all of them are used in the same place, we now have to create three mocks for what seems like a consistent set of obligations scattered across three different interfaces.

#### Doing too much

It may be that a class needs lots of dependencies because it does too much. It may do validation, read configuration, page through persistent records, handle errors etc. The problem with this is that when the class is coupled to too many things, there are many reasons for the class to change.

A remedy for this could be to extract parts of the logic into separate classes so that our specified class does less with less peers.

#### Mocks returning mocks returning mocks

This one is discussed further, because it's a separate problem. Still, one of the symptoms of it may be many mocks needed in a Statement.


0. too fine grained role separation
1. Many mocks - coupling maybe extract some
2. too many set up return values - probably not tell don't ask
3. too many unused mocks - probably an issue with cohesion (facades are OK)

### Mock stubbing and verifying the same call

```csharp
interface ISlotAssignment
{
  public void AssignSlot(int slotNumber);
}
```



### Trying to mock a third-party interface


## General description

what does smell mean?
why test smells can mean code smells?

## Flavors

* testing the same thing in many places
  * Redundancy
  * When this is not a problem - decoupling of different contexts, no real redundancy
* Many mocks/ Bloated constructor (GOOS) / Too many dependencies (GOOS)
  * Coupling
  * Lack of abstractions
  * Not a problem when: facades
* Mock stubbing and verifying the same call
  * Breaking CQS
  * When not a problem: close to I/O boundary
* Blinking test (Any + boolean flags and ifs on them, multiple ways of getting the same information)
  * too much focus on data instead of abstractions
  * lack of data encapsulation
  * When not a problem: when it's only a test problem (badly written test). Still a problem but not design problem.
* Excessive setups (sustainabletdd) - both preparing data & preparing the unit with additional calls 
  * chatty protocols
  * issues with cohesion
  * coupling (e.g. to lots of data that is needed)
  * When not a problem: higher level tests (e.g. configuration upload) - maybe this still means bad higher level architecture?
* Combinatorial explosion (TODO: confirm name)
  * cohesion issues?
  * too low abstraction level (e.g. ifs to collection)
  * When not a problem: decision tables (domain logic is based on many decisions and we already decoupled them from other parts of logic)
* Need to assert on private fields
  * Cohesion
* pass-through tests (test simple forwarding of calls)
  * too many layers of abstraction. 
  * Also happens in decorators when decorated interfaces are too wide
* Set up mock calls consistency (many ways to get the same information, the tested code can use either, so we need to setup multiple calls to behave consistently)
  * Might mean too wide interface with too many options 
  * or insufficient level of abstraction
* overly protective test (sustainabletdd) - checking other behaviors than only the intended one out of fear
  * lack of cohesion
  * hidden coupling?
* Having to mock/prepare framework/library objects (e.g. HttpRequest or sth.)
  * Don't mock what you don't own?
  * In domain code - coupling to tech details
* Liberal matchers (lost control over how objects flow through methods)
  * cohesion
  * chatty protocols
  * separate usage from construction
* Encapsulating the protocol (hiding mock configuration and verification behind helper methods because they are too complex or repeat in each test)
  * Cohesion (the repeated code might be moved to a separate class)
* I need to mock object I can't replace (GOOS)
* Mocking concrete classes (GOOS)
* Mocking value-like objects (GOOS)
  * making objects instead of values
* Confused object (GOOS)
* Too many expectations (GOOS)
* Many tests in one (hard to setup)
* also look here: https://www.yegor256.com/2018/12/11/unit-testing-anti-patterns.html