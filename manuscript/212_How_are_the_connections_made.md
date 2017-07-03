# How does a sender obtain a reference to a recipient (i.e. how connections are made)?

There are several ways a sender can obtain a reference to a recipient, each of them being useful in certain circumstances. These ways are:

1. Receive as constructor parameter
1. Receive inside a message (i.e. as a method parameter)
1. Receive in response to a message (i.e. as method return value)
1. Receive as a registered observer

Let's take a closer look at what each of them is about and which one to choose in what circumstances.

## Receive as constructor parameter

Two objects can be composed by passing one into a constructor of another:

```csharp
sender = new Sender(recipient);
```

A sender that receives the recipient then saves a reference to it in a private field for later, like this:

```csharp
private Recipient _recipient;

public Sender(Recipient recipient)
{
  _recipient = recipient;
}
```

Starting from this point, the `Sender` may send messages to `Recipient` at will:

```csharp
public void DoSomething()
{
  //... other code

  _recipient.DoSomethingElse();

  //... other code
}
```

### Advantage: "what you hide, you can change"

Composing using constructors has one significant advantage. Let's look again at how `Sender` is created:

```csharp
sender = new Sender(recipient);
```

and at how it's used:

```csharp
sender.DoSomething();
```

Note that only the code that creates a `Sender` needs to be aware of it having an access to a `Recipient`. When it comes to actually invoking a method, this private reference is invisible from outside. Now, remember when I described the principle of separating object use from its construction? If we follow this principle here, we end up with the code that creates a `Sender` being in a totally different place than the code that uses it. Thus, every code that uses a `Sender` will not be aware of it sending messages to a `Recipient` at all. There is a maxim that says: "what you hide, you can change"[^kolskybain] -- in this particular case, if we decide that the `Sender` does not need a `Recipient` to do its job, all we have to change is the composition code to remove the `Recipient`:

```csharp
//no need to pass a reference to Recipient anymore
new Sender();
```

and the code that uses `Sender` doesn't need to change at all -- it still looks the same as before, since it never had the knowledge of `Recipient`:

```csharp
sender.DoSomething();
```

### Communication of intent: required recipient

Another advantage of the constructor approach is that it allows to state explicitly what the required recipients are for a particular sender. For example, a `Sender` accepts a `Recipient` in its constructor:

```csharp
public Sender(Recipient recipient)
{
 //...
}
```

The signature of the constructor makes it explicit that a reference to `Recipient` is required for a `Sender` to work correctly -- the compiler will not allow creating a `Sender` without passing *something* as a `Recipient`[^nullfortrouble].

### Where to apply

Passing into constructor is a great solution in cases we want to compose sender with a recipient permanently (i.e. for the lifetime of a `Sender`). To be able to do this, a `Recipient` must, of course, exist before a `Sender` does. Another less obvious requirement for this composition is that a `Recipient` must be usable at least as long as a `Sender` is usable. A simple example of violating this requirement is this code:

```csharp
sender = new Sender(recipient);

recipient.Dispose(); //but sender is unaware of it
                     //and may still use recipient later:
sender.DoSomething();
```

In this case, when we tell `sender` to `DoSomething()`, it uses a recipient that is already disposed of, which may lead to some nasty bugs.

## Receive inside a message (i.e. as a method parameter)

Another common way of composing objects together is passing one object as a parameter of another object's method call:

```csharp
sender.DoSomethingWithHelpOf(recipient);
```

In such case, the objects are most often composed temporarily, just for the time of execution of this single method:

```csharp
public void DoSomethingWithHelpOf(Recipient recipient)
{
  //... perform some logic

  recipient.HelpMe();

  //... perform some logic
}
```

### Where to apply

Contrary to the constructor approach, where a `Sender` could hide from its user the fact that it needs a `Recipient`, in this case the user of `Sender` is explicitly responsible for supplying a `Recipient`. In other words, there need to be some kind of coupling between the code using `Sender` and a `Recipient`. It may look like this coupling is a disadvantage, but I know of some scenarios where it's actually **required** for code using `Sender` to be able to provide its own `Recipient` -- it allows us to use the same sender with different recipients at different times (most often from different parts of the code):

