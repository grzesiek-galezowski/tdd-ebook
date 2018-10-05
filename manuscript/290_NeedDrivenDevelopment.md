# Test-driving at the input boundary

In this chapter, we'll be joining Johnny and Benjamin again as thy try to test-drive a system starting from its input boundaries. This will hopefully show a picture of how abstractions are pulled from need and how roles are invented at the boundary of a system. THe further chapters will explore domain model. This example is based on severl assumptions:

1. Johnny is a super programmer, who never makes mistakes
2. No story slicing
3. No refactoring
4. No higher level tests
4. ..?


## Initial objects

TODO remember to describe how a TODO list changes!!!

### Request

Johnny: Somebody's already written the part that accepts the HTTP request and maps it to the following structure:

```csharp
public class ReservationRequestDto
{
  public readonly string trainId;
  public readonly uint seatCount;

  public ReservationRequestDto(string trainId, uint seatCount)
  {
    this.trainId = trainId;
    this.seatCount = seatCount;
  }
}
```

Benjamin: I see... Hey, why does the `ReservationRequestDto` name has `Dto` in it? What is it?

Johnny: The suffix `Dto` means that this class represents a Data Transfer Object (in short, DTO)[^POEAA]. Its role is just to transfer data across the process boundaries.

Benjamin: So you mean it is just needed to represent some kind of XML or JSON that is sent to the application?

Johnny: Yes, you could say that.

Benjamin: Cool, what's next?

Johnny: We also need to return a response, which, guess what, is also a DTO. This response represents the reservation made:

### Response

```csharp
public class ReservationDto
{
  public readonly string trainId;
  public readonly string reservationId;
  public readonly List<TicketDto> perSeatTickets;

  public ReservationDto(
    string trainId,
    List<TicketDto> perSeatTickets, 
    string reservationId)
  {
    this.trainId = trainId;
    this.perSeatTickets = perSeatTickets;
    this.ticketId = ticketId;
  }
}
```

Benjamin: OK, I can see that there's a train ID, which is... the same as the one in the request, right?

Johnny: Right. This is a way to correlate the request with the response.

Benjamin: ...and there is a reservation ID that is probably assigned by our application.

Johnny: correct.

Benjamin: but the `perSeatTickets` field... it is a list of `TicketDto`, which as I understand is one of our custom types. Where is it?

Johnny: Oh, yeah, forgot to show it to you. `TicketDto` is defined as:

```csharp
public class TicketDto
{
  public readonly string coach;
  public readonly int seatNumber;

  public TicketDto(string coach, int seatNumber)
  {
    this.coach = coach;
    this.seatNumber = seatNumber;
  }
}
```

so it has a coach name and a seat number, and we have a list of these in our ticket.

Benjamin: Ok, so a single reservation can contain many tickets and each ticket is for a single place in a specific coach, right?

Johnny: Yes. There are some constraints however, which I will tell you about later.

Benjamin: Ok. So we need these datqa structures to deserialize some kind of JSON or XML input into them?

Johnny: Well, lucky us, as this part is already done. Our work starts from the point where the desrialized data is passed to the application logic. The request entry point is in a class called `TicketOffice`:

```csharp
[SomeKindOfController]
public class TicketOffice
{
    [SuperFrameworkMethod]
    public ReservationDto MakeReservation(ReservationRequestDto requestDto)
    {
        throw new NotImplementedException("Not implemented");
    }
}
```

As I can see, it has annotations specific to a web framework, so we will probably not implement the use case directly in the `MakeReservation` method to avoid coupling our use case logic to code that needs to meet the requirements of a specific framework.


## Bootstrap

Benjamin: Are we ready to go?

Johnny: Typically, if I were you, I would like to see one more place in the code.

Benjamin: Which is..?

Johnny: The composition root, of course.

Benjamin: Why would I like to see a composition root?

Johnny: Well, first reason is that it is very close the entry point for the application, so it is a chance for you to see how the application manages its dependencies. The second reason is that each time we will be adding a new class that has the same lifespan as the application, we will need to go to the composition root and modify it. Sooo it would probably be nice to be able to tell where it is.

