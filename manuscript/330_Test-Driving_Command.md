# Test-driving application logic

Johnny: What's next on our TODO list?

Benjamin: We have a single reminder to change the name of the factory that creates `ReservationInProgress` instances. Also, we have two places where a `NotImplementedException` suggests there's something left to implement. The first one is the mentioned factory. The second one is the `NewReservationComand` class that we discovered when writing a Statement for the factory.

Johnny: Let's do the command. I suspect the complexity we put inside the controller will pay back here and we will be able to do some TDD with mocks on our own terms.

Benjamin: Can't wait to see that. Here's the code of the command we have so far:

```csharp
public class NewReservationCommand : ReservationCommand
{
 public void Execute()
 {
  throw new NotImplementedException();
 } 
}
```

Johnny: So we have the class and method signature. Seems we can use the usual strategy of writing new Statement.

Benjamin: Yes, "start by invoking a method if you have one". I'll start then.

This is what I can write almost brain-dead:

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

We need to think now what should happen when we execute the command.

Johnny: To do that, we need to look back to the input data for this use case. We passed it to the factory and forgot about it. Here's how it looks like:

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

The first part is train id -- it says on which train we should reserve the seats. So we need to somehow pick a train from the fleet. Then, on that train, we need to reserve as many seats as the customer requests. This is the second part of the user request.

Benjamin: Aren't we going to update the data in some kind of persistent storage? I doubt that the railways company would want the reservation to disappear on application restart.

Johnny: Yes, we need to act as if there was some kind of persistence. Anyway, I can see two roles here:

1. A fleet - which is from where we pick the train and where we save our changes
1. A train - which is going to handle the reservation logic.

Both of them need to be mocks, because I expect them to play active roles in this scenario. Given all of this, my first stab would be something like this:

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

Benjamin: I can see there are many things missing here. For instance, we don't have the `train` and `fleet` variables. 

Johnny: We created a need for them. I think we can safely introduce them into the Statement.

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

Benjamin: I see two new types.

Johnny: They symbolize the roles we just discovered.

Benjamin: Also, I can see that you used `Received.InOrder()`

Johnny: That's because we need to reserve the seats before we update the information in some kind of storage. If we got the order wrong, the change could be lost.

Benjamin: But there's something missing in this Statement. I just looked at the outputs out users expect:

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

how exactly are we going to pass all of this information back to the user when the `train.ReserveSeats(seatCount)` call you invented is not expected to return anything?

Johnny: Ah, yes, I almost forgot - we've got the `ReservationInProgress` instance that we passed to the factory, but not here, right? The `ReservationInProgress` was invented exactly for this purpose - to gather the information necessary to produce a result of the whole operation. Let me just quickly update the Statement:

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

Benjamin: Why are you passing the `reservationInProgress` further to the `ReserveSeats` method?

Johnny: The command does not have the necessary information to pass to the `reservationInProgress` once the reservation is successful. We need to defer it to the `ReservableTrain` implementations to further decide the best place to use it.

 Benjamin: I see. And you're missing two more variables -- `trainId` and `seatCount` -- and not only definitions, but also we don't pass them to the command at all. They are only present in our assumptions and expectations.

 Johnny: Right, let me correct that.

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

Benjamin: Why is `seatCount` a `uint`?

Johnny: Look it up in the DTO - it's a `uint` there. I don't see the need to redefine that here.

Benjamin: Fine, but what about the trainId - it's a `string`. Didn't you tell me we need to use value objects for concepts like this?

Johnny: Yes, and we will refactor this `string` into a value object, especially that train id comparisons should be case-insensitive. But first, I want to finish this Statement before I go into defining and specifying a new type. Still, we'd best leave a TODO note to get back to it later:

```csharp
 var trainId = Any.String(); //TODO extract value object
```

So far so good, I think we have a complete Statement. Want to take the keyboard?

Benjamin: Thanks. Let's start implementing it then. First, I will start with these two interfaces:

```csharp
var fleet = Substitute.For<TrainFleet>();
var train = Substitute.For<ReservableTrain>();
```

They don't exist so this code doesn't compile. I can easily fix this by introducing the interfaces:

```csharp
interface TrainFleet
{
}

interface ReservableTrain
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

It doesn't compile because the command does not accept any constructor parameters, but we are passing four.



TODO one more question: repo.Update(x) or x.UpdateIn(repo)??????