# Object Composition as a Language

While most of the earlier chapters talked a lot about viewing object composition as a web, this one will take a different view -- one of a language. These two views are remarkably similar in nature and complement each other in guiding design.

It might surprise you that I am comparing object composition to a language, but, as I hope you'll see, there are many similarities. Don't worry, we'll get there step by step, the first step being taking a second look at the composition root. 

## More readable composition root

When describing object compositon and composition root in particular, I promised to get back to the topic of making the composition code cleaner and more readable.

Before I do this, however, we need to get one important question answered...

### Why bother?

By now you have to be sick and tired of how I stress the importance of composability. I do so, however, because I believe it is one of the most important aspect of well-designed classes. Also, I said that to reach high composability of a class, it has to be context-independent. To explain how to reach this independence, I introduced the principle of separating object use from construction, pushing the construction part away into specialized places in code. I also said that a lot can be contributed to this quality by making the interfaces and protocols abstract and having them expose as small amount of implementation details as possible.

All of this has its cost, however. Striving for high context-independence takes away from us the ability to look at a single class and determine its context just by reading its code. Such class knows very little about the context it operates in. For example, few chapters back we dealt with dumping sessions and I showed you that such dump method may be implemented like this:

```csharp
public class RealSession : Session
{
  //...

  public void DumpInto(Destination destination)
  {
    destination.AcceptOwner(this.owner);
    destination.AcceptTarget(this.target);
    destination.AcceptExpiryTime(this.expiryTime);
    destination.Done();
  }

  //...
}
```

Here, the session knows that whatever the destination is, `Destination` it accepts owner, target and expiry time and needs to be told when all information is passed to it. Still, reading this code, we cannot tell where the destination leads to, since `Destination` is an interface that abstracts away the details.  It is a role that can be played by a file, a network connection, a console screen or a GUI widget. Context-independence enables composability.

On the other hand, as much as context-independent classes and interfaces are important, the behavior of the application as a whole is important as well. Didn't I say that the goal of composability is to be able to change the behavior of application more easily? But how can we consciously make decision about changing application behavior when we do not understand it? And no longer than a paragraph ago we came to conclusion that just reading a class after class is not enough. We have to have a view of how these classes work together as a system. So, where is the overall context that defines the behavior of the application? 

The context is in the composition code -- the code that connects objects together, passing a real collaborators to each object and showing the connected parts make a whole.

### Example

I assume you barely remember the alarms example I gave you in one of the first chapters of this part of the book to explain changing behavior by changing object composition. Anyway, just to remind you, we ended with a code that looked like this:

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

So we had three buildings all armed with alarms. The nice property of this code was that we could read the alarm setups from it, e.g. the following part of the composition:

```csharp
new OfficeBuilding(
  new DayNightSwitchedAlarm(
    new SilentAlarm("222-333-444"), 
    new LoudAlarm()
  )
),
```

meant that we were arming an office building with an alarm that calls number `222-333-444` when triggered during the day, but plays loud sirens when activated during the night. We could read this straight from the composition code, provided we knew what each object added to the overall composite behavior. So, again, composition of parts describes the behavior of the whole. There is, however, one more thing to note about this piece of code: it describes the behavior without explicitly stating its control flow (`if`, `else`, `for`, etc.). Such description is often called *declarative* -- by composing objects, we write *what* we want to achieve without writing *how* to achieve it -- the control flow itself is hidden inside the objects. 

Let's sum up these two conclusions with the following statement:

I> The composition code is a declarative description of the overall behavior of our application.

Wow, this is quite a statement, isn't it? But, as we already noticed, it is true. There is, however, one problem with treating the composition code as overall application description: readability. Even though the composition *is* the description of the system, it doesn't read naturally. We want to see the description of behavior, but most of what we see is: `new`, `new`, `new`, `new`, `new`... There is a lot of syntactic noise involved, especially in real systems, where composition code is much longer than this tiny example. Can't we do something about it?

## Refactoring for readability

The declarativeness of composition code goes hand in hand with an approach of defining so called *fluent interfaces*. A fluent interface is an API made with readability and flow-like reading in mind. It is usually declarative and targeted towards specific domain, thus another name: *internal domain specific languages*, in short: DSL.

