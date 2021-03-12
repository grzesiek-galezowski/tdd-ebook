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

