
## Initial objects

### Request

```csharp
public class ReservationRequestDto
{
  public readonly string trainId;
  public readonly int seatCount;

  public ReservationRequestDto(string trainId, int seatCount)
  {
    this.trainId = trainId;
    this.seatCount = seatCount;
  }
}
```

### Response

```csharp
public class TicketDto
{
  public readonly string trainId;
  public readonly string ticketId;
  public readonly List<SeatDto> seats;

  public TicketDto(string trainId, List<SeatDto> seats, string ticketId)
  {
    this.trainId = trainId;
    this.ticketId = ticketId;
    this.seats = seats;
  }
}
```

```csharp
public class SeatDto
{
  public readonly string coach;
  public readonly int seatNumber;

  public SeatDto(string coach, int seatNumber)
  {
    this.coach = coach;
    this.seatNumber = seatNumber;
  }

}
```

## bootstrap

hosting the web app. The web part is already written, time for the TicketOffice.

```csharp
public class Main
{
  public static void Main(string[] args) 
  {
    new WebApp(new TicketOffice()).Host();
  }
}
```

Ticket office class:

```csharp
public class TicketOffice
{
    public TicketDto MakeReservation(ReservationRequestDto requestDto) 
    {
        throw new NotImplementedException("Not implemented");
    }
}
```

## Let's go!

### First Statement skeleton:

(brain dump -> method, assertion, good name, not a full Statement yet)

```csharp
public class TicketOfficeSpecification
{

  [Fact]
  public void ShouldCreateAndExecuteCommandWithTicketAndTrain()
  {
    //WHEN
    var ticketOffice = new TicketOffice();
    var reservation = Any.Instance<ReservationRequestDto>();

    //WHEN
    var ticketDto = ticketOffice.MakeReservation(reservation);

    //THEN
    Assert.Equal(resultDto, ticketDto);
  }
}
```

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
    //WHEN
    var ticketDto = ticketOffice.MakeReservation(reservation);
```

This leads to discovery of `Ticket` interface and `ToDto()` method.

```csharp
         var ticketOffice = new TicketOffice();
         var reservation = Any.Instance<ReservationRequestDto>();
         var resultDto = Any.Instance<TicketDto>();
+        Ticket ticket = Substitute.For<Ticket>();
 
         ticket.ToDto().Returns(resultDto);
```

And this needs to be represented in code (btw, are the rest of the objects shown implemented?)

```csharp
+public interface Ticket
+{
+}

```

Introduced toDto method. But how to pass the Ticket?

```csharp
public interface Ticket
{
+ TicketDto toDto();
}
```

//TODO this will be renamed to TicketInProgress

Ticket will come from factory - factories don't use tell don't ask. Also, ToDto() also returns a value - because we need to cope with an API that violates CQS. Not much OO, is it?

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
```csharp
    var resultDto = Any.Instance<TicketDto>();
    var ticket = Substitute.For<Ticket>();

+   ticketFactory.CreateBlankTicket().Returns(ticket);
    ticket.ToDto().Returns(resultDto);

//WHEN
```

The Statement shows that we need a factory, so let's introduce it in the Statement first. Name: TicketFactory collaborator

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
```csharp
    var resultDto = Any.Instance<TicketDto>();
    var ticket = Substitute.For<Ticket>();
+   var ticketFactory = Substitute.For<TicketFactory>());

    ticketFactory.CreateBlankTicket().Returns(ticket);
    ticket.ToDto().Returns(resultDto);
```

The interface does not exist yet, let's create it:

diff --git a/Java/src/main/java/logic/TicketFactory.java b/Java/src/main/java/logic/TicketFactory.java
new file mode 100644

+++ b/Java/src/main/java/logic/TicketFactory.java
@@ -0,0 +1,5 @@
```csharp
public interface TicketFactory 
{
  Ticket CreateBlankTicket();
}
```

Time for assertions - what do we expect? Johnny uses his experience to pull a command - because we want to get out of CQS violation. Typically we can do two things - either use a command or a facade. For now mistakenly assuming that it will take a parameter.

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
```csharp
  var ticketDto = ticketOffice.MakeReservation(reservation);

  //THEN
+ bookCommand.Received(1).Execute(ticket);
  Assert.Equal(resultDto, ticketDto);
}
```

Interesting thing is that having both an assertion and a mock verification means we violate CQS. We want to avoid it, but sometimes 3rd party APIs require that.

We know that we need a command, so let's introduce it in the Statement. 

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java

```csharp
  var ticket = Substitute.For<Ticket>();
+ var bookCommand = Sustitute.For<Command>();

  var ticketFactory = Substitute.For<TicketFactory>();
  ticketFactory.CreateBlankTicket().Returns(ticket);
```

+++ b/Java/src/main/java/logic/Command.java
@@ -0,0 +1,4 @@
```csharp
public interface Command
{
}
```

Also, this method goes inside the `Command`:

```csharp
 public interface Command {
+    void Execute(Ticket ticket);
 }
 ```

`TicketOffice` needs to know about the command - how will it get it? I decide a command factory will wrap dto with a command. I'm using this opportunity to 

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
```csharp
  var ticketFactory = Substitute.For<TicketFactory>();
  ticketFactory.CreateBlankTicket().Returns(ticket);
  ticket.ToDto().Returns(resultDto);
+ commandFactory.CreateBookCommand(reservation)
+   .Returns(bookCommand);

  //WHEN
  var ticketDto = ticketOffice.MakeReservation(reservation);
