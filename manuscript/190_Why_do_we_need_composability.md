Why do we need composability?
=============================

It might seem stupid to ask this question here - if you have managed to
stay with me this long, then you're probably motivated enough not to
need a justification? Well, anyway, it's still worth discussing it a
little. Hopefully, you'll learn as much reading this back-to-basics
chapter as I did writing it.

Pre-object oriented approaches
------------------------------

Back in the days of procedural programming, when we wanted to execute a
different code based on some factor, it was usually achieved using an
'if' statement. For example, if our application was in need to be able to use
different kinds of alarms, like a loud alarm (that plays a loud sound)
and a silent alarm (that does not play any sound, but instead silently
contacts the security) interchangeably, then usually, we could achieve this using a piece of code like
the following:

{lang="c"}
~~~
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
~~~

The code queries the alarm kind which is embedded in the alarm structure:

{lang="c"}
~~~
struct Alarm
{
  int kind;
  //other data
};
~~~

and decides what do do based on this kind. Unfortunately, if we wanted to make
a second decision based on the alarm kind, we would need to query for
the alarm kind again. This would mean duplicating the conditional code, just with different set of
actions to perform depending on what kind of alarm we were dealing with:

{lang="c"}
~~~
void disableAlarm(Alarm* alarm)
{
  if(alarm->kind == LOUD_ALARM)
  {
    stopLoudSound(alarm);
  }
  else if(alarm->kind == SILENT_ALARM)
  {
    stopNotfyingPolice(alarm);
  }
}
~~~

Do I have to say why this duplication is bad? Do I hear a "no"? My
apologies then, but I'll tell you anyway. The duplication means that
every time a new kind of alarm is introduced, a developer has to
remember to update both places that contain 'if-else' - the compiler
will not force this. As you are probably aware, in the context of teams,
where one developer picks up work that another left and where, from time to time, people leave to find another job, expecting someone to "remember" to update all the
places where the logic is duplicated is asking for trouble.

So we see that the duplication is bad, but can we do something about it?
To answer this question, let us take a look at the reason it was introduced.
The reason is: We have two things we do with
our alarms: triggering and disabling. In other words, we have a set of questions we want to be able to ask an alarm. Each kind of alarm has a different way of
answering these questions - resulting in having a set of "answers" specific to each alarm kind:

| Alarm Kind          | Triggering                 |     Disabling              |
|---------------------|----------------------------|------------------------|
| Loud Alarm          | `playLoudSound()`     | `notifyPolice()` |
| Silent Alarm          | `stopLoudSound()`     | `stopNotfyingPolice()` | 

So, at least conceptually, as soon as we know the alarm kind, we already
know which set of behaviors (represented as a row in the above table) it needs. 
We could just decide the alarm
kind once and associate the right set of behaviors with the data
structure. Then, we would not have to query the alarm data again as we
did, but instead, we could say: "execute triggering the alarm from the
set of behaviors associated with this alarm, whatever it is".

Unfortunately, procedural programming does not let us bind behaviors
with data. As a matter of fact, the whole paradigm of procedural
programming is about separating behaviors and data! Well, honestly, they
had some answers to those concerns, but they were mostly awkward (for
those of you that still remember C: I'm talking about macros and
function pointers). So, as data and behaviors are separated, we need to
query the data each time we want to pick a behavior based on it. That's
why we have the duplication.

Object oriented programming to the rescue!
------------------------------------------

On the other hand, object oriented programming has for a long time made
available two mechanisms that made what we didn't have in procedural
languages available:

1.  Classes - allow binding behavior together with data
2.  Polymorphism - allows executing behavior without knowing the exact
    class which holds them, but knowing only a set of behaviors that it
    supports. This knowledge was obtained by depending on an abstract
    type which all others inherited from (or implemented - in case of
    interfaces), and which contained the signatures of behaviors each
    inheriting class could provide on its own.

So, in case of our alarms, we could make an interface with the following
signature:

{lang="csharp"}
~~~
public interface Alarm
{
  void Trigger();
  void Disable();
}
~~~

and then make two classes: `LoudAlarm` and `SilentAlarm`, both
implementing the `Alarm` interface. Example for `LoudAlarm`:

{lang="csharp"}
~~~
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
~~~

Now, we can make parts of code use the alarm without having to know its
type, so what we previously had:

{lang="c"}
~~~
if(alarm->kind == LOUD_ALARM)
{
  playLoudSound(alarm);
}
else if(alarm->kind == SILENT_ALARM)
{
  notifyPolice(alarm);
}
~~~

becomes just:

{lang="csharp"}
~~~
alarm.Trigger();
~~~~

where `alarm` is either `LoudAlarm` or `SilentAlarm`, but seen
polymorphically as `Alarm`, so there's no need for 'if-else' anymore.
But hey, isn't this cheating? Even provided I can execute a the trigger
behavior on the alarm without knowing the actual class of the alarm, I
still have to decide which class instance to create somewhere, so it
looks like I am not eliminating the 'else-if' after all, just moving it
somewhere else! This is true, but the good news is that I eliminated the
duplication by making our dream of picking the right set of behaviors to
use with certain data once.

