# Test-driving at the input boundary -- a retrospective

A lot of things happened in the last chapter and I feel some of them deserve a deeper dive. The purpose of this chapter is to do a small retrospective of what Johnny and Benjamin did when test-driving a controller-type class for the train reservation system.

## Outside-in development

Johnny and Benjamin started their development almost entirely at the peripherals of the system, at the beginning of the flow of control. This is typical of the outside-in approach to software development. It took me a while to get used to it. To illustrate it, let's consider a system of three classes, where `Object3` depends on `Object2` and `Object2` depends on `Object1`:

```text
Object3 -> Object2 -> Object1
```

Before adopting the outside-in approach, my habit was to start with the objects at the end of the dependency chain (which would typically be at the end of the control flow as well) because I had everything I needed to run and check them. Looking at the graph above, I could develop and run the logic in `Object1` because it did not require dependencies. Then, I could develop `Object2` because it depended on `Object1` that I already created and I could then do the same with `Object3` because it depended only on `Object2` that I already had. At any given time, I could run everything I created up to that point.

The outside-in approach contradicted this habit of mine, because the objects I had to start with were the ones that had to have dependencies and these dependencies did not exist yet. Looking at the example above, I would need to start with `Object3`, which could not be instantiated without `Object2`, which, in turn, could not be instantiated without `Object1`.

"If this feels difficult, then why bother?" you might ask. My reasons are:

1. By starting from the inputs and going inside, I allow my interfaces and protocols to be shaped by use cases rather than by the underlying technology. That does not mean I can always ignore the technology stuff, but I consider the use case logic to be the main driver. This way, my protocols tend to be more abstract which in turn enforces higher composability.
1. Every line of code I introduce is there because the use case needs it. Every method, every interface, and class exists because there already exists someone who needs it to perform its obligations. This way, I ensure I only implement the stuff that's needed and that it is shaped the way the users find it comfortable to use. Before adpoting this approach, I would start from the inside of the system and I would design classes by guessing how they would be used and I would later often regret these guesses, because of the rework and complexity they would create.

For me, these pros outweigh the cons. Moreover, I found I can mitigate the uncomfortable feeling of starting from the inputs ("there is nothing I can fully run") with the following practices:

1. Using TDD with mocks -- TDD encourages every little piece of code to be executed well before the whole task completion. Mock objects serve as the first collaborators that allow this execution to happen. To take advantage of mocks, at least in C#, I need to use interfaces more liberally than in a typical development approach. A property of interfaces is that they typically don't contain implementation[^csandjavainterfaces], so they can be used to cut the dependency chain. In other words, whereas without interfaces, I would need all three: `Object1`, `Object2` and `Object3` to instantiate and use `Object3`, I could alternatively introduce an interface that `Object3` would depend on and `Object2` would implement. This would allow me to use `Object3` before its concrete collaborators exist, simply by supplying a mock object as its dependency.
1. Slicing the scope of work into smaller vertical parts (e.g. scenarios, stories, etc.) that can be implemented faster than a full-blown feature. We had a taste of this in action when Johnny and Benjamin were developing the calculator in one of the first chapters of this book.
1. Not starting with a unit-level Statement, but instead, writing on a higher-level first (e.g. end-to-end or against another architectural boundary). I could then make this bigger Statement work, then refactor the initial objects out of this small piece of working code. Only after having this initial structure in place would I start using unit-level Statements with mocks. This approach is what I will be aiming at eventually, but for this and several furter chapters, I want to focus on the mocks and object-oriented design, so I left this part for later.

## Workflow specification

The Statement about the controller is an example of what Amir Kolsky and Scott Bain call a workflow Statement[^workflowspecification]. This kind of Statement describes how a specified unit of behavior (in our case, an object) interacts with other units by sending messages and receiving answers. In Statements specifying workflow, we document the intended purpose and behaviors of the specified class in terms of its interaction with other roles in the system. We use mock objects to play these roles by specifying the return values of some methods and asserting that other methods are called.

For example, in the Statement Johnny and Benjamin wrote in the last chapter, they described how a command factory reacts when asked for a new command and they also asserted on the call to the command's `Execute()` method. That was a description of a workflow.

### Should I verify that the factory got called?

