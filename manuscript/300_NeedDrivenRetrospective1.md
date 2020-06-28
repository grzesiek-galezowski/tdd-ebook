# Test-driving at the input boundary - a retrospective

I suppose a lot was going on in the last chapter and some things that demand a deeper dive. The purpose of this chapter is to do a small retrospective of what Johnny and Benjamin did when test-driving a controller for the train reservation system.

## Outside-in development

Johnny and Benjamin started their development almost entirely at the peripherals of the system, at the beginning of the flow of control. This is typical of the outside-in approach to software development. It took me a while to get used to it. After all, if I had started with the inside-most objects, I could run the logic inside them with whatever dependencies they had, because all those dependencies already existed. Looking at the graph below, I could develop and run the logic in `Object1` because it did not require dependencies. Then, I could develop `Object2` because it depends on `Object1` that I already created and I could as well do that with `Object3` because it only depends on `Object2` that I already had. At any given time, I could run everything I created up to that point.

```text
Object3 -> Object2 -> Object1
```

The outside-in approach broke this for me because the objects I had to start with were the ones that had to have dependencies and these dependencies did not exist yet. With outside-in, I would need to start with `Object3`, which could not be instantiated without `Object2`, which, in turn, could not be instantiated without `Object1`.

If this feels difficult, then why bother? -- you may ask. My reasons are:

1. By starting from the inputs and going inside, I allow my interfaces and protocols to be shaped by use cases rather than by the underlying technology. That does not mean I can just ignore the technology stuff, but I consider the use case logic to be the main driver. This way, my protocols tend to be more abstract which in turn enforces higher composability.
1. Every line of code I introduce is there because the use case needs it. Every method, every interface, and class exists because there already exists someone who needs it to perform its obligations. This way, I ensure I only implement the stuff that's needed and that it is shaped the way the users find it comfortable to use. Until I started using this approach, I would start from the inside of the system and I would design classes by guessing how they would be used and I would later regret these guesses, because of the rework and complexity they would often create.

I found I can mitigate the uncomfortable feeling of starting from the inputs ("there is nothing I can fully run") with the following practices:

1. Using TDD with mocks - TDD allows every little piece of code to be executed well before the whole task completion and mock objects serve as first collaborators that allow this execution to happen.
1. Slicing the scope of work into smaller vertical parts (e.g. scenarios, stories, etc.) that can be implemented faster than a full-blown feature. We have had a taste of this in action when Johnny and Benjamin were developing the calculator in one of the first chapters of this book.
1. Not starting with a unit-level Statement, but instead, writing on a higher-level (e.g. end-to-end or against another architectural boundary). I could then make this bigger Statement work, then refactor the initial objects out of this small piece of working code. Only after having this initial structure in place would I start using class-level Statements with mocks. This approach is what we will be aiming at eventually, but for this chapter, I wanted to focus on the mocks and OO design, so I left this part out.

## Workflow specification

The Statement about the controller is an example of what Amir Kolsky and Scott Bain call a workflow Statement[^workflowspecification]. This kind of Statement describes how a specified unit of behavior (in our case, an object) interacts with other units by sending messages and receiving answers. In Statements specifying workflow, we document the intended purpose and behaviors of the specified class in terms of its interaction with other roles in the system. We use mock objects to play these roles by specifying the return values of some methods and asserting that other methods are called.

For example, in the Statement Johnny and Benjamin wrote in the last chapter, they described how a command factory reacts when asked for a new command and they also asserted on the call to the command's `Execute()` method.

### Should I verify that the factory got called?

You might have noticed in the same Statement that some interactions are verified (using the `.Received()` syntax) while some are only set up to return something. An example of the latter is a factory, e.g. `reservationInProgressFactory.FreshInstance().Returns(reservationInProgress)`. You may question why Johnny and Benjamin did not write something like `reservationInProgressFactory.Received().FreshInstance()` at the end.

The reason is, the factory is just a function -- it is not supposed to have any side-effects. As such, calling the factory is not the goal of the behavior I specify -- it will always be a means to an end. The goal of this behavior is to execute the command and return its result. If I didn't need a factory to achieve that, it wouldn't exist.

