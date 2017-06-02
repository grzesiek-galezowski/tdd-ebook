# Why do we need composability?

It might seem stupid to ask this question here -- if you have managed to stay with me this long, then you're probably motivated enough not to need a justification? Well, anyway, it's still worth discussing it a little. Hopefully, you'll learn as much reading this back-to-basics chapter as I did writing it.

## Pre-object-oriented approaches

Back in the days of procedural programming[^skipfunc], when we wanted to execute a different code based on some factor, it was usually achieved using an 'if' statement. For example, if our application was in need to be able to use different kinds of alarms, like a loud alarm (that plays a loud sound) and a silent alarm (that does not play any sound, but instead silently contacts the police) interchangeably, then usually, we could achieve this using a conditional like in the following function:

```c
void triggerAlarm(Alarm* alarm)
{
  if(alarm->kind == LOUD_ALARM)
  {
    playLoudSound(alarm);
  }
  else if(alarm->kind == SILENT_ALARM)
  {
    notifyPolice(alarm);
  }
}
```

The code above makes decision based on the alarm kind which is embedded in the alarm structure:

```c
struct Alarm
{
  int kind;
  //other data
};
```

If the alarm kind is the loud one, it executes behavior associated with loud alarm. If this is a silent alarm, the behavior for silent alarms is executed. This seems to work. Unfortunately, if we wanted to make a second decision based on the alarm kind (e.g. we needed to disable the alarm), we would need to query the alarm kind again. This would mean duplicating the conditional code, just with a different set of actions to perform, depending on what kind of alarm we were dealing with:

```c
void disableAlarm(Alarm* alarm)
{
  if(alarm->kind == LOUD_ALARM)
  {
    stopLoudSound(alarm);
  }
  else if(alarm->kind == SILENT_ALARM)
  {
    stopNotifyingPolice(alarm);
  }
}
```

Do I have to say why this duplication is bad? Do I hear a "no"? My apologies then, but I'll tell you anyway. The duplication means that every time a new kind of alarm is introduced, a developer has to remember to update both places that contain 'if-else' -- the compiler will not force this. As you are probably aware, in the context of teams, where one developer picks up work that another left and where, from time to time, people leave to find another job, expecting someone to "remember" to update all the places where the logic is duplicated is asking for trouble.

So, we see that the duplication is bad, but can we do something about it? To answer this question, let's take a look at the reason the duplication was introduced. And the reason is: We have two things we want to be able to do with our alarms: triggering and disabling. In other words, we have a set of questions we want to be able to ask an alarm. Each kind of alarm has a different way of answering these questions -- resulting in having a set of "answers" specific to each alarm kind:

| Alarm Kind          | Triggering                 |     Disabling              |
|---------------------|----------------------------|------------------------|
| Loud Alarm          | `playLoudSound()`     | `stopLoudSound()` |
| Silent Alarm          | `notifyPolice()`     | `stopNotifyingPolice()` | 

So, at least conceptually, as soon as we know the alarm kind, we already know which set of behaviors (represented as a row in the above table) it needs. We could just decide the alarm kind once and associate the right set of behaviors with the data structure. Then, we would not have to query the alarm kind in few places as we did, but instead, we could say: "execute triggering behavior from the set of behaviors associated with this alarm, whatever it is".

Unfortunately, procedural programming does not let's bind behaviors with data. As a matter of fact, the whole paradigm of procedural programming is about separating behaviors and data! Well, honestly, they had some answers to those concerns, but these answers were mostly awkward (for those of you that still remember C language: I'm talking about macros and function pointers). So, as data and behaviors are separated, we need to query the data each time we want to pick a behavior based on it. That's why we have the duplication.

## Object-oriented programming to the rescue!

On the other hand, object-oriented programming has for a long time made available two mechanisms that enable what we didn't have in procedural languages:

1. Classes -- that allow binding behavior together with data.
1. Polymorphism -- allows executing behavior without knowing the exact class that holds them, but knowing only a set of behaviors that it supports. This knowledge is obtained by having an abstract type (interface or an abstract class) define this set of behaviors, with no real implementation. Then we can make other classes that provide their own implementation of the behaviors that are declared to be supported by the abstract type. Finally, we can use the instances of those classes where an instance of the abstract type is expected. In case of statically-typed languages, this requires implementing an interface or inheriting from an abstract class.

So, in case of our alarms, we could make an interface with the following
signature:

```csharp
public interface Alarm
{
  void Trigger();
  void Disable();
}
```

