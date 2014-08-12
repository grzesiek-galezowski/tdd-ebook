Composing a web of objects
==========================

Three important questions
-------------------------

łódź

Ok, I told you that such a thing as a web of objects exists, that there are connections, protocols and such, but there is one thing I left out: how does a web of objects come into existence?

This is, of course, a fundamental question, because if we are not able to build a web, we do not have a web. In addition, this is a question that is a little more tricky that you may think and it contains three other questions that we need to answer:

1.  How does an object obtain a reference to another one in the web (i.e. how a connection is made)?
2.  When are objects composed (i.e. when a connection is made)?
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

1.  How does an object (`Sender`) obtain a reference to another one 
(`Recipient`)? Answer: the reference is passed through constructor.
2.  When are objects composed? Answer: during application startup.
3.  Where are objects composed? Answer: at application entry point (`Main()` 
method)

Depending on circumstances, we have different sets of best answers to these 
questions. To find them, let us take the questions on one by one.

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
  private Temperature _meanValue = Temperature.Zero();
  
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

TODO make below a side note

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

Now, the observer API we just skimmed over gives us the possibility to
have a single observer at any given time. When we register new observer,
the reference to the old one is overwritten. This is not really useful 
in our context, is it? With real sensors, we often want them to report 
their measurements to multiple places (e.g. we want the measurements 
printed on screen, saved to database, used as part of more complex 
calculations). This can be achieved in two ways.

The first way would be to just hold a collection of observers in our 
sensor, and add to this collection whenever a new observer is registered:

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

Ok, we went through some ways of passing a recipient to a sender. The big 
question is: which code should pass the recipient?

For almost all of the approaches described above there is no 
limitation - you pass the recipient from where you need to pass it.

There is one approach, however, that is more limited, and this approach 
is **passing as constructor parameter**.

Why is that? Well, remember we were talking about separating objects 
usage from construction, right? And invoking constructor 
implies creating an object, right? Which means that we can assemble 
objects using constructors only in the places where we moved the creation of 
the objects to.

Typically, there are two such types of places: **composition root** and 
**factories** (or other creational design pattern incarnations). Let's start with the first one.

### Composition Root

A composition root is a location near application entry point where 
you compose the part of the system on which you invoke your `Run()`, 
`Execute()`,  `Go()` or whatever, i.e. the part of the web that is necessary for the application to start running.

For simplification, let's take an example of a console application. 
In such case, your application usually has some kind of a single top-level class that serves as a starting point. In this example, I called it `MyApplication`:

{lang="csharp"}
~~~
public static void Main(string[] args)
{
  var myApplication = new MyApplication();
  myApplication.Run();
}
~~~

The above is a simple composition root.

TODO

### Factories

Factories are objects responsible for creating other objects. They are a level of indirection placed above constructors to achieve flexibility (as you will see in the examples in this section). 

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

Although in this shape, the usefulness of the factory is quite limited, because there is not much indirection in here. More often, when talking about simple factories, we think about something like this:

{lang="csharp"}
~~~
//let's assume MessageFactory 
//and Message are interfaces
public class XmlMessageFactory : MessageFactory
{
  public Message CreateSessionInitialization()
  {
    return new XmlSessionInitialization(_serialization);
  }
}
~~~

Note the two things that the factory in the second example has that the one in the first example does not:

* it implements an interface (one level of indirection)
* its `CreateSessionInitialization()` method declares a return type to be an interface (another level of indirection)

In order for you to use factories effectively, I need you to understand why this indirection is useful, especially that when I talk with people, they often do not understand the benefits of using factories, "because we already have the `new` operator to create objects". So, here are the benefits of using factories:

#### Factories allow creating objects polymorphically (encapsulation of type)

When we invoke a `new` operator, we have to put a name of a concrete type next to it:

{lang="csharp"}
~~~
new List<int>(); //OK!
new IList<int>(); //won't compile...
~~~

Factories are different. Because we get objects from factories by invoking a method, not by saying which class we want to get instantiated, we can take advantage of polymorhism, i.e. our factory may have a method like this:

{lang="csharp"}
~~~
IList<int> createContainerForData() {...}
~~~

and everything is well as long as the code of this method returns an instance of a real class (say, `List<int>`).

It is typical for a return type of a factory to be an interface or, at worst, an abstract class. This means that whatever uses the factory, it knows only 
that it receives an object of that type. This means that a factory may return objects of different types at different times, depending on some rules only they know.

Time to look at some more realistic example of how to apply this. Let's say we have a factory of messages like this:

{lang="csharp"}
~~~
public class Version1ProtocolMessageFactory 
  : MessageFactory
{
  public Message createFrom(MessageData rawData)
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
        throw new UnknownMessage(rawData);
    }
  }
}
~~~

