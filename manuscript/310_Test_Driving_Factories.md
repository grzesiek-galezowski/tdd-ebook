1. No refactoring
1. There will be no story slicing
1. No higher level tests
1. ..?


//////////////////////////////////


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

///////////////////////////////////////////////////////////////////////

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
