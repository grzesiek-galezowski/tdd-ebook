# Test-driving application logic

**Johnny:** What's next on our TODO list?

**Benjamin:** We have...

* a single reminder to change the name of the factory that creates `ReservationInProgress` instances. 
* Also, we have two places where a `NotImplementedException` suggests there's something left to implement. 
  * The first one is the mentioned factory. 
  * The second one is the `NewReservationCommand` class that we discovered when writing a Statement for the factory.

**Johnny:** Let's do the `NewReservationCommand`. I suspect the complexity we put inside the controller will pay back here and we will be able to test-drive the command logic on our own terms.

**Benjamin:** Can't wait to see that. Here's the current code of the command:

```csharp
public class NewReservationCommand : ReservationCommand
{
 public void Execute()
 {
  throw new NotImplementedException();
 } 
}
```

**Johnny:** So we have the class and method signature. It seems we can use the usual strategy of writing new Statement.

**Benjamin:** You mean "start by invoking a method if you have one"? I thought of the same. Let me try it.

```csharp
public class NewReservationCommandSpecification
{
 [Fact] public void
 ShouldXXXXXXXXXXX() //TODO change the name
 {
  //GIVEN
  var command = new NewReservationCommand();
  
  //WHEN
  command.Execute();
 
  //THEN
  Assert.True(false); //TODO unfinished
 }
}
```

This is what I could write almost brain-dead. I just took the parts we have and put them in the Statement.

The assertion is still missing - the one we have is merely a placeholder. This is the right time to think what should happen when we execute the command.

**Johnny:** To come up with that expected behavior, we need to look back to the input data for the whole use case. We passed it to the factory and forgot about it. So just as a reminder - here's how it looks like:

```csharp
public class ReservationRequestDto
{
  public readonly string TrainId;
  public readonly uint SeatCount;

  public ReservationRequestDto(string trainId, uint seatCount)
  {
    TrainId = trainId;
    SeatCount = seatCount;
  }
}
```

The first part is train id -- it says on which train we should reserve the seats. So we need to somehow pick a train from the fleet for reservation. Then, on that train, we need to reserve as many seats as the customer requests. The requested seat count is the second part of the user request.

**Benjamin:** Aren't we going to update the data in some kind of persistent storage? I doubt that the railways company would want the reservation to disappear on application restart.

**Johnny:** Yes, we need to act as if there was some kind of persistence. 

Given all of above, I can see two new roles in our scenario:

1. A fleet - from which we pick the train and where we save our changes
1. A train - which is going to handle the reservation logic.

Both of these roles need to be modeled as mocks, because I expect them to play active roles in this scenario.

Let's expand our Statement with our discoveries. 

```csharp
[Fact] public void
ShouldReserveSeatsInSpecifiedTrainWhenExecuted()
{
 //GIVEN
 var command = new NewReservationCommand(fleet);
 
 fleet.Pick(trainId).Returns(train);

 //WHEN
 command.Execute();

 //THEN
 Received.InOrder(() =>
 {
  train.ReserveSeats(seatCount);
  fleet.UpdateInformationAbout(train);
 };
}
```

**Benjamin:** I can see there are many things missing here. For instance, we don't have the `train` and `fleet` variables.

**Johnny:** We created a need for them. I think we can safely introduce them into the Statement now.

```csharp
[Fact] public void
ShouldReserveSeatsInSpecifiedTrainWhenExecuted()
{
 //GIVEN
 var fleet = Substitute.For<TrainFleet>();
 var train = Substitute.For<ReservableTrain>();
 var command = new NewReservationCommand(fleet);
 
 fleet.Pick(trainId).Returns(train);

 //WHEN
 command.Execute();

 //THEN
 Received.InOrder(() =>
 {
  train.ReserveSeats(seatCount);
  fleet.UpdateInformationAbout(train);
 };
}
```

**Benjamin:** I see two new types: `TrainFleet` and `ReservableTrain`.

**Johnny:** They symbolize the roles we just discovered.

**Benjamin:** Also, I can see that you used `Received.InOrder()` from NSubstitute to specify the expected call order.

**Johnny:** That's because we need to reserve the seats before we update the information in some kind of storage. If we got the order wrong, the change could be lost.

**Benjamin:** But something is missing in this Statement. I just looked at the outputs our users expect:

```csharp
public class ReservationDto
{
  public readonly string TrainId;
  public readonly string ReservationId;
  public readonly List<TicketDto> PerSeatTickets;

  public ReservationDto(
    string trainId,
    List<TicketDto> perSeatTickets,
    string reservationId)
  {
    TrainId = trainId;
    PerSeatTickets = perSeatTickets;
    ReservationId = reservationId;
  }
}
```

That's a lot of info we need to pass back to the user. How exactly are we going to do that when the `train.ReserveSeats(seatCount)` call you invented is not expected to return anything?

**Johnny:** Ah, yes, I almost forgot - we've got the `ReservationInProgress` instance that we passed to the factory, but not yet to the command, right? The `ReservationInProgress` was invented exactly for this purpose - to gather the information necessary to produce a result of the whole operation. Let me just quickly update the Statement:

```csharp
[Fact] public void
ShouldReserveSeatsInSpecifiedTrainWhenExecuted()
{
 //GIVEN
 var fleet = Substitute.For<TrainFleet>();
 var train = Substitute.For<ReservableTrain>();
 var reservationInProgress = Any.Instance<ReservationInProgress>();
 var command = new NewReservationCommand(fleet, reservationInProgress);
 
 fleet.Pick(trainId).Returns(train);

 //WHEN
 command.Execute();

 //THEN
 Received.InOrder(() =>
 {
  train.ReserveSeats(seatCount, reservationInProgress);
  fleet.UpdateInformationAbout(train);
 };
}
```

Now the `ReserveSeats` method accepts `reservationInProgress`.

**Benjamin:** Why are you passing the `reservationInProgress` further to the `ReserveSeats` method?

**Johnny:** The command does not have the necessary information to fill the `reservationInProgress` once the reservation is successful. We need to defer it to the `ReservableTrain` implementations to further decide the best place to do that.

 **Benjamin:** I see. Looking at the Statement again - we're missing two more variables -- `trainId` and `seatCount` -- and not only their definitions, but also we don't pass them to the command at all. They are only present in our assumptions and expectations.

 **Johnny:** Right, let me correct that.

```csharp
[Fact] public void
ShouldReserveSeatsInSpecifiedTrainWhenExecuted()
{
 //GIVEN
 var fleet = Substitute.For<TrainFleet>();
 var train = Substitute.For<ReservableTrain>();
 var trainId = Any.String();
 var seatCount = Any.UnsignedInt();
 var reservationInProgress = Any.Instance<ReservationInProgress>();
 var command = new NewReservationCommand(
   trainId,
   seatCount,
   fleet, 
   reservationInProgress);
 
 fleet.Pick(trainId).Returns(train);

 //WHEN
 command.Execute();

 //THEN
 Received.InOrder(() =>
 {
  train.ReserveSeats(seatCount, reservationInProgress);
  fleet.UpdateInformationAbout(train);
 };
}
```

**Benjamin:** Why is `seatCount` a `uint`?

**Johnny:** Look it up in the DTO - it's a `uint` there. I don't see the need to redefine that here.

**Benjamin:** Fine, but what about the `trainId` - it's a `string`. Didn't you tell me we need to use domain-related value objects for concepts like this?

**Johnny:** Yes, and we will refactor this `string` into a value object, especially that we have a requirement that train id comparisons should be case-insensitive. But first, I want to finish this Statement before I go into defining and specifying a new type. Still, we'd best leave a TODO note to get back to it later:

```csharp
 var trainId = Any.String(); //TODO extract value object
```

So far so good, I think we have a complete Statement. Want to take the keyboard?

**Benjamin:** Thanks. Let's start implementing it then. First, I will start with these two interfaces:

```csharp
var fleet = Substitute.For<TrainFleet>();
var train = Substitute.For<ReservableTrain>();
```

They don't exist, so this code doesn't compile. I can easily fix this by creating the interfaces in the production code:

```csharp
public interface TrainFleet
{
}

public interface ReservableTrain
{
}
```

Now for this part:

```csharp
var command = new NewReservationCommand(
   trainId,
   seatCount,
   fleet, 
   reservationInProgress);
```

It doesn't compile because the command does not accept any constructor parameters yet. Let's create a fitting constructor, then:

```csharp
public class NewReservationCommand : ReservationCommand
{
 public NewReservationCommand(
  string trainId,
  uint seatCount,
  TrainFleet fleet,
  ReservationInProgress reservationInProgress)
 {

 }

 public void Execute()
 {
  throw new NotImplementedException();
 } 
}
```

Our Statement can now invoke this constructor, but we broke the `TicketOfficeCommandFactory` which also creates a `NewReservationCommand` instance. Look:

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto,
    ReservationInProgress reservationInProgress)
 {
  //Stopped compiling:
  return new NewReservationCommand();
 }
```

**Johnny:** We need to fix the factory the same way we needed to fix the composition root when test-driving the controller. Let's see... Here:

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto,
    ReservationInProgress reservationInProgress)
 {
  return new NewReservationCommand(
   requestDto.TrainId,
   requestDto.SeatCount,
   new TodoTrainFleet(), // TODO fix name and scope
   reservatonInProgress
   );
 }
```

**Benjamin:** The parameter passing looks straightforward to me except the `TodoTrainFleet()` -- I already know that the name is a placeholder - you already did something like that earlier. But what about the lifetime scope?

**Johnny:** It's also a placeholder. For now, I want to make the compiler happy, at the same time keeping existing Statements true and introducing a new class -- `TodoTrainFleet` --  that will bring new items to our TODO list.

**Benjamin:** New TODO items?

**Johnny:** Yes. Look -- the type `TodoTrainFleet` does not exist yet. I'll create it now:

```csharp
public class TodoTrainFleet
{

}
```

This doesn't match the signature of the command constructor, which expects a `TrainFleet`, so I need to make `TodoTrainFleet` implement this interface:

```csharp
public class TodoTrainFleet : TrainFleet
{

}
```

