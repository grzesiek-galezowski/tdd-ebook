
## Initial objects

TODO remember to describe how a TODO list changes!!!

Notes:

1. Johnny is a super programmer, who never makes mistakes
2. No story slicing
3. No refactoring
4. No higher level tests
4. ..?

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

Ticket office class:

```csharp
public class TicketOffice
{
    public ReservationDto MakeReservation(ReservationRequestDto requestDto) 
    {
        throw new NotImplementedException("Not implemented");
    }
}
```

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
reservationInProgress.ToDto().Returns(reservationDto);
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

Benjamin: Good, the code compiles, and... the Statement is now reported as true! Does it mean we're finished with this one?

Johnny: No, it seems we are missing one more expectation in our `THEN` section. if you look at the Statement full body as it is now:

```csharp
[Fact]
public void ShouldXXXXX() //TODO better name
{
  //WHEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var ticketOffice = new TicketOffice();
  var reservationInProgress = Substitute.For<ReservationInProgress>();
  var expectedReservationDto = Any.Instance<ReservationDto>();
  var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();

  reservationInProgressFactory.FreshInstance().Returns(reservationInProgress);
  reservationInProgress.ToDto().Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservation, reservationDto);
}
```

the only way the `TicketOffice` interacts with the `ReservationInProgress` is by calling the `ToDto` method. So the question that we need to ask ourselves now is "how will the instance of `ReservationInProgress` know what `ReservationDto` to create?".

Benjamin: Oh right... the `ReservationDto` needs to be created based on the current application state and the data in the `ReservationRequestDto`, but the `ReservationInProgress` knows nothing about this data.










//TODO TODO TODO TODO 

In other words,  which, in turn, forces us to introduce an interface called `ReservationInProgress`.

//TODO TODO
//TODO order of calls
//todo exposing ToDto()

Now, we need to somehow let `TicketOffice` know that it should use our `reservationInProgress`. We cannot pass it as a constructor parameter to the `TicketOffice`, as the lifetime of a reservation is the same as the request, but `TicketOffice` lives longer - we don't create a new `TicketOffice` for each request. Thus, we need to pass a factory that will create an empty reservation in progress for us:



//TODO with outside in, no such speculation!!!




//TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 

But who is going to return the ticket DTO? (BTW, what is a DTO?)

### Who will give us a ticket DTO?
 
Let's have a ticket convertible to dto (btw, how to hide this toDto method?)

```csharp 
    //WHEN
    var ticketOffice = new TicketOffice();
    var reservation = Any.Instance<ReservationRequestDto>();
+   var resultDto = Any.Instance<TicketDto>();
+
+   ticket.ToDto().Returns(resultDto);
+
```

This leads to discovery of `Ticket` interface and `ToDto()` method.

```csharp
+        Ticket ticket = Substitute.For<Ticket>();
 
         ticket.ToDto().Returns(resultDto);
```

And this needs to be represented in code (btw, are the rest of the objects shown implemented?)

```csharp
+public interface Ticket
+{
+}

```

Introducing toDto method. But how to pass the Ticket?

```csharp
public interface Ticket
{
+ TicketDto toDto();
}
```

//TODO this will be renamed to TicketInProgress

Ticket will come from factory - factories don't use tell don't ask. Also, ToDto() also returns a value - because we need to cope with an API that violates CQS. Not much OO, is it?

TicketOfficeSpecification.java:

```csharp
+   ticketFactory.CreateBlankTicket().Returns(ticket);
    ticket.ToDto().Returns(resultDto);

//WHEN
```

The Statement shows that we need a factory, so let's introduce it in the Statement first. Name: TicketFactory collaborator.

TicketOfficeSpecification.java

```csharp
+   var ticketFactory = Substitute.For<TicketFactory>());

    ticketFactory.CreateBlankTicket().Returns(ticket);
```

The interface does not exist yet, let's create it:

+++ b/Java/src/main/java/logic/TicketFactory.java

```csharp
public interface TicketFactory
{
  Ticket CreateBlankTicket();
}
```

Time for assertions - what do we expect? Johnny uses his experience to pull a command - because we want to get out of CQS violation. Typically we can do two things - either use a command or a facade. For now mistakenly assuming that the command will take a parameter.

TicketOfficeSpecification.java

```csharp
  //THEN
+ bookCommand.Received(1).Execute(ticket);
  Assert.Equal(resultDto, ticketDto);
}
```

Interesting thing is that having both an assertion and a mock verification means we violate CQS. We want to avoid it, but sometimes 3rd party APIs require that.

Also, `Ticket` is an example of collecting parameter pattern. Probably `TicketInProgress` would be a better name.

We know that we need a command, so let's introduce it in the Statement in the GIVEN section.

TicketOfficeSpecification.java

```csharp
M var ticket = Substitute.For<TicketInProgress>();
+ var bookCommand = Sustitute.For<Command>();

  var ticketFactory = Substitute.For<TicketFactory>();
  ticketFactory.CreateBlankTicket().Returns(ticket);
```

Command.java

```csharp
+public interface Command
+{
+}
```

Also, this method goes inside the `Command` (already used in the Statement):

```csharp
 public interface Command {
+    void Execute(TicketInProgress ticket);
 }
 ```

`TicketOffice` needs to know about the command - how will it get it? I decide a command factory will wrap dto with a command (GIVEN section).

TicketOfficeSpecification.java

```csharp
+ commandFactory.CreateBookCommand(reservation)
+   .Returns(bookCommand);

  //WHEN
  var ticketDto = ticketOffice.MakeReservation(reservation);
```

Introducing the factory declaration.

```csharp
public class TicketOfficeSpecification {
+        var commandFactory = Substitute.For<CommandFactory>();
         commandFactory.CreateBookCommand(reservation)
             .Returns(bookCommand);
```

it means we need an interface:

CommandFactory.java

```csharp
public interface CommandFactory
{
  Command CreateBookCommand(ReservationRequestDto reservation);
}
```

Now how should a ticket office get to know it? We can just pass the factory to the constructor, since it does not need anything from the request during its construction time. (since its creation is not dependent on local scope).

TicketOfficeSpecification.java

Something's wrong here. Some of these lines were already added:

```csharp
+   var commandFactory = Substitute.For<CommandFactory>();
-   var ticketOffice = new TicketOffice();
+   var ticketOffice = new TicketOffice(commandFactory);
    //...
-   TicketInProgress ticket = Substitute.For<TicketInProgress>();
+   var ticket = Substitute.For<TicketInProgress>();
    var bookCommand = Substitute.For<Command>();
    var ticketFactory = Substitute.For<TicketFactory>();

    ticket.ToDto().Returns(resultDto);
-   var commandFactory = Substitute.For<CommandFactory>();
    commandFactory.CreateBookCommand(reservation).Returns(bookCommand);
``` 

