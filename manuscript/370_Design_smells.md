# Design smells visible in the Specification

In the earlier chapters, I stressed many times how mock objects can and should be used as a design tool, helping flesh out the protocols between collaborating objects. This is because something I call *Test-design approach mismatch* exists. The way I chose to phrase it is:

"Test automation approach and design approach need to live in symbiosis - build on a similar sets of assumptions and towards the same goals. If they do, they reinforce each other. If they don't, there will be friction between them."

I find this to be universally true. For example, if I test an asynchronous application as if I was testing a synchronous application or if I try to test JSON web API using a clicking tool, my code will either not work correctly or look weird. I will probably need to put extra work to compensate for the mismatch between the testing and design approach. For this reason some who prefer much different design approaches [consider mock objects a smell](https://medium.com/javascript-scene/mocking-is-a-code-smell-944a70c90a6a).

I am seeing it on the unit level as well. In this book, I am using the specification terminology instead of testing terminology. Thus I can say that by writing my Specification on unit level and using mock objects in my Statements, I expect my design to have certain properties and I find these properties desirable. If my code does not show these properties, it will make my life harder. The other side of this coin is that if I train myself to recognize the situations where the design and specification approaches diverge and patterns by which it happens, I can use this knowledge to improve my design.

In this chapter, I present some of the smells that can be seen in the Statements but are in reality design issues. All of these smells come from the community and you can find them catalogued in other places.

## Design smells' catalog

### Specifying the same behavior in many places

Sometimes, when I write a Statement, I have a deja vu and start thinking "I remember specifying a behavior like this already". I will feel this especially when that other time is not so long ago, maybe even a couple of minutes.

Consider the following Statement describing a reporting rule generation logic:

```csharp
[Fact] public void
ShouldReportAllEmployeesWhenExecuted()
{
  //GIVEN
  var employee1 = Substitute.For<Employee>();
  var employee2 = Substitute.For<Employee>();
  var employee3 = Substitute.For<Employee>();
  var allEmployees = new List<Employee>() {employee1, employee2, employee3};
  var reportBuilder = Substitute.For<ReportBuilder>();
  var employeeReportingRule = new EmployeeReport(allEmployees, reportBuilder);

  //WHEN
  employeeReportingRule.Execute();

  //THEN
  Received.InOrder(() =>
  {
    reportBuilder.AddHeader();
    employee1.AddTo(report);
    employee2.AddTo(report);
    employee3.AddTo(report);
    reportBuilder.AddFooter();
  });
}
```

Now, another Statement for a different rule:

```csharp
[Fact] public void
ShouldReportTotalCost()
{
  //GIVEN
  var calculatedTotalCost = Any.Integer();
  var reportBuilder = Substitute.For<ReportBuilder>();
  var costReportingRule = new EmployeeReport(totalCost, reportBuilder);

  //WHEN
  employeeReportingRule.Execute();

  //THEN
  Received.InOrder(() =>
  {
    reportBuilder.AddHeader();
    reportBuilder.AddTotalCost(totalCost);
    reportBuilder.AddFooter();
  });
}
```

And note that I have to specify again that a header and a footer is added to the report. This might mean there is redundancy in the design and maybe every report or at least most of them, need a header and a footer. This observation, amplified of the feeling of pointlessness from describing the same behavior several times, may lead me to try to extract some logic into a separate object, maybe a decorator, that will add footer before the main part of the report and footer at the end.

#### When this is not a problem

The trick with recognizing redundancy in the design is to detect whether the behavior in both places will change for the same reasons and in the same way. This is usually true if both places duplicate the same domain rule. But consider these two functions:

```csharp
double CmToM(double value)
{ 
  return value/100;
}

double PercentToFraction(double value)
{ 
  return value/100;
}
```

While the implementation is the same, the domain rule is different. In such situations, we're not talking about redundancy, but coincidence. Also see [Vladimir Khorikov's excellent post on this topic](https://enterprisecraftsmanship.com/posts/dry-damp-unit-tests/). 

Redundancy in the code is often referred to as "DRY (don't repeat yourself) violation". Remember that DRY is about domain rules, not code.

### Many mocks

So far, I have advertised using mocks in modelling roles in the Statements. So, mocking is good, right? Well, not exactly. Through mock objects, we can see how the class we specify interacts with its context. If the interactions are complex, then the Statements will show that. This isn't something we should ignore. Quite the contrary, the ability to see this problem through our Statements is one of the main reasons we use mocks.

One of the symptoms of the design issues is that we have too many mocks. We can feel the pain either when writing the Statement ("oh no, I need another mock") or when reading ("so many mocks, I can't see where something real happens").


#### Doing too much

It may be that a class needs lots of dependencies because it does too much. It may do validation, read configuration, page through persistent records, handle errors etc. The problem with this is that when the class is coupled to too many things, there are many reasons for the class to change.

A remedy for this could be to extract parts of the logic into separate classes so that our specified class does less with less peers.

### Mocks returning mocks returning mocks

Mocks returning mocks returning mocks typically mean that our code is not built around the tell don't ask heuristic and that the specified class is coupled to too many types.

### Many unused mocks

If we are passing many mocks in each Statement only to fill the parameter list, it may be a sign of poor cohesion.

Having many unused mocks is OK in facade classes, because the reasons for facades to exist is to simplify access to a subsystem and they typically hold references to many objects, doing little with each of them.

### Mock stubbing and verifying the same call

Consider an example where our application manages some kind of resource and each requester obtains a "slot" in this resource. The resource is represented by the following interface:

```csharp
interface ISharedResource
{
  public SlotId AssignSlot();
}
```

when specifying the behaviors of any class that uses this resource, will use a mock:

```csharp
var resource = Substitute.For<ISharedResource>();
```

we want to describe that a slot reservation is attempted in a shared resource only once, so we will have the following call on our mock:

```csharp
resource.Received(1).AssignSlot();
```

But we will also need to describe what happens when the slot is successfully assigned or when the assignment fails, so we need to configure the mock to return something:

```csharp
resource.AssignSlot().Returns(slotId);
```

Having both setting up a return value and verification of the call to same method in a Statement is a sign we are violating the command-query separation principle. This will limit our ability to elevate polymorphism in implementations of this interface.

But what can we do about this? 

#### pass a continuation

We may pass a more full-featured role that will continue the flow. Below is an example of passing a cache where the assigned slot will be saved if the assignment is successful:

```csharp
resource.Received(1).AssignSlot(cache);
```

#### pass a callback

we may create a special role for a recipient of the result and pass it inside the `AssignSlot` method, then make it act on the result:

```csharp
Received.InOrder(() =>
{
  resource.AssignSlot(assignSlotResponse);
  assignSlotResponse.Received(1).DisplayOn(screen);
})
```

#### pass a the needed collaborators through the constructor

Sometimes we may completely remove the notion of result from the interface and make passing it further an implementation detail. Here is the Statement where we don't specify anything about handling a potential result:

```csharp
resource.Received(1).AssignSlot();
```

the implementations are still free to do what they want (or nothing at all) depending on assignment success or failure. One such implementation might have a constructor that looks like this:

```csharp
public CacheBackedSharedResource(IAssignmentCache cache) { ... }
```

and may use its constructor argument to delegate some of the logic there.

#### When is this not a problem?

TODO: I/O boundary - sometimes easier to return something than to pass a collaborator through an architectural boundary.

### Trying to mock a third-party interface

The classic book on TDD, Growing Object-Oriented Software Guided By Tests, suggests to not mock types you don't own. Because mocks are a design tool, we only want to create mocks of types we can control and which represent abstractions. Otherwise we are tied by the definition of the interface "as is" and cannot improve our Statements by improving the design.

Does it mean that if I have a `File` class, I can just wrap it in a thin interface and create an `IFile` interface to enable mocking and I'm good? If the constraint I place on this interface is that it's 1:1 to the type I don't own, then it's back to square one - I still have an interface which is defined in a way that may make writing Statements with mocks hard and there is nothing I can do about it.

So what should I do when I am close to the I/O boundary? I should use a different type of Statements, which I will show you in one of the next parts of this book.

#### What about logging?

The GOOS book also discusses this topic - loggers from libraries are often ubiquitous all over many codebases. TODO https://learn.microsoft.com/en-us/dotnet/core/extensions/logger-message-generator and Support class.

#### Blinking tests because of generated data

This specific smell is not related to mock objects, but rather to using constrained non-determinism. 

When a Statement becomes unstable due to data being generated as different values on each execution, this might mean that the behavior is too reliant of data and lacks abstraction. The code might look like this:

```csharp
if(customer.Accounts.First(a => a.IsPrimary).IsActive)
{
  customer.Status = CustomerStatus.Active;
}
```

Note that code checks the `IsActive` flag (a boolean) of the first account set as primary (again, using a boolean `IsPrimary` flag). Booleans are especially vulnerable to non-deterministic generation because they have two possible values, each of which is typically in a different equivalence class. And here we have two. So I would expect Statements that use generated data to fail regularly in a non-deterministic way.

One of the possible solutions here could be to create an abstraction over the customer data structure and use a mock instead of a generated data structure. Something like this:

```csharp
if(customer.HasActiveAccount())
{
  customer.Activate();
}
```

This solution is the naive, textbook solution. In reality, we might even end up rethinking the whole concept of activation and it could lead us to inventing new interesting roles.

Many times, I encountered people using data generators such as `Any` as a free pass to pass monstrous and complicated data structures around (because "why not? I can generate it with a single call to `Any.Instance<>()`"). However, I believe they should be working in the opposite direction - by introducing the notion of non-determinism, they force me to be more paranoid about the context in which my object works to keep "moving parts" of it to a minimum.

TODO: example

TODO: lack of abstraction

TODO: do I need this?

#### Too fine-grained role separation

can we introduce too many roles? Probably.

For example, we might have a cache class playing three roles: `ItemWriter` for saving items, `ItemReader` for reading items and `ExpiryCheck` for checking if a specific item is expired. While I consider striving for more fine-grained roles to be a good idea, if all are used in the same place, we now have to create three mocks for what seems like a consistent set of obligations scattered across three different interfaces.



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