There are some simple patterns for creating such domain-specific languages. One of them that can be applied to our situation is called *nested function*[^fowlerdsl], which, in our context, means wrapping a call to `new` with a more descriptive method. Don't worry if that confuses you, we'll see how it plays out in practice in a second. We will do this step by step, so there will be a lot of repeated code, but hopefully, you will be able to closely watch the process of improving the readability of composition code.

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

This step may look silly, (after all, we are introducing a method wrapping a single line of code), but there is a lot of sense to it. First of all, it lets us reduce the syntax noise -- when we need to create a silent alarm, we do not have to say `new` anymore. Another benefit is that we can describe the role a `SilentAlarm` instance plays in our composition (I will explain later why we are doing it using passive voice).

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

and the composition code after applying this method looks like this:

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

Note that we have removed some more `new`s in favor of something that's more readable. This is exactly what I meant by "reducing syntax noise".

Now let's focus a bit on this part:

```csharp
  new GuardsBuilding(
    new HybridAlarm(
      Calls("919"), //police number
      MakesLoudNoise()
    )
  )
```

and try to apply the same trick of introducing factory method to `HybridAlarm` creation. You know, we are always told that class names should be nouns and that's why `HybridAlarm` is named like this. But it does not act well as a description of what the system does. Its real functionality is to trigger both alarms when it is triggered itself. Thus, we need to come up with a better name. Should we name the method `TriggersBothAlarms()`? Naah, it's too much noise -- we already know it's alarms that we are triggering, so we can leave the "alarms" part out. What about "triggers"? It says what the hybrid alarm does, which might seem good, but when we look at the composition, `Calls()` and `MakesLoudNoise()` already say what is being done. The `HybridAlarm` only says that both of those things happen simultaneously. We could leave `Trigger` if we changed the names of the other methods in the composition to look like this:

```csharp
  new GuardsBuilding(
    TriggersBoth(
      Calling("919"), //police number
      LoudNoise()
    )
  )
```

But that would make the names `Calling()` and `LoudNoise()` out of place everywhere it is not being nested as `TriggersBoth()` arguments. For example, if we wanted to make another building that would only use a loud alarm, the composition would look like this:

```csharp
new OtherBuilding(LoudNoise());
```

or if we wanted to use silent one:

```csharp
new OtherBuilding(Calling("919"));
```

Instead, let's try to name the method wrapping construction of `HybridAlarm` just `Both()` -- it is simple and communicates well the role hybrid alarms play -- after all, they are just a kind of combining operators, not real alarms. This way, our composition code is now:

```csharp
new GuardsBuilding(
  Both(
    Calls("919"), //police number
    MakesLoudNoise()
  )
)
```

and, by the way, the `Both()` method is defined as:

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

Now the most difficult part -- finding a way to make the following piece of code readable:

```csharp
new OfficeBuilding(
  new DayNightSwitchedAlarm(
    Calls("222-333-444"), 
    MakesLoudNoise()
  )
),
```

The difficulty here is that `DayNightSwitchedAlarm` accepts two alarms that are used alternatively. We need to invent a term that:

 1.  Says it's an alternative.
 1.  Says what kind of alternative it is (i.e. that one happens at day, and the other during the night).
 1.  Says which alarm is attached to which condition (silent alarm is used during the day and  loud alarm is used at night).

If we introduce a single name, e.g. `FirstDuringDayAndSecondAtNight()`, it will feel awkward and we will loose the flow. Just look:

```csharp
new OfficeBuilding(
  FirstDuringDayAndSecondAtNight(
    Calls("222-333-444"), 
    MakesLoudNoise()
  )
),
```

It just doesn't feel well... We need to find another approach to this situation. There are two approaches we may consider:

### Approach 1: use named parameters

Named parameters are a feature of languages like Python or C#. In short, when we have a method like this:

```csharp
public void DoSomething(int first, int second)
{
  //...
}
```

we can call it with the names of its arguments stated explicitly, like this:

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

which is quite readable. Using named parameters has this small added benefit that it lets us pass the arguments in different order they were declared, thanks to their names stated explicitly. This makes both following invocations valid:

```csharp
//this is valid:
DependingOnTimeOfDay(
  duringDay: Calls("222-333-444"), 
  atNight: MakesLoudNoise()
)

//arguments in different order,
//but this is valid as well:
DependingOnTimeOfDay(
  atNight: MakesLoudNoise(),
  duringDay: Calls("222-333-444")  
)
```

Now, on to the second approach.

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

So as you see, this is very similar in reading, the main difference being that it's more work. It might not be obvious from the start how this kind of parameter passing works:

```csharp
DependingOnTimeOfDay
  .DuringDay(...)
  .AtNight(...)
```

so, let's decipher it. First, `DependingOnTimeOfDay`. This is just a class:

```csharp
public class DependingOnTimeOfDay
{
}
```

which has a static method called `DuringDay()`:

```csharp
//note: this method is static
public static 
DependingOnTimeOfDay DuringDay(Alarm alarm)
{
  return new DependingOnTimeOfDay(alarm);
}

//The constructor is private:
private DependingOnTimeOfDay(Alarm dayAlarm)
{
  _dayAlarm = dayAlarm;
}
```

Now, this method seems strange, doesn't it? It is a static method that returns an instance of its enclosing class (not an actual alarm!). Also, the private constructor stores the passed alarm inside for later... why?

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
DependingOnTimeOfDay //class
  .DuringDay(dayAlarm) //static method
  .AtNight(nightAlarm) //non-static method
