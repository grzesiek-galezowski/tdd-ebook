# Design smells

## General description

what does smell mean?

## Flavors

* testing the same thing in many places
* Many mocks
* Mock stubbing and verifying the same call
* Blinking test (Any + boolean flags and ifs on them) - too much focus on data instead of abstractions
* Excessive setups (sustainabletdd) - both preparing data & preparing the unit with additional calls (chatty protocols)
* Combinatorial explosion (TODO: confirm name)
* Need to assert on private fields
* pass-through tests (test simple forwarding of calls - maybe too many layers of abstraction. Also happens in decorators when decorated interfaces are too wide)
* Set up mock calls consistency (many ways to get the same information, the tested code can use either, so we need to setup multiple calls to behave consistently. Might mean too wide interface with too many options or insufficient level of abstraction)
* overly protective test (sustainabletdd) - checking other behaviors than only the intended one out of fear
* Having to prepare framework/library objects (e.g. HttpRequest or sth.)
* Liberal matchers (lost control over how objects flow through methods)
* Encapsulating the protocol (hiding mock configuration and verification behind helper methods because they are too complex or repeat in each test)
* I need to mock object I can't replace (GOOS)
* Mocking concrete classes (GOOS)
* Mocking value-like objects (GOOS)
* Bloated constructor (GOOS)
* Confused object (GOOS)
* Too many dependencies (GOOS)
* Too many expectations (GOOS)