You might have noticed in the same Statement that some interactions were verified (using the `.Received()` syntax) while some were only set up to return something. An example of the latter is a factory, e.g. 

```csharp
reservationInProgressFactory.FreshInstance().Returns(reservationInProgress);`
```

You may question why Johnny and Benjamin did not write something like  
`reservationInProgressFactory.Received().FreshInstance()` at the end.

One reason is that a factory resembles a function -- it is not supposed to have any visible side-effects. As such, calling the factory is not a goal of the behavior I specify -- it will always be only a mean to an end. For example, the goal of the behavior Johnny and Benjamin specified was to execute the command and return its result. The factory was brought to existence to make getting there easier.

Also, Johnny and Benjamin allowed the factory to be called many times in the implementation without altering the expected behavior in the Statement. For example, if the code of the `MakeReservation()` method they were test-driving did not look like this:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateNewReservationCommand(
  requestDto, reservationInProgress);
reservationCommand.Execute();
return reservationInProgress.ToDto();
```

but like this:

```csharp
// Repeated multiple times:
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
reservationInProgress = _reservationInProgressFactory.FreshInstance();
reservationInProgress = _reservationInProgressFactory.FreshInstance();
reservationInProgress = _reservationInProgressFactory.FreshInstance();

var reservationCommand = _commandFactory.CreateNewReservationCommand(
  requestDto, reservationInProgress);
reservationCommand.Execute();
return reservationInProgress.ToDto();
```

then the behavior of this method would still be correct. Sure, it would do some needless work, but when writing Statements, I care about externally visible behavior, not lines of production code. I leave more freedom to the implementation and try not to overspecify.

On the other hand, consider the command -- it is supposed to have a side effect, because I expect it to alter some kind of reservation registry in the end. So if I sent the `Execute()` message more than once like this:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateNewReservationCommand(
  requestDto, reservationInProgress);
