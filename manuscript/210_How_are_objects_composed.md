Composing a web of objects
==========================

Three important questions
-------------------------

Ok, I told you that such a thing as a web of objects exists, that there are connections, protocols and such, but there is one thing I left out: how does a web of objects come into existence?

This is, of course, a fundamental question, because if we are not able to build a web, we do not have a web. In addition, this is a question that is a little more tricky that you may think and it contains three other questions that we need to answer:

1.  When are objects composed (i.e. when a connection is made)?
2.  How does an object obtain a reference to another one in the web (i.e. how a connection is made)?
3.  Where are objects composed (i.e. where a connection is made)?

For now, you may have some trouble understanding why these questions 
are important, but the good news is that you won't have to trust me 
too long, because these questions are the topic of this chapter. Let's go!

## A preview

Before we take a deep dive, let's try to answer these questions for a 
really simple example code of a console application:

{lang="csharp"}
~~~
public static void Main(string[] args)
{
  var sender = new Sender(new Recipient());
}
~~~

1.  When are objects composed? Answer: up-front, during application startup.
2.  How does an object (`Sender`) obtain a reference to another one 
(`Recipient`)? Answer: the reference is passed through constructor.
3.  Where are objects composed? Answer: at application entry point (`Main()` 
method)

Depending on circumstances, we have different sets of best answers to these 
questions. To find them, let us take the questions on one by one.

When are objects composed?
--------------------------

The quick answer to this question is: as early as possible.

Most of our system is assembled up-front when the application starts and stays this way until the application finishes executing. Let's call this part the **static part** of the web. We will talk about the **composition root** pattern that handles this part. 

Apart from that, there's the **dynamic part**. There are two reasons this dynamic part exists:

1. Some objects represent requests that arrive during the application runtime, are processed and then discarded. These objects cannot be created up-front, but can be created only as soon as the necessary event occurs. Also, these objects do not live until the application is terminated, but are discarded as soon as the processing of a request is finished. Other objects represent items in the cache that live for some time and then expire etc. so it's impossible to define these objects up-front. All of these objects come and go, making temporary connections. We will talk about **getting recipients in response to a message** approach (which will largely be about **factories**) that is made for such situations.
2. There are objects that have a lifespan as long as the application itself, but be connected only for the needs of a single interaction (e.g. when one object is passed to a method of another as an argument) or at some point during the application runtime. We will talk about **passing objects inside messages** and **registering objects** approaches that allow us manage such connections.

There can be situations when an object is part of both static and dynamic part - some of its connections may be made up-front, while others may be created later.

How does sender obtain a reference to recipient (i.e. how a connection is made)?
------------------------------------------------

There are few ways this happens, each of them useful in certain circumstances:

### Receive as constructor parameter

Two objects can be composed by passing one into the constructor of
another:

{lang="csharp"}
~~~
sender = new Sender(recipient);
~~~

A sender then saves a reference to the recipient in a private field for later, like this:

{lang="csharp"}
~~~
public Sender(Recipient recipient)
{
  this._recipient = recipient;
}
~~~

Composing using constructors has one significant advantage. The code that passes `Recipient` to `Sender` through constructor is most often in a totally different place than the code using `Sender`. Thus, the code using `Sender` is not aware that `Sender` stores a reference to `Recipient` inside it. This basically means that when `Sender` is used, e.g. like this:

{lang="csharp"}
~~~
sender.DoSomething()
~~~

the `Sender` may then react by sending message to `Recipient`, but the code invoking the `DoSomething()` method is completely unaware of that. 
Which is good, because "what you hide, you can change"[^kolskybain] - if we decide that the `Sender` needs not use the `Recipient` to do its duty (or pass in a different implementation of `Sender` that does not need the `Recipient`), the code that uses `Sender` does not need to change at all - it still uses the `Sender` the same way:

{lang="csharp"}
~~~
sender.DoSomething()
~~~

All we have to change is the composition code to remove `Recipient`:

{lang="csharp"}
~~~
//no need to pass a reference to Recipient anymore
new Sender();
~~~

Another advantage of the constructor approach is that if `Recipient` is required for a `Sender` to work correctly and it does not make sense to create a `Sender` without a `Recipient`, the signature of the constructor makes it explicit - the compiler will not let us create a `Sender` without passing *something* as a `Recipient`.

