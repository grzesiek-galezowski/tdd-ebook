
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
      new WebApp(new TicketOffice())
       .Host();
    }
}
```
-------------------------------------
+import api.TicketOffice;
+import autofixture.publicinterface.Any;
+import lombok.val;
 import org.testng.annotations.Test;
+import request.dto.ReservationRequestDto;
+
+import static org.assertj.core.api.Assertions.assertThat;
 
 public class TicketOfficeSpecification {
     
     @Test
-    public void shouldXXXYYYZZZ() {
-        // TODO: Write this code!
+    public void shouldCreateAndExecuteCommandWithTicketAndTrain() {
+        //WHEN
+        val ticketOffice = new TicketOffice();
+        val reservation = Any.anonymous(ReservationRequestDto.class);
+        //WHEN
+        val reservationDto = ticketOffice.makeReservation(reservation);
 
+        //THEN
+        assertThat(reservationDto).isEqualTo(resultDto);
     }
 }
---------------------------------------------------------------------------------------------------------------
commit 5b552ca4717d3795d649b6aa70b3ed4cee92b844
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Tue Feb 27 16:17:58 2018 +0100

    ticket dto feels better

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index a4406eb..045f2c0 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -1,11 +1,11 @@
 package api;
 
 import request.dto.ReservationRequestDto;
-import response.dto.ReservationDto;
+import response.dto.TicketDto;
 
 public class TicketOffice {
 
-    public ReservationDto makeReservation(
+    public TicketDto makeReservation(
         ReservationRequestDto request) {
         throw new RuntimeException("lol");
     }

---------------------------------------------------------------------------------------------------------------
rename reservation dto to ticket dto
---------------------------------------------------------------------------------------------------------------

@@ -2,12 +2,12 @@ package response.dto;
 
 import java.util.List;
 
-public class ReservationDto {
+public class TicketDto {
     public final String trainId;
     public final String ticketId;
     public final List<SeatDto> seats;
 
-    public ReservationDto(
+    public TicketDto(
         String trainId,
         List<response.dto.SeatDto> seats,
         String ticketId) {
---------------------------------------------------------------------------------------------------------------
this changes the specification as well
---------------------------------------------------------------------------------------------------------------
@@ -14,9 +14,9 @@ public class TicketOfficeSpecification {
         val ticketOffice = new TicketOffice();
         val reservation = Any.anonymous(ReservationRequestDto.class);
         //WHEN
-        val reservationDto = ticketOffice.makeReservation(reservation);
+        val ticketDto = ticketOffice.makeReservation(reservation);
 
         //THEN
-        assertThat(reservationDto).isEqualTo(resultDto);
+        assertThat(ticketDto).isEqualTo(resultDto);
     }
 }

commit 59c3e78f91feee08be6ba7ea155f0dcb398cb3f8
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Tue Feb 27 16:20:34 2018 +0100

    Let's have a ticket convertible to dto
    
    (btw, how to hide this toDto method?)

---------------------------------------------------------------------------------------------------------------
Introducing ticket dto into the test
---------------------------------------------------------------------------------------------------------------
@@ -3,8 +3,10 @@ import autofixture.publicinterface.Any;
 import lombok.val;
 import org.testng.annotations.Test;
 import request.dto.ReservationRequestDto;
+import response.dto.TicketDto;
 
 import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.BDDMockito.given;
 
 public class TicketOfficeSpecification {
     
@@ -13,6 +15,10 @@ public class TicketOfficeSpecification {
         //WHEN
         val ticketOffice = new TicketOffice();
         val reservation = Any.anonymous(ReservationRequestDto.class);
+        val resultDto = Any.anonymous(TicketDto.class);
+
+        given(ticket.toDto()).willReturn(resultDto);
+
         //WHEN
         val ticketDto = ticketOffice.makeReservation(reservation);
 

commit 23002b0151dc0130c15a5b21effa037440123832
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Tue Feb 27 16:24:09 2018 +0100

    discovered a Ticket interface and one method

diff --git a/Java/src/main/java/logic/Ticket.java b/Java/src/main/java/logic/Ticket.java
new file mode 100644






index 0000000..1cc7e63
--- /dev/null
+++ b/Java/src/main/java/logic/Ticket.java
@@ -0,0 +1,4 @@
+package logic;
+
+public interface Ticket {
+}
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index 6cbdfbd..fc9a496 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -1,5 +1,6 @@
 import api.TicketOffice;
 import autofixture.publicinterface.Any;
+import logic.Ticket;
 import lombok.val;
 import org.testng.annotations.Test;
 import request.dto.ReservationRequestDto;
@@ -7,6 +8,7 @@ import response.dto.TicketDto;
 
 import static org.assertj.core.api.Assertions.assertThat;
 import static org.mockito.BDDMockito.given;
+import static org.mockito.Mockito.mock;
 
 public class TicketOfficeSpecification {
     
@@ -16,6 +18,7 @@ public class TicketOfficeSpecification {
         val ticketOffice = new TicketOffice();
         val reservation = Any.anonymous(ReservationRequestDto.class);
         val resultDto = Any.anonymous(TicketDto.class);
+        Ticket ticket = mock(Ticket.class);
 
         given(ticket.toDto()).willReturn(resultDto);
 

commit 858b5befe562f951594a167bf426a32835ac20c6
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Tue Feb 27 16:24:54 2018 +0100

    Introduced toDto method. But how to pass the Ticket?

diff --git a/Java/src/main/java/logic/Ticket.java b/Java/src/main/java/logic/Ticket.java
index 1cc7e63..a7ad63b 100644
--- a/Java/src/main/java/logic/Ticket.java
+++ b/Java/src/main/java/logic/Ticket.java
@@ -1,4 +1,7 @@
 package logic;
 
+import response.dto.TicketDto;
+
 public interface Ticket {
+    TicketDto toDto();
 }

commit 89b504c62009db00b63b1a2b8a6ecb80df52fe6a
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Tue Feb 27 16:25:53 2018 +0100

    TIcket will come from factory
    
    Not much OO, is it?

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index fc9a496..81523e6 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -20,6 +20,7 @@ public class TicketOfficeSpecification {
         val resultDto = Any.anonymous(TicketDto.class);
         Ticket ticket = mock(Ticket.class);
 
+        given(ticketFactory.createBlankTicket()).willReturn(ticket);
         given(ticket.toDto()).willReturn(resultDto);
 
         //WHEN

commit 68eab6eb29f83bc9bc3342478baae48644366568
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Tue Feb 27 16:27:19 2018 +0100

    Introduced TicketFactory collaborator

diff --git a/Java/src/main/java/logic/TicketFactory.java b/Java/src/main/java/logic/TicketFactory.java
new file mode 100644






index 0000000..27a10ef
--- /dev/null
+++ b/Java/src/main/java/logic/TicketFactory.java
@@ -0,0 +1,5 @@
+package logic;
+
+public interface TicketFactory {
+    Ticket createBlankTicket();
+}
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index 81523e6..b6728f5 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -1,6 +1,7 @@
 import api.TicketOffice;
 import autofixture.publicinterface.Any;
 import logic.Ticket;
+import logic.TicketFactory;
 import lombok.val;
 import org.testng.annotations.Test;
 import request.dto.ReservationRequestDto;
@@ -20,6 +21,7 @@ public class TicketOfficeSpecification {
         val resultDto = Any.anonymous(TicketDto.class);
         Ticket ticket = mock(Ticket.class);
 
+        val ticketFactory = mock(TicketFactory.class);
         given(ticketFactory.createBlankTicket()).willReturn(ticket);
         given(ticket.toDto()).willReturn(resultDto);
 

commit 6ebe534eedbfbf08bcdfc1ffff46b4fe80d83049
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 07:49:26 2018 +0100

    Discovered a command
    
    For now mistakenly assuming that it will take a parameter

diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index b6728f5..b92dc64 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -9,6 +9,7 @@ import response.dto.TicketDto;
 
 import static org.assertj.core.api.Assertions.assertThat;
 import static org.mockito.BDDMockito.given;
+import static org.mockito.BDDMockito.then;
 import static org.mockito.Mockito.mock;
 
 public class TicketOfficeSpecification {
@@ -29,6 +30,7 @@ public class TicketOfficeSpecification {
         val ticketDto = ticketOffice.makeReservation(reservation);
 
         //THEN
+        then(bookCommand).should().execute(ticket);
         assertThat(ticketDto).isEqualTo(resultDto);
     }
 }

commit 80934e48144dbea60567f464795d38fb2b905644
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 07:50:37 2018 +0100

    Introduced Command collaborator
    
    Now our problem is - where do we get the command from?

diff --git a/Java/src/main/java/logic/Command.java b/Java/src/main/java/logic/Command.java
new file mode 100644






index 0000000..da9e156
--- /dev/null
+++ b/Java/src/main/java/logic/Command.java
@@ -0,0 +1,4 @@
+package logic;
+
+public interface Command {
+}
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index b92dc64..f1cf97f 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -1,8 +1,10 @@
 import api.TicketOffice;
 import autofixture.publicinterface.Any;
+import logic.Command;
 import logic.Ticket;
 import logic.TicketFactory;
 import lombok.val;
+import org.testng.CommandLineArgs;
 import org.testng.annotations.Test;
 import request.dto.ReservationRequestDto;
 import response.dto.TicketDto;
@@ -21,6 +23,7 @@ public class TicketOfficeSpecification {
         val reservation = Any.anonymous(ReservationRequestDto.class);
         val resultDto = Any.anonymous(TicketDto.class);
         Ticket ticket = mock(Ticket.class);
+        val bookCommand = mock(Command.class);
 
         val ticketFactory = mock(TicketFactory.class);
         given(ticketFactory.createBlankTicket()).willReturn(ticket);

commit 9af87d9e8f4f931dd1c65d04d00a0b5bded88007
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 07:52:08 2018 +0100

    I decide a command factory will wrap dto with a command

diff --git a/Java/src/main/java/logic/Command.java b/Java/src/main/java/logic/Command.java
index da9e156..c0202a2 100644
--- a/Java/src/main/java/logic/Command.java
+++ b/Java/src/main/java/logic/Command.java
@@ -1,4 +1,5 @@
 package logic;
 
 public interface Command {
+    void execute(Ticket ticket);
 }
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index f1cf97f..7720e10 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -4,7 +4,6 @@ import logic.Command;
 import logic.Ticket;
 import logic.TicketFactory;
 import lombok.val;
-import org.testng.CommandLineArgs;
 import org.testng.annotations.Test;
 import request.dto.ReservationRequestDto;
 import response.dto.TicketDto;
@@ -28,6 +27,8 @@ public class TicketOfficeSpecification {
         val ticketFactory = mock(TicketFactory.class);
         given(ticketFactory.createBlankTicket()).willReturn(ticket);
         given(ticket.toDto()).willReturn(resultDto);
+        given(commandFactory.createBookCommand(reservation))
+            .willReturn(bookCommand);
 
         //WHEN
         val ticketDto = ticketOffice.makeReservation(reservation);

commit 27c3d4a3f39cb97f1ac61d024f79c60737e2a971
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 07:55:22 2018 +0100

    Introduced the factory interface
    
    Now how should a ticket office get to know it?

diff --git a/Java/src/main/java/logic/CommandFactory.java b/Java/src/main/java/logic/CommandFactory.java
new file mode 100644






index 0000000..62baaa3
--- /dev/null
+++ b/Java/src/main/java/logic/CommandFactory.java
@@ -0,0 +1,7 @@
+package logic;
+
+import request.dto.ReservationRequestDto;
+
+public interface CommandFactory {
+    Command createBookCommand(ReservationRequestDto reservation);
+}
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index 7720e10..ca0ac87 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -1,6 +1,7 @@
 import api.TicketOffice;
 import autofixture.publicinterface.Any;
 import logic.Command;
+import logic.CommandFactory;
 import logic.Ticket;
 import logic.TicketFactory;
 import lombok.val;
@@ -27,6 +28,7 @@ public class TicketOfficeSpecification {
         val ticketFactory = mock(TicketFactory.class);
         given(ticketFactory.createBlankTicket()).willReturn(ticket);
         given(ticket.toDto()).willReturn(resultDto);
+        val commandFactory = mock(CommandFactory.class);
         given(commandFactory.createBookCommand(reservation))
             .willReturn(bookCommand);
 

commit a46886c0a1f1414b3bcd78aaa6fb06b51737c791
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 07:56:38 2018 +0100

    We can just pass the factory to the constructor
    
    since its creation is not dependent on local scope

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index 045f2c0..c2687db 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -1,10 +1,16 @@
 package api;
 
+import logic.CommandFactory;
 import request.dto.ReservationRequestDto;
 import response.dto.TicketDto;
 
 public class TicketOffice {
 
+    public TicketOffice(CommandFactory commandFactory) {
+        //todo implement
+
+    }
+
     public TicketDto makeReservation(
         ReservationRequestDto request) {
         throw new RuntimeException("lol");
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index ca0ac87..bb0a5d0 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -19,16 +19,16 @@ public class TicketOfficeSpecification {
     @Test
     public void shouldCreateAndExecuteCommandWithTicketAndTrain() {
         //WHEN
-        val ticketOffice = new TicketOffice();
+        val commandFactory = mock(CommandFactory.class);
+        val ticketOffice = new TicketOffice(commandFactory);
         val reservation = Any.anonymous(ReservationRequestDto.class);
         val resultDto = Any.anonymous(TicketDto.class);
-        Ticket ticket = mock(Ticket.class);
+        val ticket = mock(Ticket.class);
         val bookCommand = mock(Command.class);
-
         val ticketFactory = mock(TicketFactory.class);
+
         given(ticketFactory.createBlankTicket()).willReturn(ticket);
         given(ticket.toDto()).willReturn(resultDto);
-        val commandFactory = mock(CommandFactory.class);
         given(commandFactory.createBookCommand(reservation))
             .willReturn(bookCommand);
 

commit 4ae76313220c9fda115482c9ffe33668033d8a3d
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 07:57:56 2018 +0100

    I noticed I can pass the ticket to factory
    
    and have the command as something more generic with a void execute() method

diff --git a/Java/src/main/java/logic/Command.java b/Java/src/main/java/logic/Command.java
index c0202a2..96b1f3f 100644
--- a/Java/src/main/java/logic/Command.java
+++ b/Java/src/main/java/logic/Command.java
@@ -1,5 +1,5 @@
 package logic;
 
 public interface Command {
-    void execute(Ticket ticket);
+    void execute();
 }
diff --git a/Java/src/main/java/logic/CommandFactory.java b/Java/src/main/java/logic/CommandFactory.java
index 62baaa3..18208a5 100644
--- a/Java/src/main/java/logic/CommandFactory.java
+++ b/Java/src/main/java/logic/CommandFactory.java
@@ -3,5 +3,5 @@ package logic;
 import request.dto.ReservationRequestDto;
 
 public interface CommandFactory {
-    Command createBookCommand(ReservationRequestDto reservation);
+    Command createBookCommand(ReservationRequestDto reservation, Ticket ticket);
 }
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index bb0a5d0..8b3f66a 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -29,14 +29,14 @@ public class TicketOfficeSpecification {
 
         given(ticketFactory.createBlankTicket()).willReturn(ticket);
         given(ticket.toDto()).willReturn(resultDto);
-        given(commandFactory.createBookCommand(reservation))
+        given(commandFactory.createBookCommand(reservation, ticket))
             .willReturn(bookCommand);
 
         //WHEN
         val ticketDto = ticketOffice.makeReservation(reservation);
 
         //THEN
-        then(bookCommand).should().execute(ticket);
+        then(bookCommand).should().execute();
         assertThat(ticketDto).isEqualTo(resultDto);
     }
 }

commit 811073ca33b291615e666b9e89f3877cbc191724
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 07:59:19 2018 +0100

    returning whatever to make sure we fail for the right reason

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index c2687db..9804346 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -13,7 +13,7 @@ public class TicketOffice {
 
     public TicketDto makeReservation(
         ReservationRequestDto request) {
-        throw new RuntimeException("lol");
+        return new TicketDto(null, null, null);
     }
 
 }
\ No newline at end of file

commit 6cb900562686d0afcc6fc315616abcb329816992
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 08:02:01 2018 +0100

    TicketOffice should also know ticket factory

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index 9804346..6239a21 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -1,14 +1,18 @@
 package api;
 
 import logic.CommandFactory;
+import logic.TicketFactory;
 import request.dto.ReservationRequestDto;
 import response.dto.TicketDto;
 
 public class TicketOffice {
 
-    public TicketOffice(CommandFactory commandFactory) {
+    private CommandFactory commandFactory;
+
+    public TicketOffice(CommandFactory commandFactory, TicketFactory ticketFactory) {
         //todo implement
 
+        this.commandFactory = commandFactory;
     }
 
     public TicketDto makeReservation(
diff --git a/Java/src/test/java/TicketOfficeSpecification.java b/Java/src/test/java/TicketOfficeSpecification.java
index 8b3f66a..62624d9 100644
--- a/Java/src/test/java/TicketOfficeSpecification.java
+++ b/Java/src/test/java/TicketOfficeSpecification.java
@@ -20,12 +20,14 @@ public class TicketOfficeSpecification {
     public void shouldCreateAndExecuteCommandWithTicketAndTrain() {
         //WHEN
         val commandFactory = mock(CommandFactory.class);
-        val ticketOffice = new TicketOffice(commandFactory);
         val reservation = Any.anonymous(ReservationRequestDto.class);
         val resultDto = Any.anonymous(TicketDto.class);
         val ticket = mock(Ticket.class);
         val bookCommand = mock(Command.class);
         val ticketFactory = mock(TicketFactory.class);
+        val ticketOffice = new TicketOffice(
+            commandFactory,
+            ticketFactory);
 
         given(ticketFactory.createBlankTicket()).willReturn(ticket);
         given(ticket.toDto()).willReturn(resultDto);

commit 517dbacaf02f9122898deaa73de9ad4f53256b79
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:31:35 2018 +0100

    Passed the first assertion, but the second one fails
    
    Check the error message, Luke!

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index 6239a21..0fb9af4 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -2,21 +2,28 @@ package api;
 
 import logic.CommandFactory;
 import logic.TicketFactory;
+import lombok.val;
 import request.dto.ReservationRequestDto;
 import response.dto.TicketDto;
 
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
 
     public TicketDto makeReservation(
         ReservationRequestDto request) {
+        val ticket = ticketFactory.createBlankTicket();
+        val command = commandFactory.createBookCommand(request, ticket);
         return new TicketDto(null, null, null);
     }
 

commit 353d368c0745a42e5c41df633a9a57b75b462c17
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:32:28 2018 +0100

    Passed the first assertion but the second one still fails
    
    (look at the error message, Luke)

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index 0fb9af4..7929925 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -24,6 +24,7 @@ public class TicketOffice {
         ReservationRequestDto request) {
         val ticket = ticketFactory.createBlankTicket();
         val command = commandFactory.createBookCommand(request, ticket);
+        command.execute();
         return new TicketDto(null, null, null);
     }
 

commit 1d5baf66bfb58d8abf52d6b8256db8678d76e486
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:34:08 2018 +0100

    Passed the second assertion, test green. WHat about the order of invocations?
    
    Can we alter it to make it invalid? No, creation comes before usage, usage goes before returning value, return comes last.

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index 7929925..941b7fd 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -25,7 +25,7 @@ public class TicketOffice {
         val ticket = ticketFactory.createBlankTicket();
         val command = commandFactory.createBookCommand(request, ticket);
         command.execute();
-        return new TicketDto(null, null, null);
+        return ticket.toDto();
     }
 
 }
\ No newline at end of file

commit 23de6b1c8e6d7d84fb972ab02c2888c3a933d333
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:37:04 2018 +0100

    [LATE] creating an instance. need some implementations

diff --git a/Java/src/main/java/bootstrap/Main.java b/Java/src/main/java/bootstrap/Main.java
index 2f5013f..5c11658 100644
--- a/Java/src/main/java/bootstrap/Main.java
+++ b/Java/src/main/java/bootstrap/Main.java
@@ -1,9 +1,11 @@
 package bootstrap;
 
+import api.TicketOffice;
+
 public class Main {
 
     public static void main(String[] args) {
-
+        new TicketOffice();
     }
 
 }

commit 07c2b7388d1a33d457b61f76ce27dfa7916a0fa8
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:38:41 2018 +0100

    the empty implementations add to TODO list.
    
    I need to pick one item to work on.

diff --git a/Java/src/main/java/api/TicketOffice.java b/Java/src/main/java/api/TicketOffice.java
index 941b7fd..a16d7de 100644
--- a/Java/src/main/java/api/TicketOffice.java
+++ b/Java/src/main/java/api/TicketOffice.java
@@ -14,7 +14,6 @@ public class TicketOffice {
     public TicketOffice(
         CommandFactory commandFactory,
         TicketFactory ticketFactory) {
-        //todo implement
 
         this.commandFactory = commandFactory;
         this.ticketFactory = ticketFactory;
diff --git a/Java/src/main/java/bootstrap/Main.java b/Java/src/main/java/bootstrap/Main.java
index 5c11658..acd7e6d 100644
--- a/Java/src/main/java/bootstrap/Main.java
+++ b/Java/src/main/java/bootstrap/Main.java
@@ -1,11 +1,14 @@
 package bootstrap;
 
 import api.TicketOffice;
+import logic.BookingCommandFactory;
+import logic.TrainTicketFactory;
 
 public class Main {
 
     public static void main(String[] args) {
-        new TicketOffice();
+        new TicketOffice(new BookingCommandFactory(),
+            new TrainTicketFactory());
     }
 
 }
diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
new file mode 100644






index 0000000..a5eb928
--- /dev/null
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -0,0 +1,11 @@
+package logic;
+
+import request.dto.ReservationRequestDto;
+
+public class BookingCommandFactory implements CommandFactory {
+    @Override
+    public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
+        //todo implement
+        return null;
+    }
+}
diff --git a/Java/src/main/java/logic/TrainTicketFactory.java b/Java/src/main/java/logic/TrainTicketFactory.java
new file mode 100644






index 0000000..4bc54a5
--- /dev/null
+++ b/Java/src/main/java/logic/TrainTicketFactory.java
@@ -0,0 +1,9 @@
+package logic;
+
+public class TrainTicketFactory implements TicketFactory {
+    @Override
+    public Ticket createBlankTicket() {
+        //todo implement
+        return null;
+    }
+}

commit b536cc0491ca89a7be6c1ccd81d12a0b2cb91dc1
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:40:33 2018 +0100

    I pick the factory as there is not much I can do with Ticket yet

diff --git a/Java/src/test/java/logic/TrainTicketFactorySpecification.java b/Java/src/test/java/logic/TrainTicketFactorySpecification.java
new file mode 100644






index 0000000..e58520b
--- /dev/null
+++ b/Java/src/test/java/logic/TrainTicketFactorySpecification.java
@@ -0,0 +1,6 @@
+package logic;
+
+public class TrainTicketFactorySpecification {
+    
+
+}
\ No newline at end of file

commit 867552ef44b8f0c51a7fbdc7316f739b64c5e561
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:41:23 2018 +0100

    THe factory should create a specific command for me

diff --git a/Java/src/test/java/logic/TrainTicketFactorySpecification.java b/Java/src/test/java/logic/TrainTicketFactorySpecification.java
index e58520b..c5ce32b 100644
--- a/Java/src/test/java/logic/TrainTicketFactorySpecification.java
+++ b/Java/src/test/java/logic/TrainTicketFactorySpecification.java
@@ -1,6 +1,18 @@
 package logic;
 
+import org.testng.annotations.Test;
+
+import static org.assertj.core.api.Assertions.assertThat;
+
 public class TrainTicketFactorySpecification {
-    
+    @Test
+    public void shouldCreateBookingCommand() {
+        //GIVEN
+
+        //WHEN
+
+        //THEN
+        assertThat(1).isEqualTo(2);
+    }
 
 }
\ No newline at end of file

commit cbf2f0f18e49ee13842d7aa61532b738e9bd3f59
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Feb 28 16:43:17 2018 +0100

    [SORRY] I pick command factory as there is not much I can do with tickets

diff --git a/Java/src/test/java/logic/BookingCommandFactoryTest.java b/Java/src/test/java/logic/BookingCommandFactoryTest.java
new file mode 100644






index 0000000..6dc1b99
--- /dev/null
+++ b/Java/src/test/java/logic/BookingCommandFactoryTest.java
@@ -0,0 +1,5 @@
+package logic;
+
+public class BookingCommandFactoryTest {
+
+}
\ No newline at end of file
diff --git a/Java/src/test/java/logic/TrainTicketFactorySpecification.java b/Java/src/test/java/logic/TrainTicketFactorySpecification.java
deleted file mode 100644
index c5ce32b..0000000
--- a/Java/src/test/java/logic/TrainTicketFactorySpecification.java
+++ /dev/null
@@ -1,18 +0,0 @@
-package logic;
-
-import org.testng.annotations.Test;
-
-import static org.assertj.core.api.Assertions.assertThat;
-
-public class TrainTicketFactorySpecification {
-    @Test
-    public void shouldCreateBookingCommand() {
-        //GIVEN
-
-        //WHEN
-
-        //THEN
-        assertThat(1).isEqualTo(2);
-    }
-
-}
\ No newline at end of file

commit 08a4b6753369993e170395b3a54df1ad4ad53dea
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 07:57:53 2018 +0100

    wrote a failing test for a type and dependencies

diff --git a/Java/src/main/java/logic/BookTicketCommand.java b/Java/src/main/java/logic/BookTicketCommand.java
new file mode 100644






index 0000000..ae17b99
--- /dev/null
+++ b/Java/src/main/java/logic/BookTicketCommand.java
@@ -0,0 +1,4 @@
+package logic;
+
+public class BookTicketCommand {
+}
diff --git a/Java/src/test/java/logic/BookingCommandFactoryTest.java b/Java/src/test/java/logic/BookingCommandFactoryTest.java
index 6dc1b99..7a6b6b8 100644
--- a/Java/src/test/java/logic/BookingCommandFactoryTest.java
+++ b/Java/src/test/java/logic/BookingCommandFactoryTest.java
@@ -1,5 +1,27 @@
 package logic;
 
+import lombok.val;
+import org.testng.annotations.Test;
+import request.dto.ReservationRequestDto;
+
+import static com.github.grzesiek_galezowski.test_environment.types.ObjectGraphContainsDependencyCondition.dependencyOn;
+import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.Mockito.mock;
+
 public class BookingCommandFactoryTest {
+    @Test
+    public void shouldCreateBookTicketCommand() {
+        //GIVEN
+        val bookingCommandFactory = new BookingCommandFactory();
+        val reservation = mock(ReservationRequestDto.class);
+        val ticket = mock(Ticket.class);
+
+        //WHEN
+        Command result = bookingCommandFactory.createBookCommand(reservation, ticket);
 
+        //THEN
+        assertThat(result).isInstanceOf(BookTicketCommand.class);
+        assertThat(result).has(dependencyOn(reservation));
+        assertThat(result).has(dependencyOn(ticket));
+    }
 }
\ No newline at end of file

commit 9829f47c60d93a90a06a1b2a40b49c2eb67cb679
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 07:59:49 2018 +0100

    Returning book ticket command forced interface implementation
    
    (can be applied via a quick fix)

diff --git a/Java/src/main/java/logic/BookTicketCommand.java b/Java/src/main/java/logic/BookTicketCommand.java
index ae17b99..137bf5c 100644
--- a/Java/src/main/java/logic/BookTicketCommand.java
+++ b/Java/src/main/java/logic/BookTicketCommand.java
@@ -1,4 +1,9 @@
 package logic;
 
-public class BookTicketCommand {
+public class BookTicketCommand implements Command {
+    @Override
+    public void execute() {
+        //todo implement
+
+    }
 }
diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
index a5eb928..ad8bd50 100644
--- a/Java/src/main/java/logic/BookingCommandFactory.java
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -5,7 +5,6 @@ import request.dto.ReservationRequestDto;
 public class BookingCommandFactory implements CommandFactory {
     @Override
     public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        //todo implement
-        return null;
+        return new BookTicketCommand();
     }
 }
diff --git a/Java/src/test/java/logic/BookingCommandFactoryTest.java b/Java/src/test/java/logic/BookingCommandFactoryTest.java
index 7a6b6b8..d1e7e4e 100644
--- a/Java/src/test/java/logic/BookingCommandFactoryTest.java
+++ b/Java/src/test/java/logic/BookingCommandFactoryTest.java
@@ -17,7 +17,8 @@ public class BookingCommandFactoryTest {
         val ticket = mock(Ticket.class);
 
         //WHEN
-        Command result = bookingCommandFactory.createBookCommand(reservation, ticket);
+        Command result = bookingCommandFactory
+            .createBookCommand(reservation, ticket);
 
         //THEN
         assertThat(result).isInstanceOf(BookTicketCommand.class);

commit ff7322cbe40c6a241c3422f133ff183241c5bd51
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 08:00:57 2018 +0100

    Made 2nd assertion pass by introducing field for dto
    
    The 3rd assertion still fails.

diff --git a/Java/src/main/java/logic/BookTicketCommand.java b/Java/src/main/java/logic/BookTicketCommand.java
index 137bf5c..c254c5c 100644
--- a/Java/src/main/java/logic/BookTicketCommand.java
+++ b/Java/src/main/java/logic/BookTicketCommand.java
@@ -1,6 +1,14 @@
 package logic;
 
+import request.dto.ReservationRequestDto;
+
 public class BookTicketCommand implements Command {
+    private ReservationRequestDto reservation;
+
+    public BookTicketCommand(ReservationRequestDto reservation) {
+        this.reservation = reservation;
+    }
+
     @Override
     public void execute() {
         //todo implement
diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
index ad8bd50..9a685da 100644
--- a/Java/src/main/java/logic/BookingCommandFactory.java
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -5,6 +5,6 @@ import request.dto.ReservationRequestDto;
 public class BookingCommandFactory implements CommandFactory {
     @Override
     public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        return new BookTicketCommand();
+        return new BookTicketCommand(reservation);
     }
 }

commit 3dff9247d571348d6121495b1ededef983a26a36
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 08:01:56 2018 +0100

    The test now passes. New items on TODO list
    
    (e.g. execute() method)

diff --git a/Java/src/main/java/logic/BookTicketCommand.java b/Java/src/main/java/logic/BookTicketCommand.java
index c254c5c..41e2ff8 100644
--- a/Java/src/main/java/logic/BookTicketCommand.java
+++ b/Java/src/main/java/logic/BookTicketCommand.java
@@ -4,9 +4,11 @@ import request.dto.ReservationRequestDto;
 
 public class BookTicketCommand implements Command {
     private ReservationRequestDto reservation;
+    private Ticket ticket;
 
-    public BookTicketCommand(ReservationRequestDto reservation) {
+    public BookTicketCommand(ReservationRequestDto reservation, Ticket ticket) {
         this.reservation = reservation;
+        this.ticket = ticket;
     }
 
     @Override
diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
index 9a685da..abec844 100644
--- a/Java/src/main/java/logic/BookingCommandFactory.java
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -5,6 +5,6 @@ import request.dto.ReservationRequestDto;
 public class BookingCommandFactory implements CommandFactory {
     @Override
     public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        return new BookTicketCommand(reservation);
+        return new BookTicketCommand(reservation, ticket);
     }
 }

commit 51fd3d1e982031bf6f8b34bead2f97a545b09cef
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 08:03:46 2018 +0100

    As my next step, I choose BookTicketCommand
    
    I prefer it over TicketFactory as it will allow me to learn more about the Ticket interface. So now I am optimizing for learning.

diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketCommandSpecification.java
new file mode 100644






index 0000000..dd0ef10
--- /dev/null
+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java
@@ -0,0 +1,5 @@
+package logic;
+
+public class BookTicketCommandSpecification {
+
+}
\ No newline at end of file

commit 0f3e0bdb151f4a65c6eb110c0dcd012624cf5ad4
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 08:04:30 2018 +0100

    I have yet to discover what behavior I will require from the command

diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketCommandSpecification.java
index dd0ef10..0f2adeb 100644
--- a/Java/src/test/java/logic/BookTicketCommandSpecification.java
+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java
@@ -1,5 +1,17 @@
 package logic;
 
+import org.testng.annotations.Test;
+
+import static org.assertj.core.api.Assertions.assertThat;
+
 public class BookTicketCommandSpecification {
+    @Test
+    public void shouldXXXXXXXXXXXXX() {
+        //GIVEN
+
+        //WHEN
 
+        //THEN
+        assertThat(1).isEqualTo(2);
+    }
 }
\ No newline at end of file

commit 2daff5d44e2977e97f568e7bf5cce742f3c516cf
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 08:05:48 2018 +0100

    I realize I have no train, so I comment the test and backtrack

diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketCommandSpecification.java
index 0f2adeb..d1960b5 100644
--- a/Java/src/test/java/logic/BookTicketCommandSpecification.java
+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java
@@ -1,11 +1,9 @@
 package logic;
 
-import org.testng.annotations.Test;
-
-import static org.assertj.core.api.Assertions.assertThat;
-
 public class BookTicketCommandSpecification {
+    /*
     @Test
+    //hmm, should reserve a train, but I have no train
     public void shouldXXXXXXXXXXXXX() {
         //GIVEN
 
@@ -13,5 +11,5 @@ public class BookTicketCommandSpecification {
 
         //THEN
         assertThat(1).isEqualTo(2);
-    }
+    }*/
 }
\ No newline at end of file

commit 80ca8a3a29f3e0b5f3ab7830bfa1e7414fd0c4f6
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:14:20 2018 +0100

    Discovered TrainRepository interface

diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
index abec844..14ad559 100644
--- a/Java/src/main/java/logic/BookingCommandFactory.java
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -3,6 +3,11 @@ package logic;
 import request.dto.ReservationRequestDto;
 
 public class BookingCommandFactory implements CommandFactory {
+    public BookingCommandFactory(TrainRepository trainRepo) {
+        //todo implement
+
+    }
+
     @Override
     public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
         return new BookTicketCommand(reservation, ticket);
diff --git a/Java/src/main/java/logic/TrainRepository.java b/Java/src/main/java/logic/TrainRepository.java
new file mode 100644






index 0000000..fdb959b
--- /dev/null
+++ b/Java/src/main/java/logic/TrainRepository.java
@@ -0,0 +1,4 @@
+package logic;
+
+public interface TrainRepository {
+}
diff --git a/Java/src/test/java/logic/BookingCommandFactoryTest.java b/Java/src/test/java/logic/BookingCommandFactoryTest.java
index d1e7e4e..8650cfb 100644
--- a/Java/src/test/java/logic/BookingCommandFactoryTest.java
+++ b/Java/src/test/java/logic/BookingCommandFactoryTest.java
@@ -12,10 +12,12 @@ public class BookingCommandFactoryTest {
     @Test
     public void shouldCreateBookTicketCommand() {
         //GIVEN
-        val bookingCommandFactory = new BookingCommandFactory();
+        val trainRepo = mock(TrainRepository.class);
+        val bookingCommandFactory = new BookingCommandFactory(
+            trainRepo
+        );
         val reservation = mock(ReservationRequestDto.class);
         val ticket = mock(Ticket.class);
-
         //WHEN
         Command result = bookingCommandFactory
             .createBookCommand(reservation, ticket);

commit 4466cd02d45b53db9c2b3c0382c0cecacf8ed8e7
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:16:14 2018 +0100

    Discovered train collaborator and getBy repo method
    
    Now what type should the train variable be?

diff --git a/Java/src/test/java/logic/BookingCommandFactoryTest.java b/Java/src/test/java/logic/BookingCommandFactoryTest.java
index 8650cfb..932c94a 100644
--- a/Java/src/test/java/logic/BookingCommandFactoryTest.java
+++ b/Java/src/test/java/logic/BookingCommandFactoryTest.java
@@ -6,6 +6,7 @@ import request.dto.ReservationRequestDto;
 
 import static com.github.grzesiek_galezowski.test_environment.types.ObjectGraphContainsDependencyCondition.dependencyOn;
 import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.BDDMockito.given;
 import static org.mockito.Mockito.mock;
 
 public class BookingCommandFactoryTest {
@@ -18,6 +19,10 @@ public class BookingCommandFactoryTest {
         );
         val reservation = mock(ReservationRequestDto.class);
         val ticket = mock(Ticket.class);
+
+        given(trainRepo.getTrainBy(reservation.trainId))
+            .willReturn(train);
+
         //WHEN
         Command result = bookingCommandFactory
             .createBookCommand(reservation, ticket);
@@ -26,5 +31,7 @@ public class BookingCommandFactoryTest {
         assertThat(result).isInstanceOf(BookTicketCommand.class);
         assertThat(result).has(dependencyOn(reservation));
         assertThat(result).has(dependencyOn(ticket));
+        assertThat(result).has(dependencyOn(ticket));
+        assertThat(result).has(dependencyOn(train));
     }
 }
\ No newline at end of file

commit 53448a8b7b04913a07f719cecf3927939ce23463
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:17:14 2018 +0100

    Discovered a Train interface

diff --git a/Java/src/main/java/logic/Train.java b/Java/src/main/java/logic/Train.java
new file mode 100644






index 0000000..c96a022
--- /dev/null
+++ b/Java/src/main/java/logic/Train.java
@@ -0,0 +1,4 @@
+package logic;
+
+public interface Train {
+}
diff --git a/Java/src/test/java/logic/BookingCommandFactoryTest.java b/Java/src/test/java/logic/BookingCommandFactoryTest.java
index 932c94a..6cdb16b 100644
--- a/Java/src/test/java/logic/BookingCommandFactoryTest.java
+++ b/Java/src/test/java/logic/BookingCommandFactoryTest.java
@@ -19,6 +19,7 @@ public class BookingCommandFactoryTest {
         );
         val reservation = mock(ReservationRequestDto.class);
         val ticket = mock(Ticket.class);
+        val train = mock(Train.class);
 
         given(trainRepo.getTrainBy(reservation.trainId))
             .willReturn(train);

commit 099039cdcf54bbf52ce7c10135855d7f795dc55d
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:19:04 2018 +0100

    Discovered CouchDbTrainRepository
    
    the TODO list grows

diff --git a/Java/src/main/java/bootstrap/Main.java b/Java/src/main/java/bootstrap/Main.java
index acd7e6d..60e055a 100644
--- a/Java/src/main/java/bootstrap/Main.java
+++ b/Java/src/main/java/bootstrap/Main.java
@@ -2,12 +2,15 @@ package bootstrap;
 
 import api.TicketOffice;
 import logic.BookingCommandFactory;
+import logic.CouchDbTrainRepository;
 import logic.TrainTicketFactory;
 
 public class Main {
 
     public static void main(String[] args) {
-        new TicketOffice(new BookingCommandFactory(),
+        new TicketOffice(new BookingCommandFactory(
+            new CouchDbTrainRepository()
+        ),
             new TrainTicketFactory());
     }
 
diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
new file mode 100644






index 0000000..fa1688d
--- /dev/null
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -0,0 +1,9 @@
+package logic;
+
+public class CouchDbTrainRepository implements TrainRepository {
+    @Override
+    public Train getTrainBy(String trainId) {
+        //todo implement
+        return null;
+    }
+}
diff --git a/Java/src/main/java/logic/TrainRepository.java b/Java/src/main/java/logic/TrainRepository.java
index fdb959b..ed8681c 100644
--- a/Java/src/main/java/logic/TrainRepository.java
+++ b/Java/src/main/java/logic/TrainRepository.java
@@ -1,4 +1,5 @@
 package logic;
 
 public interface TrainRepository {
+    Train getTrainBy(String trainId);
 }

commit 6258d57f9ead2f7098192f68761ec547d59fbb04
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:21:38 2018 +0100

    Made the last assertion pass
    
    (one more backtracking will be needed)

diff --git a/Java/src/main/java/bootstrap/Main.java b/Java/src/main/java/bootstrap/Main.java
index 60e055a..6eae569 100644
--- a/Java/src/main/java/bootstrap/Main.java
+++ b/Java/src/main/java/bootstrap/Main.java
@@ -10,8 +10,7 @@ public class Main {
     public static void main(String[] args) {
         new TicketOffice(new BookingCommandFactory(
             new CouchDbTrainRepository()
-        ),
-            new TrainTicketFactory());
+        ), new TrainTicketFactory());
     }
 
 }
diff --git a/Java/src/main/java/logic/BookTicketCommand.java b/Java/src/main/java/logic/BookTicketCommand.java
index 41e2ff8..2cf945f 100644
--- a/Java/src/main/java/logic/BookTicketCommand.java
+++ b/Java/src/main/java/logic/BookTicketCommand.java
@@ -5,10 +5,15 @@ import request.dto.ReservationRequestDto;
 public class BookTicketCommand implements Command {
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
 
     @Override
diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
index 14ad559..8bd9c3a 100644
--- a/Java/src/main/java/logic/BookingCommandFactory.java
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -3,13 +3,16 @@ package logic;
 import request.dto.ReservationRequestDto;
 
 public class BookingCommandFactory implements CommandFactory {
-    public BookingCommandFactory(TrainRepository trainRepo) {
-        //todo implement
+    private TrainRepository trainRepo;
 
+    public BookingCommandFactory(TrainRepository trainRepo) {
+        this.trainRepo = trainRepo;
     }
 
     @Override
     public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
-        return new BookTicketCommand(reservation, ticket);
+        return new BookTicketCommand(
+            reservation,
+            ticket, trainRepo.getTrainBy(reservation.trainId));
     }
 }

commit bacf1d00a1d3a250d11df4bd610a062920035430
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:23:13 2018 +0100

    Uncommented a test for booking command

diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketCommandSpecification.java
index d1960b5..4515842 100644
--- a/Java/src/test/java/logic/BookTicketCommandSpecification.java
+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java
@@ -1,9 +1,12 @@
 package logic;
 
+import org.testng.annotations.Test;
+
+import static org.assertj.core.api.Assertions.assertThat;
+
 public class BookTicketCommandSpecification {
-    /*
+
     @Test
-    //hmm, should reserve a train, but I have no train
     public void shouldXXXXXXXXXXXXX() {
         //GIVEN
 
@@ -11,5 +14,5 @@ public class BookTicketCommandSpecification {
 
         //THEN
         assertThat(1).isEqualTo(2);
-    }*/
+    }
 }
\ No newline at end of file

commit 72c8bf56bbc71fbf4fe8ce654b8a084786ad7641
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:25:36 2018 +0100

    Starting command test
    
    brain dump - just invoke the only existing method

diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketCommandSpecification.java
index 4515842..73e50af 100644
--- a/Java/src/test/java/logic/BookTicketCommandSpecification.java
+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java
@@ -1,5 +1,6 @@
 package logic;
 
+import lombok.val;
 import org.testng.annotations.Test;
 
 import static org.assertj.core.api.Assertions.assertThat;
@@ -9,8 +10,10 @@ public class BookTicketCommandSpecification {
     @Test
     public void shouldXXXXXXXXXXXXX() {
         //GIVEN
-
+        val bookTicketCommand
+            = new BookTicketCommand(reservation, ticket, train);
         //WHEN
+        bookTicketCommand.execute();
 
         //THEN
         assertThat(1).isEqualTo(2);

commit 3f4c03be0f277c6f163015d00821df3cf80b2c3e
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 1 16:29:00 2018 +0100

    Introduced collaborators and stated expectation

diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketCommandSpecification.java
index 73e50af..49ec989 100644
--- a/Java/src/test/java/logic/BookTicketCommandSpecification.java
+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java
@@ -1,21 +1,27 @@
 package logic;
 
+import autofixture.publicinterface.Any;
 import lombok.val;
 import org.testng.annotations.Test;
+import request.dto.ReservationRequestDto;
 
-import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.BDDMockito.then;
+import static org.mockito.Mockito.mock;
 
 public class BookTicketCommandSpecification {
 
     @Test
     public void shouldXXXXXXXXXXXXX() {
         //GIVEN
+        val reservation = Any.anonymous(ReservationRequestDto.class);
+        val ticket = Any.anonymous(Ticket.class);
+        val train = mock(Train.class);
         val bookTicketCommand
             = new BookTicketCommand(reservation, ticket, train);
         //WHEN
         bookTicketCommand.execute();
 
         //THEN
-        assertThat(1).isEqualTo(2);
+        then(train).should().reserve(reservation.seatCount, ticket);
     }
 }
\ No newline at end of file

commit 329b370e3cb105b40902f457372d98d1d83541ad
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Mon Mar 5 08:08:06 2018 +0100

    Introduced the reserve method

diff --git a/Java/src/main/java/logic/Train.java b/Java/src/main/java/logic/Train.java
index c96a022..7756147 100644
--- a/Java/src/main/java/logic/Train.java
+++ b/Java/src/main/java/logic/Train.java
@@ -1,4 +1,5 @@
 package logic;
 
 public interface Train {
+    void reserve(int seatCount, Ticket ticketToFill);
 }

commit 0887a104e359021e49da4252d6c00c449ec3c616
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Mon Mar 5 08:11:53 2018 +0100

    Implemented. Our next stop is a train repository
    
    We will not be testing it.

diff --git a/Java/src/main/java/logic/BookTicketCommand.java b/Java/src/main/java/logic/BookTicketCommand.java
index 2cf945f..7f130be 100644
--- a/Java/src/main/java/logic/BookTicketCommand.java
+++ b/Java/src/main/java/logic/BookTicketCommand.java
@@ -5,7 +5,7 @@ import request.dto.ReservationRequestDto;
 public class BookTicketCommand implements Command {
     private ReservationRequestDto reservation;
     private Ticket ticket;
-    private Train trainBy;
+    private Train train;
 
     public BookTicketCommand(
         ReservationRequestDto reservation,
@@ -13,12 +13,12 @@ public class BookTicketCommand implements Command {
         Train train) {
         this.reservation = reservation;
         this.ticket = ticket;
-        this.trainBy = train;
+        this.train = train;
     }
 
     @Override
     public void execute() {
-        //todo implement
-
+        //todo a full DTO is not required
+        train.reserve(reservation.seatCount, ticket);
     }
 }
diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
index 8bd9c3a..5fb0c73 100644
--- a/Java/src/main/java/logic/BookingCommandFactory.java
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -13,6 +13,7 @@ public class BookingCommandFactory implements CommandFactory {
     public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
         return new BookTicketCommand(
             reservation,
-            ticket, trainRepo.getTrainBy(reservation.trainId));
+            ticket,
+            trainRepo.getTrainBy(reservation.trainId));
     }
 }

commit ba7694a0585c44d2369f2a62810c94432ace4cae
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Mon Mar 5 08:14:42 2018 +0100

    Made dummy implementation of TrainWithCoaches

diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
index fa1688d..1d827ef 100644
--- a/Java/src/main/java/logic/CouchDbTrainRepository.java
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -3,7 +3,6 @@ package logic;
 public class CouchDbTrainRepository implements TrainRepository {
     @Override
     public Train getTrainBy(String trainId) {
-        //todo implement
-        return null;
+        return new TrainWithCoaches();
     }
 }
diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
new file mode 100644






index 0000000..a1e89ff
--- /dev/null
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -0,0 +1,9 @@
+package logic;
+
+public class TrainWithCoaches implements Train {
+    @Override
+    public void reserve(int seatCount, Ticket ticketToFill) {
+        //todo implement
+
+    }
+}

commit 66446796663bb988afc49961ef96a530bfd14aed
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Mon Mar 5 15:23:23 2018 +0100

    Renaming a test (should've done this earlier)
    
    Should have left a TODO.

diff --git a/Java/src/test/java/logic/BookTicketCommandSpecification.java b/Java/src/test/java/logic/BookTicketCommandSpecification.java
index 49ec989..057d6dd 100644
--- a/Java/src/test/java/logic/BookTicketCommandSpecification.java
+++ b/Java/src/test/java/logic/BookTicketCommandSpecification.java
@@ -11,7 +11,7 @@ import static org.mockito.Mockito.mock;
 public class BookTicketCommandSpecification {
 
     @Test
-    public void shouldXXXXXXXXXXXXX() {
+    public void shouldReserveSeatsOnTrainWhenExecuted() {
         //GIVEN
         val reservation = Any.anonymous(ReservationRequestDto.class);
         val ticket = Any.anonymous(Ticket.class);
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
new file mode 100644






index 0000000..f428d56
--- /dev/null
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -0,0 +1,6 @@
+package logic;
+
+public class TrainWithCoachesSpecification {
+
+
+}
\ No newline at end of file

commit 27bf90f698aa81c05297e2b71f38878ed0081db4
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Mon Mar 5 15:26:14 2018 +0100

    braindumping a new test

diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index f428d56..b94e1b5 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -1,6 +1,21 @@
 package logic;
 
+import lombok.val;
+import org.testng.annotations.Test;
+
+import static org.assertj.core.api.Assertions.assertThat;
+
 public class TrainWithCoachesSpecification {
+    @Test
+    public void shouldXXXXX() { //todo rename
+        //GIVEN
+        val trainWithCoaches = new TrainWithCoaches();
+
+        //WHEN
+        trainWithCoaches.reserve(seatCount, ticket);
 
+        //THEN
+        assertThat(1).isEqualTo(2);
+    }
 
 }
\ No newline at end of file

commit 21c1858e1f48bd96782500d0dc7387ca8930d9c2
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Mon Mar 5 15:29:51 2018 +0100

    passed the compiler
    
    Now time for some deeper thinking on the expectation

diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index b94e1b5..dc2e1f5 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -1,15 +1,19 @@
 package logic;
 
+import autofixture.publicinterface.Any;
 import lombok.val;
 import org.testng.annotations.Test;
 
 import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.Mockito.mock;
 
 public class TrainWithCoachesSpecification {
     @Test
     public void shouldXXXXX() { //todo rename
         //GIVEN
         val trainWithCoaches = new TrainWithCoaches();
+        val seatCount = Any.intValue();
+        val ticket = mock(Ticket.class);
 
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);

commit 8a88f13dd2f4d359895aa29be75e087a300a093e
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 07:53:13 2018 +0100

    I know one coach should be reserved even though more meet the condition

diff --git a/Java/src/main/java/logic/BookTicketCommand.java b/Java/src/main/java/logic/BookTicketCommand.java
index 7f130be..d51b09a 100644
--- a/Java/src/main/java/logic/BookTicketCommand.java
+++ b/Java/src/main/java/logic/BookTicketCommand.java
@@ -4,21 +4,21 @@ import request.dto.ReservationRequestDto;
 
 public class BookTicketCommand implements Command {
     private ReservationRequestDto reservation;
-    private Ticket ticket;
+    private TicketInProgress ticketInProgress;
     private Train train;
 
     public BookTicketCommand(
         ReservationRequestDto reservation,
-        Ticket ticket,
+        TicketInProgress ticketInProgress,
         Train train) {
         this.reservation = reservation;
-        this.ticket = ticket;
+        this.ticketInProgress = ticketInProgress;
         this.train = train;
     }
 
     @Override
     public void execute() {
         //todo a full DTO is not required
-        train.reserve(reservation.seatCount, ticket);
+        train.reserve(reservation.seatCount, ticketInProgress);
     }
 }
diff --git a/Java/src/main/java/logic/BookingCommandFactory.java b/Java/src/main/java/logic/BookingCommandFactory.java
index 5fb0c73..45d369d 100644
--- a/Java/src/main/java/logic/BookingCommandFactory.java
+++ b/Java/src/main/java/logic/BookingCommandFactory.java
@@ -10,10 +10,10 @@ public class BookingCommandFactory implements CommandFactory {
     }
 
     @Override
-    public Command createBookCommand(ReservationRequestDto reservation, Ticket ticket) {
+    public Command createBookCommand(ReservationRequestDto reservation, TicketInProgress ticketInProgress) {
         return new BookTicketCommand(
             reservation,
-            ticket,
+            ticketInProgress,
             trainRepo.getTrainBy(reservation.trainId));
     }
 }
diff --git a/Java/src/main/java/logic/CommandFactory.java b/Java/src/main/java/logic/CommandFactory.java
index 18208a5..28a0048 100644
--- a/Java/src/main/java/logic/CommandFactory.java
+++ b/Java/src/main/java/logic/CommandFactory.java
@@ -3,5 +3,5 @@ package logic;
 import request.dto.ReservationRequestDto;
 
 public interface CommandFactory {
-    Command createBookCommand(ReservationRequestDto reservation, Ticket ticket);
+    Command createBookCommand(ReservationRequestDto reservation, TicketInProgress ticketInProgress);
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
-    void reserve(int seatCount, Ticket ticketToFill);
+    void reserve(int seatCount, TicketInProgress ticketInProgressToFill);
 }
diff --git a/Java/src/main/java/logic/TrainTicketFactory.java b/Java/src/main/java/logic/TrainTicketFactory.java
index 4bc54a5..356a56a 100644
--- a/Java/src/main/java/logic/TrainTicketFactory.java
+++ b/Java/src/main/java/logic/TrainTicketFactory.java
@@ -2,7 +2,7 @@ package logic;
 
 public class TrainTicketFactory implements TicketFactory {
     @Override
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
 
 public class TrainWithCoaches implements Train {
     @Override
-    public void reserve(int seatCount, Ticket ticketToFill) {
+    public void reserve(int seatCount, TicketInProgress ticketInProgressToFill) {
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
     
     @Test
     public void shouldCreateAndExecuteCommandWithTicketAndTrain() {
@@ -22,7 +22,7 @@ public class TicketOfficeSpecification {
         val commandFactory = mock(CommandFactory.class);
         val reservation = Any.anonymous(ReservationRequestDto.class);
         val resultDto = Any.anonymous(TicketDto.class);
-        val ticket = mock(Ticket.class);
+        val ticket = mock(TicketInProgress.class);
         val bookCommand = mock(Command.class);
         val ticketFactory = mock(TicketFactory.class);
         val ticketOffice = new TicketOffice(
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
 
     @Test
     public void shouldReserveSeatsOnTrainWhenExecuted() {
         //GIVEN
         val reservation = Any.anonymous(ReservationRequestDto.class);
-        val ticket = Any.anonymous(Ticket.class);
+        val ticket = Any.anonymous(TicketInProgress.class);
         val train = mock(Train.class);
         val bookTicketCommand
             = new BookTicketCommand(reservation, ticket, train);
diff --git a/Java/src/test/java/logic/BookingCommandFactoryTest.java b/Java/src/test/java/logic/BookingCommandFactoryTest.java
index 6cdb16b..caa1b3c 100644
--- a/Java/src/test/java/logic/BookingCommandFactoryTest.java
+++ b/Java/src/test/java/logic/BookingCommandFactoryTest.java
@@ -18,7 +18,7 @@ public class BookingCommandFactoryTest {
             trainRepo
         );
         val reservation = mock(ReservationRequestDto.class);
-        val ticket = mock(Ticket.class);
+        val ticket = mock(TicketInProgress.class);
         val train = mock(Train.class);
 
         given(trainRepo.getTrainBy(reservation.trainId))
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
     @Test
@@ -13,13 +14,16 @@ public class TrainWithCoachesSpecification {
         //GIVEN
         val trainWithCoaches = new TrainWithCoaches();
         val seatCount = Any.intValue();
-        val ticket = mock(Ticket.class);
+        val ticket = mock(TicketInProgress.class);
 
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);
 
         //THEN
-        assertThat(1).isEqualTo(2);
+        then(coach1).should(never()).reserve(seatCount, ticket);
+        then(coach2).should().reserve(seatCount, ticket);
+        then(coach3).should(never()).reserve(seatCount, ticket);
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
         val trainWithCoaches = new TrainWithCoaches();
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);
+        Coach coach1 = mock(Coach.class);
+        Coach coach2 = mock(Coach.class);
+        Coach coach3 = mock(Coach.class);
 
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);

commit 051c009926e1f332455e9e325ba3135d863d30fb
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 07:56:04 2018 +0100

    Discovered the reserve() method

diff --git a/Java/src/main/java/logic/Coach.java b/Java/src/main/java/logic/Coach.java
index e4b82df..300a248 100644
--- a/Java/src/main/java/logic/Coach.java
+++ b/Java/src/main/java/logic/Coach.java
@@ -1,4 +1,5 @@
 package logic;
 
 public interface Coach {
+    void reserve(int seatCount, TicketInProgress ticket);
 }
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 6a96aef..cd3969f 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -15,9 +15,9 @@ public class TrainWithCoachesSpecification {
         val trainWithCoaches = new TrainWithCoaches();
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);
-        Coach coach1 = mock(Coach.class);
-        Coach coach2 = mock(Coach.class);
-        Coach coach3 = mock(Coach.class);
+        val coach1 = mock(Coach.class);
+        val coach2 = mock(Coach.class);
+        val coach3 = mock(Coach.class);
 
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);

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
 
 public class TrainWithCoaches implements Train {
+    public TrainWithCoaches(Coach... coaches) {
+    }
+
     @Override
     public void reserve(int seatCount, TicketInProgress ticketInProgressToFill) {
         //todo implement
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index cd3969f..7afa52f 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -12,12 +12,14 @@ public class TrainWithCoachesSpecification {
     @Test
     public void shouldXXXXX() { //todo rename
         //GIVEN
-        val trainWithCoaches = new TrainWithCoaches();
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);
         val coach1 = mock(Coach.class);
         val coach2 = mock(Coach.class);
         val coach3 = mock(Coach.class);
+        val trainWithCoaches = new TrainWithCoaches(
+            coach1, coach2, coach3
+        );
 
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);

commit 585426746e7ad1e5f0e082ec432e42f98855f3d3
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 7 08:00:58 2018 +0100

    discovered allowsUpFrontReservationOf() method
    
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
 
+        given(coach1.allowsUpFrontReservationOf(seatCount))
+            .willReturn(false);
+        given(coach2.allowsUpFrontReservationOf(seatCount))
+            .willReturn(true);
+        given(coach3.allowsUpFrontReservationOf(seatCount))
+            .willReturn(true);
+
+
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);
 
@@ -29,6 +38,5 @@ public class TrainWithCoachesSpecification {
         then(coach2).should().reserve(seatCount, ticket);
         then(coach3).should(never()).reserve(seatCount, ticket);
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
     void reserve(int seatCount, TicketInProgress ticket);
+
+    boolean allowsUpFrontReservationOf(int seatCount);
 }
diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
index 1d827ef..9f7ea45 100644
--- a/Java/src/main/java/logic/CouchDbTrainRepository.java
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -3,6 +3,7 @@ package logic;
 public class CouchDbTrainRepository implements TrainRepository {
     @Override
     public Train getTrainBy(String trainId) {
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
@@ -7,6 +7,5 @@ public class TrainWithCoaches implements Train {
     @Override
     public void reserve(int seatCount, TicketInProgress ticketInProgressToFill) {
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
     @Test
-    public void shouldXXXXX() { //todo rename
+    public void shouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() { //todo rename
         //GIVEN
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);

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
 
 public class TrainWithCoaches implements Train {
+    private Coach[] coaches;
+
     public TrainWithCoaches(Coach... coaches) {
+        this.coaches = coaches;
     }
 
     @Override
-    public void reserve(int seatCount, TicketInProgress ticketInProgressToFill) {
-        //todo implement
+    public void reserve(int seatCount, TicketInProgress ticketInProgress) {
+        for (Coach coach : coaches) {
+            if(coach.allowsUpFrontReservationOf(seatCount)) {
+                coach.reserve(seatCount, ticketInProgress);
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
     @Test
-    public void shouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() { //todo rename
+    public void shouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() { 
         //GIVEN
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);
@@ -29,7 +29,6 @@ public class TrainWithCoachesSpecification {
         given(coach3.allowsUpFrontReservationOf(seatCount))
             .willReturn(true);
 
-
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);
 
@@ -38,5 +37,7 @@ public class TrainWithCoachesSpecification {
         then(coach2).should().reserve(seatCount, ticket);
         then(coach3).should(never()).reserve(seatCount, ticket);
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
     void reserve(int seatCount, TicketInProgress ticket);
 
     boolean allowsUpFrontReservationOf(int seatCount);
+
+    boolean allowsReservationOf(int seatCount);
 }
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index 87a62fe..8157890 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -11,7 +11,7 @@ import static org.mockito.Mockito.never;
 
 public class TrainWithCoachesSpecification {
     @Test
-    public void shouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() { 
+    public void shouldReserveSeatsInFirstCoachThatHasPlaceBelowLimit() {
         //GIVEN
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);
@@ -38,6 +38,41 @@ public class TrainWithCoachesSpecification {
         then(coach3).should(never()).reserve(seatCount, ticket);
     }
 
+    @Test
+    public void
+    shouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() {
+        //GIVEN
+        val seatCount = Any.intValue();
+        val ticket = mock(TicketInProgress.class);
+        val coach1 = mock(Coach.class);
+        val coach2 = mock(Coach.class);
+        val coach3 = mock(Coach.class);
+        val trainWithCoaches = new TrainWithCoaches(
+            coach1, coach2, coach3
+        );
+
+        given(coach1.allowsUpFrontReservationOf(seatCount))
+            .willReturn(false);
+        given(coach2.allowsUpFrontReservationOf(seatCount))
+            .willReturn(false);
+        given(coach3.allowsUpFrontReservationOf(seatCount))
+            .willReturn(false);
+        given(coach1.allowsReservationOf(seatCount))
+            .willReturn(false);
+        given(coach2.allowsReservationOf(seatCount))
+            .willReturn(true);
+        given(coach3.allowsReservationOf(seatCount))
+            .willReturn(false);
+
+        //WHEN
+        trainWithCoaches.reserve(seatCount, ticket);
+
+        //THEN
+        then(coach1).should(never()).reserve(seatCount, ticket);
+        then(coach2).should().reserve(seatCount, ticket);
+        then(coach3).should(never()).reserve(seatCount, ticket);
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
@@ -9,6 +9,12 @@ public class TrainWithCoaches implements Train {
 
     @Override
     public void reserve(int seatCount, TicketInProgress ticketInProgress) {
+        for (Coach coach : coaches) {
+            if(coach.allowsReservationOf(seatCount)) {
+                coach.reserve(seatCount, ticketInProgress);
+                break;
+            }
+        }
         for (Coach coach : coaches) {
             if(coach.allowsUpFrontReservationOf(seatCount)) {
                 coach.reserve(seatCount, ticketInProgress);

commit f9a24aeb01276dd1a1bc0dc6f534abd45b4db3f6
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 9 08:03:07 2018 +0100

    forced the right implementation
    
    But need to refactor the tests. Next time we change this class, we refactor the code

diff --git a/Java/src/main/java/logic/TrainWithCoaches.java b/Java/src/main/java/logic/TrainWithCoaches.java
index 1e45cd9..abb29e5 100644
--- a/Java/src/main/java/logic/TrainWithCoaches.java
+++ b/Java/src/main/java/logic/TrainWithCoaches.java
@@ -10,17 +10,16 @@ public class TrainWithCoaches implements Train {
     @Override
     public void reserve(int seatCount, TicketInProgress ticketInProgress) {
         for (Coach coach : coaches) {
-            if(coach.allowsReservationOf(seatCount)) {
+            if(coach.allowsUpFrontReservationOf(seatCount)) {
                 coach.reserve(seatCount, ticketInProgress);
-                break;
+                return;
             }
         }
         for (Coach coach : coaches) {
-            if(coach.allowsUpFrontReservationOf(seatCount)) {
+            if(coach.allowsReservationOf(seatCount)) {
                 coach.reserve(seatCount, ticketInProgress);
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
             .willReturn(true);
         given(coach3.allowsUpFrontReservationOf(seatCount))
             .willReturn(true);
+        given(coach1.allowsReservationOf(seatCount))
+            .willReturn(true);
+        given(coach2.allowsReservationOf(seatCount))
+            .willReturn(true);
+        given(coach3.allowsReservationOf(seatCount))
+            .willReturn(true);
 
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);

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
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);
-        val coach1 = mock(Coach.class);
-        val coach2 = mock(Coach.class);
-        val coach3 = mock(Coach.class);
+
+        Coach coach1 = coachWithoutAvailableUpFront(seatCount);
+        Coach coach2 = coachWithAvailableUpFront(seatCount);
+        Coach coach3 = coachWithAvailableUpFront(seatCount);
+
         val trainWithCoaches = new TrainWithCoaches(
             coach1, coach2, coach3
         );
-
-        given(coach1.allowsUpFrontReservationOf(seatCount))
-            .willReturn(false);
-        given(coach2.allowsUpFrontReservationOf(seatCount))
-            .willReturn(true);
-        given(coach3.allowsUpFrontReservationOf(seatCount))
-            .willReturn(true);
-        given(coach1.allowsReservationOf(seatCount))
-            .willReturn(true);
-        given(coach2.allowsReservationOf(seatCount))
-            .willReturn(true);
-        given(coach3.allowsReservationOf(seatCount))
-            .willReturn(true);
-
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);
 
@@ -44,6 +32,24 @@ public class TrainWithCoachesSpecification {
         then(coach3).should(never()).reserve(seatCount, ticket);
     }
 
+    private Coach coachWithAvailableUpFront(Integer seatCount) {
+        val coach2 = mock(Coach.class);
+        given(coach2.allowsUpFrontReservationOf(seatCount))
+            .willReturn(true);
+        given(coach2.allowsReservationOf(seatCount))
+            .willReturn(true);
+        return coach2;
+    }
+
+    private Coach coachWithoutAvailableUpFront(Integer seatCount) {
+        val coach1 = mock(Coach.class);
+        given(coach1.allowsUpFrontReservationOf(seatCount))
+            .willReturn(false);
+        given(coach1.allowsReservationOf(seatCount))
+            .willReturn(true);
+        return coach1;
+    }
+
     @Test
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
@@ -15,6 +15,7 @@ public class TrainWithCoaches implements Train {
                 return;
             }
         }
+
         for (Coach coach : coaches) {
             if(coach.allowsReservationOf(seatCount)) {
                 coach.reserve(seatCount, ticketInProgress);
diff --git a/Java/src/test/java/logic/TrainWithCoachesSpecification.java b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
index c1a5b96..b14abc2 100644
--- a/Java/src/test/java/logic/TrainWithCoachesSpecification.java
+++ b/Java/src/test/java/logic/TrainWithCoachesSpecification.java
@@ -32,50 +32,19 @@ public class TrainWithCoachesSpecification {
         then(coach3).should(never()).reserve(seatCount, ticket);
     }
 
-    private Coach coachWithAvailableUpFront(Integer seatCount) {
-        val coach2 = mock(Coach.class);
-        given(coach2.allowsUpFrontReservationOf(seatCount))
-            .willReturn(true);
-        given(coach2.allowsReservationOf(seatCount))
-            .willReturn(true);
-        return coach2;
-    }
-
-    private Coach coachWithoutAvailableUpFront(Integer seatCount) {
-        val coach1 = mock(Coach.class);
-        given(coach1.allowsUpFrontReservationOf(seatCount))
-            .willReturn(false);
-        given(coach1.allowsReservationOf(seatCount))
-            .willReturn(true);
-        return coach1;
-    }
-
     @Test
     public void
     shouldReserveSeatsInFirstCoachThatHasFreeSeatsIfNoneAllowsReservationUpFront() {
         //GIVEN
         val seatCount = Any.intValue();
         val ticket = mock(TicketInProgress.class);
-        val coach1 = mock(Coach.class);
-        val coach2 = mock(Coach.class);
-        val coach3 = mock(Coach.class);
+        val coach1 = coachWithout(seatCount);
+        val coach2 = coachWithoutAvailableUpFront(seatCount);
+        val coach3 = coachWithout(seatCount);
         val trainWithCoaches = new TrainWithCoaches(
             coach1, coach2, coach3
         );
 
-        given(coach1.allowsUpFrontReservationOf(seatCount))
-            .willReturn(false);
-        given(coach2.allowsUpFrontReservationOf(seatCount))
-            .willReturn(false);
-        given(coach3.allowsUpFrontReservationOf(seatCount))
-            .willReturn(false);
-        given(coach1.allowsReservationOf(seatCount))
-            .willReturn(false);
-        given(coach2.allowsReservationOf(seatCount))
-            .willReturn(true);
-        given(coach3.allowsReservationOf(seatCount))
-            .willReturn(false);
-
         //WHEN
         trainWithCoaches.reserve(seatCount, ticket);
 
@@ -85,6 +54,30 @@ public class TrainWithCoachesSpecification {
         then(coach3).should(never()).reserve(seatCount, ticket);
     }
 
+    private Coach coachWithout(Integer seatCount) {
+        val coach1 = mock(Coach.class);
+        given(coach1.allowsUpFrontReservationOf(seatCount))
+            .willReturn(false);
+        given(coach1.allowsReservationOf(seatCount))
+            .willReturn(false);
+        return coach1;
+    }
 
-    //todo what if no coach allows up front reservation?
+    private Coach coachWithAvailableUpFront(Integer seatCount) {
+        val coach2 = mock(Coach.class);
+        given(coach2.allowsUpFrontReservationOf(seatCount))
+            .willReturn(true);
+        given(coach2.allowsReservationOf(seatCount))
+            .willReturn(true);
+        return coach2;
+    }
+
+    private Coach coachWithoutAvailableUpFront(Integer seatCount) {
+        val coach1 = mock(Coach.class);
+        given(coach1.allowsUpFrontReservationOf(seatCount))
+            .willReturn(false);
+        given(coach1.allowsReservationOf(seatCount))
+            .willReturn(true);
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
+public class CoachWithSeats implements Coach {
+    @Override
+    public void reserve(int seatCount, TicketInProgress ticket) {
+        //todo implement
+
+    }
+
+    @Override
+    public boolean allowsUpFrontReservationOf(int seatCount) {
+        //todo implement
+        return false;
+    }
+
+    @Override
+    public boolean allowsReservationOf(int seatCount) {
+        //todo implement
+        return false;
+    }
+}
diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
index 9f7ea45..1a4b009 100644
--- a/Java/src/main/java/logic/CouchDbTrainRepository.java
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -4,6 +4,8 @@ public class CouchDbTrainRepository implements TrainRepository {
     @Override
     public Train getTrainBy(String trainId) {
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
+    @Test
+    public void xxXXxxXX() { //todo rename
+        //GIVEN
+        val coachWithSeats = new CoachWithSeats();
+        //WHEN
+        int seatCount = Any.intValue();
+        val reservationAllowed = coachWithSeats.allowsReservationOf(seatCount);
+
+        //THEN
+        assertThat(reservationAllowed).isTrue();
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
     @Test
     public void xxXXxxXX() { //todo rename
         //GIVEN
-        val coachWithSeats = new CoachWithSeats();
+        Seat seat1 = Any.anonymous(Seat.class);
+        val coachWithSeats = new CoachWithSeats(
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
         int seatCount = Any.intValue();
         val reservationAllowed = coachWithSeats.allowsReservationOf(seatCount);

commit 893d36847f8d48def0fab6b286e76f90e6baa310
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Wed Mar 14 16:32:05 2018 +0100

    created enough seats

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index a1a9cbe..ec90a2b 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -11,7 +11,17 @@ public class CoachWithSeatsSpecification {
     @Test
     public void xxXXxxXX() { //todo rename
         //GIVEN
+        //todo what's special about these seats?
         Seat seat1 = Any.anonymous(Seat.class);
+        Seat seat2 = Any.anonymous(Seat.class);
+        Seat seat3 = Any.anonymous(Seat.class);
+        Seat seat4 = Any.anonymous(Seat.class);
+        Seat seat5 = Any.anonymous(Seat.class);
+        Seat seat6 = Any.anonymous(Seat.class);
+        Seat seat7 = Any.anonymous(Seat.class);
+        Seat seat8 = Any.anonymous(Seat.class);
+        Seat seat9 = Any.anonymous(Seat.class);
+        Seat seat10 = Any.anonymous(Seat.class);
         val coachWithSeats = new CoachWithSeats(
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
         int seatCount = Any.intValue();

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
 
 public class CoachWithSeats implements Coach {
+    public CoachWithSeats(Seat... seats) {
+    }
+
     @Override
     public void reserve(int seatCount, TicketInProgress ticket) {
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
 
     @Test
-    public void xxXXxxXX() { //todo rename
+    public void shouldNotAllowReservingMoreSeatsThanItHas() { //todo rename
         //GIVEN
-        //todo what's special about these seats?
         Seat seat1 = Any.anonymous(Seat.class);
         Seat seat2 = Any.anonymous(Seat.class);
         Seat seat3 = Any.anonymous(Seat.class);
@@ -34,12 +33,14 @@ public class CoachWithSeatsSpecification {
             seat9,
             seat10
         );
+
         //WHEN
-        int seatCount = Any.intValue();
-        val reservationAllowed = coachWithSeats.allowsReservationOf(seatCount);
+        val reservationAllowed = coachWithSeats.allowsReservationOf(11);
 
         //THEN
-        assertThat(reservationAllowed).isTrue();
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
 
     @Test
-    public void shouldNotAllowReservingMoreSeatsThanItHas() { //todo rename
+    public void shouldNotAllowReservingMoreSeatsThanItHas() {
         //GIVEN
         Seat seat1 = Any.anonymous(Seat.class);
         Seat seat2 = Any.anonymous(Seat.class);
@@ -36,11 +36,15 @@ public class CoachWithSeatsSpecification {
 
         //WHEN
         val reservationAllowed = coachWithSeats.allowsReservationOf(11);
+        val upFrontAllowed = coachWithSeats.allowsUpFrontReservationOf(11);
 
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
 
+    @Test
+    public void shouldAllowReservingSeatsThatAreFree() {
+        //GIVEN
+        Seat seat1 = freeSeat();
+        Seat seat2 = freeSeat();
+        Seat seat3 = freeSeat();
+        Seat seat4 = freeSeat();
+        Seat seat5 = freeSeat();
+        Seat seat6 = freeSeat();
+        Seat seat7 = freeSeat();
+        Seat seat8 = freeSeat();
+        Seat seat9 = freeSeat();
+        Seat seat10 = freeSeat();
+        val coachWithSeats = new CoachWithSeats(
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
+        val reservationAllowed = coachWithSeats.allowsReservationOf(10);
+
+        //THEN
+        assertThat(reservationAllowed).isTrue();
+    }
+
+    private Seat freeSeat() {
+        return Any.anonymous(Seat.class);
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
 public class CoachWithSeats implements Coach {
+    private Seat[] seats;
+
     public CoachWithSeats(Seat... seats) {
+        this.seats = seats;
     }
 
     @Override
@@ -18,7 +23,7 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsReservationOf(int seatCount) {
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
+    boolean isFree();
 }
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index dbc7abb..dfc4f8e 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -5,6 +5,8 @@ import lombok.val;
 import org.testng.annotations.Test;
 
 import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.Mockito.mock;
+import static org.mockito.Mockito.when;
 
 public class CoachWithSeatsSpecification {
 
@@ -77,7 +79,9 @@ public class CoachWithSeatsSpecification {
     }
 
     private Seat freeSeat() {
-        return Any.anonymous(Seat.class);
+        Seat mock = mock(Seat.class);
+        when(mock.isFree()).thenReturn(true);
+        return mock;
     }
 
 

commit 1cebb829e844081bcc482e26412ef4cbb23a1d10
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:28:06 2018 +0100

    Refactored test
    
    no need for variables

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index dfc4f8e..e835cab 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -48,27 +48,17 @@ public class CoachWithSeatsSpecification {
     @Test
     public void shouldAllowReservingSeatsThatAreFree() {
         //GIVEN
-        Seat seat1 = freeSeat();
-        Seat seat2 = freeSeat();
-        Seat seat3 = freeSeat();
-        Seat seat4 = freeSeat();
-        Seat seat5 = freeSeat();
-        Seat seat6 = freeSeat();
-        Seat seat7 = freeSeat();
-        Seat seat8 = freeSeat();
-        Seat seat9 = freeSeat();
-        Seat seat10 = freeSeat();
         val coachWithSeats = new CoachWithSeats(
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
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat()
         );
 
         //WHEN
@@ -78,6 +68,8 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isTrue();
     }
 
+
+
     private Seat freeSeat() {
         Seat mock = mock(Seat.class);
         when(mock.isFree()).thenReturn(true);

commit ab3475b0ee19bf11d3cc4c140703549d917480ee
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:30:14 2018 +0100

    added another test

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index e835cab..c1aba66 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -68,6 +68,34 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isTrue();
     }
 
+    @Test
+    public void shouldNotAllowReservingWhenNotEnoughFreeSeats() {
+        //GIVEN
+        val coachWithSeats = new CoachWithSeats(
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            reservedSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat()
+        );
+
+        //WHEN
+        val reservationAllowed = coachWithSeats.allowsReservationOf(10);
+
+        //THEN
+        assertThat(reservationAllowed).isTrue();
+    }
+
+    private Seat reservedSeat() {
+        Seat mock = mock(Seat.class);
+        when(mock.isFree()).thenReturn(false);
+        return mock;
+    }
 
 
     private Seat freeSeat() {

commit 3503e7dcb9772fefec6a1661b9cdc7909d15f87b
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:32:12 2018 +0100

    implemented only free seats

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 01c882f..952b8fb 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -23,7 +23,8 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsReservationOf(int seatCount) {
-        //todo not yet the right implementation
-        return seatCount == Arrays.stream(seats).count();
+        return seatCount == Arrays.stream(seats)
+            .filter(seat -> seat.isFree())
+            .count();
     }
 }
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index c1aba66..542dbd1 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -88,7 +88,7 @@ public class CoachWithSeatsSpecification {
         val reservationAllowed = coachWithSeats.allowsReservationOf(10);
 
         //THEN
-        assertThat(reservationAllowed).isTrue();
+        assertThat(reservationAllowed).isFalse();
     }
 
     private Seat reservedSeat() {

commit 09583d22e23e8b55154ef1e5c75215337764294d
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:34:50 2018 +0100

    First test for up front reservations
    
    why 7 and not calculating? DOn't be smart in tests - if you have to, put smartness in a well-tested library.

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index 542dbd1..cf3e163 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -91,6 +91,31 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isFalse();
     }
 
+    @Test
+    public void shouldAllowReservingUpFrontUpTo70PercentOfSeats() {
+        //GIVEN
+        val coachWithSeats = new CoachWithSeats(
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat()
+        );
+
+        //WHEN
+        val reservationAllowed =
+            coachWithSeats.allowsUpFrontReservationOf(7);
+
+        //THEN
+        assertThat(reservationAllowed).isTrue();
+    }
+
+
     private Seat reservedSeat() {
         Seat mock = mock(Seat.class);
         when(mock.isFree()).thenReturn(false);

commit fe86c7c467e238e6409fd49e6995237312a22e43
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:35:45 2018 +0100

    Naively passing the test

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 952b8fb..ef62030 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -17,8 +17,8 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsUpFrontReservationOf(int seatCount) {
-        //todo implement
-        return false;
+        //todo not the right implementation yet
+        return true;
     }
 
     @Override

commit 2102466b3e3a3bd937bb58584121c615145daa1c
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 08:38:02 2018 +0100

    New test for up front

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index cf3e163..331d351 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -115,6 +115,29 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isTrue();
     }
 
+    @Test
+    public void shouldNotAllowReservingUpFrontOverTo70PercentOfSeats() {
+        //GIVEN
+        val coachWithSeats = new CoachWithSeats(
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat()
+        );
+
+        //WHEN
+        val reservationAllowed =
+            coachWithSeats.allowsUpFrontReservationOf(8);
+
+        //THEN
+        assertThat(reservationAllowed).isTrue();
+    }
 
     private Seat reservedSeat() {
         Seat mock = mock(Seat.class);

commit da173981eceb7af6e24c7e4f815ad949dd70d7fb
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 16:46:37 2018 +0100

    Commented out a failing test and refactored

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index ef62030..4669230 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -23,7 +23,11 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsReservationOf(int seatCount) {
-        return seatCount == Arrays.stream(seats)
+        return seatCount == freeSeatCount();
+    }
+
+    private long freeSeatCount() {
+        return Arrays.stream(seats)
             .filter(seat -> seat.isFree())
             .count();
     }
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index 331d351..f37ab16 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -115,7 +115,7 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isTrue();
     }
 
-    @Test
+    //@Test todo uncomment!
     public void shouldNotAllowReservingUpFrontOverTo70PercentOfSeats() {
         //GIVEN
         val coachWithSeats = new CoachWithSeats(

commit 0e80f243d62c036f33ec96756304888ae67cd453
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 16:48:42 2018 +0100

    damn, 2 tests failing...

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index f37ab16..9d56b74 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -115,7 +115,7 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isTrue();
     }
 
-    //@Test todo uncomment!
+    @Test
     public void shouldNotAllowReservingUpFrontOverTo70PercentOfSeats() {
         //GIVEN
         val coachWithSeats = new CoachWithSeats(
@@ -136,7 +136,7 @@ public class CoachWithSeatsSpecification {
             coachWithSeats.allowsUpFrontReservationOf(8);
 
         //THEN
-        assertThat(reservationAllowed).isTrue();
+        assertThat(reservationAllowed).isFalse();
     }
 
     private Seat reservedSeat() {

commit cbbb474eb90284bed957abd0a13833f1d7d26b75
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 16:49:52 2018 +0100

    OK, one test failing

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 4669230..4f1440e 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -17,13 +17,13 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsUpFrontReservationOf(int seatCount) {
-        //todo not the right implementation yet
-        return true;
+        return seatCount <= seats.length;
     }
 
     @Override
     public boolean allowsReservationOf(int seatCount) {
-        return seatCount == freeSeatCount();
+
+        return seatCount <= freeSeatCount();
     }
 
     private long freeSeatCount() {

commit bde8fa7131861ffbc4f640a9af65a77376db115e
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 16:51:10 2018 +0100

    Made last test pass
    
    omitting rounding behavior etc.

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 4f1440e..b7be055 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -17,7 +17,7 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsUpFrontReservationOf(int seatCount) {
-        return seatCount <= seats.length;
+        return seatCount <= seats.length * 0.7;
     }
 
     @Override

commit c72a4cc250e0627c7eb1347acb00ae1e6ad86c0e
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Thu Mar 15 16:55:33 2018 +0100

    Picked the right formula for the criteria
    
    Another test green

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index b7be055..4074012 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -17,7 +17,7 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsUpFrontReservationOf(int seatCount) {
-        return seatCount <= seats.length * 0.7;
+        return (freeSeatCount() - seatCount) >= seats.length * 0.3;
     }
 
     @Override
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index 9d56b74..a4b8de0 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -139,6 +139,31 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isFalse();
     }
 
+    @Test
+    public void shouldNotAllowReservingUpFrontOver70PercentOfSeatsWhenSomeAreAlreadyReserved() {
+        //GIVEN
+        val coachWithSeats = new CoachWithSeats(
+            reservedSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat(),
+            freeSeat()
+        );
+
+        //WHEN
+        val reservationAllowed =
+            coachWithSeats.allowsUpFrontReservationOf(7);
+
+        //THEN
+        assertThat(reservationAllowed).isFalse();
+    }
+
+
     private Seat reservedSeat() {
         Seat mock = mock(Seat.class);
         when(mock.isFree()).thenReturn(false);

commit 05355a1aca3a0d902ac4c8ba62bdc30ac73e6d3b
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 16 08:27:34 2018 +0100

    Added reservation test

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 4074012..43ce204 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -22,7 +22,6 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public boolean allowsReservationOf(int seatCount) {
-
         return seatCount <= freeSeatCount();
     }
 
diff --git a/Java/src/main/java/logic/Seat.java b/Java/src/main/java/logic/Seat.java
index 4f03bd8..0c24d39 100644
--- a/Java/src/main/java/logic/Seat.java
+++ b/Java/src/main/java/logic/Seat.java
@@ -2,4 +2,5 @@ package logic;
 
 public interface Seat {
     boolean isFree();
+    void reserveFor(TicketInProgress ticketInProgress);
 }
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index a4b8de0..75d87df 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -5,7 +5,10 @@ import lombok.val;
 import org.testng.annotations.Test;
 
 import static org.assertj.core.api.Assertions.assertThat;
+import static org.mockito.ArgumentMatchers.any;
+import static org.mockito.BDDMockito.then;
 import static org.mockito.Mockito.mock;
+import static org.mockito.Mockito.never;
 import static org.mockito.Mockito.when;
 
 public class CoachWithSeatsSpecification {
@@ -163,6 +166,27 @@ public class CoachWithSeatsSpecification {
         assertThat(reservationAllowed).isFalse();
     }
 
+    @Test
+    public void shouldReserveFirstFreeSeats() {
+        //GIVEN
+        val seat1 = mock(Seat.class);
+        val seat2 = mock(Seat.class);
+        val seat3 = mock(Seat.class);
+        val ticketInProgress = mock(TicketInProgress.class);
+        val coachWithSeats = new CoachWithSeats(
+            seat1,
+            seat2,
+            seat3
+        );
+
+        //WHEN
+        coachWithSeats.reserve(2, ticketInProgress);
+
+        //THEN
+        then(seat1).should().reserveFor(ticketInProgress);
+        then(seat2).should().reserveFor(ticketInProgress);
+        then(seat1).should(never()).reserveFor(any(TicketInProgress.class));
+    }
 
     private Seat reservedSeat() {
         Seat mock = mock(Seat.class);

commit 398d4ab300d4394ae097ab202332757f2f63d5d7
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 16 08:31:47 2018 +0100

    Added reservation

diff --git a/Java/src/main/java/logic/CoachWithSeats.java b/Java/src/main/java/logic/CoachWithSeats.java
index 43ce204..713c4d4 100644
--- a/Java/src/main/java/logic/CoachWithSeats.java
+++ b/Java/src/main/java/logic/CoachWithSeats.java
@@ -11,7 +11,14 @@ public class CoachWithSeats implements Coach {
 
     @Override
     public void reserve(int seatCount, TicketInProgress ticket) {
-        //todo implement
+        for (Seat seat : seats) {
+            if (seatCount == 0) {
+                return;
+            } else {
+                seat.reserveFor(ticket);
+                seatCount--;
+            }
+        }
 
     }
 
diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index 75d87df..b046ef2 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -185,7 +185,7 @@ public class CoachWithSeatsSpecification {
         //THEN
         then(seat1).should().reserveFor(ticketInProgress);
         then(seat2).should().reserveFor(ticketInProgress);
-        then(seat1).should(never()).reserveFor(any(TicketInProgress.class));
+        then(seat3).should(never()).reserveFor(any(TicketInProgress.class));
     }
 
     private Seat reservedSeat() {
@@ -202,8 +202,5 @@ public class CoachWithSeatsSpecification {
     }
 
 
-    //todo all free
-    //todo other scenarios
-    //todo what's special about these seats?
-
+    //todo should we protect reserve() method?
 }
\ No newline at end of file

commit 449ebbc49d71c02007d365b43abe68bbe73c327f
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 16 16:44:28 2018 +0100

    Looking at todo list

diff --git a/Java/src/test/java/logic/CoachWithSeatsSpecification.java b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
index b046ef2..68a1034 100644
--- a/Java/src/test/java/logic/CoachWithSeatsSpecification.java
+++ b/Java/src/test/java/logic/CoachWithSeatsSpecification.java
@@ -201,6 +201,5 @@ public class CoachWithSeatsSpecification {
         return mock;
     }
 
-
     //todo should we protect reserve() method?
 }
\ No newline at end of file

commit c382a3bb80f3c36aff86936aed6bec9521c6e71c
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 16 16:46:56 2018 +0100

    Discovered a NamedSeat class

diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
index 1a4b009..8bf4abd 100644
--- a/Java/src/main/java/logic/CouchDbTrainRepository.java
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -5,7 +5,10 @@ public class CouchDbTrainRepository implements TrainRepository {
     public Train getTrainBy(String trainId) {
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
diff --git a/Java/src/main/java/logic/NamedSeat.java b/Java/src/main/java/logic/NamedSeat.java
new file mode 100644






index 0000000..2e20b7f
--- /dev/null
+++ b/Java/src/main/java/logic/NamedSeat.java
@@ -0,0 +1,15 @@
+package logic;
+
+public class NamedSeat implements Seat {
+    @Override
+    public boolean isFree() {
+        //todo implement
+        return false;
+    }
+
+    @Override
+    public void reserveFor(TicketInProgress ticketInProgress) {
+        //todo implement
+
+    }
+}

commit b0cc065b84d56cf5eecbf7e15933e2aca52f47e4
Author: Galezowski Grzegorz-FTW637 <FTW637@motorolasolutions.com>
Date:   Fri Mar 16 16:55:13 2018 +0100

    Added failing test
    
    Note that depending on what Any.boolean() returns, this might pass or not

diff --git a/Java/src/main/java/logic/CouchDbTrainRepository.java b/Java/src/main/java/logic/CouchDbTrainRepository.java
index 8bf4abd..3e9340e 100644
--- a/Java/src/main/java/logic/CouchDbTrainRepository.java
+++ b/Java/src/main/java/logic/CouchDbTrainRepository.java
@@ -6,8 +6,8 @@ public class CouchDbTrainRepository implements TrainRepository {
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
diff --git a/Java/src/main/java/logic/NamedSeat.java b/Java/src/main/java/logic/NamedSeat.java
index 2e20b7f..26b5b8e 100644
--- a/Java/src/main/java/logic/NamedSeat.java
+++ b/Java/src/main/java/logic/NamedSeat.java
@@ -1,6 +1,11 @@
 package logic;
 
 public class NamedSeat implements Seat {
+    public NamedSeat(Boolean isFree) {
+        //todo implement
+
+    }
+
     @Override
     public boolean isFree() {
         //todo implement
diff --git a/Java/src/test/java/logic/NamedSeatSpecification.java b/Java/src/test/java/logic/NamedSeatSpecification.java
new file mode 100644






index 0000000..3568928
--- /dev/null
+++ b/Java/src/test/java/logic/NamedSeatSpecification.java
@@ -0,0 +1,25 @@
+package logic;
+
+import autofixture.publicinterface.Any;
+import lombok.val;
+import org.testng.annotations.Test;
+
+import static org.assertj.core.api.Assertions.assertThat;
+
+public class NamedSeatSpecification {
+    @Test
+    public void shouldBeFreeDependingOnPassedConstructorParameter() {
+        //GIVEN
+        val isInitiallyFree = Any.booleanValue();
+        val namedSeat = new NamedSeat(isInitiallyFree);
+
+        //WHEN
+        val isEventuallyFree = namedSeat.isFree();
+
+        //THEN
+        assertThat(isEventuallyFree).isEqualTo(isInitiallyFree);
+    }
+
+    //todo add ctrl + enter to presentation
+    //todo add CamelHumps to presentation
+}
\ No newline at end of file

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
 
 public class NamedSeat implements Seat {
-    public NamedSeat(Boolean isFree) {
-        //todo implement
+    private Boolean isFree;
 
+    public NamedSeat(Boolean isFree) {
+        this.isFree = isFree;
     }
 
     @Override
     public boolean isFree() {
-        //todo implement
-        return false;
+        return isFree;
     }
 
     @Override
diff --git a/Java/src/test/java/logic/NamedSeatSpecification.java b/Java/src/test/java/logic/NamedSeatSpecification.java
index 3568928..5894ae3 100644
--- a/Java/src/test/java/logic/NamedSeatSpecification.java
+++ b/Java/src/test/java/logic/NamedSeatSpecification.java
@@ -7,7 +7,7 @@ import org.testng.annotations.Test;
 import static org.assertj.core.api.Assertions.assertThat;
 
 public class NamedSeatSpecification {
-    @Test
+    @Test(invocationCount = 2)
     public void shouldBeFreeDependingOnPassedConstructorParameter() {
         //GIVEN
         val isInitiallyFree = Any.booleanValue();