and then make two classes: `LoudAlarm` and `SilentAlarm`, both implementing the `Alarm` interface. Example for `LoudAlarm`:

```csharp
public class LoudAlarm : Alarm
{
  public void Trigger()
  {
    //play very loud sound
  }

  public void Disable()
  {
    //stop playing the sound
  }
}
```

Now, we can make parts of code use the alarm, but by knowing the interface only instead of the concrete classes. This makes the parts of the code that use alarm this way not having to check which alarm they are dealing with. Thus, what previously looked like this:

```c
if(alarm->kind == LOUD_ALARM)
{
  playLoudSound(alarm);
}
else if(alarm->kind == SILENT_ALARM)
{
  notifyPolice(alarm);
}
```

becomes just:

```csharp
alarm.Trigger();
```

where `alarm` is either `LoudAlarm` or `SilentAlarm`, but seen polymorphically as `Alarm`, so there's no need for 'if-else' anymore.

But hey, isn't this cheating? Even provided I can execute the trigger behavior on an alarm without knowing the actual class of the alarm, I still have to decide which class it is in the place where I create the actual instance:

```csharp
// we must know the exact type here:
alarm = new LoudAlarm(); 
```

so it looks like I am not eliminating the 'else-if' after all, just moving it somewhere else! This may be true (we will talk more about it in future chapters), but the good news is that I eliminated at least the duplication by making our dream of "picking the right set of behaviors to use with certain data once" come true.

Thanks to this, I create the alarm once, and then I can take it and pass it to ten, a hundred or a thousand different places where I will not have to determine the alarm kind anymore to use it correctly.

This allows writing a lot of classes that have no knowledge whatsoever about the real class of the alarm they are dealing with, yet are able to use the alarm just fine only by knowing a common abstract type -- `Alarm`. If we are able to do that, we arrive at a situation where we can add more alarms implementing `Alarm` and watch existing objects that are already using `Alarm` work with these new alarms without any change in their source code! There is one condition, however -- the **creation of the alarm instances must be moved out of the classes that use them**. That's because, as we already observed, to create an alarm using a `new` operator, we have to know the exact type of the alarm we are creating. So whoever creates an instance of `LoudAlarm` or `SilentAlarm`, loses its uniformity, since it is not able to depend solely on the `Alarm` interface.

## The power of composition

Moving creation of alarm instances away from the classes that use those alarms brings up an interesting problem -- if an object does not create the objects it uses, then who does it? A solution is to make some special places in the code that are only responsible for composing a system from context-independent objects[^moreonindependence]. We saw this already as Johnny was explaining composability to Benjamin. He used the following example:

```csharp
new SqlRepository(
  new ConnectionString("..."), 
  new AccessPrivileges(
    new Role("Admin"), 
    new Role("Auditor")
  ),
  new InMemoryCache()
);
```

We can do the same with our alarms. Let's say that we have a secure area that has three buildings with different alarm policies:

- Office building -- the alarm should silently notify guards during the day (to keep office staff from panicking) and loud during the night, when guards are on patrol.
- Storage building -- as it is quite far and the workers are few, we want to trigger loud and silent alarms at the same time.
- Guards building -- as the guards are there, no need to notify them. However, a silent alarm should call police for help instead, and a loud alarm is desired as well.

Note that besides just triggering loud or silent alarm, we have a requirement for a combination ("loud and silent alarms at the same time") and a conditional ("silent during the day and loud during the night"). we could just hardcode some `for`s and `if-else`s in our code, but instead, let's factor out these two operations (combination and choice) into separate classes implementing the alarm interface.

Let's call the class implementing the choice between two alarms `DayNightSwitchedAlarm`. Here is the source code:

```csharp
public class DayNightSwitchedAlarm : Alarm
{
  private readonly Alarm _dayAlarm;
  private readonly Alarm _nightAlarm;

  public DayNightSwitchedAlarm(
    Alarm dayAlarm,
    Alarm nightAlarm)
  {
    _dayAlarm = dayAlarm;
    _nightAlarm = nightAlarm;
  }

  public void Trigger()
  {
    if(/* is day */)
    {
      _dayAlarm.Trigger();
    }
    else
    {
      _nightAlarm.Trigger();
    }
  }

  public void Disable()
  {
    _dayAlarm.Disable();
    _nightAlarm.Disable();
  }
}
```

Studying the above code, it is apparent that this is not an alarm *per se*, e.g. it does not raise any sound or notification, but rather, it contains some rules on how to use other alarms. This is the same concept as power splitters in real life, which act as electric devices but do not do anything other than redirecting the electricity to other devices. 