```

Introduced the factory interface. 

+++ b/Java/src/main/java/logic/CommandFactory.java
@@ -0,0 +1,7 @@

```csharp
public interface CommandFactory
{
  Command CreateBookCommand(ReservationRequestDto reservation);
}
```

And declaring it inside the Statement:

```csharp
public class TicketOfficeSpecification {
         var ticketFactory = Substitute.For<TicketFactory>();
         ticketFactory.CreateBlankTicket().Returns(ticket);
         ticket.ToDto().Returns(resultDto);
+        var commandFactory = Substitute.For<CommandFactory>();
         commandFactory.CreateBookCommand(reservation)
             .Returns(bookCommand);
```

Now how should a ticket office get to know it? We can just pass the factory to the constructor, since it does not need anything from the request during its construction time. (since its creation is not dependent on local scope).

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java

```csharp
public class TicketOfficeSpecification {
  [Fact]
  public void ShouldCreateAndExecuteCommandWithTicketAndTrain() 
  {
    //WHEN
    var commandFactory = Substitute.For<CommandFactory>();
-   var ticketOffice = new TicketOffice();
+   var ticketOffice = new TicketOffice(commandFactory);
    var reservation = Any.Instance<ReservationRequestDto>();
    var resultDto = Any.Instance<TicketDto>();
-   Ticket ticket = Substitute.For<Ticket>();
+   var ticket = Substitute.For<Ticket>();
    var bookCommand = Substitute.For<Command>();
    var ticketFactory = Substitute.For<TicketFactory>();

+   ticketFactory.CreateBlankTicket().Returns(ticket);
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
+    //todo implement
+  }
+
   public TicketDto MakeReservation(
     ReservationRequestDto request) 
   {
     throw new NotImplementedException();
```

//TODOOOOOOOOOOOOOOOO

I noticed I can pass the ticket to factory and have the command as something more generic with a void Execute() method.

+++ b/Java/src/test/java/TicketOfficeSpecification.java

```csharp
  ticketFactory.CreateBlankTicket().Returns(ticket);
  ticket.ToDto().Returns(resultDto);
- commandFactory.CreateBookCommand(reservation)
+ commandFactory.CreateBookCommand(reservation, ticket)
      .Returns(bookCommand);
 
  //WHEN
  var ticketDto = ticketOffice.MakeReservation(reservation);
 
  //THEN
- bookCommand.Received(1).Execute(ticket);
+ bookCommand.Received(1).Execute();
  Assert.Equal(resultDto, ticketDto);
```

Remove Ticket from the Command:

diff --git a/Java/src/main/java/logic/Command.java b/Java/src/main/java/logic/Command.java

```csharp 
 public interface Command 
 {
-  void Execute(Ticket ticket);
+  void Execute();
 }
```

And push it to the factory: 

diff --git a/Java/src/main/java/logic/CommandFactory.java b/Java/src/main/java/logic/CommandFactory.java
 
```csharp
 public interface CommandFactory 
 {
-  Command CreateBookCommand(ReservationRequestDto reservation);
+  Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket);
 }
```

TicketOffice should know ticket factory

+++ b/Java/src/test/java/TicketOfficeSpecification.java

```csharp
+ var ticketOffice = new TicketOffice(
+   commandFactory,
+   ticketFactory);
```

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp 
 public class TicketOffice 
 {
+  private CommandFactory commandFactory;
-  public TicketOffice(CommandFactory commandFactory) 
+  public TicketOffice(CommandFactory commandFactory, TicketFactory ticketFactory) 
   {
     //todo implement
+    this.commandFactory = commandFactory;
   }
```

Returning whatever to make sure we fail for the right reason


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
 
     private CommandFactory commandFactory;
+    private TicketFactory ticketFactory;
 
-    public TicketOffice(CommandFactory commandFactory, TicketFactory ticketFactory) {
+    public TicketOffice(
+        CommandFactory commandFactory,
+        TicketFactory ticketFactory) {
         //todo implement
 
         this.commandFactory = commandFactory;
+        this.ticketFactory = ticketFactory;
     }
 
     public TicketDto MakeReservation(
         ReservationRequestDto request) {
+        var ticket = ticketFactory.createBlankTicket();
+        var command = commandFactory.CreateBookCommand(request, ticket);
         return new TicketDto(null, null, null);
     }
```

We can remove TODOs? Btw, what about TODO list?

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
  ReservationRequestDto request) 
  {
    var ticket = ticketFactory.createBlankTicket();
    var command = commandFactory.CreateBookCommand(request, ticket);
+   command.Execute();
    return new TicketDto(null, null, null);
  }
```

Passed the first assertion but the second one still fails (look at the error message, Luke)

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
         var ticket = ticketFactory.createBlankTicket();
         var command = commandFactory.CreateBookCommand(request, ticket);
         command.Execute();
-        return new TicketDto(null, null, null);
+        return ticket.toDto();
     }
```

Passed the second assertion, test green. WHat about the order of invocations?

Can we alter it to make it invalid? No, creation comes before usage, usage goes before returning value, return comes last.
 
Date:   Wed Feb 28 16:37:04 2018 +0100

    [LATE] creating an instance. need some implementations

+++ b/Java/src/main/java/bootstrap/Main.java

```csharp
 public class Main {
 
