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

TODO example 


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