Note that the factory can create many different types of messages 
depending on what is inside the raw data, but for the user of the factory, 
this is irrelevant. All that it knows is that it gets a `Message`, thus, it (and additional code operating on messages for that matter) can be written as general-purpose logic:

{lang="csharp"}
~~~
var message = _messageFactory.NewInstanceFrom(rawData);
message.ValidateUsing(_primitiveValidations);
message.ApplyTo(_sessions);
~~~

Note that while the above code needs to change when the rule "first validate, then apply to sessions" changes, it does not need to change when all we do is adding new type of message that complies with the current logic. The only place we need to change in such case is the factory: 

~~~
public class Version1ProtocolMessageFactory
  : MessageFactory
{
  public Message createFrom(MessageData rawData)
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
        throw new UnknownMessage(rawData);
    }
  }
}
~~~

This makes maintaining code easier, because there is less code to change when adding new types of messages to the system or removing existing ones (e.g. in case when we do not need to initiate a session anymore) [^encapsulatewhatvaries].

#### Factories are themselves polymorphic (encapsulation of rule)

So far, I keep talking about composability over and over again so much 
that you're probably already sick of the word. But hey, here comes 
another benefit of the factory - in contrast to constructors, they are 
composable.

We may have a class that uses a factory:

{lang="csharp"}
~~~
public class MessageInbound
{
  private MessageFactory _factory;
  
  public MessageInbound(MessageFactory factory)
  {
    _factory = factory;
  }
  
  public void Process(MessageData data)
  {
    Message message = _factory.NewMessageFrom(data);
    message.ValidateUsing(_primitiveValidations);
    message.ApplyTo(_system);
  }
}
~~~

Object of this class needs to be composed with factory implementing 
the `MessageFactory` interface in a composition root like this:

{lang="csharp"}
~~~
new MessageInbound(new BinaryMessageFactory());
~~~

Suppose that one day we need to reuse the logic of `MessageInbound` in 
another place, but make it create XML messages instead of binary 
messages. If we used a constructor to create messages, we would need 
to either copy-paste the `MessageInbound` class code and change the 
line where message is created, or we would need to make an `if` 
statement inside the `MessageInbound` to choose which message we are 
required to create.

This is not reuse - this is hacking.

Thankfully, thanks to the factory, we can use the `MessageInbound` 
just as it is, but compose it with a different factory. So, we will 
have to instances of `MessageInbound` class in our composition root:

{lang="csharp"}
~~~
var binaryMessageInbound
  = new MessageInbound(
      new BinaryMessageFactory(), 
      BinListenAddress); 

var xmlMessageInbound
  = new MessageInbound(
      new XmlMessageFactory(), 
      XmlListenAddress);
~~~

TODO make each a subchapter of L4

1.  They allow creating objects polymorphically (hiding of 
created type):
1.  They are themselves polymorphic (hiding of object creation rule)
1.  They allow putting more complex creation logic in one place 
(reduce redundancy)
1.  They allow decoupling from some of the dependencies of created 
objects (lower coupling)
1.  They allow naming rulesets for object creation (better readability)

#### They allow to hide some of the constructor parameters from their users (encapsulation of dependencies)

When are objects composed?
--------------------------

Most of our system is assembled up-front when the application
starts and stays this way until the application finishes executing. But 
not all of it. Let's call this part the static part of the web. We 
will talk about **composition root** pattern that guides definition of 
that part.

Apart from that, there's the dynamic part. The first thing that leads 
to this dynamism is the lifetime of the objects that are connected. 
Some objects represent requests that arrive during the application 
runtime, are processed and then discarded. When there is no need to 
process such a request anymore, the objects representing it are 
discarded as well. Other objects represent items in the cache that live 
for some time and then expire etc. so it's impossible to define these 
objects up-front. Soon, we will talk about the **Factory** pattern that 
will let us handle creation and composition of such short-lived objects.

Another thing affecting the dynamic part of the web is the temporary 
character of connections themselves. The objects may have a lifespan 
as long as the application itself, but be connected only the needs of a 
single interaction (e.g. when one object is passed to a method of 
another as an argument) or at some point during the application 
runtime. We will talk about doing these things by passing objects 
inside messages and by using the **Observer** pattern.

Where are objects composed?
---------------------------

First, let's take a look at different ways of acquiring an object by
another object:


Now that we discussed how to pass a reference to recipient into a
sender, let's take a look at places it can be done:

TODO factory and composition root


[^kolskybain]: I got this saying from Amir Kolsky and Scott Bain

[^implementationpatterns]: Kent Beck, Implementation Patterns

[^gofcreationpatterns]: While factory is the most often used, other creational patterns such as builder also fall into this category. Other than this, we may have caches, that usually hold ready to use objects and yields them when requested.

[^encapsulatewhatvaries] Note that this is an application of Gang of Four guideline: "encapsulate what varies"