Thanks to this, I create the alarm once, and then I can take it and pass
it to ten, a hundred or a thousand different places where I will not
have to determine the alarm kind anymore to use it correctly.

This allows writing a lot of classes that have no knowledge whatsoever
about the real class of the alarm they are dealing with, yet are able to
use the alarm just fine only by knowing a common abstract type -
`Alarm`. If we are able to do that, we arrive at a situation where we
can add more alarms implementing `Alarm` and watch already existing
objects that are using `Alarm` work with these new alarms without any
change in their source code! There is one condition, however - the
creation of the alarm instances must be moved out of of these objects.
That's because to create an alarm using a `new` operator, an object must
know the exact type of the alarm it is creating, losing its uniformity,
because it would not be able to depend solely on the `Alarm` interface.

The power of composition
------------------------

Moving creation of alarm instances away from the classes that use those
alarms brings up an interesting problem - if an object does not create
its own dependencies, then who does it? I have cleverly avoided
answering this question so far, so let's tackle this issue now. A
solution is to make some special place in the code that assembles a
system from loosely coupled objects. We saw this already as Johnny was
explaining composability to Benjamin. He used the following example:

{lang="csharp"}
~~~
new SqlRepository(
  new ConnectionString("..."), 
  new AccessPrivileges(
    new Role("Admin"), 
    new Role("Auditor")
  ),
  new InMemoryCache()
);
~~~

We can do the same with our alarms. Let's say that we have a secure area
that has three buildings with different alarm policies:

-   Office building - the alarm should be silent during the day (to keep
    office staff from panicking) and loud in the night, when guards are
    on patrol.
-   Storage building - as it is quite far and the workers are few, we
    want to trigger loud and silent alarms at the same time
-   Guards building - as the guards are there, no need to notify them
    with silent alarm, but a loud alarm is desired

The composition of objects fulfilling these needs could look like this:

{lang="csharp"}
~~~
new SecureArea(
  new OfficeBuilding(
    new DayNightSwitchedAlarm(
      new SilentAlarm(), 
      new LoudAlarm()
    )
  ),
  new StorageBuilding(
    new HybridAlarm(
      new SilentAlarm(),
      new LoudAlarm()
    )
  ),
  new GuardsBuilding(
    new LoudAlarm()
  )
);
~~~

The parts I would like to turn your attention to are: `HybridAlarm` and
`DayNightSwitchedAlarm`. These are both classes implementing the `Alarm`
interface, at the same time taking `Alarm` implementations as their
constructor arguments. For example, `DayNightSwitchedAlarm` uses
different alarm during the day and another during the night. Note that
this allows us to change the alarm behaviors in many interesting ways
using the parts we already have, but composing them together
differently. For example, we might have, as in the above example:

{lang="csharp"}
~~~
new DayNightSwitchAlarm(
  new SilentAlarm(), 
  new LoudAlarm());
~~~

which would mean triggering silent alarm during a day and loud one
during night. However, instead of this combination, we might use:

{lang="csharp"}
~~~
new DayNightSwitchAlarm(
  new SilentAlarm(),
  new HybridAlarm(
    new SilentAlarm(),
    new LoudAlarm()
  )
)
~~~

Which would mean that we use silent alarm during the day, but a
combination of silent and loud during the night.

Additionally, if we suddenly decided that we do not want alarm at all
during the day, we could use a special class called `NoAlarm` that would
implement `Alarm` interface, but have both `Trigger` and `Disable`
methods do nothing. The composition code would look like this:

{lang="csharp"}
~~~
new DayNightSwitchAlarm(
  new NoAlarm(), // no alarm during day
  new HybridAlarm(
    new SilentAlarm(),
    new LoudAlarm()
  )
)
~~~

And, last but not least, we could completely remove all alarms from the
guards building using the following code:

{lang="csharp"}
~~~
new GuardsBuilding(
  new NoAlarm()
)
~~~

Noticed something funny about the last few examples? If not, here goes an explanation:
in the last few examples, we have twisted the behaviors of our application in wacky ways, but all
of this took place in the composition code! We did not have to modify
any other existing classes! True, we had to write a new class called
`NoAlarm`, but did not need to modify any other code than the
composition code to make objects if this new class work with objects of existing classes!

This ability to change the behavior of our application just by changing
the way objects are composed together is extremely powerful (although
you will always be able to achieve it only to certain extent),
especially in evolutionary, incremental design, where we want to evolve
some pieces of code with as little as possible other pieces of code
having to realize that the evolution takes place..

Summary - are you still with me?
--------------------------------

Although we started with what seemed to be a repetition from basic
object oriented programming class, using a basic example. It was
necessary though to make a fluent transition to the benefits of
composability we eventually introduced at the end. I hope you did not
get overwhelmed and can understand now why I am putting so much stress
on composability.

In the next chapter, we will take a closer look at composing objects
itself.
