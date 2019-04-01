# Test-driving at the input boundary - a retrospective

I suppose there was a lot going on in the last chapter and some things that demand a deeper dive. The purpose of this chapter is to do a small retrospective on what Johnny and Benjamin did when test-driving a controller for train reservation system.

## Outside-in development

Johnny and Benjamin started almost entirely at the peripheral, on the inputs
This is not true outside-in. True outside-in requires higher-level tests and maybe refactoring in the middle.
TODO: outside-in + maybe some drawing
interface discovery
TODO: read chapter on interface discovery

## Data Transfer Objects

While looking at the initial data structures, Johnny and Benjamin callded them Data Transfer Objects.

A Data Transfer Object is a pattern to describe objects responsible for exchanging information between process boundaries (TODO: confirm with the book). So, we can have DTOs representing input that our process receives and DTOs representing output that our process sends out.

As you might have seen, DTOs are typically just data structures. That may come as surprising, because for several chapters now, I have repeatedly stressed how we should bundle data and behavior together. Isn't this breaking all the rules that I mentioned?

Yes, it does and it does so for good reason. But before I explain that, let's take a look at two ways of decoupling.

# Decoupling through interfaces

In a way, it is and it is because of decoupling. There are two main ways of decoupling.

TODO: every system is procedural at the boundaries.

DTO:

1. Two types of decoupling 
    1. with interfaces (pure behavior descriptions, decouple from the data)
    1. with data (decouples from behavior)
1. As it's very hard to pass behavior and quite easy to pass data, thus typically services exchange data, not behavior.
1. DTOs are for data interchange between processes
1. Typically represent an external data contract
1. Data can be easily serialized into text or bytes and deserialized on the other side.
1. DTOs can contain values, although this may be hard because these values need to be serializable. This may put some constraints on our value types depending on the parser
1. differences between DTOs and value objects (value objects can have behavior, DTOs should not, although the line is blurred e.g. when a value objecy is part of a DTO. String contains lots of behaviors but they are not domain-specific). Can DTOs implement equality?
1. Also, for this reason, application logic should be kept away from DTOs to avoid coupling them to external constract and making serialization/deserialization difficult.
1. Mapping vs. Wrapping
1. We do not mock DTOs
1. input DTOs best read only and immutable but can have builders

**Johnny:** The suffix `Dto` means that this class represents a Data Transfer Object (in short, DTO)[^POEAA]. Its role is just to transfer data across the process boundaries.

**Benjamin:** So you mean it is just needed to represent some kind of XML or JSON that is sent to the application?

**Johnny:** Yes, you could say that. The reason people typically place `Dto` in these names is to communicate that these data structures are special - they represent an outside contract and cannot be freely modified like other objects.

**Benjamin:** Does it mean that I can't touch them?

**Johnny:** It means that if you did touch them, you'd have to make sure they are still correctly mapped from outside data, like JSON or XML.


## Collecting parameter

1. Instead of combining parameters, add them somewhere
1. Simplest - a collection
1. Advantage, CQS
1. Advantage: caller has a better control over the identity
1. Advantage:  Anyone can call methods multiple times or not at all
1. Disadvantage: Anyone can call a method multiple times or not at all
1. Problem: return values enforce the "~exactly one~" result as there can always be one value returned. Collecting parameter does not enforce anything.
1. blurred line between this and builder

TODO: why separate factories?

## Workflow specifications

Workflow Statements specify how objects of a class coordinate and delegate work to other objects
Sustainable TDD blog reference
TODO: workflow specification
Seargant, programming by intention

## Sources of abstractions

The goal was to decouple from the framework, so if there was domain knowledge here, this would be a problem
Command/UseCase - pattern, (services layer)
CommandFactory - pattern
ReservationInProgress - pattern/domain
ReservationInProgressFactory - pattern
TODO: sources of abstraction - here, it's mainly architecture, but there is ReservationInProgress

## Maintaining a composition root

TODO: maintaining composition root to make the Statement run - don't spend too much time on it

## Factories and commands

TODO: why separate factories?
TODO: why commands? -> Fowler's command oriented API~~
TODO: give example of controller test from my solution to Ploeh kata
TODO: composing commands - why Execute() is parameterless

"**Benjamin:** Oh, I can see that the factory's `CreateReservationCommand()` is where you decided to pass the `reservationInProgress` that I wanted to pass to the `Execute()` method earlier. Clever. By leaving the commands's `Execute()` method parameterless, you made it more abstract and made the interface decpoupled from any particular argument types. On the other hand, the command is created in the same scope it is used, so there is literally no issue with passing all the parameters through the factory method.
"

"**Johnny:** This is where we need to exercise our design skills to introduce some new collaborators. This task is hard at the boundaries of application logic, since we need to draw the collaborators not from the domain, but rather think about design patterns that will allow us to reach our goals. Every time we enter our application logic, we do so from a perspective of a use case. In this particular example, our use case is "making a reservation". A use case is typically represented by either a method in a facade[^FacadePattern] or a command object[^CommandPattern]. Commands are a bit more complex, but more scalable. If making a reservation was our only use case, it probably wouldn't make sense to use it. But as we already have more high priority requests for features, I believe we can assume that commands will be a better fit.
"

"**Johnny**: Let's start with the collecting parameter, which will represent a domain concept of a reservation in progress. We need it to collect the data necessary to build a response DTO. Thus, what we currently know about it is that it's going to be converted to a response DTO at the very end. All of the three objects: the command, the collecting parameter and the factory, are collaborators, so they will be mocks in our Statement."

TODO: overdesign (and Sandro Mancuso version - compare with code and dependencies count, query count), anticorruption layer, mapping vs. wrapping. Wrapping is a little bit harder to maintain in case domain model follows the data, but is more convenient when domain model diverges from the data model.

```csharp
[Fact] public void
ShouldExecuteReservationCommandAndReturnResponseWhenMakingReservation()
{
  //GIVEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var commandFactory = Substitute.For<CommandFactory>();
  var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
  var reservationInProgress = Substitute.For<ReservationInProgress>();
  var expectedReservationDto = Any.Instance<ReservationDto>();
  var reservationCommand = Substitute.For<ReservationCommand>();

  var ticketOffice = new TicketOffice(
    reservationInProgressFactory,
    commandFactory);

  reservationInProgressFactory.FreshInstance()
    .Returns(reservationInProgress);
  commandFactory.CreateReservationCommand(requestDto, reservationInProgress)
    .Returns(reservationCommand);
  reservationInProgress.ToDto()
    .Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservationDto, reservationDto);
  reservationCommand.Received(1).Execute();
}
```

```csharp
[Fact] public void
ShouldExecuteReservationCommandAndReturnResponseWhenMakingReservation()
{
  //GIVEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var expectedReservationDto = Any.Instance<ReservationDto>();
  var ticketOffice = new TicketOffice(
    facade);

  facade.MakeReservation(requestDto).Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservationDto, reservationDto);
}
```

No value unless we intend to catch some exceptions here. The next class has to handle the DTO.

## So should I write unit-level Statements for my controllers?

Uncle Bob did not
These tests are repeatable
I like it to monitor dependencies that my controllers have


TODO: other ways to test-drive this (higher level tests)

## Design quality vs Statements

TODO: Design quality vs. Tests (intro) and what this example told us - verifying and setting up a mock for the same method is violation of the CQS principle, too many mocks - too many dependencies. Too many stubs - violation of TDA principle. These things *may* mean a violation.

Next chapter - a factory