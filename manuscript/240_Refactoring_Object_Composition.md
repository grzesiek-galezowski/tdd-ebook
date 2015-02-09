#Refactoring Object Composition

When describing object compositon and Composition Root in particular, I promised to get back to the topic of making the composition root cleaner and more readable.

Before I do this, however, we need to get one important question answered...

## Why bother?

Up to now you have to be sick and tired from reading me stressing how important composability is. Also, I said that in order to reach high composability of a class, it has to be context-independent. To reach this independence, I introduced the principle of separating object use from construction, pushing the construction part away into specialized places. I also said that a lot can be contributed to this quality by making the interfaces and protocols abstract and having as small amount of implementation details there as possible.

All of this has its cost, however. Striving for high context-independence takes away from us the ability to look at a single class and determine its context just by reading its code. Such class is "dumb" about the context it operates in.

On the other hand, the behavior of the application as a whole is important as well. Didn't I say that the goal of composability is to be able to change the behavior of application more easily? But how can we consciously make decision about changing application behavior when we do not understand it? And no longer than a paragraph ago we came to conclusion that just reading a class after class is not enough.

So, where is the overall context that defines the behavior of the application? It is in the composition code - the code that defines the real web of objects that work together as the application.

I assume you barely remember the alarms example I gave you in one of the first chapters of this part of the book to explain changing behavior through composition. Anyway, just to remind you, we ended with a code that looked like this:

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

where the following part of the composition code:

```csharp
new OfficeBuilding(
  new DayNightSwitchedAlarm(
    new SilentAlarm("222-333-444"), 
    new LoudAlarm()
  )
),
```

meant that we are arming an office building with an alarm that calls 222-333-444 when triggered during the day and plays loud sirens when activated during the night. We could read this straight from the composition code, provided we knew what each object adds to the overall composite behavior. So, again, composition of parts describes the behavior of the whole. There is, however, one more thing to note about this piece of code: it describes the behavior without explicitly stating its control flow (`if`, `else`, `for`, etc.). Such description is often called *declarative* - by composing objects, we write *what* we want to achieve without writing *how* to achieve it - the control flow itself is hidden inside the objects. 

Let's sum up these two conclusions with the following statement:

I> The composition code is a declarative description of the overall behavior of our application.

Wow, this is quite a statement, isn't it? But there is another problem with the composition code: readability. Even though the composition *is* the description of the system, it does not read naturally. We want to see the description of behavior, but most of what we see is: new, new new new new... There is a lot of syntactic noise involved, especially in real systems, where composition code is long. Can't we do something about it?

## Refactoring for readability

The declarativeness of composition code goes hand in hand with an approach of defining so called *fluent interfaces*. A fluent interface is an API made with readability and flow-like reading in mind. It is usually declarative and targeted towards specific domain, thus another name: *internal domain specific languages*.

There are some simple patterns for creating such domain-specific language. One of them that can be applied to our situation is called *nested function*[^fowlerdsl]. Let's see how it plays out in practice. We will do this step by step, so there will be a lot of repeated code, but hopefully, you will be able to closely watch the process of improving the readability of composition code.

Ok, Let's see the code again before making any changes to it:

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

Note that we have few places where we create `SilentAlarm`. Let's move creation of these objects into a separate method:

```csharp
public Alarm Calls(string number)
{
  return new SilentAlarm(number);
}
```

This step may look silly, (after all, we are introducing a method wrapping one line), but there is a lot of sense to it. First of all, it lets us reduce the syntax noise - when we need to create a silent alarm, we do not have to say `new` anymore. Another benefit is that we can describe the role a `SilentAlarm` instance plays in our composition (I will explain later why we are doing it using passive voice).

After replacing each invocation of `SilentAlarm` constructor with a call to this method, we get:

```csharp
new SecureArea(
  new OfficeBuilding(
    new DayNightSwitchedAlarm(
      Calls("222-333-444"), 
      new LoudAlarm()
    )
  ),
  new StorageBuilding(
    new HybridAlarm(
      Calls("222-333-444"),
      new LoudAlarm()
    )
  ),
  new GuardsBuilding(
    new HybridAlarm(
      Calls("919"), //police number
      new LoudAlarm()
    )
  )
);
```
Next, let's do the same with `LoudAlarm`, wrapping its creation with a method:

```csharp
public Alarm MakesLoudNoise()
{
  return new LoudAlarm();
}
```

and the composition code after applying this methos looks like this:

```csharp
new SecureArea(
  new OfficeBuilding(
    new DayNightSwitchedAlarm(
      Calls("222-333-444"), 
      MakesLoudNoise()
    )
  ),
  new StorageBuilding(
    new HybridAlarm(
      Calls("222-333-444"),
      MakesLoudNoise()
    )
  ),
  new GuardsBuilding(
    new HybridAlarm(
      Calls("919"), //police number
      MakesLoudNoise()
    )
  )
);
```

Note that we have removed some more `new`s. This is exactly what I meant by "reducing syntax noise".

Now let's focus a bit on this part:

```csharp
  new GuardsBuilding(
    new HybridAlarm(
      Calls("919"), //police number
      MakesLoudNoise()
    )
  )
```

and try to apply the same trick to `HybridAlarm` creation and extract a method that handles the creation. You know, we are always told that class names should be nouns and that's why `HybridAlarm` is named like this. But it does not act well as a description of what the system does. Its real functionality is to trigger both alarms when it is triggered. Thus, should we name the method `TriggersBothAlarms()`? Naah, it's too much noise - we already know it's alarms that we are triggering, so we can leave the "alarms" part out. What about "triggers"? It says what the hybrid alarm does, which might seem good, but when we look at the composition, `Calls()` and `MakesLoudNoise()` already say what is being done. The `HybridAlarm` only says that both of those things happen simultaneously. We could leave `Trigger` if we changed the names of the other methods in the composition to look like this:

```csharp
  new GuardsBuilding(
    TriggersBoth(
      Calling("919"), //police number
      LoudNoise()
    )
  )
```

But that would make the names `Calling()` and `LoudNoise()` out of place without being nested as `TriggersBoth()` arguments. For example, if we wanted to make another building that would only use a loud alarm, the composition would look like this:

```csharp
new OtherBuilding(LoudNoise());
```

or if we wanted to use silent one:

```csharp
new OtherBuilding(Calling("919"));
```

Instead, let's try to name the method wrapping construction of `HybridAlarm` just `Both()`. This way, our composition code is now:

```csharp
new GuardsBuilding(
  Both(
    Calls("919"), //police number
    MakesLoudNoise()
  )
)
```
and the `Both()` method is obviously defined as:

```csharp
public Alarm Both(Alarm alarm1, Alarm alarm2)
{
  return new HybridAlarm(alarm1, alarm2);
}
```

Remember that `HybridAlarm` was also used in the `StorageBuilding` instance composition:

```csharp
new StorageBuilding(
  new HybridAlarm(
    Calls("222-333-444"),
    MakesLoudNoise()
  )
),
```

which now becomes:

```csharp
new StorageBuilding(
  Both(
    Calls("222-333-444"),
    MakesLoudNoise()
  )
),
```


Now the most difficult part - finding a way to make the following piece of code readable:

```csharp
new OfficeBuilding(
  new DayNightSwitchedAlarm(
    Calls("222-333-444"), 
    MakesLoudNoise()
  )
),
```

The difficulty here is that `DayNightSwitchedAlarm` accepts two alarms that are used alternatively. We need to invent a term that:

 1.  Says it's an alternative 
 1.  Says what kind of alternative it is (i.e. that one happens at day, and the other during the night).
 1.  Says which alarm is attached to which condition (silent alarm is used during the day and at night, loud alarm is used)

If we introduce a single name, e.g. `FirstDuringDayAndSecondAtNight()`, it will feel awkward and we will loose the flow. Just look:

```csharp
new OfficeBuilding(
  FirstDuringDayAndSecondAtNight(
    Calls("222-333-444"), 
    MakesLoudNoise()
  )
),
```

We need to find another approach to this situation. There are two approaches we may consider:

### Approach 1: use named parameters

Named parameters are a feature of languages like Python or C#. In short, when we have a method like this:

```csharp
public void DoSomething(int first, int second)
{
  //...
}
```

we can call it like this:

```csharp
DoSomething(first: 12, second: 33);
```

We can use this technique to refactor the creation of `DayNightSwitchedAlarm` into the following method:

```csharp
public Alarm DependingOnTimeOfDay(
    Alarm duringDay, Alarm atNight)
{
  return new DayNightSwitchedAlarm(duringDay, atNight);
} 
```

This lets us write the composition code like this:

```csharp
new OfficeBuilding(
  DependingOnTimeOfDay(
    duringDay: Calls("222-333-444"), 
    atNight: MakesLoudNoise()
  )
),
```

which is quite readable. Now, on to the second approach.

### Approach 2: use method chaining

This approach is better translatable to different languages and can be used e.g. in Java and C++. This time, before I show you the implementation, let's look at the final result we want to achieve:

```csharp
new OfficeBuilding(
  DependingOnTimeOfDay
    .DuringDay(Calls("222-333-444"))
    .AtNight(MakesLoudNoise())
  )
),
```

So as you see, this is very similar, the main difference being that it's more work.

Ok, let's decypher this strange construction:

```csharp
DependingOnTimeOfDay
  .DuringDay(...)
  .AtNight(...)
```

First, `DependingOnTimeOfDay` is a class:

```csharp
public class DependingOnTimeOfDay
{
}
```

which has a static method called `DuringDay()`:

```csharp
public static 
DependingOnTimeOfDay DuringDay(Alarm alarm)
{
  return new DependingOnTimeOfDay(alarm);
}

private DependingOnTimeOfDay(Alarm dayAlarm)
{
  _dayAlarm = dayAlarm;
}
```

Now, this method seems strange, doesn't it? It is a static method that returns an instance of its enclosing class. Also, the private constructor stores the passed alarm inside for later... why?

The mystery resolves itself when we look at another method defined in the `DependingOnTimeOfDay` class:

```csharp
//note: this method is NOT static
public Alarm AtNight(Alarm nightAlarm)
{
  return new DayNightSwitchedAlarm(_dayAlarm, nightAlarm);
}
```

This method is not static and it returns the alarm that we were trying to create. To do so, it uses the first alarm passed through the constructor and the second one passed as its parameter. So if we were to take this construct:

```csharp
DependingOnTimeOfDay
  .DuringDay(dayAlarm)
  .AtNight(nightAlarm)
```

and assign a result of each operation to a separate variable, it would look like this:

```csharp
DependingOnTimeOfDay firstPart 
  = DependingOnTimeOfDay.DuringDay(dayAlarm);
Alarm final alarm = firstPart.AtNight(nightAlarm);
```

Now, we can just chaing these calls and get the result we wanted to:

```csharp
new OfficeBuilding(
  DependingOnTimeOfDay
    .DuringDay(Calls("222-333-444"))
    .AtNight(MakesLoudNoise())
  )
),
```

### Discussion continued

For now, I will assume we have chosen approach 1 because it is simpler.

Our composition code looks like this so far:

```csharp
new SecureArea(
  new OfficeBuilding(
    DependingOnTimeOfDay(
      duringDay: Calls("222-333-444"), 
      atNight: MakesLoudNoise()
    )
  ),
  new StorageBuilding(
    Both(
      Calls("222-333-444"),
      MakesLoudNoise()
    )
  ),
  new GuardsBuilding(
    Both(
      Calls("919"), //police number
      MakesLoudNoise()
    )
  )
);
```

There are few more finishing touches we need to make. First of all, let's try and extract these dial numbers like `222-333-444` into constants. For example, this code:

```csharp
Both(
  Calls("919"), //police number
  MakesLoudNoise()
)
```

becomes

```csharp
Both(
  Calls(Police),
  MakesLoudNoise()
)

```

And the last thing is to hide creation of the following classes: `SecureArea`, `OfficeBuilding`, `StorageBuilding`, `GuardsBuilding` and we have this:

```csharp
SecureAreaContaining(
  OfficeBuildingWithAlarmThat(
    DependingOnTimeOfDay(
      duringDay: Calls(Guards), 
      atNight: MakesLoudNoise()
    )
  ),
  StorageBuildingWithAlarmThat(
    Both(
      Calls(Guards),
      MakesLoudNoise()
    )
  ),
  GuardsBuildingWithAlarmThat(
    Both(
      Calls(Police),
      MakesLoudNoise()
    )
  )
);
```
And here it is: the real, declarative description of our application! The composition reads better than when we started, doesn't it?

