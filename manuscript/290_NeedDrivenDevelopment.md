# Test-driving at the input boundary

In this chapter, we'll be joining Johnny and Benjamin again as they try to test-drive a system starting from its input boundaries. This will hopefully show a picture of how abstractions are pulled from need and how roles are invented at the boundary of a system. The further chapters will explore domain model. This example makes several assumptions:

1. In this story, Johnny is a super programmer, who never makes mistakes. In real-life TDD, people make mistakes and correct them, sometimes they go back and forth thinking about tests and design. Here, Johnny gets everything right the first time. Although I know this is a drop on realism, I hope that it will help my readers in observing how some TDD mechanics work. This is also why Johnny and Benjamin will not need to refactor anything in this chapter.
1. There will be no Statements written on higher than unit level. This means that Johnny and Benjamin will do TDD using unit-level Statements only. This is why they will need to do some things they could avoid if they could write a higher-level test. A separate part of this book will cover working with different levels of tests at the same time.
1. This chapter (and several next ones) will avoid the topic of working with any I/O, randomness and other hard to test stuff. For now I want to focus on test-driving pure code-based logic.

With all of that out of our way, let's join Johnny and Benjamin and see what kind of issue they are dealing with and how they try to solve it using TDD.

## Fixing the ticket office

**Johnny:** What do you think about trains, Benjamin?

**Benjamin:** Are you asking because I was travelling by train yesterday to get here? Well, I like it, especially after some of the changes that happened over the recent years. I truly think that today's railways are modern and passenger-friendly.

**Johnny:** And about the seat reservation process?

**Benjamin:** Oh yeah, that... I mean, why didn't they still automate the process? Is this even thinkable that in the 21st century I cannot reserve a seat through the internet?

**Johnny:** I kinda hoped you'd say that, because our next assignment is to do exactly that.

**Benjamin:** You mean reserving seats through the internet?

**Johnny:** Yes, the railroads company hired us.

**Benjamin:** You're kidding me, right?

**Johnny:** No, I'm being really honest.

**Benjamin:** No way.

**Johnny:** Take your smartphone and check your e-mail, I already forwarded the details to you.

**Benjamin:** Hey, that looks legit. Why didn't you tell me earlier?

**Johnny:** I'll explain on the way. Come on, let's go.

## Initial objects

**Benjamin:** do we have any sort of requirements, stories or whatever to work with?

**Johnny:** Yes, I'll explain some as I walk you through the input and output data structures. This will be enough to get us going.

### Request

**Johnny:** Somebody's already written the part that accepts an HTTP request and maps it to the following structure:

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

**Benjamin:** I see... Hey, why does the `ReservationRequestDto` name has `Dto` in it? What is it?

**Johnny:** The suffix `Dto` means that this class represents a Data Transfer Object (in short, DTO)[^POEAA]. Its role is just to transfer data across the process boundaries.

**Benjamin:** So you mean it is just needed to represent some kind of XML or JSON that is sent to the application?

**Johnny:** Yes, you could say that. The reason people typically place `Dto` in these names is because these data structures are special - they represent an outside contract and cannot be freely modified like other objects.

**Benjamin:** Does it mean that I can't touch them?

**Johnny:** It means that if you did touch them, you'd have to make sure they are still correctly mapped from outside data, like JSON or XML.

**Benjamin:** Cool, and what about the ID?

**Johnny:** It represents a train. The client application will know these IDs and someone has slaready written the part for retrieving them.

**Benjamin:** Cool, what's next?

**Johnny:** The client tells us how many seats we need to reserve, but doesn't tell us where. This is why there's only a `seatCount` parameter. We are the ones who determine which steas to pick.

**Benjamin:** So if a couple wants to reserve two steas, they can be in different coaches?

**Johnny:** Yes, however, there are some preference rules that we need to code in, like, if we can, a single reservation should have all seats in the same coach. I'll fill you in on the rules later as for now we're not going to need them.

### Response

**Benjamin:** Do we return something back to the client?

**Johnny:** Yes, need to return a response, which, guess what, is also a DTO. This response represents the reservation made:

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

**Benjamin:** OK, I can see that there's a train ID, which is... the same as the one in the request, I suppose?

**Johnny:** Right.

**Benjamin:** ...and there is a reservation ID that is probably assigned by our application.

**Johnny:** correct.

**Benjamin:** but the `perSeatTickets` field... it is a list of `TicketDto`, which as I understand is one of our custom types. Where is it?

**Johnny:** Oh, yeah, forgot to show it to you. `TicketDto` is defined as:

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