```

and assign a result of each operation to a separate variable, it would look like this:

```csharp
DependingOnTimeOfDay firstPart = DependingOnTimeOfDay.DuringDay(dayAlarm);
Alarm alarm = firstPart.AtNight(nightAlarm);
```

Now, we can just chain these calls and get the result we wanted to:

```csharp
new OfficeBuilding(
  DependingOnTimeOfDay
    .DuringDay(Calls("222-333-444"))
    .AtNight(MakesLoudNoise())
  )
),
```

The advantage of this solution is that it does not require your programming language of choice to support named parameters. The downside is that the order of the calls is strictly defined. The `DuringDay` returns an object on which `AtNight` is invoked, so it must come first.

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

There are few more finishing touches we need to make. First of all, let's try and extract these dial numbers like `222-333-444` into constants. When we do so, then, for example, this code:

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

And here it is -- the real, declarative description of our application! The composition reads better than when we started, doesn't it?

## Composition as a language

Written this way, object composition has another important property -- it is extensible and can be extended using the same terms that are already used (of course we can add new ones as well). For example, using the methods we invented to make the composition more readable, we may write something like this:

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

to obtain different behavior. Note that we have invented something that has these properties:

 1. It defines some kind of *vocabulary* -- in our case, the following "words" are form part of the vocabulary: `Both`, `Calls`, `MakesLoudNoise`, `DependingOnTimeOfDay`, `atNight`, `duringDay`, `SecureAreaContaining`, `GuardsBuildingWithAlarmThat`, `OfficeBuildingWithAlarmThat`. 
 1. It allows combining the words from the vocabulary. These combinations have meaning, which is based solely on the meaning of used words and the way they are combined. For example: `Both(Calls(Police), Calls(Guards))` has the meaning of "calls both police and guards when triggered" -- thus, it allows us to combine words into *sentences*.
 1. Although we are quite liberal in defining behaviors for alarms, there are some rules as what can be composed with what (for example, we cannot compose guards building with an office, but each of them can only be composed with alarms). Thus, we can say that the *sentences* we write have to obey certain rules that look a lot like *a grammar*.
 1. The vocabulary is *constrained to the domain* of alarms. On the other hand, it *is more powerful and expressive* as a description of this domain than a combination of `if` statements, `for` loops, variable assignments and other elements of a general-purpose language. It is tuned towards describing rules of a domain on a *higher level of abstraction*. 
 1. The sentences written define a behavior of the application -- so by writing sentences like this, we still write software! Thus, what we do by combining *words* into *sentences* constrained by a *grammar* is still *programming*!
 
All of these points suggest that we have created a *Domain-Specific Language*[^fowlerdsl], which, by the way, is a *higher-level language*, meaning we describe our software on a higher level of abstraction. 

## The significance of a higher-level language

So... why do we need a higher-level language to describe the behavior of our application? After all, expressions, statements, loops and conditions (and objects and polymorphism) are our daily bread and butter. Why invent something that moves us away from this kind of programming into something "domain-specific"?

My main answer is: to deal with with complexity more effectively. 

What's complexity? For our purpose we can approximately define it as a number of different decisions our application needs to make. As we add new features and fix errors or implement missed requirements, the complexity of our software grows. What can we do when it grows larger than we are able to manage? We have the following choices:

 1. Remove some decisions -- i.e. remove features from our application. This is very cool when we *can* do this, but there are times when this might be unacceptable from the business perspective.
 1. Optimize away redundant decisions -- this is about making sure that each decision is made once in the code base -- I already showed you some examples how polymorphism can help with that.    
 1. Use 3rd party component or a library to handle some of the decisions for us -- while this is quite easy for "infrastructure" code and utilities, it is very, very hard (impossible?) to find a library that will describe our "domain rules" for us. So if these rules are where the real complexity lies (and often they are), we are still left alone with our problem.
 1. Hide the decisions by programming on higher level of abstraction -- this is what we did in this chapter so far. The advantage is that it allows us to reduce complexity of our domain, by creating a bigger building blocks from which a behavior description can be created.

So, as you see, only the last of the above points really helps in reducing domain complexity. This is where the idea of domain-specific languages falls in. If we carefully craft our object composition into a set of domain-specific languages (one is often too little in all but simplest cases), one day we may find that we are adding new features by writing new sentences in these languages in a declarative way rather than adding new imperative code. Thus, if we have a good language and a firm understanding of its vocabulary and grammar, we can program on a higher level of abstraction which is more expressive and less complex.

This is very hard to achieve -- it requires, among others:

 1. A huge discipline across a develoment team.
 1. A sense of direction of how to structure the composition and where to lead the language designs as they evolve.
 1. Merciless refactoring.
 1. Some minimal knowledge of language design and experience in doing so.
 1. Knowledge of some techniques (like the ones we used in our example) that make constructs written in general-purpose language look like another language. 

Of course, not all parts of the composition make a good material to being structured like a language. Despite these difficulties, I think it's well worth the effort. Programming on higher level of abstraction with declarative code rather than imperative is where I place my hope for writing maintainable and understandable systems. 

## Some advice

So, eager to try this approach? Let me give you a few pieces of advice first:

### Evolve the language as you evolve code

At the beginning of this chapter, we achieved our higher-level language by refactoring already existing object composition. This does not at all mean that in real projects we need to wait for a lot of composition code to appear and then try to wrap all of it. It is true that I did just that in the alarm example, but this was just an example and its purpose was mainly didactical. 

In reality, the language is better off evolving along the composition it describes. One reason for this is because there is a lot of feedback about the composability of the design gained by trying to put a language on top of it. As I said in the chapter on single responsibility, if objects are not comfortably composable, something is probably wrong with the distribution of responsibilities between them (for comparison of wrongly placed responsibilities, imagine a general-purpose language that would not have a separate `if` and `for` constructs but only a combination of them called `forif` :-)). Don't miss out on this feedback!

The second reason is because even if you can safely refactor all the code because you have an executable Specification protecting you from making mistakes, it's just too many decisions to handle at once (plus it takes a lot of time and your colleagues keep adding new code, don't they?). Good language grows and matures organically rather than being created in a big bang effort. Some decisions take time and a lot of thought to be made.

### Composition is not a single DSL, but a series of mini DSLs[^DDDBoundedContext]

I already briefly noted this. While it may be tempting to invent a single DSL to describe whole application, in practice it is hardly possible, because our applications have different subdomains that often use different sets of terms. Rather, it pays off to hunt for such subdomains and create smaller languages for them. The alarm example shown above would probably be just a small part of a real composition. Not all parts would lend themselves to shape this way, at least not instantly. What starts off as a single class might become a subdomain with its own vocabulary at some point. We need to pay attention. Hence, we still want to apply some of the DSL techniques even to those parts of the composition that are not easily turned into DSLs and hunt for an occasion when we are able to do so.

As [Nat Pryce puts it](http://www.natpryce.com/articles/000783.html), it's all about:

> (...) clearly expressing the dependencies between objects in the code that composes them, so that the system structure can easily be refactored, and aggressively refactoring that compositional code to remove duplication and express intent, and thereby raising the abstraction level at which we can program (...). The end goal is to need less and less code to write more and more functionality as the system grows. 

For example, a mini-DSL for setting up handling of an application configuration updates might look like this:

```csharp
return ConfigurationUpdates(
  Of(log),
  Of(localSettings),
  OfResource(Departments()),
  OfResource(Projects()));