Passing into constructor is a great solution in cases we want to compose sender with a recipient permanently (i.e. for the lifetime of `Sender`). In order to be able to do this, a `Recipient` must, of course, exist before a `Sender` does. Another less obvious requirement for this composition is that `Recipient` must be usable at least as long as `Sender` is usable. In other words, the following is nonsense:

{lang="csharp"}
~~~
sender = new Sender(recipient);
recipient.Dispose(); //but sender is unaware of it 
                     //and may still use recipient in:
sender.DoSomething();
~~~

### Receive inside a message (i.e. as a method parameter)

Another common way of composing objects together is passing one object
as a parameter of another object's method call:

{lang="csharp"}
~~~
sender.DoSomethingWithHelpOf(recipient);
~~~

In such case, the objects are most often composed temporarily, just for 
the time of execution of this single method:

{lang="csharp"}
~~~
public void DoSomethingWithHelpOf(Recipient recipient)
{
  //... perform some logic
  
  recipient.HelpMe();
  
  //... perform some logic
}
~~~

Contrary to the constructor approach, where a `Sender` could hide from its user the fact that it needs `Recipient`, in this case the user of `Sender` is explicitly responsible for supplying a `Recipient`. It may look like the coupling of user to `Recipient` is a disadvantage, but there are scenarios where it is actually **required** for a code using `Sender` to be able to provide its own `Recipient` - it lets us use the same sender with different recipients at different times (most often from different parts of the code):

{lang="csharp"}
~~~
//in one place
sender.DoSomethingWithHelpOf(recipient);

//in another place:
sender.DoSomethingWithHelpOf(anotherRecipient);

//in yet another place:
sender.DoSomethingWithHelpOf(yetAnotherRecipient);
~~~

If this ability is not required, the constructor approach is better as it removes the then unnecessary coupling between code using `Sender` and a `Recipient`.

### Get recipient in response to message (i.e. as method return value)

This method of composing objects uses another intermediary object - often a factory (that creates new recipient instance on each call)[^gofcreationpatterns]. Most often, the sender is given a reference to this intermediary object as a constructor parameter (an approach we already discussed):

{lang="csharp"}
~~~
sender = new Sender(factory);
~~~

and then the intermediary object is used to deliver other objects:

{lang="csharp"}
~~~
public class Sender
{
  //...

  public DoSomething() 
  {
    var recipient = _factory.CreateRecipient();
    recipient.DoSomethingElse();
  }
}
~~~

This kind of composition is beneficial when a new recipient is needed each time `DoSomething()` is called (much like in case of previously discussed approach of receiving a recipient as a method parameter), but at the same time (contrary to the mentioned approach), it is not the code using the `Sender` that should (or can) be responsible for supplying a recipient.

To be more clear, here is a comparison of two approaches: passing 
recipient inside a message:

{lang="csharp"}
~~~
//user of Sender passes a recipient:
public DoSomething(Recipient recipient) 
{
  recipient.DoSomethingElse();
}
~~~

and obtaining from factory:

{lang="csharp"}
~~~
//user of Sender does not know about Recipient
public DoSomething() 
{
  var recipient = _factory.CreateRecipient();
  recipient.DoSomethingElse();
}
~~~

### "Register" a recipient with already created sender

This means passing a recipient to an **already created** sender 
(contrary to passing as constructor parameter where recipient was 
passed **during** creation) as a parameter of a method that stores the 
reference for later use. This may be a "setter" method, although I do 
not like naming it according to convention "setWhatever()" - after Kent 
Beck[^implementationpatterns] I find this convention too much 
implementaion-focused instead of purpose-focused. Thus, I pick 
different names based on what domain concept is modeled by the 
registration method or what is its purpose.

Note that this is similar to "pass inside a message" approach, only this time, the passed recipient is not used immediately and forgotten, but rather remembered for later use.

I hope I can clear up the confusion with a quick example. Suppose we have a temperature sensor that can report its current and historically mean value for the current date to whoever registers with it. If no one registers, it still does its job, because it still has to be able to give a history-based mean value to whoever registers at whatever time, right? 