reservationCommand.Execute();
reservationCommand.Execute();
reservationCommand.Execute();
reservationCommand.Execute();
reservationCommand.Execute();
return reservationInProgress.ToDto();
```

then it could possibly alter the behavior -- maybe by reserving more seats than the user requested, maybe by throwing an error from the second `Execute()`... This is why I want to strictly specify how many times the `Execute()` message should be sent:

```csharp
reservationCommand.Received(1).Execute();
```

The approach to specifying functions and side-effects I described above is what Steve Freeman and Nat Pryce call "Allow queries; expect commands"[^GOOS]. According to their terminology, the factory is a "query" -- side-effect-free logic returning some kind of result. The `ReservationCommand`, on the other side, is a "command" - not producing any kind of result, but causing a side-effect like a state change or an I/O operation.

## Data Transfer Objects and TDD

While looking at the initial data structures, Johnny and Benjamin called them Data Transfer Objects.

A Data Transfer Object is a pattern to describe objects responsible for exchanging information between processes[^PEAA]. As processes cannot really exchange objects, the purpose of DTOs is to be serialized into some kind of data format and then transferred in that form to another process which deserializes the data. So, we can have DTOs representing output that our process sends out and DTOs representing input that our process receives.

As you might have seen, DTOs are typically just data structures. That may come as surprising, because for several chapters now, I have repeatedly stressed how I prefer to bundle data and behavior together. Isn't this breaking all the principles that I mentioned?

My response to this would be that exchanging information between processes is where the mentioned principles do not apply and that there are some good reasons why data is exchanged between processes.

1. It is easier to exchange data than to exchange behavior. If I wanted to send behavior to another process, I would have to send it as data anyway, e.g. in a form of source code. In such a case, the other side would need to interpret the source code, provide all the dependencies, etc. which could be cumbersome and strongly couple implementations of both processes.
2. Agreeing on a simple data format makes creating and interpreting the data in different programming languages easier.
3. Many times, the boundaries between processes are designed as functional boundaries at the same time. In other words, even if one process sends some data to another, both of these processes would not want to execute the same behavior on the data.

These are some of the reasons why processes send data to each other. And when they do, they typically bundle the data into bigger structures for consistency and performance reasons.

### DTOs vs value objects

While DTOs, similarly to value objects, carry and represent data, their purpose and design constraints are different.

1. Values have value semantics, i.e. they can be compared based on their content. This is one of the core principles of their design. DTOs don't need to have value semantics (if I add value semantics to DTOs, I do it because I find it convenient for some reason, not because it's a part of the domain model).
1. DTOs must be easily serializable and deserializable from some kind of data exchange format (e.g. JSON or XML).
1. Values may contain behavior, even quite complex (an example of this would be the `Replace()` method of the `String` class), while DTOs typically contain no behavior at all.
1. Despite the previous point, DTOs may contain value objects, as long as these value objects can be reliably serialized and deserialized without loss of information. Value objects don't contain DTOs.
1. Values represent atomic and well-defined concepts (like text, date, money), while DTOs mostly function as bundles of data.

### DTOs and mocks

As we observed in the example of Johnny and Benjamin writing their first Statement, they did not mock DTOs. It's a general rule -- a DTO is a piece of data, it does not represent an implementation of an abstract protocol nor does it benefit from polymorphism the way objects do. Also, it is typically far easier to create an instance of a DTO than to mock it. Imagine we have the following DTO:

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

If we were to create a mock, we would probably need to extract an interface:

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

A> Do not try to mock a DTO in your Statements. Create the real thing.

### Creating DTOs in Statements

As DTOs tend to bundle data, creating them for specific Statements might be a chore as there might sometimes be several fields we would need to initialize in each Statement. How do I approach creating instances of DTOs to avoid this? I summarized my advice on dealing with this as the priority-ordered list below:

#### 1. Limit the reach of your DTOs in the production code

As a rule of thumb, the fewer types and methods know about them, the better. DTOs represent an external application contract. They are also constrained by some rules mentioned earlier (like the ease of serialization), so they cannot evolve the same way normal objects do. Thus, I try to limit the number of objects that know about DTOs in my application to a necessary minimum. I use one of the two strategies: wrapping or mapping.

When wrapping, I have another object that holds a reference to the DTO and then all the other pieces of logic interact with this wrapping object instead of directly with a DTO:

```csharp
var user = new User(userDto);
//...
user.Assign(resource);
```

I consider this approach simpler but more limited. I find that it encourages me to shape the domain objects similarly to how the DTOs are designed (because one object wraps one DTO). I usually start with this approach when the external contract is close enough to my domain model and move to the other strategy -- mapping -- when the relationship starts getting more complex.

When mapping, I unpack the DTO and pass specific parts into my domain objects:

```csharp
var user = new User(
  userDto.Name, 
  userDto.Surname, 
  new Address(
    userDto.City, 
    userDto.Street));