so it has a coach name and a seat number, and we have a list of these in our reservation.

**Benjamin:** Ok, so a single reservation can contain many tickets and each ticket is for a single place in a specific coach, right?

**Johnny:** Yes.

### Ticket Office class

**Benjamin:** Ok. So we need these data structures to deserialize some kind of JSON or XML input into them?

**Johnny:** Don't you remember? This part is already done, lucky us. Our work starts from the point where the desrialized data is passed to the application logic as a DTO. The request entry point is in a class called `TicketOffice`:

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

**Johnny:** As I can see, it has some annotations specific to a web framework, so we will probably not implement the use case directly in the `MakeReservation` method to avoid coupling our use case logic to code that needs to meet the requirements of a specific framework.

**Benjamin:** So what you're saying is that you're trying to keep the TicketOffice as much away from the business logic as you can?

**Johnny:** Yes, in a way, I think about it as an anti-corruption layer. I only need it to wrap all the objects into appropriate abstractions and run the use case where it is us who dictate the conditions, not a framework.

## Bootstrap

**Benjamin:** Are we ready to go?

**Johnny:** Typically, if I were you, I would like to see one more place in the code.

**Benjamin:** Which is..?

**Johnny:** The composition root, of course.

**Benjamin:** Why would I like to see a composition root?

**Johnny:** Well, first reason is that it is very close to the entry point for the application, so it is a chance for you to see how the application manages its dependencies. The second reason is that each time we will be adding a new class that has the same lifespan as the application, we will need to go to the composition root and modify it. Sooo it would probably be nice to be able to tell where it is and know how to work with it.

**Benjamin:** I thought I could find that later, but while we're at it, can you show me the composition root?

**Johnny:** Sure, it's here, in the `Application` class:

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

**Benjamin:** Good to see it doesn't require us to use any fancy reflection-based mechanism for composing objects.

**Johnny:** Yes, we're lucky about that. We can just create the objects with `new` operator and pass them to the framework.

## Writing the first Statement

**Johnny:** Anyway, I think we're ready to start.

**Benjamin:** Ok, where do we start from? Should we write some kind of a class called "Reservation" or "Train" first?

**Johnny:** No, what we will do is we will start from the inputs and work our way towards the inside of the application. Then, if necessary, to the outputs again.

**Benjamin:** I don't think I understand what you're talking about. Do you mean this "outside-in" approach that you talked about yesterday?

**Johnny:** Yes and don't worry if you didn't get what I said, I will explain as we go. For now, the only thing I mean by it is that we will follow the path of the request as it comes from the outside of our application and start implementing at the first place that where the request is not handled as it should. Specifically, this means we start at:

```csharp
public class TicketOffice
{
    public ReservationDto MakeReservation(ReservationRequestDto requestDto) 
    {
        throw new NotImplementedException("Not implemented");
    }
}
```

**Benjamin:** Why?

**Johnny:** Because this is the place nearest to the request entry point where the behavior differs from the one we expect. As soon as the request reaches this point, its handling will stop and an exception will be thrown. We need to alter this code if we want the request to go any further.

**Benjamin:** I see... so... if we didn't have the request deserialization code in place already, we'd start there, because that would be the first place where the request would stuck on its way towards it goal, right?

**Johnny:** Yes, you got it.

**Benjamin:** And... we start with a false Statement, no?

**Johnny:** Yes, let's do that.

### First Statement skeleton

**Benjamin:** Don't tell me anything, I'll try doing it myself.

**Johnny:** Sure, as you wish.

**Benjamin:** The first thing I need to do is to add an empty Specification for the TicketOffice class:

```csharp
public class TicketOfficeSpecification
{
    //TODO add a Statement
}
```

Then, I need to add my first Statement. I know that in this Statement, I need to create an instance of the `TicketOffice` class and call the `MakeReservation` method, since it's the only method in this class and it's not implemented.

**Johnny:** so what strategy do you use for starting with a false Statement?

**Benjamin:** "invoke method when you have one", as far as I remember.

**Johnny:** So what's the code going to look like?

**Benjamin:** for starters, I will do my brain dump just as you taught me. After stating all the bleedy obvious facts, I get:

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

**Johnny:** Good... my... apprentice...

**Benjamin:** What?

**Johnny:** Oh, nevermind...  anyway, the code doesn't compile now, since this line:

```csharp
ticketOffice.MakeReservation(requestDto);
```

uses a variable `requestDto` that does not exist. Let's generate it using our IDE!

**Benjamin:** By the way, I wanted to ask about this line. Making it compile is something we need to do to move on. Weren't we supposed to add a `TODO` comment for things we need to get back to, like we did with the Statement name, which was:

```csharp
public void ShouldXXXXX() //TODO better name
```

**Johnny:** My opinion is that this is not necessary, because the compiler, by failing on this line, has already creeated a TODO item of sort for us, just not on our TODO list but on compile error log. This is different than e.g. the need to change a method name, which the compiler will not remind us about.

**Benjamin:** So my TODO list is composed of compile errors, false Statements and the items I manually mark as `TODO`? Is this how I should understand it?

**Johnny:** Exactly. Going back to the `requestDto` variable, let's create it.

**Benjamin:** Sure. It came out like this:

```csharp
ReservationRequestDto requestDto;
```

We need to assign something to the variable.

**Johnny:** Yes, and since it's a DTO, it is certainly not going to be a mock.

**Benjamin:** You mean we don't mock DTOs?

**Johnny:** No, there's no need to. DTOs are, by definition, data structures and mocking involves polymorphism which applies to behavior rather than data. Later I will explain it in more details. For now, just accept my word on it.

**Benjamin:** Sooo... if it's not going to be a mock, then let's generate it using the `Any.Instance<>()` method.

**Johnny:** That is exactly what I would do.

**Benjamin:** So I will change this line:

```csharp
ReservationRequestDto requestDto;
```

to:

```csharp
var requestDto = Any.Instance<ReservationRequestDto>();
```

### Setting up the expectation

**Johnny:** Yes, and now the Statement compiles, so after everything compiles, our Statement seems to be false. This is because of this line:

```csharp
Assert.True(false);
```

**Benjamin:** so we change this `false` to `true` and we're done here, right?

**Johnny:** ...

**Benjamin:** Oh, this was a joke. You believe me, don't you? What I really wanted to say is let's turn this assertion into something useful.

**Johnny:** phew, don't scare me like that. Yes, this assertion needs to be rewritten. And it so happens that when we look at the following line:

```csharp
ticketOffice.MakeReservation(requestDto);
```

it doesn't make any use of the return value of `MakeReservation()` while it's evident from the signature that its return type is a `ReservationDto`. Look:

```csharp
public ReservationDto MakeReservation(ReservationRequestDto requestDto)
```

In our Statement, we don't do anything with it.

**Benjamin:** Ok, let me guess, you want me go to the Statement, assign this return value to a variable and then assert its equality to... what exactly?

**Johnny:** For now, to an expected value, which we don't know yet what's going to be, but we will worry about it later when it really blocks us.