Also, I can call the factory many times in the code without altering the expected behavior. For example, if the code of the `MakeReservation()` method Johnny and Benjamin were test-driving did not look like this:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateReservationCommand(requestDto, reservationInProgress);
reservationCommand.Execute();
return reservationInProgress.ToDto();
```

but like this:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
reservationInProgress = _reservationInProgressFactory.FreshInstance();
reservationInProgress = _reservationInProgressFactory.FreshInstance();
reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateReservationCommand(requestDto, reservationInProgress);
reservationCommand.Execute();
return reservationInProgress.ToDto();
```

The behavior of this method would still be correct. Sure, it would do some needless work, but when writing Statements, I care about externally visible behavior, not how the flow is structured. I leave more freedom to the implementation and try not to overspecify.

On the other hand, consider the command -- it is supposed to have a side effect, because I expect it to alter some kind of reservation registry in the end. So if I sent the `Execute()` message more than once:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateReservationCommand(requestDto, reservationInProgress);
reservationCommand.Execute();
reservationCommand.Execute();
reservationCommand.Execute();
reservationCommand.Execute();
reservationCommand.Execute();
return reservationInProgress.ToDto();
```

then it would alter the behavior -- maybe by reserving more seats than the user requested, maybe by throwing an error from the second `Execute()`... This is why I want to strictly specify how many times the `Execute()` message should be sent:

```csharp
reservationCommand.Received(1).Execute();
```

This approach is what Steve Freeman and Nat Pryce call "Allow queries; expect commands"[^GOOS].

## Interface discovery and the sources of abstractions

=====================TODO

As promised, the last chapter included some interface discovery, even though it wasn't your typical way of applying this approach.

The goal was to decouple from the framework, so if there was domain knowledge here, this would be a problem
Command/UseCase - pattern, (services layer)
CommandFactory - pattern
ReservationInProgress - pattern/domain
ReservationInProgressFactory - pattern
TODO: sources of abstraction - here, it's mainly architecture, but there is ReservationInProgress

## Data Transfer Objects and TDD

While looking at the initial data structures, Johnny and Benjamin called them Data Transfer Objects.

A Data Transfer Object is a pattern to describe objects responsible for exchanging information between processes[^PEAA]. So, we can have DTOs representing input that our process receives and DTOs representing output that our process sends out.

As you might have seen, DTOs are typically just data structures. That may come as surprising, because for several chapters now, I have repeatedly stressed how I prefer to bundle data and behavior together. Isn't this breaking all the principles that I mentioned?

My response to this would be that exchanging information between processes is where these principles do not apply and that there are some good reasons why.

1. It is easier to exchange data than to exchange behavior. If I wanted to send behavior to another process, I would have to send it as data anyway, e.g. in a form of source code. In such a case, the other side would need to interpret the source code, provide all the dependencies, etc. which could be cumbersome and strongly couple implementations of both processes.
2. Agreeing on a simple data format makes creating and interpreting the data in different programming languages easier.
3. Many times, the boundaries between processes are designed as functional boundaries at the same time. In other words, even if one process sends some data to another, both of these processes would not want to execute the same behaviors on the data.

These are some of the reasons why processes send data to each other. And when they do, they typically bundle the data for consistency and performance reasons.

### DTOs vs value objects

While DTOs, similarly to value objects, carry and represent data, their purpose and design constraints are different.

1. Values have value semantics, i.e. they can be compared based on their content. This is one of the core principles of their design. DTOs don't need to have value semantics (if I add value semantics to DTOs, I do it because I find it convenient for some reason, not because it's a part of domain model).
1. DTOs must be easily serializable and deserializable from some kind of data exchange format (i.e. JSON or XML).
1. Values may contain behavior, even quite complex (an example of this would be the `Replace()` method of the `String` class), while DTOs typically contain no behavior at all.
1. Despite the previous point, DTOs may contain value objects, as long as these value objects can be reliably serialized and deserialized without loss of information. Value objects don't contain DTOs.
1. Values represent atomic and well-defined concepts (like text, date, money), while DTOs mostly function as bundles of data.

### DTOs and mocks

As we observed in the example of Johnny and Benjamin writing their first Statement, they did not mock DTOs. This is a general rule -- a DTO is a piece of data, it does not represent an implementation of an abstract protocol nor does it benefit from polymorphism the way objects do. Also, it is typically far easier to create an instance of a DTO than to mock it. Imagine we have the following DTO:

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
  public string Login { get; }
  public string Password { get; }
}
```

and then write something like this in our Statement:

```csharp
var loginDto = Substitute.For<ILoginDto>();
loginDto.Login.Returns("James");
loginDto.Password.Returns("Bond");
```

Not only is this more verbose, it also does not buy us anything. Hence my advice:

A> Do not try to mock DTOs in your Statements. Create the real thing.

### Creating DTOs in Statements

As DTOs tend to bundle data, creating them for specific Statements might be a chore as there might sometimes be several fields we would need to initialize in each Statement. How do I approach creating instances of DTOs to avoid this? I summarized my advice on dealing with this as the priority-ordered list below:

#### Limit the reach of your DTOs in the production code

As a rule of thumb, the fewer types and methods know about them, the better. DTOs represent an external application contract. They are also constrained by some rules mentioned earlier (like the ease of serialization), so they cannot evolve the same way normal objects do. Thus, I try to limit the number of objects that know about DTOs to a necessary minimum. I use one of the two strategies: wrapping or mapping.

When wrapping, I have another object that holds a reference to the DTO and then all the other pieces of logic interact with this wrapping object instead of directly with a DTO:

```csharp
var user = new User(userDto);
//...
user.Assign(resource);
```

I consider this approach simpler but more limited. I find that it encourages me to shape the domain objects similarly to how the DTOs are designed (because one object wraps one DTO).

When mapping, I unpack the DTO and pass specific parts into my domain objects:

```csharp
var user = new User(userDto.Name, userDto.Surname, new Address(userDto.City, userDto.Street));
//...
user.Assign(resource);
```

This approach requires me to rewrite data into new objects field by field, but in exchange leaving me more room to shape my domain objects independent of the DTO structure[^mapperpattern]. In the example above, I was able to introduce an `Address` abstraction even though the DTO does not have an explicit field containing the address.

How does all of this help me avoid the tediousness of creating DTOs? Well, the fewer objects and methods know about a DTO, the fewer Statements will need to know about it as well, which leads to fewer places where I need to create and initialize one.

#### Use constrained non-determinism if you don't need specific data

In many Statements where I need to create DTOs, the specific values held inside it don't matter to me. I care only about *some* data being there. This is a perfect match for constrained non-determinism. I can just create an anonymous instance and use it, which I find easier than assigning field by field.

As an example, look at this line from the Statement Johnny and Benjamin wrote in the last chapter:

```csharp
var requestDto = Any.Instance<ReservationRequestDto>();
```

In that Statement, they did not need to care about the exact values held by the DTO, so they just created an anonymous instance. In this particular case, using constrained non-determinism not only simplified the creation of the DTO, but it even allowed them to completely decouple the Statement from the DTO's structure.

#### Use patterns such as factory methods or builders

When all else fails, I use factory methods and builders to ease the pain of creating DTOs to hide away the complexity and provide some good default values for the parts I don't care about.

A factory method can be useful if there is a single distinguishing factor about the particular instance that I want to create. For example:

```csharp
public UserDto AnyUserWith(params Privilege[] privileges)
{
  var dto = Any.Instance<UserDto>();
  dto.Privileges = privileges;
  return dto;
}
```

This method creates any user with a particular set of privileges. Note that I utilized constrained non-determinism as well in this method, which helped me a bit. If this is not possible, I try to come up with some sort of "safe default" values for each of the fields.

I like factory methods, but the more flexibility I need, the more I gravitate towards test data builders[^natprycetestdatabuilder].

A builder leaves me much more flexibility with how I set up my DTOs. The typical syntax for using a builder you can find on the internet[^ploehtestdatabuilder] looks like this:

```csharp
var user = new UserBuilder().WithName("Johnny").WithAge("43").Build();
```

Note that the value for each field is configured separately. Typically, the builder holds some kind of default values for the fields I don't specify:

```csharp
var user = new UserBuilder().WithName("Johnny").Build(); //some safe default age will be used
```

I am not showing an example implementation on purpose, because one of the further chapters will include a longer discussion on this topic.

## Using a `ReservationInProgress`

A controversial point of the design in the last chapter might be the usage of a `ReservationInProgress` class. The core idea of this abstraction is to collect the data needed to produce a result. To introduce this object, we needed a separate factory, which made the design more complex. Thus, some questions might pop into your mind:

1. What exactly is `ReservationInProgress`?
1. Is the `ReservationInProgress` really necessary and if not, what are the alternatives?
1. Is a separate factory for `ReservationInProgress` needed?