Next, let's use the same approach and model the combination of two alarms as a class called `HybridAlarm`. Here is the source code:

```csharp
public class HybridAlarm : Alarm
{
  private readonly Alarm _alarm1;
  private readonly Alarm _alarm2;

  public HybridAlarm(
    Alarm alarm1,
    Alarm alarm2)
  {
    _alarm1 = alarm1;
    _alarm2 = alarm2;
  }

  public void Trigger()
  {
    _alarm1.Trigger();
    _alarm2.Trigger();
  }

  public void Disable()
  {
    _alarm1.Disable();
    _alarm2.Disable();
  }
}
```

Using these two classes along with already existing alarms, we can implement the requirements by composing instances of those classes like this:

```csharp
new SecureArea(
  new OfficeBuilding(
    new DayNightSwitchedAlarm(
      new SilentAlarm("222-333-444"), 
      new LoudAlarm()
    )
  ),
  new StorageBuilding(
    new HybridAlarm(
      new SilentAlarm("222-333-444"),
      new LoudAlarm()
    )
  ),
  new GuardsBuilding(
    new HybridAlarm(
      new SilentAlarm("919"), //call police
      new LoudAlarm()
    )
  )
);
```

Note that the fact that we implemented combination and choice of alarms as separate objects implementing the `Alarm` interface allows us to define new, interesting alarm behaviors using the parts we already have, but composing them together differently. For example, we might have, as in the above example:

```csharp
new DayNightSwitchAlarm(
  new SilentAlarm("222-333-444"), 
  new LoudAlarm());
```

which would mean triggering silent alarm during a day and loud one
during night. However, instead of this combination, we might use:

```csharp
new DayNightSwitchAlarm(
  new SilentAlarm("222-333-444"),
  new HybridAlarm(
    new SilentAlarm("919"),
    new LoudAlarm()
  )
)
```

Which would mean that we use silent alarm to notify the guards during the day, but a combination of silent (notifying police) and loud during the night. Of course, we are not limited to combining a silent alarm with a loud one only. We can as well combine two silent ones:

```csharp
new HybridAlarm(
  new SilentAlarm("919"),
  new SilentAlarm("222-333-444")
)
```

Additionally, if we suddenly decided that we do not want alarm at all during the day, we could use a special class called `NoAlarm` that would implement `Alarm` interface, but have both `Trigger` and `Disable` methods do nothing. The composition code would look like this:

```csharp
new DayNightSwitchAlarm(
  new NoAlarm(), // no alarm during the day
  new HybridAlarm(
    new SilentAlarm("919"),
    new LoudAlarm()
  )
)
```

And, last but not least, we could completely remove all alarms from the guards building using the following `NoAlarm` class (which is also an `Alarm`):

```csharp
public class NoAlarm : Alarm
{
  public void Trigger()
  {
  }

  public void Disable()
  {
  }
}
```

and passing it as the alarm to guards building:

```csharp
new GuardsBuilding(
  new NoAlarm()
)
```

Noticed something funny about the last few examples? If not, here goes an explanation: in the last few examples, we have twisted the behaviors of our application in wacky ways, but all of this took place in the composition code! We did not have to modify any other existing classes! True, we had to write a new class called `NoAlarm`, but did not need to modify any other code than the composition code to make objects of this new class work with objects of existing classes!

This ability to change the behavior of our application just by changing the way objects are composed together is extremely powerful (although you will always be able to achieve it only to certain extent), especially in evolutionary, incremental design, where we want to evolve some pieces of code with as little as possible other pieces of code having to realize that the evolution takes place. This ability can be achieved only if our system consists of composable objects, thus the need for composability -- an answer to a question raised at the beginning of this chapter.

## Summary -- are you still with me?

We started with what seemed to be a repetition from basic object-oriented programming course, using a basic example. It was necessary though to make a fluent transition to the benefits of composability we eventually introduced at the end. I hope you did not get overwhelmed and can understand now why I am putting so much stress on composability.

In the next chapter, we will take a closer look at composing objects itself.

[^skipfunc]: I am simplifying the discussion on purpose, leaving out e.g. functional languages and assuming that "pre-object-oriented" means procedural or structural. While this is not true in general, this is how the reality looked like for many of us. If you are good at functional programming, you already understand the benefits of composability.

[^moreonindependence]: More on context-independence and what these "special places" are, in the next chapters.