**Benjamin:** This is one of those situations where we need to imagine that we already have something we don't, right?. Ok, here goes:

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
  Assert.Equal(expectedReservationDto, reservationDto);
}
```

There, I did what you asked. So please explain to me now how did it get us any closer to our goal?

**Johnny:** Well, we transformed our problem from "what assertion to write" into "what is the reservation that we expect". This is indeed a step in the right direction.

**Benjamin:** Enlighten me then - what is "the reservation that we expect"?

**Johnny:** For now, the Statement is not compiling at all, so to go any step further, we can just introduce a `expectedReservationDto` as any value. Thus, we can just write in the `GIVEN` section:

```csharp
var expectedReservationDto = Any.Instance<ReservationDto>();
```

and it will make the following code compile:

```csharp
//THEN
Assert.Equal(expectedReservationDto, reservationDto);
```

**Benjamin:** But this assertion will fail anyway...

**Johnny:** That's still better than not compiling, isn't it?

**Benjamin:** Well, if you put it this way... Now our problem is that the expected value from the assertion is something the production code doesn't know about - this is just something we created in our Statement. This means that this assertion is not an assertion on the outcome of the behavior of production code. How do we solve this?

**Johnny:** This is where we need to exercise our design skills to introduce some new collaborators. This task is hard at the boundaries of application logic, since we need to draw the collaborators not from the domain, but rather think about design patterns that will allow us to reach our goals. Every time we enter our application logic, we do so from a perspective of a use case. In this particular example, our use case is "making a reservation". A use case is typically represented by either a method in a facade[^FacadePattern] or a command object[^CommandPattern]. Commands are a bit more complex, but more scalable. If making a reservation was our only use case, it probably wouldn't make sense to use it. But as we already have more high priority requests for features, I believe we can assume that commands will be a better fit.

**Benjamin:** So you propose to use more complex solution - isn't that "big design up front"?

**Johnny:** I believe that it isn't. Remember I'm using just *a bit* more complex solution. The cost of implementation is only a bit higher as well as the cost of maintenance in case I'm wrong. If for some peculiar reason someone says tommorow that they don't need the rest of the features at all, the increase in complexity will be negligible taking into account the small size of the overall code base. If, however, we add more features, then using commands will save us some time in the longer run. Thus, given what I know, [I am not adding this to support speculative new features, but to make the code easier to modify in the long run](https://martinfowler.com/bliki/Yagni.html). I agree though that [choosing just enough complexity for a given moment is a difficult task](https://www.youtube.com/watch?v=aCLBd3a1rwk).

**Benjamin:** I still don't get it how introducing a command is going to help us here. Typically, a command has an `Execute()` method that typically doesn't return anything. How then will it give us the response that we need to return from the `MakeReservation()`? And also, there's this another issue: how is this command going to be created? It will probably require the request passed as one of its constructor parameters, so we cannot pass the command to the `TicketOffice`'s constructor as the first time we can access the request is when the `MakeReservation()` method is invoked.

**Johnny:** Yes, you are right in both of your concerns. Thankfully, when you choose to go with commands, typically there are standard solutions to the problems you mentioned. The commands are typically created using factories and they can convey their results using a pattern called *collecting parameter*[^KerievskyCollectingParameter] - we will pass an object inside the command to gather all the events from handling the use case and then be able to prepare a response for us.

### Introducing a reservation in progress collaborator

**Johnny**: Let's start with the collecting parameter, which will represent a domain concept of a reservation in progress. What we currently know about it is that it's going to give us a response DTO at the very end. All of the three objects: the command, the collecting parameter and the factory, are collaborators, so they will be mocks in our Statement.

**Benjamin:** Ok, lead the way.

**Johnny:** Allright, let's start with the `GIVEN` section. Here, we need to say that the collecting parameter mock, let's call it `reservationInProgress` will give us the `expectedReservationDto` (which is already defined in the body of the Statement) when asked:

```csharp
//GIVEN
//...
reservationInProgress.ToDto().Returns(expectedReservationDto);
```

Of course, we don't have the `reservationInProgress` yet, so now we need to introduce it. As I explained earlier, this needs to be a mock, because otherwise, we wouldn't be able to call `Returns()` on it:

```csharp
///GIVEN
var reservationInProgress = Substitute.For<ReservationInProgress>();
//...
reservationInProgress.ToDto().Returns(expectedReservationDto);
//...
```

Now, the Statement does not compile because the `ReservationInProgress` interface that I just used in the mock definition is not introduced yet.

**Benjamin:** In other words, you just discovered that you need this interface.

**Johnny:** Exactly. What I'm currently doing is I'm pulling abstractions and objects into my code as I need them. And my current need is to have the following interface in my code:

```csharp
public interface ReservationInProgress
{

}
```

Now, the Statement still doesn't compile, because there's this line:

```csharp
reservationInProgress.ToDto().Returns(expectedReservationDto);
```

which requires the `ReservationInProgress` interface to have a `ToDto()` method, but for now, this interface is empty. After adding the required method, it looks like this:

```csharp
public interface ReservationInProgress
{
  ReservationDto ToDto();
}
```

and the Statement compiles again, although it is still a false one.

**Benjamin:** Ok. Now give me a second to grasp the full Statement in its current state.

**Johnny:** Sure, take your time, this is how it currently looks like:

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
  Assert.Equal(expectedReservationDto, reservationDto);
}
```

### Introducing a factory collaborator

**Benjamin:** Ok, I think I managed to catch up. Can I grab the keyboard?

**Johnny:** I was about to suggest it. Here.

**Benjamin:** Thanks. Looking at this Statement, we have this `ReservationInProgress` all set up and created, but this mock of ours is not passed to the `TicketOffice` at all. So how should the `TicketOffice` use our pre-configured `reservationInProgress`?

**Johnny:** Remember our discussion about separating object use from construction?

**Benjamin:** Yeah, I guess I know what you're getting at. The `TicketOffice` should somehow get an already created `ReservationInProgress` object from the outside. It can get it e.g. through a constructor or from a factory.

**Johnny:** Yes, and if you look at the lifetime scope of our `TicketOffice`, which is created once at the start of the application, it can't really accept a `ReservationInProgress` through a constructor, because every time a new reservation request is made, we want to have a new `ReservationInProgress`, so passing it through a `TicketOffice` constructor would force us to create a new `TicketOffice` every time as well. Thus, the solution that better fits our current situation is...

**Benjamin:** A factory, right? You're suggesting that instead of passing a `ReservationInProgress` through a constructor, we should rather pass something that knows how to create `ReservationInProgress` instances?