We may solve the problem by introducing an observer registration mechanism in the sensor implementation. If no observer is registered, the values are not reported (in other words, a registered observer is not required for the object to function, but if there is one, it can take advantage of the reports). For this purpose, let's make our sensor depend on an interface called `TemperatureObserver` that could be implemented by various custom observers:

{lang="csharp"}
~~~
public interface TemperatureObserver
{
  void NotifyOn(
    Temperature currentValue,
    Temperature meanValue);  
}
~~~

Now we are ready to look at the sensor implementation. Let's make it a class called `TemperatureSensor`. Part of its definition could look like this:

{lang="csharp"}
~~~
public class TemperatureSensor
{
  private TemperatureObserver _observer 
    = new NullObserver(); //ignores reported values
  private Temperature _meanValue 
    = Temperature.Celsius(0);
  
  // + maybe more fields related to storing historical data

  public void Run()
  {
    while(/* needs to run */)
    {
      var currentValue = /* get current value somehow */;
      _meanValue = /* update mean value somehow */;

      _observer.NotifyOn(currentValue, _meanValue);
      
      WaitUntilTheNextMeasurementTime();
    } 
  }
}
~~~

As you can see, by default, the sensor reports its values to nowhere (`NullObserver`), which is a safe default value (using a `null` instead would cause exceptions or force us to put an ugly null check inside the `Run()` method). We have already seen such "null objects" a few times before (e.g. in the previous chapter, when we introduced the `NoAlarm` class) - `NullObserver` is just another incarnation of this pattern.


 Still, we want to be able to supply our own observer one day, when someone starts caring about the measured and calculated values (this may be indicated to our application e.g. with a network message or an event from the user interface). This means we need to have a method inside the `TemperatureSensor` class to overwrite this default "do-nothing" observer with a custom one **after** the `TemperatureSensor` instance is created. As I said, I do not like the "SetXYZ()" convention, so I will name the registration method `FromNowOnReportTo()` and make the observer an argument:

{lang="csharp"}
~~~
public void FromNowOnReportTo(TemperatureObserver observer)
{
  _observer = observer;
}
~~~

This lets us overwrite the observer with a new one should we ever need 
to do it. Note that, as I mentioned, this is the place where registration approach differs from the "pass inside a message" approach, where we also receive a recipient in a message, but for immediate use. Here, we don't use the recipient (i.e. the observer) when we get it, but instead we save it for later.

Time for a general remark. Allowing registering recipients after a sender is created is a way of saying: "the recipient is optional - if you provide one, fine, if not, I will do my work without it". Please, do not use this kind of mechanism for **required** recipients - these should all be passed through constructor, making it harder to create invalid objects that are only partially ready to work. Placing a 
recipient in a constructor signature is effectively saying that "I will not work without it". Look at how the following class members signatures talk to you:

{lang="csharp"}
~~~
public class Sender
{
  //"I will not work without a Recipient1"
  public Sender(Recipient1 recipient1) {...}
  
  //"I will do fine without Recipient2 but you
  //can overwrite the default here to take advantage
  //of some features"
  public void Register(Recipient2 recipient2) {...}
}
~~~ 

Now, the observer API we just skimmed over gives us the possibility to have a single observer at any given time. When we register new observer, the reference to the old one is overwritten. This is not really useful in our context, is it? With real sensors, we often want them to report 
their measurements to multiple places (e.g. we want the measurements printed on screen, saved to database, used as part of more complex calculations). This can be achieved in two ways.

The first way would be to just hold a collection of observers in our sensor, and add to this collection whenever a new observer is registered:

{lang="csharp"}
~~~
IList<TemperatureObserver> _observers 
  = new List<TemperatureObserver>();

public void FromNowOnReportTo(TemperatureObserver observer)
{
  _observers.Add(observer);
}
~~~

In such case, reporting would mean iterating over the observers list:

{lang="csharp"}
~~~
...
foreach(var observer in _observers)
{
  observer.NotifyOn(currentValue, meanValue);
}
...
~~~

Another, more flexible option, is to use something like we did in the previous chapter with a `HybridAlarm` (remember? It was an alarm aggregating other alarms) - i.e. instead of introducing a collection in the sensor, create a special kind of "broadcasting observer" that would hold collection of other observers (hurrah composability!) and broadcast the values to them every time it itself receives those values:

{lang="csharp"}
~~~
public class BroadcastingObserver 
  : TemperatureObserver
{
  private readonly 
    TemperatureObserver[] _observers;
  
  public BroadcastingObserver(
    params TemperatureObserver[] observers)
  {
    _observers = observers;
  }

  public void NotifyOn(
    Temperature currentValue,
    Temperature meanValue)
  {
    foreach(var observer in _observers)
    {
      observer.NotifyOn(currentValue, meanValue);
    }
  }  
} 
~~~

This `BroadcastingObserver` could be instantiated and registered like this:

{lang="csharp"}
~~~
//instantiation:
var broadcastingObserver 
  = new BroadcastingObserver(
      new DisplayingObserver(),
      new StoringObserver(),
      new CalculatingObserver());

//registration:
sensor.FromNowOnReportTo(broadcastingObserver);
~~~

This would let us change the broadcasting policy without touching either the sensor code or the other observers. For example, we might introduce `ParallelBroadcastObserver` that would notify each observer asynchronously instead of sequentially and put it to use by changing the composition code only:

{lang="csharp"}
~~~
//now using parallel observer
var broadcastingObserver 
  = new ParallelBroadcastObserver(
      new DisplayingObserver(),
      new StoringObserver(),
      new CalculatingObserver());

sensor.FromNowOnReportTo(broadcastingObserver);
~~~

Anyway, as I said, use registering instances very wisely and only if you specifically need it. Also, if you do use it, evaluate how allowing changing observers at runtime is affecting your multithreading scenarios. This is because maintaining a changeable field (or a collection) throughout the object lifetime means that multiple thread might access it and get in each others' ways.

Where are objects composed?
---------------------------

Ok, we went through some ways of passing a recipient to a sender. The big question is: which code should pass the recipient?

For almost all of the approaches described above there is no limitation - you pass the recipient from where you need to pass it.

There is one approach, however, that is more limited, and this approach is **passing as constructor parameter**.

Why is that? Because, we are trying to be true to the principle of "separating objects creation from usage". If an object cannot both use and create another object, we have to make special objects just for creating other objects (there are some design patterns for how to design such objects, but the most popular and useful is a factory) or defer the creation up to the application entry point (there is also a pattern for this, called **composition root**).

Let's start with the second one.

### Composition Root

Let us assume for fun that we are creating a mobile game when a player has to defend a castle. This game has two levels. Each level has a castle. So, we have three classes: a `Game` that has two `Level`s and each of them that contain a `Castle`. Let us also assume that the first two classes violate the principle of separating usage from construction.

A `Game` class is created in the `Main()` method of the application:

{lang="csharp"}
~~~
public static void Main(string[] args)
{
  var game = new Game();
  
  game.Play();
}
~~~

The `Game` creates its own `Level` objects of specific classes implementing the `Level` interface and stores them in an array:

{lang="csharp"}
~~~
public class Game
{
  private Level[] _levels = new[] { 
    new Level1(), new Level2()
  };
  
  //some methods here that use the levels
}
~~~

And the `Level` implementations create their own castles and assign them to fields of interface type `Castle`:

{lang="csharp"}
~~~
public class Level1
{
  private Castle _castle = new SmallCastle();
  
  //some methods here that use the castle
}

public class Level2
{
  private Castle _castle = new BigCastle();
  
  //some methods here that use the castle
}
~~~

We can try to make them more compliant with the principle. First, let us refactor the `Level1` and `Level2` by moving instantiation of their castles out of these classes. Existence of a castle is required for a level to make sense at all to make sense - we will say this in code by using the approach of passing them through constructor:

{lang="csharp"}
~~~
public class Level1
{
  private Castle _castle;
  
  //now castle is received as
  //constructor parameter
  public Level1(Castle castle)
  {
    _castle = castle;
  }
  
  //some methods here that use the castle
}

public class Level2
{
  private Castle _castle;
  
  //now castle is received as
  //constructor parameter
  public Level2(Castle castle)
  {
    _castle = castle;
  }
  
  //some methods here that use the castle
}
~~~

This was easy, wasn't it? The only problem is that if the instantiation of castles is not in `Level1` and `Level2` anymore, then they have to be passed by whoever creates the levels. In our case - the `Game` class:
 
{lang="csharp"}
~~~
public class Game
{
  private Level[] _levels = new[] {
    //now castles are created here as well: 
    new Level1(new SmallCastle()), 
    new Level2(new BigCastle())
  };
  