Benjamin: I thought I could find that later, but while we're at it, can you show me the composition root?

Johnny: Sure, it's here, in the `Application` class:

```csharp
public class Application
{
  public static void Main(string[] args)
  {
    new WebApp(
        new TicketOffice()
    ).Host();
  }
}
```

Benjamin: Good to see it doesn't use any fancy reflection-based mechanism for composing objects.

Johnny: Yes, we're lucky about that.

## Let's go!

Johnny: Anyway, I think we're ready to start.

Benjamin: Ok, where do we start from? Should we write a class called "Reservation" or "Train" first?

Johnny: No, what we will do is we will start from the inputs and work our way towards the inside of the application. Then, if necessary, to the outputs again.

Benjamin: I don't think I understand what you're talking about. Do you mean this "outside-in" approach that you talked about yesterday?

Johnny: Yes and don't worry if you didn't get what I said, I will explain as we go. For now, the only thing it means is that we will follow the path of the request as it comes from the outside and start implementing at first place that is not working as we think it should. Specifically, this means we start at:

```csharp
public class TicketOffice
{
    public ReservationDto MakeReservation(ReservationRequestDto requestDto) 
    {
        throw new NotImplementedException("Not implemented");
    }
}
```

Benjamin: Why?

Johnny: Because this is the place nearest to the request entry point where the behavior differs from the one we expect.

Benjamin: I see... so... if we didn't have the request deserialization code in place already, we'd start there, right?

Johnny: Yes, you got it.

Benjamin: And... we start with a false Statement, no?

Johnny: Yes, let's do that.

### First Statement skeleton:

Benjamin: Don't tell me anything, I'll try doing it myself.

Johnny: Sure, as you wish.

Benjamin: The first thing I need to do is to add an empty Specification for the TicketOffice class:

```csharp
public class TicketOfficeSpecification
{
    //TODO add a Statement
}
```

Then, I need to add my first Statement. I know that in this Statement, I need to create an instance of the `TicketOffice` class and call the `MakeReservation` method, since it's the only method in this class and it's not implemented.

Johnny: so what strategy do you use for starting with a false Statement?

Benjamin: "invoke method have one", as far as I remember.

Johnny: So what's the code going to look like?

Benjamin: for starters, I will do my brain dump just as you taught me. After stating all the bleedy obvious facts, I get:

```csharp
[Fact]
public void ShouldXXXXX() //TODO better name
{
  //WHEN
  var ticketOffice = new TicketOffice();

  //WHEN
  ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.True(false);
}
```

Johnny: Good... my... apprentice...

Benjamin: What?

Johnny: Oh, nevermind...  anyway, the code doesn't compile now, since this line:

```csharp
ticketOffice.MakeReservation(requestDto);
```

uses a variable `requestDto` that does not exist. Let's generate it using our IDE!

Benjamin: By the way, I wanted to ask about this line. Making it compile is something we need to do to move on. Weren't we supposed to add a `TODO` comment for things we need to get back to, like we did with the Statement name:

```csharp
public void ShouldXXXXX() //TODO better name
```

Johnny: My opinion is that this is not necessary, because the compiler, by failing on this line, has already creeated a TODO item for us, just not on our TODO list but on compile error log. This is different than the need to change a method name, which the compiler will not remind you about.

Benjamin: So my TODO list is composed of cmopile errors, test failures and the items I manually mark as `TODO`? Is this how I should understand it?

Johnny: Exactly. Going back to the `requestDto` variable, let's create it.

Benjamin: Sure. I came out like this:

```csharp
ReservationRequestDto requestDto;
```

We need to assign something to the variable.

Johnny: Yes, and since it's a DTO, it is certainly not going to be a mock.

Benjamin: You mean we don't mock DTOs?

Johnny: No, there's no need to. DTOs are, by definition, data structures. Later I will explain it in more details. For now, just accept my word on it.

Benjamin: Sooo... if it's not going to be a mock, then let's generate it using the `Any.Instance<>()` method.

Johnny: That is exactly what I would do.

Benjamin: So this line:

```csharp
ReservationRequestDto requestDto;
```

Becomes:

```csharp
var requestDto = Any.Instance<ReservationRequestDto>();
```