And generating the constructor from the usage:

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
 public class TicketOffice 
 {
+  public TicketOffice(CommandFactory commandFactory)
+  {
+    throw new NotImplementedException("TODO");
+  }
```

Composition root:

+++ b/Java/src/main/java/bootstrap/Main.java

```csharp
 public class Main {

     public static void main(String[] args) {
-        new TicketOffice();
+        new TicketOffice(new BookingCommandFactory() /* new class - include body or null */);
     }
 }
```

I noticed I can pass the ticket to factory and have the command as something more generic with a void Execute() method. I remove this via refactoring move:

```csharp 
 public interface Command 
 {
-  void Execute(Ticket ticket);
+  void Execute();
 }
```

and it disappears from the test as well:

+++ b/Java/src/test/java/TicketOfficeSpecification.java

```csharp
- commandFactory.CreateBookCommand(reservation)
+ commandFactory.CreateBookCommand(reservation, ticket)
      .Returns(bookCommand);

  //...

  //THEN
- bookCommand.Received(1).Execute(ticket);
+ bookCommand.Received(1).Execute();
```

And now I am adding it to the `CreateBookCommand()` method of the factory:

diff --git a/Java/src/main/java/logic/CommandFactory.java 
 
```csharp
 public interface CommandFactory
 {
-  Command CreateBookCommand(ReservationRequestDto reservation);
+  Command CreateBookCommand(
+    ReservationRequestDto reservation,
+    TicketInProgress ticket);
 }
```

TicketOffice should know ticket factory. Adding it to the test:

+++ b/Java/src/test/java/TicketOfficeSpecification.java

```csharp
var ticketOffice = new TicketOffice(
   commandFactory,
+   ticketFactory);
```

and through a quick fix - to the production code.

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
 public class TicketOffice
 {
+  private CommandFactory commandFactory;
+  private TicketFactory ticketFactory;

-  public TicketOffice(CommandFactory commandFactory)
+  public TicketOffice(
+        CommandFactory commandFactory,
+        TicketFactory ticketFactory)
   {
-     //todo implement
+    this.commandFactory = commandFactory;
+    this.ticketFactory = ticketFactory;
   }
```

+++ b/Java/src/main/java/bootstrap/Main.java

```csharp
 public class Main {

     public static void main(String[] args) {
-        new TicketOffice();
+        new TicketOffice(new BookingCommandFactory(),
+            new TrainTicketFactory()); //TODO new class, or null
     }
 
 }
```

Returning whatever to make sure we fail for the right reason:

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
  public TicketDto MakeReservation(ReservationRequestDto request)
  {
-   throw new NotImplementedException();
+   return new TicketDto(null, null, null);
  }
```

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
 public class TicketOffice {
 
    //...

    public TicketDto MakeReservation(ReservationRequestDto request)
    {
+       var ticket = ticketFactory.CreateBlankTicket();
+       var command = commandFactory.CreateBookCommand(request, ticket);
+       command.Execute();
        return new TicketDto(null, null, null);
    }
```

We can remove TODOs? Btw, what about TODO list?
Passed the first assertion but the second one still fails (look at the error message, Luke).
Now we need to make the second assertion pass:

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
         var ticket = ticketFactory.CreateBlankTicket();
         var command = commandFactory.CreateBookCommand(request, ticket);
         command.Execute();
-        return new TicketDto(null, null, null);
+        return ticket.toDto();
     }
```

Passed the second assertion, test green. What about the order of invocations?
Can we alter it to make it invalid? No, creation comes before usage, usage goes before returning value, return comes last.

the empty implementations adds to TODO list.  I need to pick one item to work on. I choose to implement booking command????


+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
+public class BookingCommandFactory : CommandFactory {
+    
+    public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) 
+    {
+        //todo implement
+        return null;
+    }
+}
```

+++ b/Java/src/main/java/logic/TrainTicketFactory.java

```csharp
+public class TrainTicketFactory : TicketFactory 
+{
+    
+    public TicketInProgress CreateBlankTicket()
+    {
+        //todo implement
+        return null;
+    }
+}
```

Date:   Wed Feb 28 16:40:33 2018 +0100

    I pick the factory as there is not much I can do with Ticket yet
    I pick command factory as there is not much I can do with tickets

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
+public class BookingCommandFactorySpecification {
+
+}
```

writing a failing test for a type and dependencies:

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
 public class BookingCommandFactorySpecification {
+    [Fact]
+    public void ShouldCreateBookTicketCommand() {
+        //GIVEN
+        var bookingCommandFactory = new BookingCommandFactory();
+        var reservation = Substitute.For<ReservationRequestDto>();
+        var ticket = Substitute.For<Ticket>();
+
+        //WHEN
+        Command result = bookingCommandFactory.CreateBookCommand(reservation, ticket);
 
+        //THEN
+        assertThat(result).isInstanceOf(BookTicketCommand.class);
+        assertThat(result).has(dependencyOn(reservation));
+        assertThat(result).has(dependencyOn(ticket));
+    }
 }
```

This demands new implementation:

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp
+public class BookTicketCommand {
+}
```

Returning book ticket command forced interface implementation (can be applied via a quick fix)

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
  public Command CreateBookCommand(
    ReservationRequestDto reservation, TicketInProgress ticket)
  {
-   //todo implement
-   return null;
+   return new BookTicketCommand();
  }
```

The above does not compile yet as the `BookTicketCommand` does not implement a `Command` interface. Need to add it (can be done via quick fix):

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp
-public class BookTicketCommand
+public class BookTicketCommand : Command
+{
+
+    public void Execute()
+    {
+        //todo implement
+    }
 }
```

Made 2nd assertion pass by introducing field for dto. The 3rd assertion still fails:

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
 public class BookingCommandFactory : CommandFactory {
     
    public Command CreateBookCommand(
       ReservationRequestDto reservation,
        TicketInProgress ticket) 
    {
-       return new BookTicketCommand();
+       return new BookTicketCommand(reservation, ticket);
    }
 }
```