  //some methods here that use the levels
}
~~~

But remember - this class suffers from the same violation of not separating objects use from construction as the levels. Thus, to make this class compliant as well, we have to move the creation of levels out of it:

{lang="csharp"}
~~~
public class Game
{
  private Level[] _levels;
  
  //now levels are received as 
  //constructor parameter
  public Game(Level[] levels)
  {
    _levels = levels;
  }
  
  //some methods here that use the levels
}
~~~

There, we did it, but again, the levels now must be supplied by whoever creates the `Game`. Where do we put them? In our case, the only choice left is the `Main()` method of our application, so this is exactly what we are going to do:

{lang="csharp"}
~~~
public static void Main(string[] args)
{
  var game = 
    new Game(
      new Level[] { 
        new Level1(new SmallCastle()), 
        new Level2(new BigCastle())
  });
  
  game.Play();
}
~~~

By the way, the `Level1` and `Level2` differed only by the castles and this difference is no more, so we can make them a single class and call it e.g. `TimedLevel` (because it is considered passed when we defend our castle for a specific period of time). Now, we have:

{lang="csharp"}
~~~
public static void Main(string[] args)
{
  var game = 
    new Game(
      new Level[] { 
        new TimedLevel(new SmallCastle()), 
        new TimedLevel(new BigCastle())
  });
  
  game.Play();
}
~~~

Looking at the code above, we might come to another funny conclusion - this violates the principle of separating usage from construction as well! First, we create and connect the web of objects and then send the `Play()` message to the `game` object. Shouldn't we fix this as well? 

The answer is "no", for two reasons:

 1. There is no further place we can defer the creation. Sure, we could move the creation of the `Game` object and its dependencies into a separate object responsible only for the creation (we call such object **a factory**), but that would leave us with the question: where where do we instantiate this factory?
 2. The whole point of the principle we are trying to apply is decoupling, i.e. giving ourselves the ability to change one thing without having to change another. When we think of it, there is no point of decoupling the entry point of the application from the application itself, since this is the most application-specific and non-reusable part of the application we can imagine.

What is important is that we reached a place where the web of objects is created using constructor approach and we have no place left to defer the the creation of the web (in other words, it is as close as possible to application entry point). Such place is called **a composition root**.

We say that composition root is "as close as possible" to application entry point, because there may be different frameworks in control of your application and you will not always have the `Main()` method at your disposal[^seemanndi].

Apart from the constructor invocations, the composition root may also contain registrations of observers (see registration approach to passing recipients) if such observers are already known at this point.

The composition root above looks quite small, but you can imagine it grow a lot in bigger applications. There are techniques of refactoring the composition root to make it more readable and reusable and we will explore those techniques in further chapters.

### Factories

As I previously said, it is not always possible to pass everything through the constructor. One of the approach we discussed that we can use in such cases is **a factory**.

#### Example  

Consider the following code that receives a frame from the network (as raw data), then packs it into an object, validates and applies to the system:
 
{lang="csharp"}
~~~
public class MessageInbound
{
  //...initialization code here...
  
  public void Handle(Frame frame)
  {
    // determine the type of message
    // and wrap it with an object
    ChangeMessage change = null;
    if(frame.Type == FrameTypes.Update)
    {
      change = new UpdateRequest(frame);
    }
    else if(frame.Type == FrameTypes.Insert)
    {
      change = new InsertRequest(frame);
    }  
    else
    {
      throw 
        new InvalidRequestException(frame.Type);
    }
    
    change.ValidateUsing(_validationRules);
    _system.Apply(change);
  }
}
~~~

Note that, again, this code violates the principle of separating usage from construction. The `change` is first created, depending on the frame type, and then used (validated and applied). On the other hand, it is impossible to pass an instance of the `ChangeMessage` through the `MessageInbound` constructor, because this would require us to create the `ChangeMessage` before we create the `MessageInbound`. This is impossible, because we can only create messages when we know the frame data which the `MessageInbound` is supposed to receive.

Thus, our choice is to make a special object that we would move the creation of new messages to. It would produce the new instances when requested, hence the name **factory**. This object itself can be passed through constructor, since it does not need the framer to exist - it only needs one when it is asked to create a message.