```

Reading this code should not be difficult, especially when we know what each term in the sentence means. This code returns an object handling configuration updates of four things: application log, local settings, and two resources (in this subdomain, resources mean things that can be added, deleted and modified). These two resources are: departments and projects (e.g. we can add a new project or delete an existing one).

Note that the constructs of this language make sense only in a context of creating configuration update handlers. Thus, they should be restricted to this part of composition. Other parts that have nothing to do with configuration updates, should not need to know these constructs. 

### Do not use an extensive amount of DSL tricks

In creating internal DSLs, one can use a lot of neat tricks, some of them being very "hacky" and twisting the general-purpose language in many ways to achieve "flluent" syntax. But remember that the composition code is to be maintained by your team. Unless each and every member of your team is an expert on creating such DSLs, do not show off with too many, too sophisticated tricks. Stick with a few of the proven ones that are simple to use and work, like the ones I have used in the alarm example.

Martin Fowler[^fowlerdsl] describes a lot of tricks for creating such DSLs and at the same time warns against using too many of them in the same language. 

### Factory method nesting is your best friend

One of the DSL techniques, the one I have used the most, is factory method nesting. Basically, it means wrapping a constructor (or constructors -- no one said each factory method must wrap exactly one `new`) invocation with a method that has a name more fitting for a context it is used in (and which hides the obscurity of the `new` keyword). This technique is what makes this:

```csharp
new HybridAlarm(
  new SilentAlarm("222-333-444"),
  new LoudAlarm()
)
```

look like this:

```csharp
Both(
  Calls("222-333-444"),
  MakesLoudNoise()
)
```

As you probably remember, in this case each method wraps a constructor, e.g. `Calls()` is defined as:

```csharp
public Alarm Calls(string number)
{
  return new SilentAlarm(number);
}
```

This technique is great for describing any kind of tree and graph-like structures as each method provides a natural scope for its arguments:

```csharp
Method1( //beginning of scope
  NestedMethod1(),
  NestedMethod2()
);       //end of scope
```  

Thus, it is a natural fit for object composition, which *is* a graph-like structure.

This approach looks great on paper but it's not like everything just fits in all the time. There are two issues with factory methods that we need to address.  

#### Where to put these methods?

In the usual case, we want to be able to invoke these methods without any qualifier before them, i.e. we want to call `MakesLoudNoise()` instead of `alarmsFactory.MakesLoudNoise()` or `this.MakesLoudNoise()` or anything. 

If so, where do we put such methods?

There are two options[^staticimports]:

 1. Put the methods in the class that performs the composition.
 1. Put the methods in superclass.
  
Apart from that, we can choose between:

 1. Making the factory methods static.
 1. Making the factory methods non-static.
   
First, let's consider the dilemma of putting in composing class vs having a superclass to inherit from. This choice is mainly determined by reuse needs. The methods that we use in one composition only and do not want to reuse are mostly better off as private methods in the composing class. On the other hand, the methods that we want to reuse (e.g. in other applications or services belonging to the same system), are better put in a superclass which we can inherit from. Also, a combination of the two approaches is possible, where superclass contains a more general method, while composing class wraps it with another method that adjusts the creation to the current context. By the way, remember that in most languages, we can inherit from a single class only -- thus, putting methods for each language in a separate superclass forces us to distribute compositiion code across several classes, each inheriting its own set of methods and returning an object or several objects. This is not bad at all -- quite the contrary, this is something we'd like to have, because it enables us to evolve a language and sentences written in this language in an isolated context.

The second choice between static and non-static is one of having access to instance fields -- instance methods have this access, while static methods do not. Thus, if the following is an instance method of a class called `AlarmComposition`:

```csharp
public class AlarmComposition
{
  //...
  