//...
user.Assign(resource);
```

This approach requires me to rewrite data into new objects field by field, but in exchange, it leaves me more room to shape my domain objects independent of the DTO structure[^mapperpattern]. In the example above, I was able to introduce an `Address` abstraction even though the DTO does not have an explicit field containing the address.

How does all of this help me avoid the tediousness of creating DTOs? Well, the fewer objects and methods know about a DTO, the fewer Statements will need to know about it as well, which leads to fewer places where I need to create and initialize one.

#### 2. Use constrained non-determinism if you don't need specific data

In many Statements where I need to create DTOs, the specific values held inside it don't matter to me. I care only about *some* data being there. For situations like this, I like using constrained non-determinism. I can just create an anonymous instance and use it, which I find easier than assigning field by field.

As an example, look at the following line from the Statement Johnny and Benjamin wrote in the last chapter:

```csharp
var requestDto = Any.Instance<ReservationRequestDto>();
```

In that Statement, they did not need to care about the exact values held by the DTO, so they just created an anonymous instance. In this particular case, using constrained non-determinism not only simplified the creation of the DTO, but it even allowed them to completely decouple the Statement from the DTO's structure.

#### 3. Use patterns such as factory methods or builders

When all else fails, I use factory methods and test data builders to ease the pain of creating DTOs to hide away the complexity and provide some good default values for the parts I don't care about.

A factory method can be useful if there is a single distinguishing factor about the particular instance that I want to create. For example:

```csharp
public UserDto AnyUserWith(params Privilege[] privileges)
{
  var dto = Any.Instance<UserDto>()
    .WithPropertyValue(user => user.Privileges, privileges);
  return dto;
}
```

This method creates any user with a particular set of privileges. Note that I utilized constrained non-determinism as well in this method, which spared me some initialization code. If this is not possible, I try to come up with some sort of "safe default" values for each of the fields.

I like factory methods, but the more flexibility I need, the more I gravitate towards test data builders[^natprycetestdatabuilder].

A test data builder is a special object that allows me to create an object with some default values, but allows me to customize the default recipe according to which the object is created. It leaves me much more flexibility with how I set up my DTOs. The typical syntax for using a builder that you can find on the internet[^ploehtestdatabuilder] looks like this:

```csharp
var user = new UserBuilder().WithName("Johnny").WithAge("43").Build();
```

Note that the value for each field is configured separately. Typically, the builder holds some kind of default values for the fields I don't specify:

```csharp
//some safe default age will be used when not specified: 
var user = new UserBuilder().WithName("Johnny").Build();
```

I am not showing an example implementation on purpose, because one of the further chapters will include a longer discussion of test data builders.

## Using a `ReservationInProgress`

A controversial point of the design in the last chapter might be the usage of a `ReservationInProgress` class. The core idea of this abstraction is to collect the data needed to produce a result. To introduce this object, we needed a separate factory, which made the design more complex. Thus, some questions might pop into your mind:

1. What exactly is `ReservationInProgress`?
1. Is the `ReservationInProgress` really necessary and if not, what are the alternatives?
1. Is a separate factory for `ReservationInProgress` needed?

Let's try answering them.

### What exactly is `ReservationInProgress`?

As mentioned earlier, the intent for this object is to collect information about processing a command, so that the issuer of the command (in our case, a controller object) can act on that information (e.g. use it to create a response) when processing finishes. Speaking in patterns language, this is an implementation of a Collecting Parameter pattern[^CollectingParameter].

There is something I often do, but I did not put in the example for the sake of simplicity. When I implement a collecting parameter, I typically make it implement two interfaces -- one more narrow and the other one -- wider. Let me show them to you:

```csharp
public interface ReservationInProgress
{
   void Success(SomeData data);
   //... methods for reporting other events
}

public interface ReservationInProgressMakingReservationDto 
  : ReservationInProgress
{
  ReservationDto ToDto();
}
```

The whole point is that only the issuer of the command can see the wider interface  
(`ReservationInProgressMakingReservationDto`) and when it passes this interface down the call chain, the next object only sees the methods for reporting events (`ReservationInProgress`). This way, the wider interface can even be tied to a specific technology, as long as the narrower one is not. For example, If I needed a JSON string response, I might do something like this:

```csharp
public interface ReservationInProgressMakingReservationJson
  : ReservationInProgress
{
  string ToJsonString();
}
```

and only the command issuer (in our case, the controller object) would know about that. The rest of the classes using the narrower interface would interact with it happily without ever knowing that it is meant to produce a JSON output.

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

but this still leaves a distinction between `void` and non-`void` commands (which some people resolve by parameterizing would-be `void` commands with `bool` and always returning `true` at the end).

The second option to avoid a collecting parameter would be to just let the command execute and then obtain the result by querying the state that was modified by the command (similarly to a command, a query may be a separate object). The code of the `MakeReservation()` would look somewhat like this:

```csharp
var reservationId = _idGenerator.GenerateId();
var reservationCommand = _factory.CreateNewReservationCommand(
  requestDto, reservationId);
var reservationQuery = _factory.CreateReservationQuery(reservationId);