Knowing this, we can refactor the above code to the following:

{lang="csharp"}
~~~
public class MessageInbound
{
  private readonly 
    MessageFactory _messageFactory;
  private readonly 
    ValidationRules _validationRules;
  private readonly 
    ProcessingSystem _system;
  
  public MessageInbound(
    //this is the factory:
    MessageFactory messageFactory,
    ValidationRules validationRules,
    ProcessingSystem system)
  {
    _messageFactory = messageFactory;
    _validationRules = validationRules;
    _system = system;
  }
  
  public void Handle(Frame frame)
  {
    var change = _messageFactory.CreateFrom(frame);  
    change.ValidateUsing(_validationRules);
    _system.Apply(change);
  }
}
~~~

This way we have separated message construction from its usage. The factory looks like this:

{lang="csharp"}
~~~
public class InboundMessageFactory
 : MessageFactory
{
  ChangeMessage CreateFrom(Frame frame)
  {
    if(frame.Type == FrameTypes.Update)
    {
      return new UpdateRequest(frame);
    }
    else if(frame.Type == FrameTypes.Insert)
    {
      return new InsertRequest(frame);
    }    
    else
    {
      throw 
        new InvalidRequestException(frame.Type);
    }
  }
}
~~~

This is it for a simple factory example, now on to the more general explanation.

#### Explanation of the factory

As you saw in the example, factories are objects responsible for creating other objects. They are used to achieve the separation object construction from its usage when not all of the information necessary to create objects is known at the time the composition root is executed (as the full context for object creation is not available, we puts the part of the context we know in the factory, and supply the rest by factory method parameters when it is available). Another reason is that we need to create a new object each time some kind of request is made (a message is received from the network or someone clicks a button). Both these reasons were present in our example:

 1. We were unable to create a `ChangeMessage` before knowing the actual `Frame`.
 2. For each `Frame` received, we needed to create a new `ChangeMessage` instance. 

The simplest possible example of a factory is something along the following lines:

{lang="csharp"}
~~~
public class MyMessageFactory
{
  public MyMessage CreateMyMessage()
  {
    return new MyMessage();
  }
}
~~~

Even in this primitive shape the factory already has some value (e.g. we can make `MyMessage` an abstract type and return instances of its subclasses from the factory, and the only place we need to change is the factory[^essentialskills]). More often, however, when talking about simple factories, we think about something like this:

{lang="csharp"}
~~~
//let's assume MessageFactory 
//and Message are interfaces
public class XmlMessageFactory : MessageFactory
{
  public Message CreateSessionInitialization()
  {
    return new XmlSessionInitialization();
  }
}
~~~

Note the two things that the factory in the second example has that the one in the first example does not:

* it implements an interface (one level of indirection)
* its `CreateSessionInitialization()` method declares a return type to be an interface (another level of indirection)

In order for you to use factories effectively, I need you to understand why and how this indirection is useful, especially that when I talk with people, they often do not understand the benefits of using factories, "because we already have the `new` operator to create objects". So, here are the benefits of using factories:

#### Factories allow creating objects polymorphically (encapsulation of type)

Each time we invoke a `new` operator, we have to put a name of a concrete type next to it:

{lang="csharp"}
~~~
new List<int>(); //OK!
new IList<int>(); //won't compile...
~~~

Factories are different. Because we get objects from factories by invoking a method, not by saying which class we want to get instantiated, we can take advantage of polymorphism, i.e. our factory may have a method like this:

{lang="csharp"}
~~~
IList<int> CreateContainerForData() {...}
~~~

and everything is well as long as the code of this method returns an instance of a real class (say, `List<int>`):

{lang="csharp"}
~~~
public /*interface in declaration: */ IList<int> 
CreateContainerForData() 
{
  return /* instance of concrete class: */ new List<int>();
}
~~~

Of course, it makes little sense for the return type of the factory to be a library class or interface (rather, we use factories to create our own classes), but you get the idea, right? Anyway, it is typical for a return type of a factory to be an interface or, at worst, an abstract class. This means that whatever uses the factory, it knows only that it receives an object of that type. Thus,  a factory may return objects of different types at different times, depending on some rules only it knows.

Time to look at some more realistic example of how to apply this. Let's say we have a factory of messages like this:

{lang="csharp"}
~~~
public class Version1ProtocolMessageFactory 
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
~~~

Note that the factory can create many different types of messages depending on what is inside the raw data, but for the user of the factory, this is irrelevant. All that it knows is that it gets a `Message`, thus, it (and additional code operating on messages for that matter) can be written as general-purpose logic:

{lang="csharp"}
~~~
var message = _messageFactory.NewInstanceFrom(rawData);
message.ValidateUsing(_primitiveValidations);
message.ApplyTo(_sessions);
~~~

Note that, while the above code needs to change when the rule "first validate, then apply to sessions" changes, it does not need to change in case we want to add a new type of message that complies with the current logic. The only place we need to change in such case is the factory. Let's see how it would look like if we decided to add a session refresh message: 

~~~
public class Version1ProtocolMessageFactory
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      case Messages.SessionRefresh: //new message type!
        return new SessionRefresh(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
~~~

Using the factory to hide the real type of message returned makes maintaining the code easier, because there is less code to change when adding new types of messages to the system or removing existing ones (e.g. in case when we do not need to initiate a session anymore) [^encapsulatewhatvaries] - the factory hides that.

#### Factories are themselves polymorphic (encapsulation of rule)

Another benefit of factories over constructors is that they are composable themselves. This allows replacing the rule used to create objects with another one.

In the example in the previous section, we examined a situation where we extended the existing factory with a `SessionRefresh` message. This was done with assumption that we do not need the previous version of the factory. But consider a situation where we need both versions of the behavior. The "version 1" of the factory looking like this:

{lang="csharp"}
~~~
public class Version1ProtocolMessageFactory 
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
~~~

and the "version 2" looking like this:

{lang="csharp"}
~~~
//note that now it is a version 2 protocol factory
public class Version2ProtocolMessageFactory
  : MessageFactory
{
  public Message NewInstanceFrom(MessageData rawData)
  {
    switch(rawData.MessageType)
    {
      case Messages.SessionInit:
        return new SessionInit(rawData);
      case Messages.SessionEnd:
        return new SessionEnd(rawData);
      case Messages.SessionPayload:
        return new SessionPayload(rawData);
      case Messages.SessionRefresh: //new message type!
        return new SessionRefresh(rawData);
      default:
        throw new UnknownMessageException(rawData);
    }
  }
}
~~~

Depending on what the user chooses in the configuration, we give them either a version 1 protocol support which does not support session refreshing, or a version 2 protocol support that does. Assuming the configuration is only read once during the application start, we may have the following code in our composition root:

{lang="csharp"}
~~~
MessageFactory messageFactory = configuration.Version == 1 ?
  new Version1ProtocolMessageFactory() : 
  new Version2ProtocolMessageFactory() ;
  
var messageProcessing = new MessageProcessing(messageFactory);
~~~

The above code composes a `MessageProcessing` instance with either a `Version1ProtocolMessageFactory` or a `Version2ProtocolMessageFactory`, depending on the configuration. 

This example shows something I like calling "encapsulation of rule". The logic inside the factory is actually a rule on how, when and which objects to create. Thus, if we make our factory implement an interface and have other objects depend on this interface, we will be able to switch the rules of object creation without these objects realizing it.

#### Factories can hide some of the created object dependencies (encapsulation of global context)

Let us consider a simple example. We have an application that, again, can process messages. One of the things that is done with those messages is saving them in a database and another is validation. The processing of message is, like in previous examples, handled by a `MessageProcessing` class, which, this time, does not use any factory, but creates the messages based on the frame data itself. let us look at this class:

{lang="csharp"}
~~~
public class MessageProcessing
{
  private DataDestination _database;
  private ValidationRules _validation;
  
  public MessageProcessing(
    DataDestination database,
    ValidationRules validation)
  {
    _database = database;
    _validation = validation;
  } 
  
  public void ApplyTo(MessageData data)
  {
    //note this creation:
    var message = 
      new Message(data, _database, _validation);
    
    message.Vaidate();
    message.Persist();
    
    //... other actions 
  }
}
~~~

There is one noticeable thing about the `MessageProcessing` class. It depends on both `DataDestination` and `ValidationRules` interfaces, but does not use them itself. The only thing it needs those interfaces is to supply them as parameters to the constructor. Thus, the class gets polluted by something that it does not need directly.

We can remove these dependencies by introducing a factory. If we manage to move the creation of the `Message` to the factory, we will be need to pass `DataDestination` and `ValidationRules` to the factory only. The factory may look like this:

{lang="csharp"}
~~~
public class MessageFactory
{
  private DataDestination _database;
  private ValidationRules _validation;
  
  public MessageFactory(
    DataDestination database,
    ValidationRules validation)
  {
    _database = database;
    _validation = validation;
  } 

  public Message CreateFrom(MessageData data)
  {
    return 
      new Message(data, _database, _validation);
  }
}
~~~

Now, note that the creation of messages was moved to the factory, along with the dependencies needed for this. The `MessageProcessing` does not need to take these dependencies anymore, and can stay more true to its real purpose:

{lang="csharp"}
~~~
public class MessageProcessing
{
  private MessageFactory _factory;
  
  //now we depend on the factory only:
  public MessageProcessing(
    MessageFactory factory)
  {
    _factory = factory;
  } 
  
  public void ApplyTo(MessageData data)
  {
    //no need to pass database and validation
    //since they already are inside the factory:
    var message = _factory.CreateFrom(data);
    
    message.Vaidate();
    message.Persist();
    
    //... other actions 
  }
}
~~~

So, instead of `DataDestination` and `ValidationRules` interfaces, the `MessageProcessing` depends only on the factory. This may not sound as a very attractive tradeoff (taking away two dependencies and introducing one), but note that whenever the `MessageFactory` needs another dependency that is like the existing two, the factory is all that will need to change. The `MessageProcessing` will remain untouched and still coupled only to the factory.

The last thing that needs to be said is that not all dependencies can be hidden inside a factory. Note that the factory still needs to receive the `MessageData` from whoever is asking for a `Message`, because the `MessageData` is not available when the factory is created. I call such dependencies a **local context** (because it is different everytime the factory is asked to create something). On the other hand, what a factory accepts through the constructor can be called a **global context** (because it is the same throughout the factory lifetime). Using this terminology, the local context cannot be hidden, but the global context can. Thanks to this, the classes using the factory do not need to know about the global context and can stay cleaner, coupled to less things and more focused.

#### Factories help eliminate redundancy

Redundancy in code means that at least two things need to change for the same reason in the same way[^essentialskills]. Usually it is understood as code duplication, but actually, "conceptual duplication" is a better term. For example, the following two methods are not redundant, even though the code seems duplicated (by the way, the following is not an example of good code, just a simple illustration):

{lang="csharp"}
~~~
public int MetersToCentimeters(int value)
{
  return value*100;
}

public int DollarsToCents(int value)
{
  return value*100;
}
~~~ 

As I said, this is not redundancy, because the two methods represent different concepts. Even if we were to extract "common logic" from the two methods, the only sensible name we could come up with would be something like `MultiplyBy100()` which wouldn't add any value at all.

Note that up to now, we considered three things factories encapsulate about creation of objects:

 1. Type
 2. Rule
 3. Global context

Thus, if factories didn't exist, all these concepts would leak to sorrounding classes (we saw an example when we were talking about encapsulation of global context). Now, as soon as there is more than one class that needs to create instances, these things leak to all of these classes, creating redundancy. In such case, any change to how instances are created would mean a change to all classes needing those instances.

Thankfully, by having a factory - an object that takes care of creating other objects and nothing else, we can reuse the ruleset, the global context and the type-related decisions across many classes without any unnecessary overhead. All we need to do is reference the factory and ask it for an object.

There are more benefits of factories, but I hope I already convinced you that this is a pretty darn beneficial concept for such a reasonably low cost.

Summary
-------------------------

TODO


[^kolskybain]: I got this saying from Amir Kolsky and Scott Bain

[^implementationpatterns]: Kent Beck, Implementation Patterns

[^gofcreationpatterns]: While factory is the most often used, other creational patterns such as builder also fall into this category. Other than this, we may have caches, that usually hold ready to use objects and yields them when requested.

[^encapsulatewhatvaries]: Note that this is an application of Gang of Four guideline: "encapsulate what varies".

[^seemanndi]: For details, check Dependency Injection in .NET by Mark Seemann.

[^essentialskills]: A. Shalloway et al., Essential Skills For The Agile Developer

