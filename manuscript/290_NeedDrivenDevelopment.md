
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

    passed the compiler Now time for some deeper thinking on the expectation

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


+++ b/Java/src/main/java/logic/CommandFactory.java
 
```csharp
 public interface CommandFactory 
 {
-    Command CreateBookCommand(ReservationRequestDto reservation, Ticket ticket);
+    Command CreateBookCommand(ReservationRequestDto reservation, TicketInProgress ticketInProgress);
 }
```

+++ b/Java/src/main/java/logic/TicketFactory.java

```csharp
 public interface TicketFactory 
 {
-    Ticket createBlankTicket();
+    TicketInProgress createBlankTicket();
 }
```


+++ b/Java/src/main/java/logic/TicketInProgress.java

```csharp
-public interface Ticket {
+public interface TicketInProgress {
     TicketDto toDto();
 }
```

+++ b/Java/src/main/java/logic/Train.java

```csharp
 public interface Train 
 {
-    void Reserve(int seatCount, Ticket ticketToFill);
+    void Reserve(int seatCount, TicketInProgress ticketInProgress);
 }
```

+++ b/Java/src/main/java/logic/TrainTicketFactory.java

```csharp
 public class TrainTicketFactory : TicketFactory 
 {
     
-    public Ticket createBlankTicket() 
-     {
+    public TicketInProgress createBlankTicket() 
+    {
         //todo implement
         return null;
     }
```

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp 
 public class TrainWithCoaches : Train {
     
-    public void Reserve(int seatCount, Ticket ticketToFill)
+    public void Reserve(int seatCount, TicketInProgress ticketInProgress)
     {
         //todo implement
     }
```

rename from Java/src/test/java/TicketOfficeSpecification.java
rename to Java/src/test/java/TicketInProgressOfficeSpecification.java

--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketInProgressOfficeSpecification.java

```csharp
-public class TicketOfficeSpecification 
+public class TicketInProgressOfficeSpecification 
{
     
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
```


+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java

```csharp
public class BookTicketCommandSpecification {
 
     [Fact]
     public void ShouldReserveSeatsOnTrainWhenExecuted() {
         //GIVEN
         var reservation = Any.Instance<ReservationRequestDto>();
-        var ticket = Any.Instance<Ticket>();
+        var ticket = Any.Instance<TicketInProgress>();
         var train = Substitute.For<Train>();
         var bookTicketCommand
             = new BookTicketCommand(reservation, ticket, train);
```

+++ b/Java/src/test/java/logic/BookingCommandFactorySpecification.java

```csharp
@@ -18,7 +18,7 @@ public class BookingCommandFactorySpecification 
{
    ...
             trainRepo
         );
         var reservation = Substitute.For<ReservationRequestDto>();
-        var ticket = Substitute.For<Ticket>();
+        var ticket = Substitute.For<TicketInProgress>();
         var train = Substitute.For<Train>();
 
         trainRepo.GetTrainBy(reservation.trainId)
```

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```chsarp

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
```

Discovered the coach interface:

```csharp
+public interface Coach
+{
+}
```

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
@@ -15,6 +15,9 @@ public class TrainWithCoachesSpecification {
         var trainWithCoaches = new TrainWithCoaches();
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
+        Coach coach1 = Substitute.For<Coach>();
+        Coach coach2 = Substitute.For<Coach>();
+        Coach coach3 = Substitute.For<Coach>();
 
         //WHEN
         trainWithCoaches.Reserve(seatCount, ticket);
```

Discovered the Reserve() method

+++ b/Java/src/main/java/logic/Coach.java

```csharp
 public interface Coach 
 {
+    void Reserve(int seatCount, TicketInProgress ticket);
 }
```

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
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
```

passed coaches as vararg: not test-driving the vararg, using the Kent Beck's putting the right implementation

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
 public class TrainWithCoaches : Train 
+{
+    public TrainWithCoaches(Coach... coaches) {
+    }
```
     
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
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
```

discovered AllowsUpFrontReservationOf() method. One more condition awaits - if no coach allows up front, we take the first one that has the limit.:


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
-    //todo ticket in progress instead of plain ticket
-
+    //todo what if no coach allows up front reservation?
 }
```


Introduced the method.  a too late TODO - CouchDbRepository should supply the coaches:

+++ b/Java/src/main/java/logic/Coach.java

@@ -2,4 +2,6 @@ package logic;

```csharp 
 public interface Coach
 {
     void Reserve(int seatCount, TicketInProgress ticket);
+
+    bool AllowsUpFrontReservationOf(int seatCount);
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

```csharp
@@ -7,6 +7,5 @@ public class TrainWithCoaches : Train 
{
     public void Reserve(int seatCount, TicketInProgress ticketInProgress) 
     {
         //todo implement
     }
 }
```

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp 
 public class TrainWithCoachesSpecification {
     [Fact]
-    public void ShouldXXXXX() { //todo rename
+    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() {
         //GIVEN
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
```

Implemented the first behavior. (in the book, play with the if and return to see each assertion fail):

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

-    public void Reserve(int seatCount, TicketInProgress ticketInProgress) 
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

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
 public class TrainWithCoachesSpecification 
 {
     [Fact]
-    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() 
     { //todo rename
+    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() 
     { 
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
```

Discovered AllowsReservationOf method:

+++ b/Java/src/main/java/logic/Coach.java

```csharp
@@ -4,4 +4,6 @@ public interface Coach
{
     void Reserve(int seatCount, TicketInProgress ticket);

     bool AllowsUpFrontReservationOf(int seatCount);
+
+    bool AllowsReservationOf(int seatCount);
 }
```

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java


```csharp 
 public class TrainWithCoachesSpecification 
 {
     [Fact]
-    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() 
     { 
+    public void ShouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() 
     {
         //GIVEN
         var seatCount = Any.Integer();
         var ticket = Substitute.For<TicketInProgress>();
@@ -38,6 +38,41 @@ public class TrainWithCoachesSpecification {
         coach3.DidNotReceive().Reserve(seatCount, ticket);
     }
 
+    [Fact]
+    public void
+    ShouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() 
+    {
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
```

Bad implementation alows the test to pass! Need to fix the first test:

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
@@ -9,6 +9,12 @@ public class TrainWithCoaches : Train 
{

     public void Reserve(int seatCount, TicketInProgress ticketInProgress) 
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

forced the right implementation. But need to refactor the tests. Next time we change this class, we refactor the code:

+++ b/Java/src/main/java/logic/TrainWithCoaches.java

```csharp
@@ -10,17 +10,16 @@ public class TrainWithCoaches : Train 
{
     
     public void Reserve(int seatCount, TicketInProgress ticketInProgress) 
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

Refactored coaches (truth be told, I should refactor prod code):

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp    
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
```

Refactored tests. TODO start from this committ to show refactoring!!

+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java

```csharp
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
```

Addressed todo - created a class CoachWithSeats:

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp
+public class CoachWithSeats : Coach {
+    
+    public void Reserve(int seatCount, TicketInProgress ticket) 
+    {
+        //todo implement
+
+    }
+
+    
+    public bool AllowsUpFrontReservationOf(int seatCount) 
+    {
+        //todo implement
+        return false;
+    }
+
+    
+    public bool AllowsReservationOf(int seatCount) 
+    {
+        //todo implement
+        return false;
+    }
+}
```

+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java

```csharp
@@ -4,6 +4,8 @@ public class CouchDbTrainRepository : TrainRepository {
     
     public Train GetTrainBy(String trainId) {
         //todo there should be something passed here!!
-        return new TrainWithCoaches();
+        return new TrainWithCoaches(
+            new CoachWithSeats()
+        );
     }
 }
```

Brain dump

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
+public class CoachWithSeatsSpecification {
+
+    [Fact]
+    public void xxXXxxXX() { //todo rename
+        //GIVEN
+        var coachWithSeats = new CoachWithSeats();
+        //WHEN
+        int seatCount = Any.Integer();
+        var reservationAllowed = coachWithSeats.AllowsReservationOf(seatCount);
+
+        //THEN
+        Assert.True(reservationAllowed);
+    }
+
+}
```

Discovered an interface Seat:

+++ b/Java/src/main/java/logic/Seat.java

```csharp
+public interface Seat {
+}
```

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
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
         var reservationAllowed = coachWithSeats.AllowsReservationOf(seatCount);
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
```

Added a constructor:

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java

+++ b/Java/src/main/java/logic/CoachWithSeats.java

```csharp 
 public class CoachWithSeats : Coach {
+    public CoachWithSeats(Seat... seats) {
+    }
+
     
     public void Reserve(int seatCount, TicketInProgress ticket) {
         //todo implement
```

clarified scenario. Test passes right away. suspicious:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
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
-        var reservationAllowed = coachWithSeats.AllowsReservationOf(seatCount);
+        var reservationAllowed = coachWithSeats.AllowsReservationOf(11);
 
         //THEN
-        Assert.True(reservationAllowed);
+        assertThat(reservationAllowed).isFalse();
     }
 
+    //todo what's special about these seats?
+
 }
```

Reused test and added todo:

+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java

```csharp
public class CoachWithSeatsSpecification {
 
     [Fact]
-    public void ShouldNotAllowReservingMoreSeatsThanItHas() { //todo rename
+    public void ShouldNotAllowReservingMoreSeatsThanItHas() {
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
     
     public bool AllowsReservationOf(int seatCount) {
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
     public bool AllowsReservationOf(int seatCount) {
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
     public bool AllowsReservationOf(int seatCount) {
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
 
     
     public bool AllowsReservationOf(int seatCount) {
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
     public bool AllowsReservationOf(int seatCount) 
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