## Composition as a language

Written this way, object composition has another important property - it is extensible and can be extended using the same terms that are already used. For example, using the methods we invented to make the composition more readable, we may write something like this:

```csharp
Both(
  Calls(Police),
  MakesLoudNoise()
)
```
but, using the same terms, we may as well write this:

```csharp
Both(
  Both(
    Calls(Police),
    Calls(Security)),
  Both(
    Calls(Boss),
    MakesLoudNoise()))
)
```

Note that we have invented something that has these properties:

 1. Defines some kind of *vocabulary* - in our case, the following "words" are form part of the vocabulary: `Both(), Calls(), MakesLoudNoise(), DependingOnTimeOfDay(), atNight, duringDay, SecureAreaContaining(), GuardsBuildingWithAlarmThat(), OfficeBuildingWithAlarmThat()`. 
 1. Allows combining the words from the vocabulary in certain combinations as which also have a meaning. For example: `Both(Calls(Police), Calls(Guards))` has the meaning of "calls both police and guards when triggered" - thus, this thing we invented allows creating *sentences*.
 1. Although we are quite liberal in defining behaviors for alarms, there are some rule as what can be composed with what (for example, we cannot compose guards building with an office, but each of them can only be composed with alarms). Thus, we can say we have created something that looks like a *grammar*.
 1. The vocabulary is *constrained to the domain* of alarms. On the other hand, it *is more powerful and expressive* as a description of this domain than a combination of `if` statements, `for` loops, variable assignments and other elements of a general-purpose language. 
 1. The sentences written define a behavior of the application - so by writing sentences like this, we still write software!
 
All of these points suggest that we have created a *Domain-Specific Language*[^fowlerdsl], which, by the way, is a *higher level language*. 

## The significance of higher level language

So.. why do we need a higher level language to describe the behavior of our application? After all, expressions, statements, loops and conditions (and objects and polymorphism) are our daily bread and butter. Why invent something that moves us away from this kind of programming into something "domain-specific"?

My main answer is: to deal with more effectively with complexity. 

Complexity might be approximated by a number of decisions our application needs to make. As much as we try, we cannot reduce this number. What can we do when this number grows too large? We have the following choices:

 1. Remove some decisions - might be unacceptable from the business perspective.
 1. Optimize redundant decisions - is about making sure that each decision is made once in the code base - I already showed you some examples how polymorphism can help with that.    
 1. Use 3rd party component or a library - While this is quite easy for "infrastructure" code and utilities, it is very, very hard (impossible?) to find a library that will describe our "domain rules" for us. So if these rules are where the real complexity lies (and often they are), we are still left alone with our problem.
 1. Hide the decisions by programming on higher level of abstraction - this may span a whole range of techniques (one of them being e.g. garbage collection that takes away the decision about when to free memory from us). 

So, as you see, only the last of the above points really helps in reducing complexity. This is where the idea of domain-specific languages falls in. If we carefully refactor our object composition into a set of domain-specific languages (one is often too little), one day we may find that we are adding new features by writing new sentences in these languages in a declarative way rather than adding new imperative code. Thus, if we have a good language and a firm understanding of its vocabulary and grammar, we can program on higher level of abstraction which is more expressive and less complex.

This is very hard - it requires, among others:

 1. A huge discipline across a develoment team.
 1. A sense of direction of how to structure the composition and where to lead the languages as they evolve.
 1. Merciless refactoring.
 1. Some minimal knowledge of language design and experience in doing so. 

Of course, not all parts of the composition make a good material to being structured like a language. Despite these difficulties, I think it's well worth the effort. Programming on higher level of abstraction with declarative code rather than imperative is my hope for writing maintainable and understandable systems. 

## Some useful techniques

In his wonderful book[^fowlerdsl] about creating domain-specific languages, Martin Fowler lists a set of techniques that help achieve "fluency" of syntax. Some of them include:


1.  Factory method & method composition
2.  variadic covering method -- creating collection using variadic parameter method or variadic constructors
3.  variable as terminator
4.  Explaining method (i.e. returns its argument. Use with care)

strive for achieving repeatable patterns - the best gain may be drawn from there.

[^fowlerdsl]: M. Fowler, Domain-Specific Languages, Addison-Wesley 2010.

