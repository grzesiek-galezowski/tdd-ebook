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

TODO the rest

## number of decisions in app is unchanged

 1.  remove unwanted decisions
 1.  optimize redundant decisions (i.e. polymorphism, factories)
 1.  use 3rd party component for some decisions - decisions become someone else's problem, at least as far as code maintenance is concerned
 1.  renegotiate existing decisions (i.e. remove code, not needed features) - removing decisions that bring low business value
 1.  use components/microservices to move away from decisions and focus on single topic
 1.  use metadata/configuration - the decisions go to higher level
 1.  APIs
 1.  CASE tools/modelling tools
 1.  DSL - program on higher level

## Useful patterns

1.  Factory method & method composition
2.  variadic covering method -- creating collection using variadic parameter method or variadic constructors
3.  variable as terminator
4.  Explaining method (i.e. returns its argument. Use with care)

strive for achieving repeatable patterns - the best gain may be drawn from there.

[^fowlerdsl]: M. Fowler, Domain-Specific Languages, Addison-Wesley 2010.