```csharp
//in one place
sender.DoSomethingWithHelpOf(recipient);

//in another place:
sender.DoSomethingWithHelpOf(anotherRecipient);

//in yet another place:
sender.DoSomethingWithHelpOf(yetAnotherRecipient);
```

If this ability is not required, I strongly prefer the constructor approach as it removes the (then) unnecessary coupling between code using `Sender` and a `Recipient`, giving me more flexibility.

## Receive in response to a message (i.e. as method return value)

This method of composing objects relies on an intermediary object -- often an implementation of a [factory pattern](http://www.netobjectives.com/PatternRepository/index.php?title=TheAbstractFactoryPattern) -- to supply recipients on request. To simplify things, I will use factories in examples presented in this section, although what I tell you is true for some other [creational patterns](http://en.wikipedia.org/wiki/Creational_pattern) as well (also, later in this chapter, I'll cover some aspects of factory pattern in depth).

To be able to ask a factory for recipients, the sender needs to obtain a reference to it first. Typically, a factory is composed with a sender through constructor (an approach I already described). For example:

```csharp
var sender = new Sender(recipientFactory);
```

The factory can then be used by the `Sender` at will to get a hold of new recipients:

```csharp
public class Sender
{
  //...

  public void DoSomething()
  {
    //ask the factory for a recipient:
    var recipient = _recipientFactory.CreateRecipient();

    //use the recipient:
    recipient.DoSomethingElse();
  }
}
```

### Where to apply

I find this kind of composition useful when a new recipient is needed each time `DoSomething()` is called. In this sense it may look much like in case of previously discussed approach of receiving a recipient inside a message. There is one difference, however. Contrary to passing a recipient inside a message, where the code using the `Sender` passed a `Recipient` "from outside" of the `Sender`, in this approach, we rely on a separate object that is used by a `Sender` "from the inside".

To be more clear, let's compare the two approaches. Passing recipient inside a message looks like this:

```csharp
//Sender gets a Recipient from the "outside":
public void DoSomething(Recipient recipient)
{
  recipient.DoSomethingElse();
}
```

and obtaining from factory:

```csharp
//a factory is used "inside" Sender
//to obtain a recipient
public void DoSomething()
{
  var recipient = _factory.CreateRecipient();
  recipient.DoSomethingElse();
}
```

So in the first example, the decision on which `Recipient` is used is made by whoever calls `DoSomething()`. In the factory example, whoever calls `DoSomething()` does not know at all about the `Recipient` and cannot directly influence which `Recipient` is used. The factory makes this decision.

### Factories with parameters

So far, all of the factories we considered had creation methods with empty parameter lists, but this is not a requirement of any sort - I just wanted to make the examples simple, so I left out everything that wasn't helpful in making my point. As the factory remains the decision maker on which `Recipient` is used, it can rely on some external parameters passed to the creation method to help it make the decision.

### Not only factories

Throughout this section, we have used a factory as our role model, but the approach of obtaining a recipient in response to a message is wider than that. Other types of objects that fall into this category include, among others: [repositories](http://martinfowler.com/eaaCatalog/repository.html), [caches](http://en.wikipedia.org/wiki/Cache_(computing)), [builders](http://www.blackwasp.co.uk/Builder.aspx), collections[^collectionsremark]. While they are all important concepts (which you can look up on the web if you like), they are not required to progress through this chapter so I won't go through them now.

## Receive as a registered [observer](http://www.oodesign.com/observer-pattern.html)

This means passing a recipient to an **already created** sender (contrary to passing as constructor parameter where recipient was passed **during** creation) as a parameter of a method that stores the reference for later use. Usually, I meet two kinds of registrations:

1. a "setter" method, where someone registers an observer by calling something like `sender.SetRecipient(recipient)`method. Honestly, even though it's a setter, I don't like naming it according to the convention "setWhatever()" -- after Kent Beck[^implementationpatterns] I find this convention too much implementation-focused instead of purpose-focused. Thus, I pick different names based on what domain concept is modeled by the registration method or what is its purpose. Anyway, this approach allows only one observer and setting another overwrites the previous one.
1. an "addition" method - where someone registers an observer by calling something like `sender.addRecipient(recipient)` - in this approach, a collection of observers needs to be maintained somewhere and the recipient registered as observer is merely added to the collection.

Note that there is one similarity to the "passing inside a message" approach -- in both, a recipient is passed inside a message. The difference is that this time, contrary to "pass inside a message" approach, the passed recipient is not used immediately (and then forgotten), but rather it's remembered (registered) for later use.

I hope I can clear up the confusion with a quick example.

### Example

Suppose we have a temperature sensor that can report its current and historically mean value to whoever subscribes with it. If no one subscribes, the sensor still does its job, because it still has to collect the data for calculating a history-based mean value in case anyone subscribes later.

We may model this behavior by using an observer pattern and allow observers to register in the sensor implementation. If no observer is registered, the values are not reported (in other words, a registered observer is not required for the object to function, but if there is one, it can take advantage of the reports). For this purpose, let's make our sensor depend on an interface called `TemperatureObserver` that could be implemented by various concrete observer classes. The interface declaration looks like this:

```csharp
public interface TemperatureObserver
{
  void NotifyOn(
    Temperature currentValue,
    Temperature meanValue);
}
```

Now we're ready to look at the implementation of the temperature sensor itself and how it uses this `TemperatureObserver` interface. Let's say that the class representing the sensor is called `TemperatureSensor`. Part of its definition could look like this:

```csharp
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
```

As you can see, by default, the sensor reports its values to nowhere (`NullObserver`), which is a safe default value (using a `null` for a default value instead would cause exceptions or force us to put a null check inside the `Run()` method). We have already seen such "null objects"[^nullobject] a few times before (e.g. in the previous chapter, when we introduced the `NoAlarm` class) -- `NullObserver` is just another incarnation of this pattern.

### Registering observers

 Still, we want to be able to supply our own observer one day, when we start caring about the measured and calculated values (the fact that we "started caring" may be indicated to our application e.g. by a network packet or an event from the user interface). This means we need to have a method inside the `TemperatureSensor` class to overwrite this default "do-nothing" observer with a custom one **after** the `TemperatureSensor` instance is created. As I said, I don't like the "SetXYZ()" convention, so I will name the registration method `FromNowOnReportTo()` and make the observer an argument. Here are the relevant parts of the `TemperatureSensor` class:

```csharp
public class TemperatureSensor
{
  private TemperatureObserver _observer
    = new NullObserver(); //ignores reported values

  //... ... ...

  public void FromNowOnReportTo(TemperatureObserver observer)
  {
    _observer = observer;
  }

  //... ... ...
}
```

This allows us to overwrite the current observer with a new one should we ever need to do it. Note that, as I mentioned, this is the place where registration approach differs from the "pass inside a message" approach, where we also received a recipient in a message, but for immediate use. Here, we don't use the recipient (i.e. the observer) when we get it, but instead we save it for later use.

### Communication of intent: optional dependency

Allowing registering recipients after a sender is created is a way of saying: "the recipient is optional -- if you provide one, fine, if not, I will do my work without it". Please, don't use this kind of mechanism for **required** recipients -- these should all be passed through a constructor, making it harder to create invalid objects that are only partially ready to work.  

Let's examine an example of a class that:

* accepts a recipient in its constructor,
* allows registering a recipient as an observer,
* accepts a recipient for a single method invocation

This example is annotated with comments that sum up what these three approaches say:

```csharp
public class Sender
{
  //"I will not work without a Recipient1"
  public Sender(Recipient1 recipient1) {...}

  //"I will do fine without Recipient2 but you
  //can overwrite the default here if you are
  //interested in being notified about something
  //or want to customize my default behavior"
  public void Register(Recipient2 recipient2) {...}

  //"I need a recipient3 only here and you get to choose
  //what object to give me each time you invoke 
  //this method on me"
  public void DoSomethingWith(Recipient3 recipient3) {...}
}
```

### More than one observer

Now, the observer API we just skimmed over gives us the possibility to have a single observer at any given time. When we register a new observer, the reference to the old one is overwritten. This is not really useful in our context, is it? With real sensors, we often want them to report their measurements to multiple places (e.g. we want the measurements printed on screen, saved to database, used as part of more complex calculations). This can be achieved in two ways.

The first way would be to just hold a collection of observers in our sensor, and add to this collection whenever a new observer is registered:

```csharp
private IList<TemperatureObserver> _observers
  = new List<TemperatureObserver>();

public void FromNowOnReportTo(TemperatureObserver observer)
{
  _observers.Add(observer);
}
```

In such case, reporting would mean iterating over the observers list:

```csharp
...
foreach(var observer in _observers)
{
  observer.NotifyOn(currentValue, meanValue);
}
...
```

The approach shown above places the policy for notifying observers inside the sensor. Many times this could be sufficient. Still, the sensor is coupled to the answers to at least the following questions:

* in what order do we notify the observers? In the example above, we notify them in order of registration.
* how do we handle errors (e.g. one of the observers throws an exception) - do we stop notifying further observers, or log an error and continue, or maybe do something else? In the example above, we stop on first observer that throws an exception and rethrow the exception. Maybe it's not the best approach for our case?
* is our notification model synchronous or asynchronous? In the example above, we are using a synchronous `for` loop.

We can gain a bit more flexibility by extracting the notification logic into a separate observer that would receive a notification and pass it to other observers. We can call it "a broadcasting observer". The implementation of such observer could look like this:

```csharp
public class BroadcastingObserver
  : TemperatureObserver,
    TemperatureObservable //I'll explain it in a second
{
  private IList<TemperatureObserver> _observers
    = new List<TemperatureObserver>();

  public void FromNowOnReportTo(TemperatureObserver observer)
  {
    _observers.Add(observer);
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
```

This `BroadcastingObserver` could be instantiated and registered like this:

```csharp
//instantiation:
var broadcastingObserver
  = new BroadcastingObserver();

...
//somewhere else in the code...:
sensor.FromNowOnReportTo(broadcastingObserver);

...
//somewhere else in the code...:
broadcastingObserver.FromNowOnReportTo(
      new DisplayingObserver())
...
//somewhere else in the code...:
broadcastingObserver.FromNowOnReportTo(
      new StoringObserver());
...
//somewhere else in the code...:
broadcastingObserver.FromNowOnReportTo(
      new CalculatingObserver());
```

With this design, the other observers register with the broadcasting observer. However, they don't really need to know who they are registering with - to hide it, I introduced a special interface called `TemperatureObservable`, which has the `FromNowOnReportTo()` method:

```csharp
public interface TemperatureObservable
{
  public void FromNowOnReportTo(TemperatureObserver observer);
}
```

This way, the code that registers an observer does not need to know what the concrete observable object is.

The additional benefit of modeling broadcasting as an observer is that it would allow us to change the broadcasting policy without touching either the sensor code or the other observers. For example, we might replace our `for` loop-based observer with something like `ParallelBroadcastingObserver` that would notify each of its observers asynchronously instead of sequentially. The only think we would need to change is the observer object that's registered with a sensor. So instead of:

```csharp
//instantiation:
var broadcastingObserver
  = new BroadcastingObserver();

...
//somewhere else in the code...:
sensor.FromNowOnReportTo(broadcastingObserver);
```

We would have

```csharp
//instantiation:
var broadcastingObserver
  = new ParallelBroadcastingObserver();

...
//somewhere else in the code...:
sensor.FromNowOnReportTo(broadcastingObserver);
```

and the rest of the code would remain unchanged. This is because the sensor implements:

* `TemperatureObserver` interface, which the sensor depends on,
* `TemperatureObservable` interface which the code that registers the observers depends on.

Anyway, as I said, use registering instances very wisely and only if you specifically need it. Also, if you do use it, evaluate how allowing changing observers at runtime is affecting your multithreading scenarios. This is because a collection of observers might potentially be modified by two threads at the same time.

[^kolskybain]: I got this saying from Amir Kolsky and Scott Bain

[^implementationpatterns]: Kent Beck, Implementation Patterns

[^collectionsremark]: If you never used collections before and you are not a copy-editor, then you are probably reading the wrong book :-)

[^nullobject]: This pattern has a name and the name is... Null Object (surprise!). You can read more on this pattern at http://www.cs.oberlin.edu/~jwalker/nullObjPattern/ and http://www.cs.oberlin.edu/~jwalker/refs/woolf.ps (a little older document)

[^nullfortrouble]: Sure, we could pass a `null` but then we are the ones asking for trouble.
