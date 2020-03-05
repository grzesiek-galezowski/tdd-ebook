# Test-driving at the input boundary - a retrospective

I suppose a lot was going on in the last chapter and some things that demand a deeper dive. The purpose of this chapter is to do a small retrospective on what Johnny and Benjamin did when test-driving a controller for the train reservation system.

## Outside-in development

Johnny and Benjamin started their development almost entirely at the peripherals, at the beginning of the flow of control. This is typical to the outside-in approach to software development. When I started learning to write software this way, I felt it as counter-intuitive. After all, if I started with the inside-most objects, I could run the logic inside them with whatever dependencies they had, because all those dependencies already existed. Looking at the graph below, I could develop and run the logic in `Object1` because it did not require dependencies. Then, I could develop `Object2` because it depends on `Object1` that I already created and I could as well do that with `Object3` because it only depends on `Object2` that I already had. In other words, at any given time, I could run everything I created up to that point.

```text
Object3 -> Object2 -> Object1
```

The outside-in approach broke this for me because the objects I had to start with were the ones that had to have dependencies and these dependencies did not exist yet. With outside-in, I would need to start with `Object3`, which could not be instantiated without `Object2`, which, in turn, could not be instantiated without `Object1`.

If this is more difficult, then why bother? My reasons are:

1. By starting from the inputs, I allow my interfaces and protocols to be shaped by a use case rather than by underlying technology. That does not mean I can just ignore the technology stuff, but I consider the use case logic to be the main driver. This way, my protocols tend to be more abstract which in turn enforces higher composability.
1. Every line of code I introduce is there because the use case needs it. Every method, every interface, and class exists because someone else needs it to perform its obligations. This way, I ensure I only implement the stuff that's needed the way the users find it comfortable to use. When going the other way, from the outputs, I designed classes by guessing how they would be used and I later regretted these guesses, because of the rework and complexity they often created.

The uncomfortable feeling of starting from the inputs ("there is nothing I can fully run") could, in my case, be mitigated with the following practices:

1. Using TDD with mocks - TDD allows every little piece of code to be executed well before the whole task completion and mock objects serve as first collaborators that allow this execution to happen.
1. Slicing the scope into smaller vertical parts (e.g. scenarios, stories, etc.) that can be implemented faster than a full-blown feature. We have had a taste of this in action when Johnny and Benjamin were developing the calculator in one of the first chapters.
1. Do not write the first Statement as a unit-level Statement, but instead, write it on a higher-level (e.g. end-to-end or against another architectural boundary), make it work, then refactor the initial structure. This gives us a kind of walking skeleton[^walkingskeleton], which can be built, tested and deployed. As the next features or scenarios are added, these traits are preserved so we can always run what we have mid-development. This approach is what we will be aiming at ultimately, but for this chapter, I will leave it out to only focus on the mocks and OO design.

## Workflow specification

The Statement about the controller is an example of what Amir Kolsky and Scott Bain call workflow specification. A workflow specification describes how a specified unit of behavior (in our case, a class) interacts with other units by sending messages and receiving answers. In Statements specifying workflow, we describe the purpose and behaviors of the specified class in terms of interacting of mocked roles that other objects play. 

In our case, TODO TODO TODO TODO TODO TODO TODO 

Workflow Statements specify how objects of a class coordinate and delegate work to other objects
Sustainable TDD blog reference
TODO: workflow specification
Sergeant, programming by intention


## Data Transfer Objects

While looking at the initial data structures, Johnny and Benjamin called them Data Transfer Objects.

A Data Transfer Object is a pattern to describe objects responsible for exchanging information between process boundaries (TODO: confirm with the book). So, we can have DTOs representing input that our process receives and DTOs representing output that our process sends out.

As you might have seen, DTOs are typically just data structures. That may come as surprising, because for several chapters now, I have repeatedly stressed how I bundle data and behavior together. Isn't this breaking all the principles that I mentioned?

My response to this would be that exchanging information between processes is where these principles do not apply and that there are some good reasons why.

1. It is easier to exchange data than to exchange behavior. If I wanted to send behavior to another process, I would have to send it as data anyway, e.g. in a form of source code. In such a  case, the other side would need to interpret the source code, provide all the dependencies etc. which could be cumbersome and strongly couple implementations of both processes.
2. Agreeing on a simple data format makes creating and interpreting the data in different programming languages easier.
3. Many times, the boundaries between processes are designed as functional boundaries at the same time. In other words, even if one process sends some data to another, both of these processes would not want to execute the same behaviors on the data.

These are some of the reasons why processes send data to each other. And when they do, they typically bundle the data for consistency and performance reasons.

### DTOs and value objects

While DTOs, similarly to value objects, carry and represent data, their purpose and design constraints are different.

1. Values have value semantics, i.e. they can be compared based on their content. DTOs typically don't have value semantics (if I add value semantics to DTOs, I do it because I find it convenient, not because it's a part of domain model).
1. Values may contain behavior, even quite complex (see e.g. `string.Replace()`), while DTOs typically contain no behaviors at all.
1. Despite the previous point, DTOs may contain value objects, as long as these value objects can be reliably serialized and deserialized without loss of information. Values don't typically contain DTOs.
1. Values represent atomic and well-defined concepts (like text, date, money), while DTOs mostly function as bundles of data.

### DTOs and mocks

As we observed in the example of Johnny and Benjamin writing their first Statement, they did not mock DTOs. This is a general rule - a DTO is a set of data, it does not represent an implementation of an abstract protocol nor does it benefit from  polymorphism the way objects do. Also, it is typically far easier to create an instance of a DTO than a mock of it. Imagine we have the following DTO:

```csharp
public class LoginDto
{
  public LoginDto(string login, string password)
  {
    Login = login;
    Password = password;
  }

  public string Login { get; }
  public string Password { get;}
}
```

An instance of this class can be created by typing:

```csharp
var loginDto = new LoginDto("James", "007");
```

If we were to create a mock, we would probably extract an interface:

```csharp
public class ILoginDto
{
  public string Login { get; set; }
  public string Password { get; set;}
}
```

and then write in our Statement something like this:

```csharp
var loginDto = Substitute.For<ILoginDto>();
loginDto.Login.Returns("James");
loginDto.Password.Returns("Bond");
```

Not only is this more verbose, it does not buy us anything. Hence my advice:

A> Do not try to mock DTOs in your Statements. Create the real thing.

## Using a `ReservationInProgress`

A controversial point of the design in the last chapter might be the usage of a `ReservationInProgress` class. The core idea of this interface is to collect the data needed to produce a result. To introduce this object, we needed a separate factory, which made the design more complex. Thus, some questions might pop into your mind:

1. What exactly is `ReservationInProgress`?
1. Is the `ReservationInProgress` really necessary and if not, what are the alternatives?
1. Is a separate factory for `ReservationInProgress` needed?

Let's try answering them.

## What exactly is `ReservationInProgress`?

As mentioned earlier, the intent for this object is to collect data on what happens during the handling of a command, so that the issuer of the command can act on that data (e.g. use it to create a response). Speaking in patterns language, this is an implementation of a Collecting Parameter pattern.

There is something I do often that I did not put in the example for the sake of simplicity. When I implement a collecting parameter, I typically make it implement two interfaces - one more narrow and the other one - wider. Let me show them: 

```csharp
public interface ReservationInProgress
{
   void Success(SomeData data);
   //...other methods for reporting events
}

public interface ReservationInProgressMakingReservationDto : ReservationInProgress
{
  ReservationDto ToDto();
}
```

The whole point is that only the issuer of the command can see the wider interface and when it passes this interface down the call chain, the next object only sees the methods for reporting events. This way, the wider interface can even be tied to a specific technology, as long as the more narrow one is not. For example, If I needed a JSON string response, I might do something like this:

```csharp
public interface ReservationInProgressMakingReservationDto : ReservationInProgress
{
  string ToJsonString();
}
```

and only the controller would know about that. The rest of the classes using the narrow interface would interact with it happily without ever knowing that it is meant to produce JSON output.

## Is `ReservationInProgress` necessary?

In short - no, although I find it useful. There are at least several alternative designs.

First of all, we might decide to return from the command's `Execute()` method. Then, the command would look like this:

```csharp
public interface ReservationCommand
{
  public ReservationDto Execute();
}
```

This would do the job for the task at hand, but would make the `ReservationCommand` break the command-query separation principle, which I like to uphold as much as I can. Also, the `ReservationCommand` interface would become much less reusable. If our application was to support different commands, each returning a different type of result, we could not have a single interface for all of them. This in turn would make it more difficult to decorate the commands using the decorator pattern. We might try to fix this by making the command generic:

```csharp
public interface ReservationCommand<T>
{
  public T Execute();
}
```

but this still leaves a distinction between `void` and non-`void` commands (which some people resolve by parameterizing would-be `void` commands with `bool` and returning `true` at the end).

The second option would be to just let the command execute and then obtain the result using a query (which, similarly to a command, may be a separate object). The code of the `MakeReservation()` would look somewhat like this:

```csharp
var reservationId = _idGenerator.GenerateId();
var reservationCommand = _factory.CreateReservationCommand(requestDto, reservationId);
var reservationQuery = _factory.CreateReservationQuery(reservationId);

reservationCommand.Execute();
return reservationQuery.Make();
```

Note that in this case, there is nothing like "result in progress", but on the other hand, we need to generate the id for the command, since the query must use the same id. This approach might be attractive provided 

1. You don't mind that the `reservationQuery` might go through database or external service again 
1. A potential destination for data allows both commands and queries on its interface (it's not always a given).

There are more options, but I'd like to stop here as this is not the main concern of this book.

## Do we need a separate factory for `ReservationInProgress`?

This question can be broken into two parts:

1. Can we use the same factory as for commands?
2. Do we need a factory at all?

The answer to the first one is: it depends on what the `ReservationInProgress` is coupled to. In the case of train reservation, it is just creating a DTO to be returned to the client. In such case, it does not need any knowledge of the framework that is being used to run the application. This lack of coupling to the framework would allow me to place creating `ReservationInProgress` in the same factory. However, if this class needed to decide e.g. HTTP status codes or create responses required by a specific framework or in a specified format (e.g. JSON or XML), then I would opt, as I did, for separating it from the command factory. This is because command factory belongs to the world of application logic and I want my application logic to be independent of the framework I use.

The answer to the second one is: it depends whether you care about specifying the controller behavior on the unit level. If yes, then it may handy to have a factory just to control the creation of `ReservationInProgress`. If you don't want to (e.g. you drive this logic with higher-level Statements, which we will talk about in one of the next parts), then you can decide to just create the object inside the controller method.

TODO: outside-in + maybe some drawing
interface discovery
TODO: read chapter on interface discovery

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

TODO: revise using the term "Stable" in the previous chapters to sync it with Uncle Bob's usage of the term.

[^walkingskeleton]: TODO add reference