Johnny: Yes, and now the Statement compiles, so after everything compiles, our Statement seems to be false. This is because of this line:

```csharp
Assert.True(false);
```

Benjamin: so we change this `false` to `true` and we're done here, right?

Johnny: ...

Benjamin: Oh, seems I pulled a string there, didn't I? What I really wanted to say is let's turn this assertion into something useful.

Johnny: phew, don't scare me like that. Yes, this assertion needs to be rewritten. And it so happens that when we look at the following line:

```csharp
ticketOffice.MakeReservation(requestDto);
```

it doesn't make any use of the return value of `MakeReservation()` while it's evident from the signature that its return type is a `ReservationDto`:

```csharp
public ReservationDto MakeReservation(ReservationRequestDto requestDto)
```

but in our Statement, we don't do anything with it.

Benjamin: Ok, let me guess, you want me to assign this return value to a variable and then assert its equality to... what exactly?

Johnny: For now, to an expected value, which we don't know yet what's going to be, but we will worry later when it really blocks us.

Benjamin: Right. So here goes:

```csharp
[Fact]
public void ShouldXXXXX() //TODO better name
{
  //WHEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var ticketOffice = new TicketOffice();

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  //doesn't compile - we don't have expectedReservationDto yet:
  Assert.Equal(expectedReservation, reservationDto);
}
```

Benjamin: So please explain to me how did it get us any closer to our solution?

Johnny: Well, we transformed our problem from "what assertion to write" into "what is the reservation that we expect". This is indeed a step in the right direction.

Benjamin: Enlighten me then - what is the reservation that we expect?

Johnny: For now, the Statement is not compiling at all, so to go any step further, we can just introduce a `ReservationDto` as any value. Thus, we can just write in the `GIVEN` section:

```csharp
var expectedReservationDto = Any.Instance<ReservationDto>();
```

and it will make the following code compile:

```csharp
//THEN
Assert.Equal(expectedReservationDto, reservationDto);
```

Benjamin: But this assertion will fail anyway...

Johnny: That's still better than not compiling, isn't it?

Benjamin: Well, if you put it this way... Now our problem is that the expected value from in assertion is something the production code doesn't know about. This means that this assertion is not assertion the outcome of the behavior of production code. How do we solve this?

Johnny: This is where we need to exercise our design skills to introduce some new collaborators. This task is hard at the boundaries of application logic, since we need to draw the collaborators not from the domain, but rather think about a design pattern that will allow us to reach our goals. Every time we enter our application logic, we do so from a perspective of a use case. In this particular example, our use case is "making a reservation". A use case is typically represented by either a method in a facade[^FacadePattern] or a command object[^CommandPattern]. Commands are a bit more complex, but more scalable. If making a reservation was our only use case, it probably wouldn't make sense to use it. But as we already have more high priority requests for features, I believe we can assume that commands will be a better fit.

Benjamin: So you propose to use more complex solution - isn't that "big design up front"?

Johnny: I believe that it isn't. Remember I'm using just *a bit* more complex solution. The cost of implementation is only a bit higher as well as the cost of maintenance. If for some peculiar reason someone says tommorow that they don't need the rest of the features at all, the increase in complexity will be negligible taking into account the small size of the overall code base. If, however, we add more features, then using commands will save us some time in the longer run. Thus, given what I know, I am not adding this to support speculative new features, but to make the code easier to modify in the long run[^FowlerSimplicity]. I agree though that choosing just enough complexity for a given moment is a difficult task[^SandroMancussoDesign].

Benjamin: I still don't get it how introducing a command is going to help us here. Typically, a command has an `Execute()` method that typically doesn't return anything. How then will it give us the response that we need? And also, there's this another issue: how is this command going to be created? It will probably require the request passed as one of its constructor parameter, so we cannot pass the command to the `TicketOffice`'s constructor as the first time we can access the request is when the `MakeReservation()` method is invoked.

