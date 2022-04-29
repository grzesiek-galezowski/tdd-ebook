# Test-driving object creation

In this chapter, we join Johnny and Benjamin as they continue their outside-in TDD journey. In this chapter, they will be test-driving a factory.

**Johnny:** What's next on our TODO list?

**Benjamin:** There are two instances of `NotImplementedException`, both from factories that we discovered when implementing the last Statement.

The first factory is for creating instances of `ReservationInProgress` -- remember? You gave it a bogus name on purpose. Look:

```csharp
public class TodoReservationInProgressFactory : ReservationInProgressFactory
{
  public ReservationInProgress FreshInstance()
  {
   throw new NotImplementedException();
  }
}
```

**Johnny:** Oh, yeah, that one...

**Benjamin:** and the second factory is for creating commands -- it's called `TicketOfficeCommandFactory`:

```csharp
public class TicketOfficeCommandFactory : CommandFactory
{
  public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto,
    ReservationInProgress reservationInProgress)
  {
   throw new NotImplementedException();
  }
}
```

**Johnny:** Let's do this one.

**Benjamin:** Why this one?

**Johnny**: No big reason. I just want to dig into the domain logic as soon as possible.

**Benjamin**: Right. We don't have a Specification for this class, so let's create one.

```csharp
public class TicketOfficeCommandFactorySpecification
{

}
```

**Johnny**: Go on, I think you will be able to write this Statement mostly without my help.

**Benjamin**: The beginning looks easy. I'll add a new Statement which I don't know yet what I'm going to call.

```csharp
public class TicketOfficeCommandFactorySpecification
{
 [Fact]
 public void ShouldCreateXXXXXXXXX() //TODO rename
 {
  Assert.True(false);
 }
}
```

Now, as you've told me before, I already know what class I am describing -- it's `TicketOfficeCommandFactory`. It implements an interface that I discovered in the previous Statement, so it already has a method: `CreateNewReservationCommand`. So in the Statement, I'll just create an instance of the class and call the method, because why not?

```csharp
public class TicketOfficeCommandFactorySpecification
{
 [Fact]
 public void ShouldCreateXXXXXXXXX() //TODO rename
 {
  //GIVEN
  var factory = new TicketOfficeCommandFactory();
  
  //WHEN
  factory.CreateNewReservationCommand();

  //THEN
  Assert.True(false);
 }
}
```

This doesn't compile. To find out why, I look at the signature of the `CreateNewReservationCommand` method, and I see that it not only returns a command, but also accepts two arguments. I need to take that into account in the Statement:

```csharp
public class TicketOfficeCommandFactorySpecification
{
 [Fact]
 public void ShouldCreateXXXXXXXXX() //TODO rename
 {
  //GIVEN
  var factory = new TicketOfficeCommandFactory();
  
  //WHEN
  var command = factory.CreateNewReservationCommand(
    Any.Instance<ReservationRequestDto>(),
    Any.Instance<ReservationInProgress>());

  //THEN
  Assert.True(false);
 }
}
```

I used `Any.Instance<>()` to generate anonymous instances of both the DTO and the `ReservationInProgress`.

**Johnny**: That's exactly what I'd do. I'd assign them to variables only if I needed to use them somewhere else in the Statement.

**Benjamin**: The Statement compiles. I still have the assertion to write. What exactly should I assert? The command I'm getting back from the factory has only a `void Execute()` method. Everything else is hidden.

**Johnny**: Typically, there isn't much we can specify about the objects created by factories. In this case, we can only state the expected type of the command.

**Benjamin**: Wait, isn't this already in the signature of the factory? Looking at the creation method, I can already see that the returned type is `ReservationCommand`... wait!

**Johnny**: I thought you'd notice that. `ReservationCommand` is an interface. But an object needs to have a concrete type and this type is what we need to specify in this Statement. We don't have this type yet. We are on the verge of discovering it, and when we do, some new items will be added to our TODO list.

**Benjamin**: I'll call the class `NewReservationCommand` and modify my Statement to assert the type. Also, I think I know now how to name this Statement:

```csharp
public class TicketOfficeCommandFactorySpecification
{
 [Fact]
 public void ShouldCreateNewReservationCommandWhenRequested()
 {
  //GIVEN
  var factory = new TicketOfficeCommandFactory();
  
  //WHEN
  var command = factory.CreateNewReservationCommand(
    Any.Instance<ReservationRequestDto>(),
    Any.Instance<ReservationInProgress>());

  //THEN
  Assert.IsType<NewReservationCommand>(command);
 }
}
```

**Johnny**: Now, let's see -- the Statement looks like it's complete. You did it almost without my help.

**Benjamin**: Thanks. The code does not compile, though. The `NewReservationCommand` type does not exist.

**Johnny**: Let's introduce it then:

```csharp
public class NewReservationCommand
{

}
```

**Benjamin**: Shouldn't it implement the `ReservationCommand` interface?

**Johnny**: We don't need to do that yet. The compiler only complained that the type doesn't exist.

**Benjamin**: The code compiles now, but the Statement is false because the `CreateNewReservationCommand` method throw a `NotImplementedException`:

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto,
    ReservationInProgress reservationInProgress)
  {
   throw new NotImplementedException();
  }
```

**Johnny**: Remember what I told you the last time?

**Benjamin**: Yes, that the Statement needs to be false for the right reason.

**Johnny**: Exactly. `NotImplementedException` is not the right reason. I will change the above code to return null:

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto,
    ReservationInProgress reservationInProgress)
  {
   return null;
  }
```

Now the Statement is false because this assertion fails:

```csharp
Assert.IsType<NewReservationCommand>(command);
```

**Benjamin**: it complains that the command is null.

**Johnny**: So the right time came to put in the correct implementation:

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto,
    ReservationInProgress reservationInProgress)
  {
   return new NewReservationCommand();
  }
```

**Benjamin**: But this doesn't compile -- the `NewReservationCommand` doesn't implement the `ReservationCommand` interface, I told you this before.

**Johnny**: and the compiler forces us to implement this interface:

```csharp
public class NewReservationCommand : ReservationCommand
{

}
```

The code still doesn't compile, because the interface has an `Execute()` method we need to implement in the `NewReservationCommand`. Any implementation will do as the logic of this method is outside the scope of the current Statement. We only need to make the compiler happy. Our IDE can generate the default method body for us. This should do:

```csharp
public class NewReservationCommand : ReservationCommand
{
 public void Execute()
 {
  throw new NotImplementedException();
 } 
}
```

The `NotImplementedException` will be added to our TODO list and we'll specify its behavior with another Statement later.

**Benjamin**: Our current Statement seems to be true now. I'm bothered by something, though. What about the arguments that we are passing to the `CreateNewReservationCommand` method? There are two: 

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto, //first argument
    ReservationInProgress reservationInProgress) //second argument
  {
   return new NewReservationCommand();
  }
```

and they are both unused. How come?

**Johnny**: We could've use them and pass them to the command. Sometimes I do this though the Statement does not depend on this, so there is no pressure. I chose not to do it this time to show you that we will need to pass them anyway when we specify the behaviors of our command.

**Benjamin**: let's say you are right and when we specify the command behavior, we will need to modify the factory to pass these two, e.g. like this:

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto, //first argument
    ReservationInProgress reservationInProgress) //second argument
  {
   return new NewReservationCommand(requestDto, reservationInProgress);
  }
```

but no Statement says which values should be used, so I will as well be able to cheat by writing something like:

```csharp
public ReservationCommand CreateNewReservationCommand(
    ReservationRequestDto requestDto, //first argument
    ReservationInProgress reservationInProgress) //second argument
  {
   return new NewReservationCommand(null, null);
  }
```

and all Statements will still be true.

**Johnny**: That's right. Though there are some techniques to specify that on unit level, I'd rather rely on higher-level Statements to guarantee we pass the correct values. I will show you how to do it another time.

**Benjamin**: Thanks, seems I'll just have to wait.

**Johnny**: Anyway it looks like we're done with this Statement, so let's take a short break.

**Benjamin**: Sure!