Let's try answering them.

### What exactly is `ReservationInProgress`?

As mentioned earlier, the intent for this object is to collect data on what happens during the handling of a command, so that the issuer of the command can act on that data (e.g. use it to create a response). Speaking in patterns language, this is an implementation of a Collecting Parameter pattern.

There is something I often do, but I did not put in the example for the sake of simplicity. When I implement a collecting parameter, I typically make it implement two interfaces -- one more narrow and the other one -- wider. Let me show them to you:

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

The whole point is that only the issuer of the command can see the wider interface and when it passes this interface down the call chain, the next object only sees the methods for reporting events. This way, the wider interface can even be tied to a specific technology, as long as the narrower one is not. For example, If I needed a JSON string response, I might do something like this:

```csharp
public interface ReservationInProgressMakingReservationDto : ReservationInProgress
{
  string ToJsonString();
}
```

and only the controller object would know about that. The rest of the classes using the narrower interface would interact with it happily without ever knowing that it is meant to produce JSON output.

### Is `ReservationInProgress` necessary?

In short -- no, although I find it useful. There are at least several alternative designs.

First of all, we might decide to return from the command's `Execute()` method. Then, the command would look like this:

```csharp
public interface ReservationCommand
{
  public ReservationDto Execute();
}
```

This would do the job for the task at hand but would make the `ReservationCommand` break the command-query separation principle, which I like to uphold as much as I can. Also, the `ReservationCommand` interface would become much less reusable. If our application was to support different commands, each returning a different type of result, we could not have a single interface for all of them. This, in turn, would make it more difficult to decorate the commands using the decorator pattern. We might try to fix this by making the command generic:

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

Note that in this case, there is nothing like "result in progress", but on the other hand, we need to generate the id for the command, since the query must use the same id. This approach might be attractive provided that:

1. You don't mind that the `reservationQuery` might go through database or external service once during the command, and again during the query.
1. A potential destination API for data allows executing both commands and queries on on the data (it's not always a given).

There are more options, but I'd like to stop here as this is not the main concern of this book.

### Do we need a separate factory for `ReservationInProgress`?

This question can be broken into two parts:

1. Can we use the same factory as for commands?
2. Do we need a factory at all?

The answer to the first one is: it depends on what the `ReservationInProgress` is coupled to. In this specific example, it is just creating a DTO to be returned to the client. In such a case, it does not need any knowledge of the framework that is being used to run the application. This lack of coupling to the framework would allow me to place creating `ReservationInProgress` in the same factory. However, if this class needed to decide e.g. HTTP status codes or create responses required by a specific framework or in a specified format (e.g. JSON or XML), then I would opt, as I did, for separating it from the command factory. This is because the command factory belongs to the world of application logic and I want my application logic to be independent of the framework or the transport protocols I use.

The answer to the second question is: it depends whether you care about specifying the controller behavior on the unit level. If yes, then it may handy to have a factory just to control the creation of `ReservationInProgress`. If you don't want to (e.g. you drive this logic with higher-level Statements, which we will talk about in one of the next parts), then you can decide to just create the object inside the controller method.

## So should I write unit-level Statements for my controllers?

Uncle Bob did not
These Statements are repeatable
I like it to monitor dependencies that my controllers have


TODO: other ways to test-drive this (higher-level tests)

## Design quality vs Statements

TODO: Design quality vs. Tests (intro) and what this example told us - verifying and setting up a mock for the same method is violation of the CQS principle, too many mocks - too many dependencies. Too many stubs - violation of TDA principle. These things *may* mean a violation.

Next chapter - a factory

TODO: revise using the term "Stable" in the previous chapters to sync it with Uncle Bob's usage of the term.

[^walkingskeleton]: TODO add reference
[^workflowspecification]: http://www.sustainabletdd.com/2012/02/testing-best-practices-test-categories.html
[^PEAA]: Patterns of Enterprise Application Architecture, Martin Fowler
[^mapperpattern]: https://martinfowler.com/eaaCatalog/mapper.html
[^natprycetestdatabuilder]: http://www.natpryce.com/articles/000714.html
[^ploehtestdatabuilder]: https://blog.ploeh.dk/2017/08/15/test-data-builders-in-c/
[^GOOS]: Steve Freeman, Nat Pryce, Growing Object Oriented Software Guided By Tests