**Johnny:** Exactly.

**Benjamin:** Ok, so how to write it in the Statement?

**Johnny:** First, write what you really need. The factory needs to be a mock, because we need to configure it so that when asked, it returns our `ReservationInProgress` mock. So let's write that return configuration first, pretending we already have the factory available in our Statement body.

**Benjamin:** Let me see... right, that should do it:

```csharp
//GIVEN
...
reservationInProgressFactory.FreshInstance().Returns(reservationInProgress);
```

**Johnny:** Nice. Now the code does not compile, because we don't have a `reservationInProgressFactory`. So let's create it.

**Benjamin:** And, like you said earlier, it should be a mock. Then this will be the definition:

```csharp
var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
```

For the need of this line, I pretended that I have an interface called `ReservationInProgressFactory`, and, let me guess, you want me to introduce this interface now?

**Johnny:** (smiles)

**Benjamin:** Allright. Here:

```csharp
public interface ReservationInProgressRepository
{

}
```

And now, the compiler tells us that we don't have the `FreshInstance()` method, so let me introduce it:

```csharp
public interface ReservationInProgressRepository
{
    ReservationInProgress FreshInstance();
}
```

Good, the compiler doesn't complain anymore, but the Statement fails with a `NotImplementedException`.

**Johnny:** Yes, this is because the current body of the `MakeReservation()` method of the  `TicketOffice` class looks like this:

```csharp
public ReservationDto MakeReservation(ReservationRequestDto requestDto) 
{
  throw new NotImplementedException("Not implemented");
}
```

### Expanding the ticket office constructor

**Benjamin:** So should we implement this now?

**Johnny:** We still some stuff to do in the Statement.

**Benjamin:** Like..?

**Johnny:** For example, the `ReservationInProgressFactory` mock that we just created is not passed to the `TicketOffice` constructor yet, so there is no way for the ticket office to use this factory.

**Benjamin:** Ok, so I'll add it. The Statement will change in this place:

```csharp
var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
var ticketOffice = new TicketOffice();
```

to:

```csharp
var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
var ticketOffice = new TicketOffice(reservationInProgressFactory);
```

and a constructor needs to be added to the `TicketOffice` class:

```csharp
public TicketOffice(ReservationInProgressFactory reservationInProgressFactory)
{

}
```

**Johnny:** Agreed. And, we need to maintain the composition root which just stopped compiling. This is because the constructor of a `TicketOffice` is invoked there and it needs an update as well:

```csharp
public class Application
{
  public static void Main(string[] args)
  {
    new WebApp(
        new TicketOffice(/* compile error - instance missing */)
    ).Host();
  }
}
```

**Benjamin:** But what should we pass? We have an interface, but no class of which we could create an instance.

**Johnny:** We need to create the class. Typically, if I have an idea about the name of the required class, I create the class by that name. If I don't have any idea on how to call it yet, I can call it e.g. `TodoReservationInProgressFactory` and leave a TODO comment to get back to it later. For now, we just need this class to compile the code. It's still out of scope of our current Statement.

**Benjamin:** So maybe We could pass a `null` so that we have `new TicketOffice(null)`?

**Johnny:** We could, but that's not my favourite option. I typically just create the class. One of the reasons is that the class will need to implement an interface to compile and then we will need to introduce a methods which will by default throw a  `NotImplementedException` and these exceptions will end up on my TODO list as well.

**Benjamin:** Ok, that sounds reasonable for me. So this line:

```csharp
new TicketOffice(/* compile error - instance missing */)
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

**Johnny:** It still doesn't compile, because the interface `ReservationInProgressFactory` has some methods that we need to implement. Thankfully, we can do this with a single IDE command and get:

```csharp
public class TodoReservationInProgressFactory : ReservationInProgressFactory
{
    public ReservationInProgress FreshInstance()
    {
        throw new NotImplementedException();
    }
}
```

and, as I mentioned a second ago, this exception will end up on my TODO list, reminding me that I need to address it.

Let's backtrack to the constructor of `TicketOffice`:

```csharp
public TicketOffice(ReservationInProgressFactory reservationInProgressFactory)
{

}
```

here, we could already assign the constructor parameter to a field, but it's also OK to do it later.

**Benjamin:** Let's so it later, I wonder how far we can get delaying work like this.

### Introducing a command collaborator

**Johnny:** Sure. So let's take a look at the Statement we're writing. It seems we are missing one more expectation in our `THEN` section. if you look at the Statement's full body as it is now:

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

the only interaction between a `TicketOffice` and `ReservationInProgress` it describes is the former calling the `ToDto` method on the latter. So the question that we need to ask ourselves now is "how will the instance of `ReservationInProgress` know what `ReservationDto` to create when this method is called?".

**Benjamin:** Oh right... the `ReservationDto` needs to be created by the `ReservationInProgress` based on the current application state and the data in the `ReservationRequestDto`, but the `ReservationInProgress` knows nothing about any of these things so far.

**Johnny:** Yes, filling the `ReservationInProgress` is one of the responsibilities of the application we are writing. If we did it all in thie `TicketOffice` class, this class would surely have too much to handle and our Statement would grow immensely. So we need to push the responsibility of handling our use case further to other collaborating objects and use mocks for those objects here.

**Benjamin:** So what do you propose?

**Johnny:** Remember our discussion from several minutes ago? Usually, when I push a use case-related logic to another object at the system boundary, I pick from among the Facade pattern and the Command pattern. Fadaces are simpler but less scalable, while commands are way more scalable and composable but a new command object needs to be created by the application each time a use case is triggered and a new command class needs to be created by a programmer when support for a new use case is added to the system.

**Benjamin:** Ok, I already know that you prefer commands.

**Johnny:** Well, yeah, bear with me if only for the sake of seeing how commands can be used here. I am sure you could figure out the Facade option by yourself.

**Benjamin:** Ok, so what do I type?

**Johnny:** Well, let's assume we have this command and then let's think about what we want our `TicketOffice` to do with it.

**Benjamin:** We want the `TicketOffice` to execute the command, obviously..?

**Johnny:** Right, let's write this in form of expectation.

**Benjamin:** Ok, I'd write something like this:

```csharp
reservationCommand.Received(1).Execute(reservationInProgress);
```

I already passed the `reservationInProgress` as the command will need to fill it.

**Johnny:** Wait, it so happens that I prefer another way of passing this `reservationInProgress` to the `Execute()` method. Please for now make the `Execute()` method parameterless.

**Benjamin:** As you wish, but I thought this would be a good place to pass it.

**Johnny:** It might look like it, but typically, I want my commands to have parameterless execution methods. This way I can compose them more freely.

**Benjamin:** I removed the parameter and the `THEN` section looks like this:

```csharp
//THEN
reservationCommand.Received(1).Execute();
Assert.Equal(expectedReservationDto, reservationDto);
```

and it doesn't compile of course. So I already know I need to introduce a variable of a type that I have to pretend already exists. Aaaand, I already know it should be a mock, since I verify that it received a call to its `Execute()` method.

**Johnny:** (nods)

**Benjamin:** In the `GIVEN` section, I'll add the `reservationCommand` as a mock:

```csharp
var reservationCommand = Substitute.For<ReservationCommand>();
```

and now I don't have this `ReservationCommand` interface so I can create it:

```csharp
public interface ReservationCommand
{

}
```

and the code still doesn't compile, because in the Statement, I expect to receive an  `Execute()` method call on the command but there's no such method. I can fix it by adding this method on the command interface:

```csharp
public interface ReservationCommand
{
  void Execute();
}
```

and now everything compiles again.

### Introducing a command factory collaborator

**Johnny:** Sure, now we need to figure out how to pass this command to the `TicketOffice`. As we discussed, by nature, a command object represents, well, an issued command, so it cannot be created once in the composition root and then passed to the constructor, because then:

1. it would essentially become a facade,
1. we would need to pass the `reservationInProgress` to the `Execute()` method which we wanted to avoid.

**Benjamin:** Wait, don't tell me... you want to add another factory here?

**Johnny:** Yes, that's what I would like to do.

**Benjamin:** But... that's a second factory in a single Statement. Aren't we, like, overdoing it a little?

**Johnny:** I understand why you feel that way. Still, this is a consequence of my design choice. We wouldn't need a command factory if we went with a facade. In simple apps, I just use a facade and do away with this dilemma. I could also drop the use of collecting parameter patern and then I wouldn't need a factory for reservations in progress, but that would mean I would not resolve the command-query separation principle violation and would need to push this violation further into my code. To cheer you up, this is an entry point for a use case where we need to wrap some things in abstractions, so I don't expect this many factories in the rest of the code. I treat this part as a sort of anti-corruption layer which protects me from everything imposed by outside of my application logic which I don't want to deal with inside of my application logic.

**Benjamin:** I will need to trust you on that. I hope it will make things easier later because for now... ugh...

**Johnny:** Let's introduce the factory mock. Of course, before we define it, we want to use it first to feel a need for it. This code needs to go into the `GIVEN` section:

```csharp
//GIVEN
...
commandFactory.CreateReservationCommand(requestDto, reservationInProgress)
    .Returns(reservationCommand);
