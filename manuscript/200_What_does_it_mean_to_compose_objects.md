
Web, messages and protocols
===========================

In the last chapter, we talked a little bit about why composability is
valuable, now let's flesh a little bit of terminology to get more
precise understanding.

So, again, what does it mean to compose objects?
------------------------------------------------

Basically it means that an object has obtained a reference to another
object and is able to invoke methods on it. By being composed together, two
objects form a small system that can be expanded with more objects as
needed. Thus, a bigger object oriented system forms something similar to
a web:

![Web of objects - the circles are the objects and the arrows are methods invocations
from one object on another](images/WebOfObjects.png)

If we take the web metaphor a little bit further, we can note some
similarities to e.g. a TCP/IP network:

1.  An object can send **messages** to other objects (i.e. call methods on them - arrows on the above diagram) via **interfaces**. Each message has a **sender** and at least one **recipient**.
2.  In order to send a message to a recipient, a sender has to acquire an **address** of the recipient, which, in object oriented world, we call a reference (actually, in languages such as C++, references are just that - addresses in memory).
3.  A communication between sender and recipients has to obey certain **protocol**. For example, a sender usually cannot invoke a method passing nulls as all arguments, or should expect an exception if it does so. Don't worry if you do not see the analogy now - I'll follow up with more explanation of this topic later).

## Alarms, again!

Let us try to apply this terminology to an example. Let's say that we have an anti-fire alarm system in an office that, when triggered, makes all lifts go to bottom floor, opens them and then disables them. Among others, the office contains automatic lifts, that contain their own remote control systems and mechanical lifts, that are controlled from the
outside by a special custom-made mechanism.

Let's try to model this behavior in code. As you might have guessed, we will have some objects like alarm, automatic lift and mechanical lift. The alarm will control the lifts when triggered.

First, we do not want the alarm to have to distinguish between an automatic and a mechanical lift - this would only add complexity to alarm system, especially that there are plans to add a third kind of lift - a more modern one, so if we made the alarm aware of the different kinds, we would have to modify it each time a new kind of lift is introduced. Thus, we need a special **interface** (let's call it `Lift`) to communicate with both `AutoLift` and `MechanicalLift` (and `ModernLift` in the future). Through this interface, an alarm will be able to send messages to both types of lifts without having to know the difference between them.

{lang="csharp"}
~~~
public interface Lift
{
  ...
}

public class AutoLift : Lift
{
  ...
}

public class MechanicalLift : Lift
{
  ...
}
~~~

Next, to be able to communicate with specific lifts through the `Lift`
interface, an alarm object has to acquire **"addresses"** of the lift objects
 (i.e. references to them). We can pass them e.g. through a constructor:

{lang="csharp"}
~~~
public class Alarm
{
  private readonly IEnumerable<Lift> _lifts;

  //obtain "addresses" through here
  public Alarm(IEnumerable<Lift> lifts)
  {
    //store the "addresses" for later use
    _lifts = lifts;
  }
}
~~~

Then, the alarm can send three kinds of **messages**: `GoToBottomFloor()`,
`OpenDoor()`, and `DisablePower()` to any of the lifts through the
`Lift` interface:

{lang="csharp"}
~~~
public interface Lift
{
  void GoToBottomFloor();
  void OpenDoor();
  void DisablePower();
}
~~~

and, as a matter of fact, it sends all these messages when triggered. The `Trigger()` method on the alarm looks like this:

{lang="csharp"}
~~~
public void Trigger()
{
  foreach(var lift in _lifts)
  {
    lift.GoToBottomFloor();
    lift.OpenDoor();
    lift.DisablePower();
  }
}
~~~

By the way, note that the order in which the messages are sent **does**
matter. For example, if we disabled the power first, asking the powerless
lift to go anywhere would be impossible. This is a first sign of a **protocol** existing between the `Alarm` and a `Lift`.

In this communication, `Alarm` is a **sender** - it knows what it is sending (controlling lifts), it knows why (because the alarm is triggered), but does not know what exactly are the recipients going to do when they receive the message - it only knows what it **wants** them to do, but does not know **how** they are going to achieve it. The rest is left to objects that implement `Lift` (namely, `AutoLift` and `MechanicalLift`). They are **recipients** - they do not know who they got the message from (unless they are told in the content of the message somehow - but even then they can be cheated), but they know how to react, based on who they are (`AutoLift` has its own way of reacting and `MechanicalLift` has its own), what kind of the message they received (a lift does different thing when asked to go to bottom floor than when it is asked to open its door) and what's the message content (i.e. method arguments - in this simplistic example there are none, actually).

To illustrate that this separation between a sender and a recipient does, in fact, exist, it is sufficient to say that we could even write an implementation of `Lift` interface that would just ignore the messages it got from the `Alarm` (or fake that it did what it was asked for) and the `Alarm` will not even notice. We sometimes say that this is not the `Alarm`'s responsibility.

![Sender, interface, and recipient](images/SenderRecipientMessage.png)

Ok, I hope we got that part straight. Time for some new requirements. It has been decided that whenever any malfunction happens in the lift when it is executing the alarm emergency procedure, the lift object should report this by throwing an exception called `LiftUnoperationalException`. This affects both `Alarm` and implementations of `Lift`:

1.  The `Lift` implementations need to know that when a malfunction
    happens, they should report it by throwing the exception.
2.  The `Alarm` must be ready to handle the exception thrown from lifts
    and act accordingly (e.g. still try to secure other lifts).

Here is an exemplary code of `Alarm` handling the malfunction reports in its `Trigger()` method:

{lang="csharp"}
~~~
public void Trigger()
{
  foreach(var lift in _lifts)
  {
    try
    {
      lift.GoToBottomFloor();
      lift.OpenDoor();
      lift.DisablePower();
    }
    catch(LiftUnoperationalException e)
    {
      report.ThatCannotSecure(lift);
    }
  }
}
~~~

This is a second example of a **protocol** existing between `Alarm` and `Lift` that must be adhered to by both sides.

## Summary

Each of the objects in the web can receive messages and most of them
send messages to other objects. Throughout the next chapters, I will
refer to an object sending a message as **sender** and an object receiving a
message as **recipient**.

For now, it may look unjustified to introduce this metaphor of webs, protocols, interfaces etc. but:

*   This is the way [object oriented programming inventors](http://c2.com/cgi/wiki?AlanKayOnMessaging) have thought about object oriented systems
*   It will prove useful as I explain making connections between objects and achieving strong composability in the next chapters