Generating the constructor:

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp
 public class BookTicketCommand : Command {
+    private ReservationRequestDto reservation;
+    private Ticket ticket;
 
+    public BookTicketCommand(ReservationRequestDto reservation, Ticket ticket) {
+        this.reservation = reservation;
+        this.ticket = ticket;
+    }
```


(Question: why could we do so many steps? Should we not generate the constructor first and assign the field only when the test fails for the right reason? Probably no, since we already saw it failing for the right reason...)

The test now passes. New items on TODO list (e.g. Execute() method)


(btw, mention here that I tried to specify BookCommand and failed)

/////////////////////////////////???

Discovered TrainRepository interface, because the command will need to get the train from somewhere. Adding it to the test:

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
@@ -12,10 +12,12 @@ public class BookingCommandFactorySpecification {
     [Fact]
     public void ShouldCreateBookTicketCommand() {
         //GIVEN
-        var bookingCommandFactory = new BookingCommandFactory();
+        var trainRepo = Substitute.For<TrainRepository>();
+        var bookingCommandFactory = new BookingCommandFactory(
+            trainRepo
+        );
         var reservation = Substitute.For<ReservationRequestDto>();
         var ticket = Substitute.For<Ticket>();
-
         //WHEN
         Command result = bookingCommandFactory
             .CreateBookCommand(reservation, ticket);
```

And the class constructor:

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
 public class BookingCommandFactory : CommandFactory {
+  public BookingCommandFactory(TrainRepository trainRepo) {
+      //todo implement
+  }
+

   public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) {
       return new BookTicketCommand(reservation, ticket);
```

Thus i have discovered a train repository:

+++ b/Java/src/main/java/logic/TrainRepository.java

```csharp
+public interface TrainRepository 
+{
+}
```

(btw, shouldn't I have started with the command? I already have the factory and the command concrete type...)

Discovered train collaborator and getBy repo method. Now what type should the train variable be?

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
public class BookingCommandFactorySpecification 
{
    //...
         );
         var reservation = Substitute.For<ReservationRequestDto>();
         var ticket = Substitute.For<TicketInProgress>();
+
+        trainRepo.GetTrainBy(reservation.trainId)
+            .Returns(train);
+
         //WHEN
         Command result = bookingCommandFactory
             .CreateBookCommand(reservation, ticket);

@@ -26,5 +31,7 @@
         assertThat(result).isInstanceOf(BookTicketCommand.class);
         assertThat(result).has(dependencyOn(reservation));
         assertThat(result).has(dependencyOn(ticket));
+        assertThat(result).has(dependencyOn(ticket));
+        assertThat(result).has(dependencyOn(train));
     }
 }
```

Discovered a Train interface

First in test:

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
@@ -19,6 +19,7 @@ public class BookingCommandFactorySpecification 
{
         );
         var reservation = Substitute.For<ReservationRequestDto>();
         var ticket = Substitute.For<Ticket>();
+        var train = Substitute.For<Train>();
 
         trainRepo.GetTrainBy(reservation.trainId)
             .Returns(train);
```

And introduced using the IDE:

+++ b/Java/src/main/java/logic/Train.java

```csharp
+public interface Train
+{
+}
```

Discovered `GetTrainBy`:

+++ b/Java/src/main/java/logic/TrainRepository.java

```csharp
 public interface TrainRepository {
+    Train GetTrainBy(String trainId);
 }
```

Discovered CouchDbTrainRepository. The TODO list grows

+++ b/Java/src/main/java/bootstrap/Main.java

```csharp
 public class Main 
 {
 
     public static void Main(string[] args)
     {
-        new TicketOffice(new BookingCommandFactory(),
+        new TicketOffice(new BookingCommandFactory(
+            new CouchDbTrainRepository()
+        ),  new TrainTicketFactory());
     }
```



+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

We won't be implementing it here... Just call the constructor later.

```csharp
+public class CouchDbTrainRepository : TrainRepository
+{
+    public Train GetTrainBy(String trainId)
+    {
+        //todo implement
+        return null;
+    }
+}
```


Date:   Thu Mar 1 16:21:38 2018 +0100

    Made the last assertion from the factory test pass
    (one more backtracking will be needed)


Adding the dependencies to the factory:

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
 public class BookingCommandFactory : CommandFactory {
-    public BookingCommandFactory(TrainRepository trainRepo) {
-        //todo implement
+    private TrainRepository trainRepo;
 
+    public BookingCommandFactory(TrainRepository trainRepo) {
+        this.trainRepo = trainRepo;
     }
 
     
     public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        return new BookTicketCommand(reservation, ticket);
+        return new BookTicketCommand(
+            reservation,
+            ticket, trainRepo.GetTrainBy(reservation.trainId));
     }
 }
```

and the command created with that factory:

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp
 public class BookTicketCommand : Command {
     private ReservationRequestDto reservation;
     private Ticket ticket;
+    private Train trainBy;
 
-    public BookTicketCommand(ReservationRequestDto reservation, Ticket ticket) {
+    public BookTicketCommand(
+        ReservationRequestDto reservation,
+        Ticket ticket,
+        Train train) {
         this.reservation = reservation;
         this.ticket = ticket;
+        this.trainBy = train;
     }
```

As my next step, I choose BookTicketCommand

I prefer it over TicketFactory as it will allow me to learn more about the TicketInProgress interface. So now I am optimizing for learning.

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
+public class BookTicketCommandSpecification
+{
+
+}
```

I have yet to discover what behavior I will require from the command

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
+public class BookTicketCommandSpecification {
+    [Fact]
+    public void ShouldXXXXXXXXXXXXX()
+    {
+        //GIVEN
+
+        //WHEN
 
+        //THEN
+        assertThat(1).isEqualTo(2);
+    }
+}
```
Starting command test
brain dump - just invoke the only existing method

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
@@ -9,8 +10,10 @@ public class BookTicketCommandSpecification 
{
     [Fact]
     public void ShouldXXXXXXXXXXXXX() 
     {
         //GIVEN
-
+        var bookTicketCommand
+            = new BookTicketCommand(reservation, ticket, train);
         //WHEN
+        bookTicketCommand.Execute();
 
         //THEN
         assertThat(1).isEqualTo(2);
```

Introducing collaborators and stating expectations

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp 
 public class BookTicketCommandSpecification 
 {
 
     [Fact]
     public void ShouldXXXXXXXXXXXXX() 
     {
         //GIVEN
+        var reservation = Any.Instance<ReservationRequestDto>();
+        var ticket = Any.Instance<Ticket>();
+        var train = Substitute.For<Train>();
         var bookTicketCommand
             = new BookTicketCommand(reservation, ticket, train);
         //WHEN
         bookTicketCommand.Execute();
 
         //THEN
-        assertThat(1).isEqualTo(2);
+        train.Received(1).Reserve(reservation.seatCount, ticket);
     }
 }
```

The test used a non-existing `Recerve` method - time to introduce it now.

+++ b/Java/src/main/java/logic/Train.java

```csharp
 public interface Train {
+    void Reserve(uint seatCount, TicketInProgress ticketToFill);
 }
```

Implementation to pass the test:

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp
 public class BookTicketCommand : Command {
     private ReservationRequestDto reservation;
     private Ticket ticket;
-    private Train trainBy;
+    private Train train;
 
     public BookTicketCommand(
         ReservationRequestDto reservation,
@@ -13,12 +13,12 @@ public class BookTicketCommand : Command {
         Train train) {
         this.reservation = reservation;
         this.ticket = ticket;
-        this.trainBy = train;
+        this.train = train;
     }
 
     
     public void Execute() {
-        //todo implement
-
+        //todo a full DTO is not required
+        train.Reserve(reservation.seatCount, ticket);
     }
}
```

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

Date:   Mon Mar 5 08:14:42 2018 +0100

Made dummy implementation of TrainWithCoaches. We're not test-driving this - Benjamin will go for coffee.

+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

```csharp
 public class CouchDbTrainRepository : TrainRepository {

     public Train GetTrainBy(String trainId) {
-        //todo implement
-        return null;
+        return new TrainWithCoaches();
     }
 }
```

TrainWithCoaches implements an interface, so it has to have the signatures. These empty methods make it to the TODO list.

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
+public class TrainWithCoaches : Train 
+{
+
+    public void Reserve(uint seatCount, TicketInProgress ticketToFill)
+    {
+        //todo implement
+
+    }
+}
```

Date:   Mon Mar 5 15:23:23 2018 +0100

 Renaming a test (should've done this earlier). Should have left a TODO.

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
 public class BookTicketCommandSpecification {
 
     [Fact]
-    public void ShouldXXXXXXXXXXXXX() {
+    public void ShouldReserveSeatsOnTrainWhenExecuted() {
```

As we discovered a new class, time to test-drive it:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp 
+public class TrainWithCoachesSpecification 
+{
+    [Fact]
+    public void ShouldXXXXX() 
+    { //todo rename
+        //GIVEN
+        var trainWithCoaches = new TrainWithCoaches();
+
+        //WHEN
+        trainWithCoaches.Reserve(seatCount, ticket);
 
+        //THEN
+        assertThat(1).isEqualTo(2);
+    }
``` 

This doesn't pass the compilation yet. Time to fill the blanks.

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp 
 public class TrainWithCoachesSpecification {
     [Fact]
     public void ShouldXXXXX() { //todo rename
         //GIVEN
         var trainWithCoaches = new TrainWithCoaches();
+        var seatCount = Any.UnsignedInt();
+        var ticket = Substitute.For<TicketInProgress>();

         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
```


Passed the compiler. Now time for some deeper thinking on the expectation
    I know one coach should be reserved even though more meet the condition

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
     [Fact]
@@ -13,13 +14,16 @@ public class TrainWithCoachesSpecification
{

         //GIVEN
         var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.UnsignedInt();
         var ticket = Substitute.For<TicketInProgress>();

         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);

         //THEN
-        assertThat(1).isEqualTo(2);
+        coach1.DidNotReceive().Reserve(seatCount, ticket);
+        coach2.Received(1).Reserve(seatCount, ticket);
+        coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
 }
```
Verifying coaches although none were added yet. Discovered the coach interface:

```csharp
+public interface Coach
+{
+}
```

Time to introduce the coaches. 3 is many:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
@@ -15,6 +15,9 @@ public class TrainWithCoachesSpecification {
         var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.UnsignedInt();
         var ticket = Substitute.For<TicketInProgress>();
+        var coach1 = Substitute.For<Coach>();
+        var coach2 = Substitute.For<Coach>();
+        var coach3 = Substitute.For<Coach>();
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
```

Also, discovered the Reserve() method - time to put it in:

+++ b/Java/src/main/java/logic/Coach.java

```csharp
 public interface Coach 
 {
+    void Reserve(uint seatCount, TicketInProgress ticket);
 }
```

passing coaches as vararg: not test-driving the vararg, using the Kent Beck's putting the right implementation.

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
 public class TrainWithCoaches : Train
+{
+    public TrainWithCoaches(params Coach[] coaches)
+    {
+    }
```

This should still pass. now passing the coaches as parameters:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java


```csharp
@@ -12,12 +12,14 @@ public class TrainWithCoachesSpecification 
{
     [Fact]
     public void ShouldXXXXX() 
     { //todo rename
         //GIVEN
-        var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.UnsignedInt();
         var ticket = Substitute.For<TicketInProgress>();
         var coach1 = Substitute.For<Coach>();
         var coach2 = Substitute.For<Coach>();
         var coach3 = Substitute.For<Coach>();
+        var trainWithCoaches = new TrainWithCoaches(
+            coach1, coach2, coach3
+        );

         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
```

Missing the assumptions about whether the coach allows up front reservation:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
@@ -21,6 +22,14 @@ public class TrainWithCoachesSpecification {
             coach1, coach2, coach3
         );
 
+        coach1.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach2.AllowsUpFrontReservationOf(seatCount)
+            .Returns(true);
+        coach3.AllowsUpFrontReservationOf(seatCount)
+            .Returns(true);
+
+
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
 
@@ -29,6 +38,5 @@ public class TrainWithCoachesSpecification {
         coach2.Received(1).Reserve(seatCount, ticket);
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }

+    //todo what if no coach allows up front reservation?
 }
```

Added an item to TODO list - we'll get back to it later. if no coach allows up front, we take the first one that has the limit.

Discovered AllowsUpFrontReservationOf() method.

Introduced the method.  a too late TODO - CouchDbRepository should supply the coaches:

+++ b/Java/src/main/java/logic/Coach.java

@@ -2,4 +2,6 @@ package logic;

```csharp 
 public interface Coach
 {
     void Reserve(uint seatCount, TicketInProgress ticket);
+
+    bool AllowsUpFrontReservationOf(uint seatCount);
 }
```

+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

```csharp
 public class CouchDbTrainRepository : TrainRepository {

     public Train GetTrainBy(String trainId) {
+        //todo there should be something passed here!!
         return new TrainWithCoaches();
     }
 }
```

gave a good name to the test.

+++ b/Java/src/main/java/logic/TrainWithCoaches.java


//????????????????????? what is this?

```csharp
@@ -7,6 +7,5 @@ public class TrainWithCoaches : Train
{
     public void Reserve(uint seatCount, TicketInProgress ticketInProgress)
     {
         //todo implement
     }
 }
```

Now that the scenario is ready, I can give it a good name:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
 public class TrainWithCoachesSpecification {
     [Fact]
-    public void ShouldXXXXX() { //todo rename
+    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() {
         //GIVEN
         var seatCount = Any.UnsignedInt();
         var ticket = Substitute.For<TicketInProgress>();
```

Implementing the first behavior. (in the book, play with the if and return to see each assertion fail):

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
 public class TrainWithCoaches : Train 
 {
+    private Coach[] coaches;
+
     public TrainWithCoaches(Coach... coaches)
     {
+        this.coaches = coaches;
     }

-    public void Reserve(uint seatCount, TicketInProgress ticketInProgress) 
     {
-        //todo implement
+        foreach (var coach in coaches) {
+            if(coach.AllowsUpFrontReservationOf(seatCount)) {
+                coach.Reserve(seatCount, ticketInProgress);
+                return;
+            }
+        }
+
     }
 }
```

//by the way, this can be nicely converted to Linq: coaches.First(c => c.AllowsUpFrontReservationOf(seatCount)).?Reserve(seatCount, ticketInProgress);

Discovered AllowsReservationOf method:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp 
 public class TrainWithCoachesSpecification
 {

+    [Fact]
+    public void
+    ShouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() 
+    {
+        //GIVEN
+        var seatCount = Any.UnsignedInt();
+        var ticket = Substitute.For<TicketInProgress>();
+        var coach1 = Substitute.For<Coach>();
+        var coach2 = Substitute.For<Coach>();
+        var coach3 = Substitute.For<Coach>();
+        var trainWithCoaches = new TrainWithCoaches(
+            coach1, coach2, coach3
+        );
+
+        coach1.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach2.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach3.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach1.AllowsReservationOf(seatCount)
+            .Returns(false);
+        coach2.AllowsReservationOf(seatCount)
+            .Returns(true);
+        coach3.AllowsReservationOf(seatCount)
+            .Returns(false);
+
+        //WHEN
+        trainWithCoaches.Reserve(seatCount, ticket);
+
+        //THEN
+        coach1.DidNotReceive().Reserve(seatCount, ticket);
+        coach2.Received(1).Reserve(seatCount, ticket);
+        coach3.DidNotReceive().Reserve(seatCount, ticket);
+    }
+
 
 }
```

+++ b/Java/src/main/java/logic/Coach.java

```csharp
@@ -4,4 +4,6 @@ public interface Coach
{
     void Reserve(uint seatCount, TicketInProgress ticket);

     bool AllowsUpFrontReservationOf(uint seatCount);
+
+    bool AllowsReservationOf(uint seatCount);
 }
```

Bad implementation (break; instead of return;) alows the test to pass! Need to fix the first test:

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
@@ -9,6 +9,12 @@ public class TrainWithCoaches : Train
{

     public void Reserve(uint seatCount, TicketInProgress ticketInProgress)
     {
+        foreach (var coach in coaches) 
+        {
+            if(coach.AllowsReservationOf(seatCount)) 
+            {
+                coach.Reserve(seatCount, ticketInProgress);
+                break;
+            }
+        }
         foreach (var coach in coaches) 
         {
             if(coach.AllowsUpFrontReservationOf(seatCount))
             {
                 coach.Reserve(seatCount, ticketInProgress);
```

In the following changes, forced the right implementation. But need to refactor the tests. Next time we change this class, we refactor the code:

First we need to say we allow reservations. This dependency between tests is a sign of a design problem. Then, the method is long. Also, every time we set mock to return up front reservation, we need to set not upfront reservation and vice versa.  We could refactor this to chain of responsibility with two elements, but it's too early for that. We could also refactor to return a value object or enum for the kind of reservation. Or, we could use a collecting parameter, pass it through the list and make it do the reservation.

I change the first Statement to include the queries:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
@@ -28,6 +28,12 @@ public class TrainWithCoachesSpecification
{
    ...
             .Returns(true);
         coach3.AllowsUpFrontReservationOf(seatCount)
             .Returns(true);
+        coach1.AllowsReservationOf(seatCount)
+            .Returns(true);
+        coach2.AllowsReservationOf(seatCount)
+            .Returns(true);
+        coach3.AllowsReservationOf(seatCount)
+            .Returns(true);
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
```

THe Statement is now false. Let's just change the implementation:

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
@@ -10,17 +10,16 @@ public class TrainWithCoaches : Train
{
     
     public void Reserve(uint seatCount, TicketInProgress ticketInProgress)
     {
         foreach (var coach in coaches) 
         {
-            if(coach.AllowsReservationOf(seatCount))
-            {
+            if(coach.AllowsUpFrontReservationOf(seatCount))
+            {
                 coach.Reserve(seatCount, ticketInProgress);
-                break;
+                return;
             }
         }
         foreach (var coach in coaches) 
         {
-            if(coach.AllowsUpFrontReservationOf(seatCount))
-            {
+            if(coach.AllowsReservationOf(seatCount))
             {
                 coach.Reserve(seatCount, ticketInProgress);
                 return;
             }
         }
-
     }
 }
```

For now, refactored coaches Statement (truth be told, I should refactor prod code, not test, but this test refactoring will allow me to refactor the prod. code later as well, e.g. to return an enum):

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
         //GIVEN
         var seatCount = Any.UnsignedInt();
         var ticket = Substitute.For<TicketInProgress>();
-        var coach1 = Substitute.For<Coach>();
-        var coach2 = Substitute.For<Coach>();
-        var coach3 = Substitute.For<Coach>();
+
+        Coach coach1 = CoachWithoutAvailableUpFront(seatCount);
+        Coach coach2 = CoachWithAvailableUpFront(seatCount);
+        Coach coach3 = CoachWithAvailableUpFront(seatCount);
+
         var trainWithCoaches = new TrainWithCoaches(
             coach1, coach2, coach3
         );
-
-        coach1.AllowsUpFrontReservationOf(seatCount)
-            .Returns(false);
-        coach2.AllowsUpFrontReservationOf(seatCount)
-            .Returns(true);
-        coach3.AllowsUpFrontReservationOf(seatCount)
-            .Returns(true);
-        coach1.AllowsReservationOf(seatCount)
-            .Returns(true);
-        coach2.AllowsReservationOf(seatCount)
-            .Returns(true);
-        coach3.AllowsReservationOf(seatCount)
-            .Returns(true);
-
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
 
@@ -44,6 +32,24 @@ public class TrainWithCoachesSpecification {
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
 
+    private Coach CoachWithAvailableUpFront(Integer seatCount) {
+        var coach2 = Substitute.For<Coach>();
+        coach2.AllowsUpFrontReservationOf(seatCount)
+            .Returns(true);
+        coach2.AllowsReservationOf(seatCount)
+            .Returns(true);
+        return coach2;
+    }
+
+    private Coach CoachWithoutAvailableUpFront(Integer seatCount) {
+        var coach1 = Substitute.For<Coach>();
+        coach1.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach1.AllowsReservationOf(seatCount)
+            .Returns(true);
+        return coach1;
+    }
+
```

Refactored tests. TODO start from this committ to show refactoring of production code later!!

Adding `CoachWithout()` method as well to the other tests:

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
@@ -32,50 +32,19 @@ public class TrainWithCoachesSpecification {
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
 
     [Fact]
     public void
     shouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() {
         //GIVEN
         var seatCount = Any.UnsignedInt();
         var ticket = Substitute.For<TicketInProgress>();
-        var coach1 = Substitute.For<Coach>();
-        var coach2 = Substitute.For<Coach>();
-        var coach3 = Substitute.For<Coach>();
+        var coach1 = coachWithout(seatCount);
+        var coach2 = CoachWithoutAvailableUpFront(seatCount);
+        var coach3 = coachWithout(seatCount);
         var trainWithCoaches = new TrainWithCoaches(
             coach1, coach2, coach3
         );
 
-        coach1.AllowsUpFrontReservationOf(seatCount)
-            .Returns(false);
-        coach2.AllowsUpFrontReservationOf(seatCount)
-            .Returns(false);
-        coach3.AllowsUpFrontReservationOf(seatCount)
-            .Returns(false);
-        coach1.AllowsReservationOf(seatCount)
-            .Returns(false);
-        coach2.AllowsReservationOf(seatCount)
-            .Returns(true);
-        coach3.AllowsReservationOf(seatCount)
-            .Returns(false);
-
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
 
@@ -85,6 +54,30 @@ public class TrainWithCoachesSpecification {
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
 
+    private Coach coachWithout(Integer seatCount) {
+        var coach1 = Substitute.For<Coach>();
+        coach1.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach1.AllowsReservationOf(seatCount)
+            .Returns(false);
+        return coach1;
+    }
 
-    //todo what if no coach allows up front reservation?
}
```

Addressed todo - created a class CoachWithSeats (or else it would probably not compile).

+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

```csharp
@@ -4,6 +4,8 @@ public class CouchDbTrainRepository : TrainRepository {
     
     public Train GetTrainBy(String trainId) {
-        //todo there should be something passed here!!
-        return new TrainWithCoaches();
+        return new TrainWithCoaches(
+            new CoachWithSeats()
+        );
     }
 }
```

The body of the class looks like this:

```csharp
+public class CoachWithSeats : Coach
+{
+
+    public void Reserve(uint seatCount, TicketInProgress ticket)
+    {
+        //todo implement
+
+    }
+
+
+    public bool AllowsUpFrontReservationOf(uint seatCount)
+    {
+        //todo implement (does not compile)
+    }
+
+    
+    public bool AllowsReservationOf(uint seatCount)
+    {
+        //todo implement (does not compile)
+    }
+}
```

The code does not compile yet, so adding just enough code to make it compile.

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
+public class CoachWithSeats : Coach
+{
+
+    public void Reserve(uint seatCount, TicketInProgress ticket)
+    {
+        //todo implement
+
+    }
+
+
+    public bool AllowsUpFrontReservationOf(uint seatCount)
+    {
+        //todo implement
+        return false;
+    }
+
+    
+    public bool AllowsReservationOf(uint seatCount)
+    {
+        //todo implement
+        return false;
+    }
+}
```


Starting specification for new class, using brain dump:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
+public class CoachWithSeatsSpecification 
+{
+
+    [Fact]
+    public void xxXXxxXX()
+    { //TODO rename
+        //GIVEN
+        var coachWithSeats = new CoachWithSeats();
+        //WHEN
+        uint seatCount = Any.UnsignedInt();
+        var reservationAllowed = coachWithSeats.AllowsReservationOf(seatCount);
+
+        //THEN
+        Assert.True(reservationAllowed);
+    }
+}
```

Now we need to somehow determine the seat count. I pass seats and then create an instance of the first one and this leads me to inventing a type for it. This way, I discover the Seat interface:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
@@ -11,7 +11,18 @@ public class CoachWithSeatsSpecification {
     [Fact]
     public void xxXXxxXX() //todo rename
     {
         //GIVEN
-        var coachWithSeats = new CoachWithSeats();
+        Seat seat1 = Any.Instance<Seat>(); //introduced later
+        var coachWithSeats = new CoachWithSeats(
+            seat1,
+            seat2,
+            seat3,
+            seat4,
+            seat5,
+            seat6,
+            seat7,
+            seat8,
+            seat9,
+            seat10
+        );
         //WHEN
         uint seatCount = Any.UnsignedInt();
         var reservationAllowed = coachWithSeats.AllowsReservationOf(seatCount);
```

and we define the interface:

+++ b/Java/src/main/java/logic/Seat.java

```csharp
+public interface Seat
+{
+}
```

Created enough seats:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
@@ -11,7 +11,17 @@ public class CoachWithSeatsSpecification {
     [Fact]
     public void xxXXxxXX() { //todo rename
         //GIVEN
+        //todo what's special about these seats?
         Seat seat1 = Any.Instance<Seat>();
+        Seat seat2 = Any.Instance<Seat>();
+        Seat seat3 = Any.Instance<Seat>();
+        Seat seat4 = Any.Instance<Seat>();
+        Seat seat5 = Any.Instance<Seat>();
+        Seat seat6 = Any.Instance<Seat>();
+        Seat seat7 = Any.Instance<Seat>();
+        Seat seat8 = Any.Instance<Seat>();
+        Seat seat9 = Any.Instance<Seat>();
+        Seat seat10 = Any.Instance<Seat>();
         var coachWithSeats = new CoachWithSeats(
             seat1,
             seat2,
```

Added a constructor:

b/Java/src/main/java/logic/CoachWithSeats.java

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp 
 public class CoachWithSeats : Coach {
+    public CoachWithSeats(Seat... seats) {
+    }
+
```

Clarified scenario. Test passes right away. suspicious:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
 public class CoachWithSeatsSpecification {
 
     [Fact]
-    public void xxXXxxXX() //todo rename
+    public void ShouldNotAllowReservingMoreSeatsThanItHas()
{
        //GIVEN
        //todo what's special about these seats?
         Seat seat1 = Any.Instance<Seat>();
         Seat seat2 = Any.Instance<Seat>();
         Seat seat3 = Any.Instance<Seat>();
@@ -34,12 +33,14 @@ public class CoachWithSeatsSpecification {
             seat9,
             seat10
         );
+
         //WHEN
-        uint seatCount = Any.UnsignedInt();
-        var reservationAllowed = coachWithSeats.AllowsReservationOf(seatCount);
+        var reservationAllowed = coachWithSeats.AllowsReservationOf(11);
 
         //THEN
-        Assert.True(reservationAllowed);
+        Assert.False(reservationAllowed);
     }
 
+    //todo what's special about these seats?
+
 }
```

//////TODOOOOOOOO I stop here and start writing the chapter. Still wondering if a method for determining the best possible reservation type returning an enum would be better than two boolean questions.

Reused test and added todo:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
public class CoachWithSeatsSpecification {

     [Fact]
     public void ShouldNotAllowReservingMoreSeatsThanItHas() 
     {
         //GIVEN
         Seat seat1 = Any.Instance<Seat>();
         Seat seat2 = Any.Instance<Seat>();
@@ -36,11 +36,15 @@ public class CoachWithSeatsSpecification {
 
         //WHEN
         var reservationAllowed = coachWithSeats.AllowsReservationOf(11);
+        var upFrontAllowed = coachWithSeats.AllowsUpFrontReservationOf(11);
 
         //THEN
         assertThat(reservationAllowed).isFalse();
+        assertThat(upFrontAllowed).isFalse();
     }
 
+    //todo all free
+    //todo other scenarios
     //todo what's special about these seats?
 
 }
```

another test. the non-upfront is easier, that's why I take it first:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp 
+    [Fact]
+    public void ShouldAllowReservingSeatsThatAreFree() {
+        //GIVEN
+        Seat seat1 = FreeSeat();
+        Seat seat2 = FreeSeat();
+        Seat seat3 = FreeSeat();
+        Seat seat4 = FreeSeat();
+        Seat seat5 = FreeSeat();
+        Seat seat6 = FreeSeat();
+        Seat seat7 = FreeSeat();
+        Seat seat8 = FreeSeat();
+        Seat seat9 = FreeSeat();
+        Seat seat10 = FreeSeat();
+        var coachWithSeats = new CoachWithSeats(
+            seat1,
+            seat2,
+            seat3,
+            seat4,
+            seat5,
+            seat6,
+            seat7,
+            seat8,
+            seat9,
+            seat10
+        );
+
+        //WHEN
+        var reservationAllowed = coachWithSeats.AllowsReservationOf(10);
+
+        //THEN
+        Assert.True(reservationAllowed);
+    }
+
+    private Seat FreeSeat() {
+        return Any.Instance<Seat>();
+    }
+
+
     //todo all free
     //todo other scenarios
     //todo what's special about these seats?
```

Made the test pass. but this is not the right implementation:

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp 
 public class CoachWithSeats : Coach {
+    private Seat[] seats;
+
     public CoachWithSeats(Seat... seats) {
+        this.seats = seats;
     }
 
@@ -18,7 +23,7 @@ public class CoachWithSeats : Coach {
     
     public bool AllowsReservationOf(uint seatCount) {
-        //todo implement
-        return false;
+        //todo not yet the right implementation
+        return seatCount == Arrays.stream(seats).count();
     }
 }
```

Discovered isFree method when clarifying the behavior

+++ b/Java/src/main/java/logic/Seat.java

```csharp 
 public interface Seat {
+    bool isFree();
 }
```

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
 public class CoachWithSeatsSpecification 
 {
     //...

     private Seat FreeSeat() {
-        return Any.Instance<Seat>();
+        Seat mock = Substitute.For<Seat>();
+        mock.IsFree().Returns(true);
+        return mock;
     }
```
 

Refactored test. no need for variables:

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java 


```csharp
     [Fact]
     public void ShouldAllowReservingSeatsThatAreFree() 
     {
         //GIVEN
-        Seat seat1 = FreeSeat();
-        Seat seat2 = FreeSeat();
-        Seat seat3 = FreeSeat();
-        Seat seat4 = FreeSeat();
-        Seat seat5 = FreeSeat();
-        Seat seat6 = FreeSeat();
-        Seat seat7 = FreeSeat();
-        Seat seat8 = FreeSeat();
-        Seat seat9 = FreeSeat();
-        Seat seat10 = FreeSeat();
         var coachWithSeats = new CoachWithSeats(
-            seat1,
-            seat2,
-            seat3,
-            seat4,
-            seat5,
-            seat6,
-            seat7,
-            seat8,
-            seat9,
-            seat10
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat()
         );
 
         //WHEN
@@ -78,6 +68,8 @@ public class CoachWithSeatsSpecification 
{
    Assert.True(reservationAllowed);
}
 
+
+
private Seat FreeSeat() 
{
    Seat mock = Substitute.For<Seat>();
    mock.IsFree().Returns(true);
```

added another test:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
@@ -68,6 +68,34 @@ public class CoachWithSeatsSpecification 
     {
         Assert.True(reservationAllowed);
     }
 
+    [Fact]
+    public void ShouldNotAllowReservingWhenNotEnoughFreeSeats() 
+    {
+        //GIVEN
+        var coachWithSeats = new CoachWithSeats(
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            ReservedSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat()
+        );
+
+        //WHEN
+        var reservationAllowed = coachWithSeats.AllowsReservationOf(10);
+
+        //THEN
+        Assert.True(reservationAllowed);
+    }
+
+    private Seat ReservedSeat() 
+    {
+        Seat mock = Substitute.For<Seat>();
+        mock.IsFree().Returns(false);
+        return mock;
+    }
 
 
     private Seat FreeSeat() {
```

implemented only free seats:

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
     public bool AllowsReservationOf(uint seatCount) {
-        //todo not yet the right implementation
-        return seatCount == Arrays.stream(seats).count();
+        return seatCount == seats
+            .Where(seat => seat.IsFree())
+            .Count();
     }
 }
```

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java 


```csharp
         var reservationAllowed = coachWithSeats.AllowsReservationOf(10);
 
         //THEN
-        Assert.True(reservationAllowed);
+        assertThat(reservationAllowed).isFalse();
     }
 
     private Seat ReservedSeat() {
```

First test for up front reservations:

    why 7 and not calculating? Don't be smart in tests - if you have to, put smartness in a well-tested library.
    TODO delegate criteria to a separate class??

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java 

```csharp
+    [Fact]
+    public void ShouldAllowReservingUpFrontUpTo70PercentOfSeats() {
+        //GIVEN
+        var coachWithSeats = new CoachWithSeats(
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat()
+        );
+
+        //WHEN
+        var reservationAllowed =
+            coachWithSeats.AllowsUpFrontReservationOf(7);
+
+        //THEN
+        Assert.True(reservationAllowed);
+    }
+
+
```

    Naively passing the test

+++ b/Java/src/main/java/logic/CoachWithSeats.java


```csharp
     public bool AllowsUpFrontReservationOf(uint seatCount) {
-        //todo implement
-        return false;
+        //todo not the right implementation yet
+        return true;
     }
```
 
New test for up front:

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java 

```csharp
@@ -115,6 +115,29 @@ public class CoachWithSeatsSpecification {
         Assert.True(reservationAllowed);
     }
 
+    [Fact]
+    public void ShouldNotAllowReservingUpFrontOverTo70PercentOfSeats() {
+        //GIVEN
+        var coachWithSeats = new CoachWithSeats(
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat()
+        );
+
+        //WHEN
+        var reservationAllowed =
+            coachWithSeats.AllowsUpFrontReservationOf(8);
+
+        //THEN
+        Assert.True(reservationAllowed);
+    }
 
     private Seat ReservedSeat() {
         Seat mock = Substitute.For<Seat>();
```

Commented out a failing test and refactored:


+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp     
     public bool AllowsReservationOf(uint seatCount) {
-        return seatCount == Arrays.stream(seats)
+        return seatCount == freeSeatCount();
+    }
+
+    private long freeSeatCount() {
+        return Arrays.stream(seats)
             .filter(seat -> seat.IsFree())
             .count();
     }
```

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp 
-    [Fact]
+    //[Fact] todo uncomment!
     public void ShouldNotAllowReservingUpFrontOverTo70PercentOfSeats() {
         //GIVEN
         var coachWithSeats = new CoachWithSeats(
```             

Damn, 2 tests failing...

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp 
-    //[Fact] todo uncomment!
+    [Fact]
     public void ShouldNotAllowReservingUpFrontOverTo70PercentOfSeats() {
         //GIVEN
         var coachWithSeats = new CoachWithSeats(
@@ -136,7 +136,7 @@ public class CoachWithSeatsSpecification {
             coachWithSeats.AllowsUpFrontReservationOf(8);
 
         //THEN
-        Assert.True(reservationAllowed);
+        assertThat(reservationAllowed).isFalse();
     }
```

OK, one test failing:


+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
@@ -17,13 +17,13 @@ public class CoachWithSeats : Coach {
 
     
     public bool AllowsUpFrontReservationOf(uint seatCount) {
-        //todo not the right implementation yet
-        return true;
+        return seatCount <= seats.length;
     }
 
     
     public bool AllowsReservationOf(uint seatCount) {
-        return seatCount == freeSeatCount();
+
+        return seatCount <= freeSeatCount();
     }
 
     private long freeSeatCount() {
```

Made last test pass. omitting rounding behavior etc.:

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
@@ -17,7 +17,7 @@ public class CoachWithSeats : Coach {
 
     
     public bool AllowsUpFrontReservationOf(uint seatCount) {
-        return seatCount <= seats.length;
+        return seatCount <= seats.length * 0.7;
     }
```
     

Picked the right formula for the criteria. Another test green.

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
     public bool AllowsUpFrontReservationOf(uint seatCount) {
-        return seatCount <= seats.length * 0.7;
+        return (freeSeatCount() - seatCount) >= seats.length * 0.3;
     }
```
 
     
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java


```csharp 
+    [Fact]
+    public void ShouldNotAllowReservingUpFrontOver70PercentOfSeatsWhenSomeAreAlreadyReserved() {
+        //GIVEN
+        var coachWithSeats = new CoachWithSeats(
+            ReservedSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat(),
+            FreeSeat()
+        );
+
+        //WHEN
+        var reservationAllowed =
+            coachWithSeats.AllowsUpFrontReservationOf(7);
+
+        //THEN
+        assertThat(reservationAllowed).isFalse();
+    }
+
+
```


Added reservation test:

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
@@ -22,7 +22,6 @@ public class CoachWithSeats : Coach 
{
     public bool AllowsReservationOf(uint seatCount) 
     {
-
         return seatCount <= freeSeatCount();
     }
```

+++ b/Java/src/main/java/logic/Seat.java

```csharp
 public interface Seat 
 {
     bool isFree();
+    void reserveFor(TicketInProgress ticketInProgress);
 }
```

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
 public class CoachWithSeatsSpecification {
 
+    [Fact]
+    public void ShouldReserveFirstFreeSeats() {
+        //GIVEN
+        var seat1 = Substitute.For<Seat>();
+        var seat2 = Substitute.For<Seat>();
+        var seat3 = Substitute.For<Seat>();
+        var ticketInProgress = Substitute.For<TicketInProgress>();
+        var coachWithSeats = new CoachWithSeats(
+            seat1,
+            seat2,
+            seat3
+        );
+
+        //WHEN
+        coachWithSeats.Reserve(2, ticketInProgress);
+
+        //THEN
+        then(seat1).should().reserveFor(ticketInProgress);
+        then(seat2).should().reserveFor(ticketInProgress);
+        then(seat1).should(never()).reserveFor(any(TicketInProgress.class));
+    }
```

Added reservation:

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
     public void Reserve(uint seatCount, TicketInProgress ticket) {
-        //todo implement
+        foreach (var seat in seats) 
+        {
+            if (seatCount == 0) 
+            {
+                return;
+            } 
+            else 
+            {
+                seat.reserveFor(ticket);
+                seatCount--;
+            }
+        }
     }
```
 
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
@@ -185,7 +185,7 @@ public class CoachWithSeatsSpecification {
         //THEN
         then(seat1).should().reserveFor(ticketInProgress);
         then(seat2).should().reserveFor(ticketInProgress);
-        then(seat1).should(never()).reserveFor(any(TicketInProgress.class));
+        then(seat3).should(never()).reserveFor(any(TicketInProgress.class));
     }
 
     private Seat ReservedSeat() {
@@ -202,8 +202,5 @@ public class CoachWithSeatsSpecification {
     }
 
 
-    //todo all free
-    //todo other scenarios
-    //todo what's special about these seats?
-
+    //todo should we protect Reserve() method?
 }
```

Discovered a NamedSeat class:

+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

```csharp
@@ -5,7 +5,10 @@ public class CouchDbTrainRepository : TrainRepository 
{
     public Train GetTrainBy(string trainId) 
     {
         //todo there should be something passed here!!
         return new TrainWithCoaches(
-            new CoachWithSeats()
+            new CoachWithSeats(
+                new NamedSeat(),
+                new NamedSeat()
+            )
         );
     }
 }
```

+++ b/Java/src/main/java/logic/NamedSeat.java

```csharp
+public class NamedSeat : Seat 
+{
+    
+    public bool isFree() 
+    {
+        //todo implement
+        return false;
+    }
+
+    
+    public void reserveFor(TicketInProgress ticketInProgress) 
+    {
+        //todo implement
+
+    }
+}
```

    Added failing test. Note that depending on what Any.boolean() returns, this might pass or not:

+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

```csharp
@@ -6,8 +6,8 @@ public class CouchDbTrainRepository : TrainRepository 
{
         //todo there should be something passed here!!
         return new TrainWithCoaches(
             new CoachWithSeats(
-                new NamedSeat(),
-                new NamedSeat()
+                new NamedSeat(true),
+                new NamedSeat(true)
             )
         );
     }
```

+++ b/Java/src/main/java/logic/NamedSeat.java

```csharp
 public class NamedSeat : Seat {
+    public NamedSeat(bool isFree) {
+        //todo implement
+
+    }
+
     
     public bool isFree() {
         //todo implement
```

+++ b/Java/src/test/java/logic/NamedSeatSpecification.java


```csharp
+public class NamedSeatSpecification 
+{
+    [Fact]
+    public void ShouldBeFreeDependingOnPassedConstructorParameter() {
+        //GIVEN
+        var isInitiallyFree = Any.booleanValue();
+        var namedSeat = new NamedSeat(isInitiallyFree);
+
+        //WHEN
+        var isEventuallyFree = namedSeat.IsFree();
+
+        //THEN
+        assertThat(isEventuallyFree).isEqualTo(isInitiallyFree);
+    }
+
+    //todo add ctrl + enter to presentation
+    //todo add CamelHumps to presentation
+}
```

    improved the test by repeating two times:

+++ b/Java/src/main/java/logic/NamedSeat.java

```csharp 
 public class NamedSeat : Seat 
 {
+    private bool isFree;

-    public NamedSeat(bool isFree) 
-    {
-        //todo implement
+    public NamedSeat(bool isFree) 
+    {
+        this.isFree = isFree;
     }
 
     
     public bool isFree() 
     {
-        //todo implement
-        return false;
+        return isFree;
     }
```
 
     
+++ b/Java/src/test/java/logic/NamedSeatSpecification.java

```csharp
 public class NamedSeatSpecification {
-    [Fact]
+    [Fact](invocationCount = 2) //TODO repeat in xunit.net????????????????????????
     public void ShouldBeFreeDependingOnPassedConstructorParameter() 
     {
         //GIVEN
         var isInitiallyFree = Any.booleanValue();
```

[^POEAA]: Patterns of enterprise application architecture, M. Fowler.
[^FowlerSimplicity]: TODO Martin Fowler on the YAGNI
[^SandorMancussoDesign]: TODO Sando Mancusso on design approaches.