     public static void main(String[] args) {
-
+        new TicketOffice();
     }
 
 }
```

Date:   Wed Feb 28 16:38:41 2018 +0100

    the empty implementations add to TODO list.
    
    I need to pick one item to work on.

+++ b/Java/src/main/java/api/TicketOffice.java

```csharp
@@ -14,7 +14,6 @@ public class TicketOffice {
     public TicketOffice(
         CommandFactory commandFactory,
         TicketFactory ticketFactory) {
-        //todo implement
 
         this.commandFactory = commandFactory;
         this.ticketFactory = ticketFactory;
```

+++ b/Java/src/main/java/bootstrap/Main.java

```csharp
 public class Main {
 
     public static void main(String[] args) {
-        new TicketOffice();
+        new TicketOffice(new BookingCommandFactory(),
+            new TrainTicketFactory());
     }
 
 }
```

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
+    public Ticket createBlankTicket() 
+    {
+        //todo implement
+        return null;
+    }
+}
```

Date:   Wed Feb 28 16:40:33 2018 +0100

    I pick the factory as there is not much I can do with Ticket yet

+++ b/Java/src/test/java/logic/TrainTicketFactorySpecification.java

```csharp
+public class TrainTicketFactorySpecification {
+    
+
+}
```

Date:   Wed Feb 28 16:43:17 2018 +0100

    [SORRY] I pick command factory as there is not much I can do with tickets

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
+public class BookingCommandFactorySpecification {
+
+}
```

Date:   Thu Mar 1 07:57:53 2018 +0100

    wrote a failing test for a type and dependencies

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp
+public class BookTicketCommand {
+}
```

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

Date:   Thu Mar 1 07:59:49 2018 +0100

    Returning book ticket command forced interface implementation
    
    (can be applied via a quick fix)

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

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
     public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        //todo implement
-        return null;
+        return new BookTicketCommand();
     }
```

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
@@ -17,7 +17,8 @@ public class BookingCommandFactorySpecification 
{
         var ticket = Substitute.For<Ticket>();
 
         //WHEN
-        Command result = bookingCommandFactory.CreateBookCommand(reservation, ticket);
+        Command result = bookingCommandFactory
+            .CreateBookCommand(reservation, ticket);
 
         //THEN
         assertThat(result).isInstanceOf(BookTicketCommand.class);
```

Date:   Thu Mar 1 08:00:57 2018 +0100

    Made 2nd assertion pass by introducing field for dto
    The 3rd assertion still fails.

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp
 public class BookTicketCommand : Command {
+    private ReservationRequestDto reservation;
+
+    public BookTicketCommand(ReservationRequestDto reservation) {
+        this.reservation = reservation;
+    }
+
```

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
 public class BookingCommandFactory : CommandFactory {
     
     public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        return new BookTicketCommand();
+        return new BookTicketCommand(reservation);
     }
 }
```

Date:   Thu Mar 1 08:01:56 2018 +0100

    The test now passes. New items on TODO list (e.g. Execute() method)

```csharp
 public class BookTicketCommand : Command {
     private ReservationRequestDto reservation;
+    private Ticket ticket;
 
-    public BookTicketCommand(ReservationRequestDto reservation) {
+    public BookTicketCommand(ReservationRequestDto reservation, Ticket ticket) {
         this.reservation = reservation;
+        this.ticket = ticket;
     }
```

     
+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
 public class BookingCommandFactory : CommandFactory {
     
     public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        return new BookTicketCommand(reservation);
+        return new BookTicketCommand(reservation, ticket);
     }
 }
``` 

Date:   Thu Mar 1 08:03:46 2018 +0100

    As my next step, I choose BookTicketCommand
    
    I prefer it over TicketFactory as it will allow me to learn more about the Ticket interface. So now I am optimizing for learning.

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
+public class BookTicketCommandSpecification {
+
+}
```

Date:   Thu Mar 1 08:04:30 2018 +0100

    I have yet to discover what behavior I will require from the command

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
 public class BookTicketCommandSpecification {
+    [Fact]
+    public void ShouldXXXXXXXXXXXXX() {
+        //GIVEN
+
+        //WHEN
 
+        //THEN
+        assertThat(1).isEqualTo(2);
+    }
 }
```

Date:   Thu Mar 1 08:05:48 2018 +0100

    I realize I have no train, so I comment the test and backtrack

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
 public class BookTicketCommandSpecification {
+    /*
     [Fact]
+    //hmm, should reserve a train, but I have no train
     public void ShouldXXXXXXXXXXXXX() {
         //GIVEN

        ...
 
         //THEN
         assertThat(1).isEqualTo(2);
-    }
+    }*/
 }
```

Date:   Thu Mar 1 16:14:20 2018 +0100

    Discovered TrainRepository interface

+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
 public class BookingCommandFactory : CommandFactory {
+    public BookingCommandFactory(TrainRepository trainRepo) {
+        //todo implement
+
+    }
+
     
     public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) {
         return new BookTicketCommand(reservation, ticket);
```

+++ b/Java/src/main/java/logic/TrainRepository.java

```csharp
+public interface TrainRepository 
+{
+}
```

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

Date:   Thu Mar 1 16:16:14 2018 +0100

    Discovered train collaborator and getBy repo method
    
    Now what type should the train variable be?



+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
public class BookingCommandFactorySpecification {
    //...
         );
         var reservation = Substitute.For<ReservationRequestDto>();
         var ticket = Substitute.For<Ticket>();
+
+        trainRepo.GetTrainBy(reservation.trainId)
+            .Returns(train);
+
         //WHEN
         Command result = bookingCommandFactory
             .CreateBookCommand(reservation, ticket);
@@ -26,5 +31,7 @@ public class BookingCommandFactorySpecification {
         assertThat(result).isInstanceOf(BookTicketCommand.class);
         assertThat(result).has(dependencyOn(reservation));
         assertThat(result).has(dependencyOn(ticket));
+        assertThat(result).has(dependencyOn(ticket));
+        assertThat(result).has(dependencyOn(train));
     }
 }
```


Date:   Thu Mar 1 16:17:14 2018 +0100

    Discovered a Train interface

+++ b/Java/src/main/java/logic/Train.java

```csharp
+public interface Train 
+{
+}
```

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


Date:   Thu Mar 1 16:19:04 2018 +0100

    Discovered CouchDbTrainRepository the TODO list grows

+++ b/Java/src/main/java/bootstrap/Main.java

```csharp
 public class Main 
 {
 
     public static void Main(string[] args)
     {
-        new TicketOffice(new BookingCommandFactory(),
+        new TicketOffice(new BookingCommandFactory(
+            new CouchDbTrainRepository()
+        ),
             new TrainTicketFactory());
     }
```


+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

```csharp
+public class CouchDbTrainRepository : TrainRepository 
+{
+    
+    public Train GetTrainBy(String trainId) 
+    {
+        //todo implement
+        return null;
+    }
+}
```

+++ b/Java/src/main/java/logic/TrainRepository.java

```csharp
 public interface TrainRepository {
+    Train GetTrainBy(String trainId);
 }
```

Date:   Thu Mar 1 16:21:38 2018 +0100

    Made the last assertion pass
    (one more backtracking will be needed)

+++ b/Java/src/main/java/bootstrap/Main.java

```csharp
     public static void main(String[] args) {
         new TicketOffice(new BookingCommandFactory(
             new CouchDbTrainRepository()
-        ),
-            new TrainTicketFactory());
+        ), new TrainTicketFactory());
     }
```

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

Date:   Thu Mar 1 16:23:13 2018 +0100

    Uncommented a test for booking command

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
 public class BookTicketCommandSpecification {
-    /*
+
     [Fact]
-    //hmm, should reserve a train, but I have no train
     public void ShouldXXXXXXXXXXXXX() {
         //GIVEN
 
@@ -11,5 +14,5 @@ public class BookTicketCommandSpecification {
 
         //THEN
         assertThat(1).isEqualTo(2);
-    }*/
+    }
 }
```

Date:   Thu Mar 1 16:25:36 2018 +0100

    Starting command test
    brain dump - just invoke the only existing method

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
@@ -9,8 +10,10 @@ public class BookTicketCommandSpecification {
     [Fact]
     public void ShouldXXXXXXXXXXXXX() {
         //GIVEN
-
+        var bookTicketCommand
+            = new BookTicketCommand(reservation, ticket, train);
         //WHEN
+        bookTicketCommand.Execute();
 
         //THEN
         assertThat(1).isEqualTo(2);
```

Date:   Thu Mar 1 16:29:00 2018 +0100

    Introduced collaborators and stated expectation

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp 
 public class BookTicketCommandSpecification {
 
     [Fact]
     public void ShouldXXXXXXXXXXXXX() {
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
+        then(train).should().Reserve(reservation.seatCount, ticket);
     }
 }
```


Date:   Mon Mar 5 08:08:06 2018 +0100

    Introduced the reserve method

+++ b/Java/src/main/java/logic/Train.java

```csharp
 public interface Train {
+    void Reserve(int seatCount, Ticket ticketToFill);
 }
```

Date:   Mon Mar 5 08:11:53 2018 +0100

    Implemented. Our next stop is a train repository
    We will not be testing it.

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

```csharp
@@ -13,6 +13,7 @@ public class BookingCommandFactory : CommandFactory 
{
    //...
     public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) 
     {
         return new BookTicketCommand(
             reservation,
-            ticket, trainRepo.GetTrainBy(reservation.trainId));
+            ticket,
+            trainRepo.GetTrainBy(reservation.trainId));
     }
 }

Date:   Mon Mar 5 08:14:42 2018 +0100