```

This doesn't compile because we have no commandFactory yet.

**Benjamin:** Oh, I can see that the factory's `CreateReservationCommand()` is where you decided to pass the `reservationInProgress` that I wanted to pass to the `Execute()` method earlier. Clever. By leaving the commands's `Execute()` method parameterless, you made it more abstract and made the interface decpoupled from any particular argument types. On the other hand, the command is created in the same scope it is used, so there is literally no issue with passing all the parameters through the factory method.

**Johnny:** That's right. We now know we need a factory, plus that it needs to be a mock, since we configure it to return a command when it is asked for one. I propose something like this:

```csharp
//GIVEN
...
var commandFactory = Substitute.For<CommandFactory>();
...
commandFactory.CreateReservationCommand(requestDto, reservationInProgress)
    .Returns(reservationCommand);
```

**Benjamin:** ...and the `CommandFactory` doesn't exist, so let's create it:

```csharp
public interface CommandFactory
{

}
```

and let's add the missing `CreateReservationCommand` method:

```csharp
public interface CommandFactory
{
  ReservationCommand CreateReservationCommand(
    ReservationRequestDto requestDto,
    ReservationInProgress reservationInProgress);
}
```

**Benjamin:** Now the code compiles and looks like this:

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
  
  commandFactory.CreateReservationCommand(requestDto, reservationInProgress)
    .Returns(reservationCommand);
  reservationInProgressFactory.FreshInstance().Returns(reservationInProgress);
  reservationInProgress.ToDto().Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservationDto, reservationDto);
  reservationCommand.Received(1).Execute();
}
```

**Benjamin:** I can see that the command factory is not passed anywhere from the Statement - the `TicketOffice` doesn't know about it.

**Johnny:** Yes, and, lucky us, a factory is something that can have the same lifetime scope as the `TicketOffice` since to create the factory, we don't need to know anything about a request for reservation. This is why we can pass it through the constructor of `TicketOffice`. Which means that these two lines:

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

As this doesn't compile, we need to add a parameter of type `CommandFactory` to the constructor:

```csharp
public TicketOffice(
    ReservationInProgressFactory reservationInProgressFactory,
    CommandFactory commandFactory)
{

}
```

and, this forces us to add a parameter to our composition root. So this part of the composition root:

```csharp
new TicketOffice(
    new TodoReservationInProgressFactory()) //TODO change the name
```

becomes:

```csharp
new TicketOffice(
    new TodoReservationInProgressFactory(), //TODO change the name
    new TicketOfficeCommandFactory())
```

which in turn forces us to create the `TicketOfficeCommandFactory` class:

```csharp
public class TicketOfficeCommandFactory : CommandFactory
{
  public ReservationCommand CreateReservationCommand(ReservationRequestDto requestDto)
  {
      throw new NotImplementedException();
  }
}
```

**Benjamin:** Hey, this time you gave the class a better name than the previous factory which was called `TodoReservationInProgressFactory`. Why didn't you want to leave it for later this time?

**Johnny:** This time, I think I have a better idea on how to name this class. Typically, I name concrete classes based on something from their implementation and I find the names hard to find when I don't have this implementation yet. This time I believe I have a name that can last a bit, which is also why I didn't leave a TODO comment next to this name. Still, further work can invalidate my naming choice and I will be happy to change the name when a need arises. For now, it should suffice.

### Giving the Statement a name

Anyway, getting back to the Statement, I think we've got it all covered. Let's just give it a good name. Looking at the assertions:

```csharp
reservationCommand.Received(1).Execute();
Assert.Equal(expectedReservationDto, reservationDto);
```

I think we can say:

```csharp
public void 
ShouldExecuteReservationCommandAndReturnResponseWhenMakingReservation()
```

**Benjamin:** Just curious... Didn't you tell me to watch out for the "and" word in Statement names and that it may suggest something is wrong with the scenario.

**Johnny:** Yes, and in this particular case, there *is* something wrong - the class `TicketOffice` violates the command-query separation principle. This is also why the Statement looks so messy. For this class, however, we don't have a big choice since our framework requires this kind of method signature. That's also why we are working so hard in this class to introduce the collecting parameter and protect the rest of the design from the violation.

**Benjamin:** Ok, I hope the future Statements will be easier to write than this one.

**Johnny:** Me too.

### Making the Statement true - the first assertion

**Johnny:** Let's take a look at the code of the Statement:

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