  public Alarm Calls(string number)
  {
    return new SilentAlarm(number);
  }
  
  //...
}
```

and I need to pass an additional dependency to `SilentAlarm` that I do not want to show in the main composition code, I am free to change the `Calls` method to:

```csharp
public Alarm Calls(string number)
{
  return new SilentAlarm(
    number, 
    _hiddenDependency) //field
}
```

and this new dependency may be passed to the `AlarmComposition` via constructor:

```csharp
public AlarmComposition(
  HiddenDependency hiddenDependency)
{
  _hiddenDependency = hiddenDependency;
} 
```

This way, I can hide it from the main composition code. This is freedom I do not have with static methods. 


#### Use implicit collections instead of explicit ones

Most object-oriented languages support passing variable argument lists (e.g. in C# this is achieved with the `params` keyword, while Java has `...` operator). This is valuable in composition, because we often want to be able to pass arbitrary number of objects to some places. Again, coming back to this composition:

```csharp
return ConfigurationUpdates(
  Of(log),
  Of(localSettings),
  OfResource(Departments()),
  OfResource(Projects()));
```

the `ConfigurationUpdates()` method is using variable argument list:

```csharp
public ConfigurationUpdates ConfigurationUpdates(
  params ConfigurationUpdate[] updates)
{
  return new MyAppConfigurationUpdates(updates);
}
```

Note that we could, of course, pass the array of `ConfigurationUpdate` instances  using explicit definition: `new ConfigurationUpdate[] {...}`, but that would greatly hinder readability and flow of this composition. See for yourself:

```csharp
return ConfigurationUpdates(
  new [] { //explicit definition brings noise
    Of(log),
    Of(localSettings),
    OfResource(Departments()),
    OfResource(Projects())
  }
);
```

Not so pretty, huh? This is why we like the ability to pass variable argument lists as it enhances readability.

#### A single method can create more than one object

No one said each factory method must create one and only one object. For example, take a look again at this method creating configuration updates:

```csharp
public ConfigurationUpdates ConfigurationUpdates(
  params ConfigurationUpdate[] updates)
{
  return new MyAppConfigurationUpdates(updates);
}
```

Now, let's assume we need to trace each invocation on the instance of `ConfigurationUpdates` class and we want to achieve this by wrapping the `MyAppConfigurationUpdates` instance with a tracing proxy (a wrapping object that passes the calls along to a real object, but writes some trace messages before and after it does). For this purpose, we can reuse the method we already have, just adding the additional object creation there:

```csharp
public ConfigurationUpdates ConfigurationUpdates(
  params ConfigurationUpdate[] updates)
{
  //now two objects created instead of one:
  return new TracedConfigurationUpdates(
    new MyAppConfigurationUpdates(updates)
  );
}
```

Note that the `TracedConfigurationUpdates` is not important from the point of view of composition -- it is pure infrastructure code, not a new domain rule. Because of that, it may be a good idea to hide it inside the factory method.

## Summary

In this chapter, I tried to convey to you a vision of object composition as a language, with its own vocabulary, its own grammar, keywords and arguments. We can compose the words from the vocabulary in different sentences to create new behaviors on higher level of abstraction.

This area of object-oriented design is something I am still experimenting with, trying to catch up with what authorities on this topic share. Thus, I am not as fluent in it as in other topics covered in this book. Expect this chapter to grow (maybe into several chapters) or to be clarified in the future. For now, if you feel you need more information, please take a look at the video by Steve Freeman and Nat Pryce called ["Building on SOLID foundations"](https://vimeo.com/105785565).
 
[^fowlerdsl]: M. Fowler, Domain-Specific Languages, Addison-Wesley 2010.

[^staticimports]: In some languages, there is a third way: Java lets us use static imports which are part of C# as well starting with version 6.0. C++ has always supported bare functions, so it's not a topic there.

[^DDDBoundedContext]: A reader noted that the ideas in this section are remarkably similar to the notion of Bounded Contexts in a book: E. Evans, Domain-Driven Design: Tackling Complexity in the Heart of Software, Prentice Hall 2003.