Now I am forced to implement the methods from the `TrainFleet` interface. Although this interface doesn't define any methods yet, we already discovered two in our Statement, so it will shortly need to get them to make the compiler happy. They will both contain code throwing `NotImplementedException`, which will land on the TODO list.

**Benjamin:** I see. Anyway, the factory compiles again. We still got this part of the Statement left:

```csharp
 fleet.Pick(trainId).Returns(train);

 //WHEN
 command.Execute();

 //THEN
 Received.InOrder(() =>
 {
  train.ReserveSeats(seatCount, reservationInProgress);
  fleet.UpdateInformationAbout(train);
 };
```

**Johnny:** That's just introducing three methods. You can handle it.

**Benjamin:** Thanks. The first line is `fleet.Pick(trainId).Returns(train)`. I'll just generate the `Pick` method using my IDE:

```csharp
public interface TrainFleet
{
 ReservableTrain Pick(string trainId);
}
```

The `TrainFleet` interface is implemented by the `TodoTrainFleet` we talked about several minutes ago. It needs to implement the `Pick` method as well or else it won't compile:

```csharp
public class TodoTrainFleet : TrainFleet
{
 public ReservableTrain Pick(string trainId)
 {
   throw new NotImplementedException();
 }
}
```

This `NotImplementedException` will land on our TODO list just as you mentioned. Nice!

Then comes the next line from the Statement: `train.ReserveSeats(seatCount, reservationInProgress)` and I'll generate a method signature out of it the same as from the previous line.

```csharp
public interface ReservableTrain
{
 void ReserveSeats(uint seatCount, ReservationInProgress reservationInProgress);
}
```

`ReservableTrain` interface doesn't have any implementations so far, so nothing more to do with this method.

The last line: `fleet.UpdateInformationAbout(train)` which needs to be added to the `TrainFleet` interface:

```csharp
public interface TrainFleet
{
 ReservableTrain Pick(string trainId);
 void UpdateInformationAbout(ReservableTrain train);
}
```

Also, we need to define this method in the `TodoTrainFleet` class:

```csharp
public class TodoTrainFleet : TrainFleet
{
 public ReservableTrain Pick(string trainId)
 {
   throw new NotImplementedException();
 }

 void UpdateInformationAbout(ReservableTrain train)
 {
   throw new NotImplementedException();
 }
}
```

**Johnny:** This `NotImplementedException` will be added to the TODO list as well, so we can revisit it later. It looks like the Statement compiles and, as expected, is false, but not for the right reason.

**Benjamin:** Let me see... yes, a `NotImplementedException` is thrown from the command's `Execute()` method.

**Johnny:** Let's get rid of it.

**Benjamin:** Sure. I removed the `throw` and the method is empty now:

```csharp
 public void Execute()
 {
  
 }
```

The Statement is false now because the expected calls are not matched.

**Johnny:** Which means we are finally ready to code some behavior into the `NewReservationCommand` class. First, let's assign all the constructor parameters to fields -- we're going to need them.

**Benjamin:** Here:

```csharp
public class NewReservationCommand : ReservationCommand
{
 private readonly string _trainId;
 private readonly uint _seatCount;
 private readonly TraingFleet _fleet;
 private readonly ReservationInProgress _reservationInProgress;

 public NewReservationCommand(
  string trainId,
  uint seatCount,
  TrainFleet fleet,
  ReservationInProgress reservationInProgress)
 {
  _trainId = trainId;
  _seatCount = seatCount;
  _fleet = fleet;
  _reservationInProgress = reservationInProgress;
 }

 public void Execute()
 {
  throw new NotImplementedException();
 } 
}
```

**Johnny:** Now, let's add the calls expected in the Statement, but in the opposite order.

**Benjamin:** To make sure the order is asserted correctly in the Statement?

**Johnny:** Exactly.

**Benjamin:** Ok.

```csharp
public void Execute()
{
 var train = _fleet.Pick(_trainId);
 _fleet.UpdateInformationAbout(train);
 train.ReserveSeats(seatCount);
}
```

The Statement is still false, this time because of the wrong call order. Now that we have confirmed that we need to make the calls in the right order, I suspect you want me to reverse it, so...

```csharp
public void Execute()
{
 var train = _fleet.Pick(_trainId);
 train.ReserveSeats(seatCount, reservationInProgress);
  _fleet.UpdateInformationAbout(train);
}
```

**Johnny:** Exactly. The Statement is now true. Congratulations!

**Benjamin:** Now that I look at this code, it's not protected from any kind of exceptions that might be thrown from either the `_fleet` or the `train`.

**Johnny:** Add that to the TODO list - we will have to take care of that, sooner or later. For now, let's take a break.

## Summary

In this chapter, Johnny and Benjamin used interface discovery again. They used some technical and some domain-related reasons to create a need for new abstractions and design their communication protocols. These abstractions were then pulled into the Statement. 

Remember Johnny and Benjamin extended effort when test-driving the controller. This effort paid off now - they were free to shape abstractions mostly outside the constraints imposed by a specific framework.

This chapter does not have a retrospective companion chapter like the previous ones. Most of the interesting stuff that happened here was already explained earlier.
