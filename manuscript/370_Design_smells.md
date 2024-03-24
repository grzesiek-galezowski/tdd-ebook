# Design smells visible in the Specification

Sometimes, when writing the Specification, certain code patterns occur that make the individual Statements hard to write, read or maintain. This may mean that the Specification code should be improved, maybe by extracting the common part into a method, or maybe by using a testing tool's feature. Before I reach that conclusion, however, I try to 

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
* Blinking test (Any + boolean flags and ifs on them)
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