Johnny: Yes, you are right in both of your conclusions. Thankfully, when you choose to go with commands, typically there are standard solutions to the problems you mentioned. The commands are typically created using factories and they convey their results using a pattern called *collecting parameter*[^KerievskyCollectingParameter]. Let's start with the collecting parameter, which will represent a domain concept of a reservation in progress. What we currently know about it is that it's going to give a response DTO at the very end. All of the three objects: the command, the collecting parameter and the factory, are collaborators, so they will be mocks in our Statement.

Benjamin: Ok, lead the way.

Johnny: Allright, let's start with the `GIVEN` section. Here, we need to say that the collecting parameter mock, let's call it `reservationInProgress` will give us the `expectedReservationDto` (which is already defined in the body of the Statement) when asked:

```csharp
//GIVEN
//...
reservationInProgress.ToDto().Returns(expectedReservationDto);
```

Of course, we don't have this variable, so now we need to introduce it. As I explained earlier, this needs to be a mock:

```csharp
///GIVEN
var reservationInProgress = Substitute.For<ReservationInProgress>();
//...
reservationInProgress.ToDto().Returns(expectedReservationDto);
//...
```

Now, the Statement does not compile because the `ReservationInProgress` interface that I just used in the mock definition is not introduced yet.

Benjamin: In other words, you just discovered that you need this interface.

Johnny: Exactly. This forces me to introduce this interface into the code:

```csharp
public interface ReservationInProgress
{

}
```

Now, the Statement still doesn't compile, because there's this line:

```csharp
reservationInProgress.ToDto().Returns(expectedReservationDto);
```

which requires the `ReservationInProgress` to have a `ToDto()` method, but for now, this interface is empty. After adding the required method, it will look like this:

```csharp
public interface ReservationInProgress
{
  ReservationDto ToDto();
}
```

Benjamin: Ok, let me take a second to grasp the full Statement as it is now.

Johnny: Sure, take your time, this is how it currently looks like:

```csharp
[Fact]
public void ShouldXXXXX() //TODO better name
{
  //WHEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var ticketOffice = new TicketOffice();
  var reservationInProgress = Substitute.For<ReservationInProgress>();
  var expectedReservationDto = Any.Instance<ReservationDto>();

  reservationInProgress.ToDto().Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservation, reservationDto);
}
```

Benjamin: Ok, I think I caught up. So, can I take grab the keyboard for some time?

Johnny: I was about to suggest it. Here.

Benjamin: Thanks. Looking at this Statement, we have this `ReservationInProgress` all set up and created, but this mock of ours is not passed to the `TicketOffice` at all. So how should it use our pre-configured mock object?

Johnny: Remember our discussion about separating object use from creation?

Benjamin: Yeah, I guess I know what you're getting at. The `TicketOffice` should somehow get an already created object. It can get it e.g. through the constructor or from a factory.

Johnny: Yes, and if you look at the lifetime of a `TicketOffice`, which is created once at the start of the application, it can't really accept a `ReservationInProgress` through a constructor, because every time a new request is made, we have a new `ReservationInProgress`, so passing it through a `TicketOffice` constructor would force us to create a new `TicketOffice` every time as well. Thus, the solution that better fits our current situation is...

Benjamin: A factory, right? You're suggesting that instead of passing a `ReservationInProgress` through a constructor, we should rather pass something that knows how to create `ReservationInProgress` instances?

Johnny: Exactly.

Benjamin: Ok, so how to write it in the Statement?

Johnny: First write what you really need. The factory is going to be a mock, because we need to configure it so that when asked, it returns our `ReservationInProgress` mock. So let's write that configuration first, pretending we already have the factory available in our Statement body.

Benjamin: Let me see... right, that should do it:

```csharp
//GIVEN
...
reservationInProgressFactory.FreshInstance().Returns(reservationInProgress);
```

Johnny: Nice, the code does not compile, because we don't have a `reservationInProgressFactory`. So let's create it.

Benjamin: And it should be a mock, just like you said earlier. Then this will be the definition:

```csharp
var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
```

and, let me guess, you want me to introduce the `ReservationInProgressFactory` as we don't currently have anything like that?

Johnny: (smiles)

Benjamin: All right.

```csharp
public interface ReservationInProgressRepository
{

}
```

Benjamin: and now, the compiler tells us that we don't have the `FreshInstance()` method, so let me introduce it:

```csharp
public interface ReservationInProgressRepository
{
    ReservationInProgress FreshInstance();
}
```

Benjamin: Good, the code compiles, but the Statement fails with a `NotImplementedException`.

Johnny: Yes, this is because the current body of the `MakeReservation()` method of the  `TicketOffice` class looks like this:

```csharp
public ReservationDto MakeReservation(ReservationRequestDto requestDto) 
{
  throw new NotImplementedException("Not implemented");
}
```

Benjamin: So should we implement this now?

Johnny: We could, however, let's take care of the things we still have to do in the Statement.

Benjamin: Like..?

Johnny: For example, the `ReservationInProgressFactory` mock is not passed to the `TicketOffice` constructor so there is no way for the ticket office to use this factory.

Benjamin: Ok, so I'll add it. The Statement will change like this:

```csharp
var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
var ticketOffice = new TicketOffice(reservationInProgressFactory);
```

and a constructor will need to be added to the `TicketOffice` class:

```csharp
public TicketOffice(ReservationInProgressFactory reservationInProgressFactory)
{

}
```

Johnny: Agree. And, we need to maintain the composition root which just stopped compiling. This is because the constructor of a `TicketOffice` is invoked there and it needs uptading as well:

```csharp
public class Application
{
  public static void Main(string[] args)
  {
    new WebApp(
        new TicketOffice() //compile error!
    ).Host();
  }
}
```

Benjamin: But what should we pass? We have an interface, but no class of which we could create an object.

Johnny: We can think about something now, but if we don't want to, we can call it e.g. `TodoReservationInProgressFactory` and leave a TODO comment to get back to it later. For now, we just need this to compile.

Benjamin: So maybe we could pass a `null`?

Johnny: We could, but that's not my favourite option. I typically just create the class.

Benjamin: Ok, so this line:

```csharp
new TicketOffice() //compile error!
```

becomes:

```csharp
new TicketOffice(
    new TodoReservationInProgressFactory()) //TODO change the name
```

And it doesn't compile, because we need to create this class so let me do it:

```csharp
public class TodoReservationInProgressFactory : ReservationInProgressFactory
{
}
```

Johnny: It still doesn't compile, because the interface `ReservationInProgressFactory` has some methods that we need to implement. Thankfully, we can do this with a single IDE command and get:


```csharp
public class TodoReservationInProgressFactory : ReservationInProgressFactory
{
    public ReservationInProgress FreshInstance()
    {
        throw new NotImplementedException();
    }
}
```

We could already assign the constructor parameter to a field, but it's also OK to do it later. Anyway, it seems we are missing one more expectation in our `THEN` section. if you look at the Statement full body as it is now:

```csharp
[Fact]
public void ShouldXXXXX() //TODO better name
{
  //WHEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
  var ticketOffice = new TicketOffice(reservationInProgressFactory);
  var reservationInProgress = Substitute.For<ReservationInProgress>();
  var expectedReservationDto = Any.Instance<ReservationDto>();

  reservationInProgressFactory.FreshInstance().Returns(reservationInProgress);
  reservationInProgress.ToDto().Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservation, reservationDto);
}
```

the only way the `TicketOffice` interacts with the `ReservationInProgress` is by calling the `ToDto` method. So the question that we need to ask ourselves now is "how will the instance of `ReservationInProgress` know what `ReservationDto` to create?".

Benjamin: Oh right... the `ReservationDto` needs to be created based on the current application state and the data in the `ReservationRequestDto`, but the `ReservationInProgress` knows nothing about this data so far.

Johnny: Yes, filling the `ReservationInProgress` is one of the responsibilities of the application we are writing. If we did it all in thie `TicketOffice` class, it would surely have too much to handle and our Statement would grow immensely. So we need to push the responsibility of handling our use case further to other collaborating objects and use mocks for those objects here.

Benjamin: So what do you propose?

Johnny: Usually, when I push use case-related logic to another object, I pick from among the Facade pattern and the Command pattern. Fadaces are simpler but less scalable, while commands are way more scalable and composable but a new command needs to be created each time a use case is triggered.

Benjamin: So shall we go with Facade?