    Made dummy implementation of TrainWithCoaches

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

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
+public class TrainWithCoaches : Train 
+{
+    
+    public void Reserve(int seatCount, Ticket ticketToFill) 
+    {
+        //todo implement
+
+    }
+}
```

Date:   Mon Mar 5 15:23:23 2018 +0100

    Renaming a test (should've done this earlier)
    
    Should have left a TODO.

+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
 public class BookTicketCommandSpecification {
 
     [Fact]
-    public void ShouldXXXXXXXXXXXXX() {
+    public void ShouldReserveSeatsOnTrainWhenExecuted() {
         //GIVEN
         var reservation = Any.Instance<ReservationRequestDto>();
         var ticket = Any.Instance<Ticket>();
```

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
+public class TrainWithCoachesSpecification {
+
+
+}
```

Date:   Mon Mar 5 15:26:14 2018 +0100

    braindumping a new test

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp 
 public class TrainWithCoachesSpecification 
 {
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

Date:   Mon Mar 5 15:29:51 2018 +0100

    passed the compiler
    
    Now time for some deeper thinking on the expectation

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp 
 public class TrainWithCoachesSpecification {
     [Fact]
     public void ShouldXXXXX() { //todo rename
         //GIVEN
         var trainWithCoaches = new TrainWithCoaches();
+        var seatCount = Any.Integer();
+        var ticket = Substitute.For<Ticket>();
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
```

Date:   Wed Mar 7 07:53:13 2018 +0100

    I know one coach should be reserved even though more meet the condition

+++ b/Java/src/main/java/logic/BookTicketCommand.java

```csharp 
 public class BookTicketCommand : Command 
 {
     private ReservationRequestDto reservation;
-    private Ticket ticket;
+    private TicketInProgress ticketInProgress;
     private Train train;
 
     public BookTicketCommand(
         ReservationRequestDto reservation,
-        Ticket ticket,
+        TicketInProgress ticketInProgress,
         Train train) 
     {
         this.reservation = reservation;
-        this.ticket = ticket;
+        this.ticketInProgress = ticketInProgress;
         this.train = train;
     }
 
     
     public void Execute() 
     {
         //todo a full DTO is not required
-        train.Reserve(reservation.seatCount, ticket);
+        train.Reserve(reservation.seatCount, ticketInProgress);
     }
 }
```


+++ b/Java/src/main/java/logic/BookingCommandFactory.java

```csharp
@@ -10,10 +10,10 @@ public class BookingCommandFactory : CommandFactory {
     }
 
     
-    public Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket) {
+    public Command CreateBookCommand(ReservationRequestDto reservation, TicketInProgress ticketInProgress) {
         return new BookTicketCommand(
             reservation,
-            ticket,
+            ticketInProgress,
             trainRepo.GetTrainBy(reservation.trainId));
     }
 }
```

diff --git a/Java/src/main/java/logic/CommandFactory.java b/Java/src/main/java/logic/CommandFactory.java
index 18208a5..28a0048 100644
--- a/Java/src/main/java/logic/CommandFactory.java
+++ b/Java/src/main/java/logic/CommandFactory.java
@@ -3,5 +3,5 @@ package logic;
 import request.dto.ReservationRequestDto;
 
 public interface CommandFactory {
-    Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket);
+    Command CreateBookCommand(ReservationRequestDto reservation, TicketInProgress ticketInProgress);
 }
diff --git a/Java/src/main/java/logic/TicketFactory.java b/Java/src/main/java/logic/TicketFactory.java
index 27a10ef..b084a79 100644
--- a/Java/src/main/java/logic/TicketFactory.java
+++ b/Java/src/main/java/logic/TicketFactory.java
@@ -1,5 +1,5 @@
 package logic;
 
 public interface TicketFactory {
-    Ticket createBlankTicket();
+    TicketInProgress createBlankTicket();
 }
diff --git a/Java/src/main/java/logic/Ticket.java b/Java/src/main/java/logic/TicketInProgress.java
similarity index 66%
rename from Java/src/main/java/logic/Ticket.java
rename to Java/src/main/java/logic/TicketInProgress.java
index a7ad63b..2078c58 100644
--- a/Java/src/main/java/logic/Ticket.java
+++ b/Java/src/main/java/logic/TicketInProgress.java
@@ -2,6 +2,6 @@ package logic;
 
 import response.dto.TicketDto;
 