**Johnny:** I think it is complete, but we won't know that until we see the assertions failing and then passing. For now, the implementation of `MakeReservation()` method throws an exception and this exception makes our Statement stop at the `WHEN` stage, not even getting to the assertions.

**Benjamin:** But I can't just put the right implementation in yet, right? This is what you have always told me.

**Johnny:** Yes, ideally, we should see the assertion errors to gain confidence that the Statement *can* turn false when the expected behavior is not in place.

**Benjamin:** This can only mean one thing - return `null` from the `TicketOffice` instead of throwing the exception. Right?

**Johnny:** Yes, let me do it. I'll just change this code:

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

Now I can see that the first assertion:

```csharp
Assert.Equal(expectedReservationDto, reservationDto);
```

is failing, because it expects an `expectedReservationDto` from the `reservationInProgress` but the `reservationInProgress` itself can only be received from the factory. The relevant lines in the Statement that say this are:

```csharp
reservationInProgressFactory.FreshInstance()
    .Returns(reservationInProgress);
 reservationInProgress.ToDto()
    .Returns(expectedReservationDto);
```

Let's just implement the part that is required to pass the first assertion. To do this, I will need to create a field in the `TicketOffice` class for the factory, based on one of the constructor parameters. So this code:

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

**Benjamin:** Couldn't you just introduce the other field as well?

**Johnny:** Yes, I could and I usually do that. But since we are training, I want to show you that we will be forced to do so anyway to make the second assertion pass.

**Benjamin:** Ok, go on.

**Johnny:** Now I have to modify the `MakeReservation()` method by adding the following code that creates the reservation in progress and makes it return a DTO:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
return reservationInProgress.ToDto();
```

**Benjamin:** ...and the first assertion passes.

### Making the Statement true - the second assertion

**Johnny:** Yes, and this is clearly not enough. If you look at the production code, we are not doing anything with the `ReservationRequestDto` instance. Thankfully, we have the second assertion:

```csharp
reservationCommand.Received(1).Execute();
```

and this one fails. In order to make it pass, We need to create a command and execute it.

**Benjamin:** Wait, why are you calling this an "assertion"? There isn't a word "assert" anywhere in this line. Shouldn't we just call it "mock verification" or something like that?

**Johnny:** I'm OK with "mock verification", however, I consider it correct to call it an assertion as well, because, in essence, that's what it is - a check that throws an exception when a condition is not met.

**Benjamin:** OK, if that's how you put it...

**Johnny:** anyway, we still need this assertion to pass.

**Benjamin:** Let me do this. So to create a command, we need the command factory and this is why at this moment, we need to introduce the second `TicketOffice` constructor argument, because as of now, the constructor looks like this:

```csharp
public TicketOffice(
    ReservationInProgressFactory reservationInProgressFactory,
    CommandFactory commandFactory)
{
  _reservationInProgressFactory = reservationInProgressFactory;
}
```

And I need to modify this code to assign the constructor parameter to a new field:

```csharp
private readonly CommandFactory _commandFactory;

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
var reservationCommand = _commandFactory.CreateReservationCommand(
  requestDto, reservationInProgress);
return reservationInProgress.ToDto();
```

At last, I just need to execute the command like this:

```csharp
var reservationInProgress = _reservationInProgressFactory.FreshInstance();
var reservationCommand = _commandFactory.CreateReservationCommand(requestDto);
reservationCommand.Execute();
return reservationInProgress.ToDto();
```

**Johnny:** Great! Now the Statement is true.

**Benjamin:** Wow, this isn't a lot of code for such a big Statement that we wrote.

**Johnny:** Yeah, the real complexity is not even in the lines of code, but the amount of dependencies that we had to drag inside. Note that we have two factories in here. Each factory is a dependency and it creates another dependency. This is better visible in the Statement and this is why I find it a good idea to pay close attention to how a Statement is growing and using it as a feedback mechanism for the quality of design. For this particular class, the design issue we observe in the Statement can't be helped a lot since, as I mentioned, this is the boundary where we need to wrap things in abstractions.

**Benjamin:** You'll have to explain this bit about design quality a bit more later.

**Johnny:** Yeah, sure. Tea?

**Benjamin:** Coffee.

**Johnny:** Whatever, let's go.

## Summary

This is how Johnny and Benjamin accomplished their first Statement using TDD and mock with an outside-in design approach. What will follow in the next chapter is a small retrospective with comments on what these guys did. One thing I'd like to mention now is that the outside-in approach does not rely solely on unit tests, so what you saw here is not the full picture. We will get to that soon.

[^POEAA]: Patterns of enterprise application architecture, M. Fowler.