Johnny: Well, let's go with Command, just to show you how it can be done. I am sure you could figure out the Facade option by yourself.

Benjamin: Ok, so what do I type?

Johnny: Well, let's assume we have this command and then let's think about what we want our `TicketOffice` to do with it.

Benjamin: We want the `TicketOffice` to execute the command, obviously..?

Johnny: Right, let's write this in form of expectation.

Benjamin: Ok, I'd write something like this:

```csharp
reservationCommand.Received(1).Execute(reservationInProgress);
```

I already passed the `reservationInProgress` as the command will need to fill it.

Johnny: Wait, it so happens that I know a better way to pass this `reservationInProgress` then to the `Execute()` method. Please for now make this method parameterless.

Benjamin: Ok, as you wish, but I thought this would be a good place to pass it.

Johnny: It might look like this, but typically, I want my commands to have parameterless execution methods. This way I can compose them more freely.

Benjamin: Ok, so I removed the parameter and the `THEN` section looks like this:

```csharp
//THEN
reservationCommand.Received(1).Execute(reservationInProgress);
Assert.Equal(expectedReservation, reservationDto);
```

Benjamin: and it doesn't compile of course. So I already know I need to introduce a variable of a type that I have to pretend already exists. Aaaand, I already know it should be a mock, since I verify that it received a call to its `Execute()` method.

Johnny: (nods)

Benjamin: In the `GIVEN` section, I'll add the `reservationCommand` as a mock:

```csharp
var reservationCommand = Substitute.For<ReservationCommand>();
```

Johnny: Sure, now we need to figure out how to pass this command to the `TicketOffice`. By nature, a command object represents, well, an issued command, so it cannot be created once in the composition root and then passed to the constrructor, because then: 

1. it would essentially become a facade, 
1. we would need to pass the `reservationInProgress` to the `Execute()` method which we wanted to avoid.

Benjamin: Wait, don't tell me... you want to add another factory here?

Johnny: Yes, that's what I would like to do.

Benjamin: But... that's a second factory in a single Statement. Aren't we, like, overdoing it a little?

Johnny: I understand why you feel that way. Still, this is a consequence of my design choice. We wouldn't need a factory if we went with a facade. In simple apps, I just use a facade and do away with this dilemma. I could also drop the use of collecting parameter patern and then I would only have a factory for commands, but that would mean I would not resolve the command-query separation principle violation and would need to push it further. And, if I used a facade without a collecting parameter, then I would not need any factory at all. To cheer you up, this is an entry point for a use case where we need to wrap some things in abstractions, so I don't expect this many factories in the rest of the code. I treat this part as a sort of anti-corruption layer which protects me from everything imposed by outside of my application logic which I don't want to deal with inside of my application logic.

Benjamin: I will need to trust you on that. I hope it will make things easier later because for now... ugh...

Johnny: Let's introduce the factory. Of course, before we define it, we need to use it to feel a need for it. This code needs to go into the `GIVEN` section:

```csharp
//GIVEN
...
commandFactory.CreateReservationCommand(requestDto)
    .Returns(reservationCommand);
```

This doesn't compile because we have no commandFactory yet.

Benjamin: Oh, I can see that the factory's `CreateReservationCommand()` is where you decided to pass the DTO. Clever. By leaving the commands's `Execute()` method parameterless, you made it more abstract and made the interface decpoupled from a particular DTO. On the other hand, the command is created in the same scope it is used, so there is literally no issue with passing all the parameters through the factory method.

Johnny: That's right. We now know we need a factory, plus that it needs to be a mock, since we configure it to return something when it is used. I propose something like this:

```csharp
//GIVEN
...
var commandFactory = Substitute.For<CommandFactory>();
...
commandFactory.CreateReservationCommand(requestDto)
    .Returns(reservationCommand);
```

Benjamin: ...and the `CommandFactory` doesn't exist, so let's create it:

```csharp
public interface CommandFactory
{

}
```

and let's add the missing `CreateReservationCommand` method:

```csharp
public interface CommandFactory
{
  ReservationCommand CreateReservationCommand(ReservationRequestDto requestDto);
}
```

Benjamin: Now the code compiles and looks like this:

```csharp
[Fact]
public void ShouldXXXXX() //TODO better name
{
  //WHEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var commandFactory = Substitute.For<CommandFactory>();
  var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
  var ticketOffice = new TicketOffice(reservationInProgressFactory);
  var reservationInProgress = Substitute.For<ReservationInProgress>();
  var expectedReservationDto = Any.Instance<ReservationDto>();
  var reservationCommand = Substitute.For<ReservationCommand>();
  
  commandFactory.CreateReservationCommand(requestDto)
    .Returns(reservationCommand);
  reservationInProgressFactory.FreshInstance().Returns(reservationInProgress);
  reservationInProgress.ToDto().Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservation, reservationDto);
  reservationCommand.Received(1).Execute(reservationInProgress);
}
```

Benjamin: and I see one more problem - the command factory is not passed anywhere from the Statement - the production code doesn't know about it.

Johnny: Yes, and, lucky us, a factory is something that can have the same lifetime as the `TicketOffice` since just to create it, we don't need to know anything about a request for booking. This is why we can pass it through the constructor of `TicketOffice`. Which means that these two lines:

```csharp
var commandFactory = Substitute.For<CommandFactory>();
var ticketOffice = new TicketOffice(reservationInProgressFactory);
```

will now look like this:

```csharp
var commandFactory = Substitute.For<CommandFactory>();
var ticketOffice = new TicketOffice(
    reservationInProgressFactory, commandFactory);
```

Johnny: As this doesn't compile, we need to add this parameter to the constructor, preferably with our IDE:

```csharp
public TicketOffice(
    ReservationInProgressFactory reservationInProgressFactory, 
    CommandFactory commandFactory)
{

}
```

and, this makes us add a parameter to our composition root. So this part:

```csharp
new TicketOffice(
    new TodoReservationInProgressFactory()) //TODO change the name
```

Becomes:

```csharp
new TicketOffice(
    new TodoReservationInProgressFactory(), //TODO change the name
    new TicketOfficeCommandFactory())
```

which forces us to create the `TicketOfficeCommandFactory` class:

```csharp
public class TicketOfficeCommandFactory : CommandFactory
{
  ReservationCommand CreateReservationCommand(ReservationRequestDto requestDto)
  {
      throw new NotImplementedException();
  }
}
```

Benjamin: Hey, this time you gave the class a better name than the previous factory which was called `TodoReservationInProgressFactory`. Why didn't you want to leave it for later this time?

Johnny: This time, I think I have a good idea on how to name this class. Typically, I name concrete classes based on something from their implementation and I find the names hard to find when I don't have this implementation yet. This time I believe I have a name that can last a bit, which is also why I didn't leave a TODO comment next to this name. Still, further work can invalidate my naming and I will be happy to change the name when need arises.

Anyway, getting back to the Statement, I think we've got it all covered. Let's just give the Statement a good name. Looking at the assertions:

```csharp
reservationCommand.Received(1).Execute(reservationInProgress);
Assert.Equal(expectedReservation, reservationDto);
```

I think we can say:

```csharp
public void 
ShouldExecuteReservationCommandAndReturnResponseWhenMakingReservation()
```

Benjamin: Just curious... Didn't you tell me to watch out for the "and" word in Statement names and that it may suggest something it wrong with the scenario.

Johnny: Yes, and in this particular case, there *is* something wrong - the class `TicketOffice` violates the command-query separation principle. This is also why the Statement looks so messy. For this class, however, we don't have a choice since our framework requires this kind of signature. That's also why we are working so hard in this class to introduce the collecting parameter and protect the rest of the design from the violation.

Benjamin: Ok, I hope the future Statements will be easier to write than this one.

Johnny: Me too. Let's take a look at the Statement code as it is now:

```csharp
[Fact] public void 
ShouldExecuteReservationCommandAndReturnResponseWhenMakingReservation()
{
  //GIVEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var commandFactory = Substitute.For<CommandFactory>();
  var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
  var ticketOffice = new TicketOffice(reservationInProgressFactory);
  var reservationInProgress = Substitute.For<ReservationInProgress>();
  var expectedReservationDto = Any.Instance<ReservationDto>();
  var reservationCommand = Substitute.For<ReservationCommand>();
  
  commandFactory.CreateReservationCommand(requestDto)
    .Returns(reservationCommand);
  reservationInProgressFactory.FreshInstance()
    .Returns(reservationInProgress);
  reservationInProgress.ToDto()
    .Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservation, reservationDto);
  reservationCommand.Received(1).Execute(reservationInProgress);
}
```

Johnny: I think it is complete, but we won't know that until we see the assertions failing and then passing. For now, the implementation of `MakeReservation()` method throws an exception and this exception makes our Statement stop at the `WHEN` stage, not even getting to the assertions.

Benjamin: But I cannot just put the right implementation in yet, right? This is what you used to tell me.

Johnny: Yes, ideally, we should see the assertion errors to gain confidence that the Statement *can* turn false when the expected behavior is not in place.

Benjamin: This can only mean one thing - return `null` from the `TicketOffice` instead of throwing the exception. Right?

Johnny: Yes, let me do it, my hands are getting rusty. I'll just change this code:

```csharp
public ReservationDto MakeReservation(ReservationRequestDto requestDto)
{
  throw new NotImplementedException("Not implemented");
}
```

to:

```csharp
public ReservationDto MakeReservation(ReservationRequestDto requestDto) 
{
  return null;
}
```

Johnny: Now I can see that the first assertion:

```csharp
Assert.Equal(expectedReservation, reservationDto);
```

is failing, because it expects something from the `ReservationInProgress` which can only be received from the factory. Let's just implement the part that is required to pass the first assertion. To do this, I will need to create a field in the `TicketOffice` class based on one of the constructor parameters. So this code:

```csharp
public TicketOffice(
    ReservationInProgressFactory reservationInProgressFactory, 
    CommandFactory commandFactory)
{

}
```

Becomes:

```csharp
private readonly ReservationInProgressFactory _reservationInProgressFactory;

public TicketOffice(
    ReservationInProgressFactory reservationInProgressFactory,
    CommandFactory commandFactory)
{
  _reservationInProgressFactory = reservationInProgressFactory;
}
```

Benjamin: Couldn't you just introduce the other field as well?

Johnny: Yes, I could and I usually do that. But since we are training, I want to show you that we will be forced to do so anyway to make the second assertion pass.

Benjamin: Ok, go on.

Johnny: Now I have to modify the `MakeReservation()` method by adding the following code that creates the reservation in progress and makes it return a DTO:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
return reservationInProgress.ToDto();
```

Benjamin: ...and the first assertion passes.

Johnny: Yes, and this is clearly not enough. If you look at the production code, we are not doing anything with the `ReservationRequestDto` instance. Thankfully, we have the second assertion:

```csharp
reservationCommand.Received(1).Execute(reservationInProgress);
```

and this one fails. In order to make it pass, We need to create a command and execute it.

Benjamin: Let me do this. So to create a command, we need the command factory and this is why at this moment, we need to introduce the second `TicketOffice` constructor argument, because as of now, the constructor looks like this:

```csharp
public TicketOffice(
    ReservationInProgressFactory reservationInProgressFactory, 
    CommandFactory commandFactory)
{
  _reservationInProgressFactory = reservationInProgressFactory;
}
```

And I need to modify this code to assign the constructor parameter to the field:

```csharp
public TicketOffice(
    ReservationInProgressFactory reservationInProgressFactory, 
    CommandFactory commandFactory)
{
  _reservationInProgressFactory = reservationInProgressFactory;
  _commandFactory = commandFactory;
}
```

and now I can use the factory in the `MakeReservation()` method and pass the request DTO inside:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateReservationCommand(requestDto);
return reservationInProgress.ToDto();
```

At last, I just need to execute the command like this:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateReservationCommand(requestDto);
reservationCommand.Execute(reservationInProgress);
return reservationInProgress.ToDto();
```


[^POEAA]: Patterns of enterprise application architecture, M. Fowler.
[^FowlerSimplicity]: TODO Martin Fowler on the YAGNI
[^SandorMancussoDesign]: TODO Sando Mancusso on design approaches.