-public interface Ticket {
+public interface TicketInProgress {
     TicketDto toDto();
 }
diff --git a/Java/src/main/java/logic/Train.java b/Java/src/main/java/logic/Train.java
index 7756147..bf2a15c 100644
--- a/Java/src/main/java/logic/Train.java
+++ b/Java/src/main/java/logic/Train.java
@@ -1,5 +1,5 @@
 package logic;
 
 public interface Train {
-    void Reserve(int seatCount, Ticket ticketToFill);
+    void Reserve(int seatCount, TicketInProgress ticketInProgress);
 }
diff --git a/Java/src/main/java/logic/TrainTicketFactory.java b/Java/src/main/java/logic/TrainTicketFactory.java
index 4bc54a5..356a56a 100644
--- a/Java/src/main/java/logic/TrainTicketFactory.java
+++ b/Java/src/main/java/logic/TrainTicketFactory.java
@@ -2,7 +2,7 @@ package logic;
 
 public class TrainTicketFactory : TicketFactory {
     
-    public Ticket createBlankTicket() {
+    public TicketInProgress createBlankTicket() {
         //todo implement
         return null;
     }
diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index a1e89ff..47c59d2 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -2,7 +2,7 @@ package logic;
 
 public class TrainWithCoaches : Train {
     
-    public void Reserve(int seatCount, Ticket ticketToFill) {
+    public void Reserve(int seatCount, TicketInProgress ticketInProgress) {
         //todo implement
 
     }
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketInProgressOfficeSpecification.java
similarity index 91%
rename from Java/src/test/java/TicketOfficeSpecification.java
rename to Java/src/test/java/TicketInProgressOfficeSpecification.java
index 62624d9..7922e08 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketInProgressOfficeSpecification.java
@@ -2,7 +2,7 @@ import api.TicketOffice;
 import autofixture.publicinterface.Any;
 import logic.Command;
 import logic.CommandFactory;
-import logic.Ticket;
+import logic.TicketInProgress;
 import logic.TicketFactory;
 import lombok.val;
 import org.testng.annotations.Test;
@@ -14,7 +14,7 @@ import static org.mockito.BDDMockito.given;
 import static org.mockito.BDDMockito.then;
 import static org.mockito.Mockito.mock;
 
-public class TicketOfficeSpecification {
+public class TicketInProgressOfficeSpecification {
     
     [Fact]
     public void ShouldCreateAndExecuteCommandWithTicketAndTrain() {
@@ -22,7 +22,7 @@ public class TicketOfficeSpecification {
         var commandFactory = Substitute.For<CommandFactory>();
         var reservation = Any.Instance<ReservationRequestDto>();
         var resultDto = Any.Instance<TicketDto>();
-        var ticket = Substitute.For<Ticket>();
+        var ticket = Substitute.For<TicketInProgress>();
         var bookCommand = Substitute.For<Command>();
         var ticketFactory = Substitute.For<TicketFactory>();
         var ticketOffice = new TicketOffice(
diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketInProgressCommandSpecification.java
similarity index 85%
rename from Java/src/test/java/logic/BookTicketCommandSpecification.java
rename to Java/src/test/java/logic/BookTicketInProgressCommandSpecification.java
index 057d6dd..34b1b23 100644
--- a/Java/src/test/java/logic/BookTicketCommandSpecification.java
+++ b/Java/src/test/java/logic/BookTicketInProgressCommandSpecification.java
@@ -8,13 +8,13 @@ import request.dto.ReservationRequestDto;
 import static org.mockito.BDDMockito.then;
 import static org.mockito.Mockito.mock;
 
-public class BookTicketCommandSpecification {
+public class BookTicketInProgressCommandSpecification {
 
     [Fact]
     public void ShouldReserveSeatsOnTrainWhenExecuted() {
         //GIVEN
         var reservation = Any.Instance<ReservationRequestDto>();
-        var ticket = Any.Instance<Ticket>();
+        var ticket = Any.Instance<TicketInProgress>();
         var train = Substitute.For<Train>();
         var bookTicketCommand
             = new BookTicketCommand(reservation, ticket, train);
diff --git a/Java/src/test/java/logic/BookingCommandFactorySpecification.java b/Java/src/test/java/logic/BookingCommandFactorySpecification.java
index 6cdb16b..caa1b3c 100644
--- a/Java/src/test/java/logic/BookingCommandFactorySpecification.java
+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java
@@ -18,7 +18,7 @@ public class BookingCommandFactorySpecification {
             trainRepo
         );
         var reservation = Substitute.For<ReservationRequestDto>();
-        var ticket = Substitute.For<Ticket>();
+        var ticket = Substitute.For<TicketInProgress>();
         var train = Substitute.For<Train>();
 
         trainRepo.GetTrainBy(reservation.trainId)
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index dc2e1f5..6bbf7aa 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -4,8 +4,9 @@ import autofixture.publicinterface.Any;
 import lombok.val;
 import org.testng.annotations.Test;
 
-import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.BDDMockito.then;
 import static org.mockito.Mockito.mock;
+import static org.mockito.Mockito.never;
 
 public class TrainWithCoachesSpecification {
     [Fact]
@@ -13,13 +14,16 @@ public class TrainWithCoachesSpecification {
         //GIVEN
         var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.Integer();
-        var ticket = Substitute.For<Ticket>();
+        var ticket = Substitute.For<TicketInProgress>();
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
 
         //THEN
-        assertThat(1).isEqualTo(2);
+        coach1.DidNotReceive().Reserve(seatCount, ticket);
+        coach2.Received(1).Reserve(seatCount, ticket);
+        coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
+    //todo ticket in progress instead of plain ticket
 
 }
\ No newline at end of file

commit 71a4ab86cd562c487371c3bb132fc3b402829e5f
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 07:54:22 2018 +0100

    Discovered the coach interface

diff --git a/Java/src/main/java/logic/Coach.java b/Java/src/main/java/logic/Coach.java
new file mode 100644






index 0000000..e4b82df
--- /dev/null
+++ b/Java/src/main/java/logic/Coach.java
@@ -0,0 +1,4 @@
+package logic;
+
+public interface Coach {
+}
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 6bbf7aa..6a96aef 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -15,6 +15,9 @@ public class TrainWithCoachesSpecification {
         var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
+        Coach coach1 = Substitute.For<Coach>();
+        Coach coach2 = Substitute.For<Coach>();
+        Coach coach3 = Substitute.For<Coach>();
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);

commit 051c009926e1f332455e9e325ba3135d863d30fb
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 07:56:04 2018 +0100

    Discovered the Reserve() method

diff --git a/Java/src/main/java/logic/Coach.java b/Java/src/main/java/logic/Coach.java
index e4b82df..300a248 100644
--- a/Java/src/main/java/logic/Coach.java
+++ b/Java/src/main/java/logic/Coach.java
@@ -1,4 +1,5 @@
 package logic;
 
 public interface Coach {
+    void Reserve(int seatCount, TicketInProgress ticket);
 }
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 6a96aef..cd3969f 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -15,9 +15,9 @@ public class TrainWithCoachesSpecification {
         var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
-        Coach coach1 = Substitute.For<Coach>();
-        Coach coach2 = Substitute.For<Coach>();
-        Coach coach3 = Substitute.For<Coach>();
+        var coach1 = Substitute.For<Coach>();
+        var coach2 = Substitute.For<Coach>();
+        var coach3 = Substitute.For<Coach>();
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);

commit 0a73afacd82d7f2d4d709ca945cd18f343164388
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 07:57:35 2018 +0100

    passed coaches as vararg
    
    not test-driving the vararg, using the Kent Beck's putting the right implementation

diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index 47c59d2..20d3221 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -1,6 +1,9 @@
 package logic;
 
 public class TrainWithCoaches : Train {
+    public TrainWithCoaches(Coach... coaches) {
+    }
+
     
     public void Reserve(int seatCount, TicketInProgress ticketInProgress) {
         //todo implement
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index cd3969f..7afa52f 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -12,12 +12,14 @@ public class TrainWithCoachesSpecification {
     [Fact]
     public void ShouldXXXXX() { //todo rename
         //GIVEN
-        var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
         var coach1 = Substitute.For<Coach>();
         var coach2 = Substitute.For<Coach>();
         var coach3 = Substitute.For<Coach>();
+        var trainWithCoaches = new TrainWithCoaches(
+            coach1, coach2, coach3
+        );
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);

commit 585426746e7ad1e5f0e082ec432e42f98855f3d3
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 08:00:58 2018 +0100

    discovered AllowsUpFrontReservationOf() method
    
    One more condition awaits - if no coach allows up front, we take the first one that has the limit.

diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 7afa52f..09badf2 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -4,6 +4,7 @@ import autofixture.publicinterface.Any;
 import lombok.val;
 import org.testng.annotations.Test;
 
+import static org.mockito.BDDMockito.given;
 import static org.mockito.BDDMockito.then;
 import static org.mockito.Mockito.mock;
 import static org.mockito.Mockito.never;
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
-    //todo ticket in progress instead of plain ticket
-
+    //todo what if no coach allows up front reservation?
 }
\ No newline at end of file

commit 01b652490cf4e33885b911061ae97f5679bd741c
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 08:03:24 2018 +0100

    Introduced the method
    
    + a too late TODO - CouchDbRepository should supply the coaches

diff --git a/Java/src/main/java/logic/Coach.java b/Java/src/main/java/logic/Coach.java
index 300a248..6cb559a 100644
--- a/Java/src/main/java/logic/Coach.java
+++ b/Java/src/main/java/logic/Coach.java
@@ -2,4 +2,6 @@ package logic;
 
 public interface Coach {
     void Reserve(int seatCount, TicketInProgress ticket);
+
+    bool AllowsUpFrontReservationOf(int seatCount);
 }
diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
index 1d827ef..9f7ea45 100644
--- a/Java/src/main/java/logic/CouchDbTrainRepository.java
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -3,6 +3,7 @@ package logic;
 public class CouchDbTrainRepository : TrainRepository {
     
     public Train GetTrainBy(String trainId) {
+        //todo there should be something passed here!!
         return new TrainWithCoaches();
     }
 }

commit 133e55b4cea24174d08a4a56a2abadd3b8b43235
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 07:53:03 2018 +0100

    gave a good name to the test

diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index 20d3221..bbe9f0f 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -7,6 +7,5 @@ public class TrainWithCoaches : Train {
     
     public void Reserve(int seatCount, TicketInProgress ticketInProgress) {
         //todo implement
-
     }
 }
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 09badf2..05b36cd 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -11,7 +11,7 @@ import static org.mockito.Mockito.never;
 
 public class TrainWithCoachesSpecification {
     [Fact]
-    public void ShouldXXXXX() { //todo rename
+    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() {
         //GIVEN
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();

commit 80d3c0fea9f2088f5b798ea03fa00ef67aa934e8
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 07:57:14 2018 +0100

    Implemented the first behavior
    
    (in the book, play with the if and return to see each assertion fail)

diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index bbe9f0f..a2ee63f 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -1,11 +1,20 @@
 package logic;
 
 public class TrainWithCoaches : Train {
+    private Coach[] coaches;
+
     public TrainWithCoaches(Coach... coaches) {
+        this.coaches = coaches;
     }
 
     
-    public void Reserve(int seatCount, TicketInProgress ticketInProgress) {
-        //todo implement
+    public void Reserve(int seatCount, TicketInProgress ticketInProgress) {
+        for (Coach coach : coaches) {
+            if(coach.AllowsUpFrontReservationOf(seatCount)) {
+                coach.Reserve(seatCount, ticketInProgress);
+                return;
+            }
+        }
+
     }
 }
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 05b36cd..87a62fe 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -11,7 +11,7 @@ import static org.mockito.Mockito.never;
 
 public class TrainWithCoachesSpecification {
     [Fact]
-    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() { //todo rename
+    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() { 
         //GIVEN
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
@@ -29,7 +29,6 @@ public class TrainWithCoachesSpecification {
         coach3.AllowsUpFrontReservationOf(seatCount)
             .Returns(true);
 
-
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
 
@@ -38,5 +37,7 @@ public class TrainWithCoachesSpecification {
         coach2.Received(1).Reserve(seatCount, ticket);
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
+
+
     //todo what if no coach allows up front reservation?
 }
\ No newline at end of file

commit 432cc28a6755c6e74bc6617582ef7a8869488534
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 08:00:34 2018 +0100

    Discovered allowsReservationOf method

diff --git a/Java/src/main/java/logic/Coach.java b/Java/src/main/java/logic/Coach.java
index 6cb559a..209e271 100644
--- a/Java/src/main/java/logic/Coach.java
+++ b/Java/src/main/java/logic/Coach.java
@@ -4,4 +4,6 @@ public interface Coach {
     void Reserve(int seatCount, TicketInProgress ticket);
 
     bool AllowsUpFrontReservationOf(int seatCount);
+
+    bool allowsReservationOf(int seatCount);
 }
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 87a62fe..8157890 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -11,7 +11,7 @@ import static org.mockito.Mockito.never;
 
 public class TrainWithCoachesSpecification {
     [Fact]
-    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() { 
+    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() {
         //GIVEN
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
@@ -38,6 +38,41 @@ public class TrainWithCoachesSpecification {
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
 
+    [Fact]
+    public void
+    ShouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() {
+        //GIVEN
+        var seatCount = Any.Integer();
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
 
     //todo what if no coach allows up front reservation?
 }
\ No newline at end of file

commit 639eb2c08f400ac5a81c9ab7123f63557d8ec0dd
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 08:01:44 2018 +0100

    Bad implementation alows the test to pass!
    
    Need to fix the first test

diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index a2ee63f..1e45cd9 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -9,6 +9,12 @@ public class TrainWithCoaches : Train {
 
     
     public void Reserve(int seatCount, TicketInProgress ticketInProgress) {
+        for (Coach coach : coaches) {
+            if(coach.allowsReservationOf(seatCount)) {
+                coach.Reserve(seatCount, ticketInProgress);
+                break;
+            }
+        }
         for (Coach coach : coaches) {
             if(coach.AllowsUpFrontReservationOf(seatCount)) {
                 coach.Reserve(seatCount, ticketInProgress);

commit f9a24aeb01276dd1a1bc0dc6f534abd45b4db3f6
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 08:03:07 2018 +0100

    forced the right implementation
    
    But need to refactor the tests. Next time we change this class, we refactor the code

diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index 1e45cd9..abb29e5 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -10,17 +10,16 @@ public class TrainWithCoaches : Train {
     
     public void Reserve(int seatCount, TicketInProgress ticketInProgress) {
         for (Coach coach : coaches) {
-            if(coach.allowsReservationOf(seatCount)) {
+            if(coach.AllowsUpFrontReservationOf(seatCount)) {
                 coach.Reserve(seatCount, ticketInProgress);
-                break;
+                return;
             }
         }
         for (Coach coach : coaches) {
-            if(coach.AllowsUpFrontReservationOf(seatCount)) {
+            if(coach.allowsReservationOf(seatCount)) {
                 coach.Reserve(seatCount, ticketInProgress);
                 return;
             }
         }
-
     }
 }
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 8157890..a84d16a 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -28,6 +28,12 @@ public class TrainWithCoachesSpecification {
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

commit 758456f88428359540a4951daaa6d099ee32970e
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 16:19:24 2018 +0100

    Refactored coaches (truth be told, I should refactor prod code)

diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index a84d16a..c1a5b96 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -15,26 +15,14 @@ public class TrainWithCoachesSpecification {
         //GIVEN
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
-        var coach1 = Substitute.For<Coach>();
-        var coach2 = Substitute.For<Coach>();
-        var coach3 = Substitute.For<Coach>();
+
+        Coach coach1 = coachWithoutAvailableUpFront(seatCount);
+        Coach coach2 = coachWithAvailableUpFront(seatCount);
+        Coach coach3 = coachWithAvailableUpFront(seatCount);
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
 
+    private Coach coachWithAvailableUpFront(Integer seatCount) {
+        var coach2 = Substitute.For<Coach>();
+        coach2.AllowsUpFrontReservationOf(seatCount)
+            .Returns(true);
+        coach2.AllowsReservationOf(seatCount)
+            .Returns(true);
+        return coach2;
+    }
+
+    private Coach coachWithoutAvailableUpFront(Integer seatCount) {
+        var coach1 = Substitute.For<Coach>();
+        coach1.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach1.AllowsReservationOf(seatCount)
+            .Returns(true);
+        return coach1;
+    }
+
     [Fact]
     public void
     shouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() {

commit 73e995d584c50ee549e23a0bb16723451b4a1e54
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 16:25:00 2018 +0100

    Refactored tests
    
    TODO start from this committ to show refactoring!!

diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index abb29e5..0afb6b4 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -15,6 +15,7 @@ public class TrainWithCoaches : Train {
                 return;
             }
         }
+
         for (Coach coach : coaches) {
             if(coach.allowsReservationOf(seatCount)) {
                 coach.Reserve(seatCount, ticketInProgress);
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index c1a5b96..b14abc2 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -32,50 +32,19 @@ public class TrainWithCoachesSpecification {
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
 
-    private Coach coachWithAvailableUpFront(Integer seatCount) {
-        var coach2 = Substitute.For<Coach>();
-        coach2.AllowsUpFrontReservationOf(seatCount)
-            .Returns(true);
-        coach2.AllowsReservationOf(seatCount)
-            .Returns(true);
-        return coach2;
-    }
-
-    private Coach coachWithoutAvailableUpFront(Integer seatCount) {
-        var coach1 = Substitute.For<Coach>();
-        coach1.AllowsUpFrontReservationOf(seatCount)
-            .Returns(false);
-        coach1.AllowsReservationOf(seatCount)
-            .Returns(true);
-        return coach1;
-    }
-
     [Fact]
     public void
     shouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() {
         //GIVEN
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
-        var coach1 = Substitute.For<Coach>();
-        var coach2 = Substitute.For<Coach>();
-        var coach3 = Substitute.For<Coach>();
+        var coach1 = coachWithout(seatCount);
+        var coach2 = coachWithoutAvailableUpFront(seatCount);
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
+    private Coach coachWithAvailableUpFront(Integer seatCount) {
+        var coach2 = Substitute.For<Coach>();
+        coach2.AllowsUpFrontReservationOf(seatCount)
+            .Returns(true);
+        coach2.AllowsReservationOf(seatCount)
+            .Returns(true);
+        return coach2;
+    }
+
+    private Coach coachWithoutAvailableUpFront(Integer seatCount) {
+        var coach1 = Substitute.For<Coach>();
+        coach1.AllowsUpFrontReservationOf(seatCount)
+            .Returns(false);
+        coach1.AllowsReservationOf(seatCount)
+            .Returns(true);
+        return coach1;
+    }
 }
\ No newline at end of file

commit 209375b5c6dcc2d424b180d7b3e9bc041dcd443a
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 16:27:15 2018 +0100

    Addressed todo - created a class CoachWithSeats

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
new file mode 100644






index 0000000..3e70cb0
--- /dev/null
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -0,0 +1,21 @@
+package logic;
+
+public class CoachWithSeats : Coach {
+    
+    public void Reserve(int seatCount, TicketInProgress ticket) {
+        //todo implement
+
+    }
+
+    
+    public bool AllowsUpFrontReservationOf(int seatCount) {
+        //todo implement
+        return false;
+    }
+
+    
+    public bool allowsReservationOf(int seatCount) {
+        //todo implement
+        return false;
+    }
+}
diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
index 9f7ea45..1a4b009 100644
--- a/Java/src/main/java/logic/CouchDbTrainRepository.java
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -4,6 +4,8 @@ public class CouchDbTrainRepository : TrainRepository {
     
     public Train GetTrainBy(String trainId) {
         //todo there should be something passed here!!
-        return new TrainWithCoaches();
+        return new TrainWithCoaches(
+            new CoachWithSeats()
+        );
     }
 }

commit 589bf5c16751b2a7980e011d5137a3241188cfe6
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 16:32:45 2018 +0100

    Brain dump

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
new file mode 100644






index 0000000..14417c8
--- /dev/null
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -0,0 +1,23 @@
+package logic;
+
+import autofixture.publicinterface.Any;
+import lombok.val;
+import org.testng.annotations.Test;
+
+import static org.assertj.core.api.Assertions.assertThat;
+
+public class CoachWithSeatsSpecification {
+
+    [Fact]
+    public void xxXXxxXX() { //todo rename
+        //GIVEN
+        var coachWithSeats = new CoachWithSeats();
+        //WHEN
+        int seatCount = Any.Integer();
+        var reservationAllowed = coachWithSeats.allowsReservationOf(seatCount);
+
+        //THEN
+        Assert.True(reservationAllowed);
+    }
+
+}
\ No newline at end of file

commit 6b77d198cc4f0dd316a83cf2e7d9f327d77726ef
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 16:35:33 2018 +0100

    Discovered an interface Seat

diff --git a/Java/src/main/java/logic/Seat.java b/Java/src/main/java/logic/Seat.java
new file mode 100644






index 0000000..7835a2a
--- /dev/null
+++ b/Java/src/main/java/logic/Seat.java
@@ -0,0 +1,4 @@
+package logic;
+
+public interface Seat {
+}
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index 14417c8..a1a9cbe 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -11,7 +11,18 @@ public class CoachWithSeatsSpecification {
     [Fact]
     public void xxXXxxXX() { //todo rename
         //GIVEN
-        var coachWithSeats = new CoachWithSeats();
+        Seat seat1 = Any.Instance<Seat>();
+        var coachWithSeats = new CoachWithSeats(
+            seat1,
+            seat2,
+            seat3,
+            seat4,
+            seat5,
+            seat6,
+            seat7,
+            seat8,
+            seat9
+        );
         //WHEN
         int seatCount = Any.Integer();
         var reservationAllowed = coachWithSeats.allowsReservationOf(seatCount);

commit 893d36847f8d48def0fab6b286e76f90e6baa310
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 14 16:32:05 2018 +0100

    created enough seats

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index a1a9cbe..ec90a2b 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
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
@@ -21,7 +31,8 @@ public class CoachWithSeatsSpecification {
             seat6,
             seat7,
             seat8,
-            seat9
+            seat9,
+            seat10
         );
         //WHEN
         int seatCount = Any.Integer();

commit c79ea731108b0b6388357240ecbb79b187dd55a2
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 14 16:32:45 2018 +0100

    Added a constructor

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 3e70cb0..57c9f25 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -1,6 +1,9 @@
 package logic;
 
 public class CoachWithSeats : Coach {
+    public CoachWithSeats(Seat... seats) {
+    }
+
     
     public void Reserve(int seatCount, TicketInProgress ticket) {
         //todo implement

commit 5c17b650ca042d5c5feb011ca94e842625eff4a9
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 14 16:35:15 2018 +0100

    clarified scenario. Test passes right away
    
    suspicious

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index ec90a2b..d3406eb 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -9,9 +9,8 @@ import static org.assertj.core.api.Assertions.assertThat;
 public class CoachWithSeatsSpecification {
 
     [Fact]
-    public void xxXXxxXX() { //todo rename
+    public void ShouldNotAllowReservingMoreSeatsThanItHas() { //todo rename
         //GIVEN
-        //todo what's special about these seats?
         Seat seat1 = Any.Instance<Seat>();
         Seat seat2 = Any.Instance<Seat>();
         Seat seat3 = Any.Instance<Seat>();
@@ -34,12 +33,14 @@ public class CoachWithSeatsSpecification {
             seat9,
             seat10
         );
+
         //WHEN
-        int seatCount = Any.Integer();
-        var reservationAllowed = coachWithSeats.allowsReservationOf(seatCount);
+        var reservationAllowed = coachWithSeats.allowsReservationOf(11);
 
         //THEN
-        Assert.True(reservationAllowed);
+        assertThat(reservationAllowed).isFalse();
     }
 
+    //todo what's special about these seats?
+
 }
\ No newline at end of file

commit 998c42b1c7909b86524266d5ad37b4fc6d65e205
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 14 16:37:15 2018 +0100

    Reused test
    
    and added todo

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index d3406eb..9740d5a 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -9,7 +9,7 @@ import static org.assertj.core.api.Assertions.assertThat;
 public class CoachWithSeatsSpecification {
 
     [Fact]
-    public void ShouldNotAllowReservingMoreSeatsThanItHas() { //todo rename
+    public void ShouldNotAllowReservingMoreSeatsThanItHas() {
         //GIVEN
         Seat seat1 = Any.Instance<Seat>();
         Seat seat2 = Any.Instance<Seat>();
@@ -36,11 +36,15 @@ public class CoachWithSeatsSpecification {
 
         //WHEN
         var reservationAllowed = coachWithSeats.allowsReservationOf(11);
+        var upFrontAllowed = coachWithSeats.AllowsUpFrontReservationOf(11);
 
         //THEN
         assertThat(reservationAllowed).isFalse();
+        assertThat(upFrontAllowed).isFalse();
     }
 
+    //todo all free
+    //todo other scenarios
     //todo what's special about these seats?
 
 }
\ No newline at end of file

commit c89a9e035c2cc67a45b08b507f290ad5a14882ae
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 14 16:39:28 2018 +0100

    another test
    
    the non-upfront is easier, that's why I take it first

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index 9740d5a..dbc7abb 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -43,6 +43,44 @@ public class CoachWithSeatsSpecification {
         assertThat(upFrontAllowed).isFalse();
     }
 
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
+        var reservationAllowed = coachWithSeats.allowsReservationOf(10);
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

commit a9dd10d40e055adc9d91f99cd2bc7b3d60d75170
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:25:05 2018 +0100

    Made the test pass
    
    but this is not the right implementation

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 57c9f25..01c882f 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -1,7 +1,12 @@
 package logic;
 
+import java.util.Arrays;
+
 public class CoachWithSeats : Coach {
+    private Seat[] seats;
+
     public CoachWithSeats(Seat... seats) {
+        this.seats = seats;
     }
 
     
@@ -18,7 +23,7 @@ public class CoachWithSeats : Coach {
 
     
     public bool allowsReservationOf(int seatCount) {
-        //todo implement
-        return false;
+        //todo not yet the right implementation
+        return seatCount == Arrays.stream(seats).count();
     }
 }

commit fb52fcf05485d9147e7d260ed1a21e70b0d3fc23
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:26:53 2018 +0100

    Discovered isFree method
    
    when clarifying the behavior

diff --git a/Java/src/main/java/logic/Seat.java b/Java/src/main/java/logic/Seat.java
index 7835a2a..4f03bd8 100644
--- a/Java/src/main/java/logic/Seat.java
+++ b/Java/src/main/java/logic/Seat.java
@@ -1,4 +1,5 @@
 package logic;
 
 public interface Seat {
+    bool isFree();
 }
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index dbc7abb..dfc4f8e 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -5,6 +5,8 @@ import lombok.val;
 
```csharp
 public class CoachWithSeatsSpecification 
 {
 
@@ -77,7 +79,9 @@ public class CoachWithSeatsSpecification 
{
 
     private Seat FreeSeat() {
-        return Any.Instance<Seat>();
+        Seat mock = Substitute.For<Seat>();
+        mock.IsFree().Returns(true);
+        return mock;
     }
 
 

commit 1cebb829e844081bcc482e26412ef4cbb23a1d10
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:28:06 2018 +0100

    Refactored test
    
    no need for variables

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java 

@@ -48,27 +48,17 @@ public class CoachWithSeatsSpecification 
{
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

commit ab3475b0ee19bf11d3cc4c140703549d917480ee
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:30:14 2018 +0100

    added another test

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index e835cab..c1aba66 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
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
+        var reservationAllowed = coachWithSeats.allowsReservationOf(10);
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

commit 3503e7dcb9772fefec6a1661b9cdc7909d15f87b
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:32:12 2018 +0100

    implemented only free seats

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
     public bool allowsReservationOf(int seatCount) {
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
         var reservationAllowed = coachWithSeats.allowsReservationOf(10);
 
         //THEN
-        Assert.True(reservationAllowed);
+        assertThat(reservationAllowed).isFalse();
     }
 
     private Seat ReservedSeat() {
```

commit 09583d22e23e8b55154ef1e5c75215337764294d
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:34:50 2018 +0100

    First test for up front reservations
    
    why 7 and not calculating? DOn't be smart in tests - if you have to, put smartness in a well-tested library.
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
     public bool AllowsUpFrontReservationOf(int seatCount) {
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
     public bool allowsReservationOf(int seatCount) {
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
 
     
     public bool AllowsUpFrontReservationOf(int seatCount) {
-        //todo not the right implementation yet
-        return true;
+        return seatCount <= seats.length;
     }
 
     
     public bool allowsReservationOf(int seatCount) {
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
 
     
     public bool AllowsUpFrontReservationOf(int seatCount) {
-        return seatCount <= seats.length;
+        return seatCount <= seats.length * 0.7;
     }
```
     

Picked the right formula for the criteria. Another test green.

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
     public bool AllowsUpFrontReservationOf(int seatCount) {
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
     public bool allowsReservationOf(int seatCount) 
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
     public void Reserve(int seatCount, TicketInProgress ticket) {
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

commit af433d11330bd66378c20cea9e9261cea0fed2e2
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 16 16:56:52 2018 +0100

    improved the test
    
    by repeating two times

diff --git a/Java/src/main/java/logic/NamedSeat.java b/Java/src/main/java/logic/NamedSeat.java
index 26b5b8e..5e93c8e 100644
--- a/Java/src/main/java/logic/NamedSeat.java
+++ b/Java/src/main/java/logic/NamedSeat.java
@@ -1,15 +1,15 @@
 package logic;
 
 public class NamedSeat : Seat {
-    public NamedSeat(bool isFree) {
-        //todo implement
+    private bool isFree;
 
+    public NamedSeat(bool isFree) {
+        this.isFree = isFree;
     }
 
     
     public bool isFree() {
-        //todo implement
-        return false;
+        return isFree;
     }
 
     
diff --git a/Java/src/test/java/logic/NamedSeatSpecification.java b/Java/src/test/java/logic/NamedSeatSpecification.java
index 3568928..5894ae3 100644
--- a/Java/src/test/java/logic/NamedSeatSpecification.java
+++ b/Java/src/test/java/logic/NamedSeatSpecification.java
@@ -7,7 +7,7 @@ import org.testng.annotations.Test;
 import static org.assertj.core.api.Assertions.assertThat;
 
```
 public class NamedSeatSpecification {
-    [Fact]
+    [Fact](invocationCount = 2)
     public void ShouldBeFreeDependingOnPassedConstructorParameter() {
         //GIVEN
         var isInitiallyFree = Any.booleanValue();
```