reservationCommand.Execute();
return reservationQuery.Make();
```

Note that in this case, there is nothing like "result in progress", but on the other hand, we need to generate the id for the command, as the query must use the same id. This approach might appeal to you if:

1. You don't mind that if you store your changes in a database or an external service, your logic might need to call it twice -- once during the command, and again during the query.
2. The state that is modified by the command is queryable (i.e. a potential destination API for data allows executing both commands and queries on the data). It's not always a given.

There are more options, but I'd like to stop here as this is not the main concern of this book.

### Do we need a separate factory for `ReservationInProgress`?

This question can be broken into two parts:

1. Can we use the same factory as for commands?
2. Do we need a factory at all?

The answer to the first one is: it depends on what the `ReservationInProgress` is coupled to. In this specific example, it is just creating a DTO to be returned to the client. In such a case, it does not necessarily need any knowledge of the framework that is being used to run the application. This lack of coupling to the framework would allow me to place creating `ReservationInProgress` in the same factory. However, if this class needed to decide e.g. HTTP status codes or create responses required by a specific framework or in a specified format (e.g. JSON or XML), then I would opt, as Johnny and Benjamin did, for separating it from the command factory. This is because the command factory belongs to the world of application logic and I want my application logic to be independent of the framework, the transport protocols, and the payload formats that I use.

The answer to the second question (whether we need a factory at all) is: it depends whether you care about specifying the controller behavior on the unit level. If yes, then it may be handy to have a factory to control the creation of `ReservationInProgress`. If you don't want to (e.g. you drive this logic with higher-level Specification, which we will talk about in one of the next parts), then you can decide to just create the object inside the controller method or even make the controller itself implement the `ReservationInProgress` interface (though if you did that, you would need to make sure a single controller instance is not shared between multiple requests, as it would contain mutable state).

#### Should I specify the controller behavior on the unit level?

As I mentioned, it's up to you. As controllers often serve as adapters between a framework and the application logic, they are constrained by the framework and so there is not that much value in driving their design with unit-level Statements. It might be more accurate to say that these Statements are closer to *integration Specification* because they often describe how the application is integrated into a framework.

An alternative to specifying the integration on the unit level could be driving it with higher-level Statements (which I will be talking about in detail in the coming parts of this book). For example, I might write a Statement describing how my application works end-to-end, then write a controller (or another framework adapter) code without a dedicated unit-level Statement for it and then use unit-level Statements to drive the application logic. When the end-to-end Statement passes, it means that the integration that my controller was meant to provide, works.

There are some preconditions for this approach to work, but I will cover them when talking about higher-level Statements in the further parts of this book.

## Interface discovery and the sources of abstractions

As promised, the earlier chapter included some interface discovery, even though it wasn't a typical way of applying this approach. This is because, as I mentioned, the goal of the Statement was to describe integration between the framework and the application code. Still, writing the Statement allowed Johnny and Benjamin to discover what their controller needs from the application to pass all the necessary data to it and to get the result without violating the command-query separation principle.

The different abstractions Johnny pulled into existence were driven by:

- his need to convert to a different programming style (command-query separation principle, "tell, don't ask"...),
- his knowledge about design patterns,
- his experience with similar problems.

Had he lacked these things, he would have probably written the simplest thing that would come to his mind and then changed the design after learning more.

## Do I need all of this to do TDD?

The last chapter might have left you confused. If you are wondering whether you need to use controllers, collecting parameters, commands and factories in order to do TDD, than my answer is *not necessarily*. Moreover, there are many debates on the internet whether these particular patterns are the right ones to use and even I don't like using controllers with problems such as this one (although I used it because this is what many web frameworks offer as a default choice).

I needed all of this stuff to create an example that resembles a real-life problem. The most important lesson though is that, while making the design decisions was up to Johnny and Benjamin's knowledge and experience, writing the Statement code before the implementation *informed* these design decisions, helping them distribute the responsibilities across collaborating objects.

## What's next?

This chapter hopefully connected all the missing dots of the last one. The next chapter will focus on test-driving object creation.

[^walkingskeleton]: https://wiki.c2.com/?WalkingSkeleton
[^workflowspecification]: http://www.sustainabletdd.com/2012/02/testing-best-practices-test-categories.html
[^PEAA]: Patterns of Enterprise Application Architecture, Martin Fowler
[^mapperpattern]: https://martinfowler.com/eaaCatalog/mapper.html
[^natprycetestdatabuilder]: http://www.natpryce.com/articles/000714.html
[^ploehtestdatabuilder]: https://blog.ploeh.dk/2017/08/15/test-data-builders-in-c/
[^GOOS]: Steve Freeman, Nat Pryce, Growing Object Oriented Software Guided By Tests
[^CollectingParameter]: https://wiki.c2.com/?CollectingParameter
[^csandjavainterfaces]: though both C# and Java in their current versions allow putting logic in interfaces. Still, due to convention and some constraints, interfaces in those languages are still considered as beings without implementation.