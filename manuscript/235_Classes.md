# Classes

We already covered interfaces and protocols. In our quest for composability, We need to look at classes as well. Classes:

* implement interfaces (i.e. play roles)
* communicate through interfaces to other services
* follow protocols in this communication

So in a way, what is "inside" a class is a byproduct of how objects of this class acts on the "outside". Still, it does not mean there is nothing to say about classes themselves that contributes to better composability.

## Single Responsibility Principle

I already said that we want our system to be a web of composable objects. Obviously, an object is a granule of composability -- we cannot e.g. unplug a half of an object and plug in another half. Thus, a valid question to ask is: how big should an object be to make the composability comfortable -- to let us unplug as much logic as we want, leaving the rest untouched and ready to work with the new recipients we plug in?

The answer comes with a *Single Responsibility Principle* (in short: SRP) for classes[^SRPMethods], which basically says[^SRP]:

A> A code of a Class should have only one reason to change.

There has been a lot written about the principle on the web, so I am not going to be wiser than your favourite web search engine (my recent search yielded over 74 thousands results). Still, I believe it is useful to explain this principle in terms of composability.

Usually, the hard part about this principle is how to understand "a reason to change". Robert C. Martin explains[^srponstackoverflow] that this is about a single source of entropy that generates changes to the class. Which leads us to another trouble of defining a "source of entropy". So I think it's better to just give you an example.

### Separating responsibilities

Remember the code Johnny and Benjamin used to apply incentive plans to employees? In case you don't, here it is (it's just a single method, not a whole class, but it should be enough for our needs):

```csharp
public void ApplyYearlyIncentivePlan()
{
  var employees = _repository.CurrentEmployees();

  foreach(var employee in employees)
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
    employee.Save();
  }
}
```

So... how many reasons to change does this piece of code have? If we weren't talking about "reason to change" but simply a "change", the answer would be "many". For example, someone may decide that we are not giving raises anymore and the `employee.EvaluateRaise()` line would be gone. Likewise, a decision could be made that we are not giving bonuses, then the `employee.EvaluateBonus()` line would have to be removed. So, there are undoubtedly many ways this method could change. But would it be for different reasons? Actually, no. The reason in both cases would be (probably) that the CEO approved a new incentive plan. So, there is one "source of entropy" for these two changes, although there are many ways the code can change. Hence, the two changes are for the same reason.

Now the more interesting part of the discussion: what about saving the employees -- is the reason for changing how we save employees the same as for the bonuses and pays? For example, we may decide that we are not saving each employee separately, because it would cause a huge performance load on our data store, but instead, we will save them together in a single batch after we finish processing the last one. This causes the code to change, e.g. like this:

```csharp
public void ApplyYearlyIncentivePlan()
{
  var employees = _repository.CurrentEmployees();

  foreach(var employee in employees)
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
  }
  
  //now all employees saved once
  _repository.SaveAll(employees);
}
```

So, as you might've already guessed, the reason for this change is different as for changing incentive plan, thus, it is a separate responsibility and the logic for reading and storing employees should be separated from this class. The method after the separation would look something like this:

```csharp
public void ApplyYearlyIncentivePlanTo(IEnumerable<Employee> employees)
{
  foreach(var employee in employees)
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
  }
}
```

In the example above, we moved reading and writing employees out, so that it is handled by different code -- thus, the responsibilities are separated. Do we now have a code that adheres to Single Reponsibility Principle? We may, but consider this situation: the evaluation of the raises and bonuses begins getting slow and, instead of doing this for all employees in a sequential `for` loop, we would rather parallelize it to process every employee at the same time in a separate thread. After applying this change, the code could look like this (This uses C#-specific API for parallel looping, but I hope you get the idea):

```csharp
public void ApplyYearlyIncentivePlanTo(IEnumerable<Employee> employees)
{
  Parallel.ForEach(employees, employee =>
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
  });
}
```

Is this a new reason to change? Of course it is! Decisions on parallelizing processing come from different source than incentive plan modifications. So, we may say we encountered another responsibility and separate it. The code that remains in the `ApplyYearlyIncentivePlanTo()` method looks like this now:

```csharp
public void ApplyYearlyIncentivePlanTo(Employee employee)
{
  employee.EvaluateRaise();
  employee.EvaluateBonus();
}
```

The looping, which is a separate responsibility, is now handled by a different class.
 
### How far do we go?

The above example begs some questions:

1. Can we reach a point where we have separated all responsibilities?
2. If we can, how can we be sure we have reached it?

The answer to the first question is: probably no. While some reasons to change are common sense, and others can be drawn from our experience as developers or knowledge about the domain of the problem, there are always some that are unexpected and until they surface, we cannot foresee them. Thus, the answer for the second question is: "there is no way". Which does not mean we should not try to separate the different reasons we see -- quite the contrary. We just don't get overzealous trying to predict every possible change.

I like the comparison of responsibilities to our usage of time in real life. Brewing time of black tea is usually around three to five minutes. This is what is usually printed on the package we buy: "3 --- 5 minutes". Nobody gives the time in seconds, because such granularity is not needed. If seconds made a noticeable difference in the process of brewing tea, we would probably be given time in seconds. But they don't. When we estimate tasks in software engineering, we also use different time granularity depending on the need[^storypoints] and the granularity becomes finer as we reach a point where the smaller differences matter more.

Likewise, a simplest software program that prints "hello world" on the screen may fit into a single "main" method and we will probably not see it as several responsibilities. But as soon as we get a requirement to write "hello world" in a native language of the currently running operating system, obtaining the text becomes a separate responsibility from putting it on the screen. It all depends on what granularity we need at the moment (which, as I said, may be spotted from code or, in some cases, known up-front from our experience as developers or domain knowledge).

### The mutual relationship between Single Responsibility Principle and composability

The reason I am writing all this is that responsibilities[^rddandsrp] are the real granules of composability. The composability of objects that I have talked about a lot already is a mean to achieve composability of responsibilities. So, this is what our real goal is. If we have two collaborating objects, each having a single responsibility, we can easily replace the way our application achieves one of these responsibilities without touching the other. Thus, objects conforming to SRP are the most comfortably composable and the right size.[^notrdd].

A good example from another playground where single responsibility goes hand in hand with composability is UNIX. UNIX is famous for its collection of single-purpose command-line tools, like `ls`, `grep`, `ps`, `sed` etc. The single-purposeness of these utilities along with the ability of UNIX commandline to pass output stream of one command to the input stream of another by using the `|` (pipe) operator. For example, we may combine three commands: `ls` (lists contents of directory), `sort` (sorts passed input) and `more` (allows comfortably viewing on the screen input that takes more than one screen) into a pipeline:

```bash
ls | sort | more
``` 

Which displays sorted content of current directory for comfortable view. This philosophy of composing a set of single-purpose tools into a more complex and more useful whole is what we are after, only that in object-oriented software development, we're using objects instead of executables. We will talk more about it in the next chapter.


## Static recipients

While static fields in a class body may sometimes seem like a good idea of "sharing" recipient references between its instances and a smart way to make the code more "memory efficient", they actually hurt composability more often than not. Let's take a look at a simple example to get a feeling of how static fields constraint our design.

### SMTP Server

Imagine we need to implement an e-mail server that receives and sends SMTP messages[^smtp]. We have an `OutboundSmtpMessage` class which symbolizes SMTP messages we send to other parties. To send the message, we need to encode it. For now, we always use an encoding called *Quoted-Printable*, which is declared in a separate class called `QuotedPrintableEncoding` and the class `OutboundSmtpMessage` declares a private field of this type:

```csharp
public class OutboundSmtpMessage
{
  //... other code
  
  private Encoding _encoding = new QuotedPrintableEncoding();
  
  //... other code
}
```  

Note that each message has its own encoding objects, so when we have, say, 1000000 messages in memory, we also have the same amount of encoding objects. 

### Premature optimization

One day we notice that it is a waste for each message to define its own encoding object, since an encoding is pure algorithm and each use of this encoding does not affect further uses in any way -- so we can as well have a single instance and use it in all messages -- it will not cause any conflicts. Also, it may save us some CPU cycles, since creating an encoding each time we create a new message has its cost in high throughput scenarios. 

But how we make the encoding shared between all instances? Out first thought -- static fields! A static field seems fit for the job, since it gives us exactly what we want -- a single object shared across many instances of its declaring class. Driven by our (supposedly) excellent idea, we modify our `OutboundSmtpMessage` message class to hold `QuotedPrintableEncoding` instance as a static field:

```csharp
public class OutboundSmtpMessage
{
  //... other code
  
  private static Encoding _encoding = new QuotedPrintableEncoding();
  
  //... other code
}
```  

There, we fixed it! But didn't our mommies tell us not to optimize prematurely? Oh well...

### Welcome, change!

One day it turns out that in our messages, we need to support not only Quoted-Printable encoding but also another one, called *Base64*. With our current design, we cannot do that, because, as a result of using a static field, a single encoding is shared between all messages. Thus, if we change the encoding for message that requires Base64 encoding, it will also change the encoding for the messages that require Quoted-Printable. This way, we constraint the composability with this premature optimization -- we cannot compose each message with the encoding we want. All of the message use either one encoding, or another. A logical conclusion is that no instance of such class is context-independent -- it cannot obtain its own context, but rather, context is forced on it.

### So what about optimizations?

Are we doomed to return to the previous solution to have one encoding per message? What if this really becomes a performance or memory problem? Is our observation that we don't need to create the same encoding many times useless?

Not at all. We can still use this observation and get a lot (albeit not all) of the benefits of static field. How do we do it? How do we achieve sharing of encodings without the constraints of static field? Well, we already answered this question few chapters ago -- give each message an encoding through its constructor. This way, we can pass the same encoding to many, many `OutboundSmtpMessage` instances, but if we want, we can always create a message that has another encoding passed. Using this idea, we will try to achieve the sharing of encodings by creating a single instance of each encoding in the composition root and have it passed it to a message through its constructor.

Let's examine this solution. First, we need to create one of each encoding in the composition root, like this:

```csharp
// We are in a composition root!

//...some initialization

var base64Encoding = new Base64Encoding();
var quotedPrintableEncoding = new QuotedPrintableEncoding();

//...some more initialization
``` 
Ok, encodings are created, but we still have to pass them to the messages. In our case, we need to create new `OutboundSmtpMessage` object at the time we need to send a new message, i.e. on demand, so we need a factory to produce the message objects. This factory can (and should) be created in the composition root. When we create the factory, we can pass both encodings to its constructor as global context (remember that factories encapsulate global context?):

```csharp
// We are in a composition root!

//...some initialization

var messageFactory 
  = new StmpMessageFactory(base64Encoding, quotedPrintableEncoding);

//...some more initialization
```  

The factory itself can be used for the on-demand message creation that we talked about. As the factory receives both encodings via its constructor, it can store them as private fields and pass whichever one is appropriate to a message object it creates: 

```csharp
public class SmtpMessageFactory : MessageFactory
{
  private Encoding _quotedPrintable;
  private Encoding _base64;
  
  public SmtpMessageFactory(
    Encoding quotedPrintable, 
    Encoding base64)
  {
    _quotedPrintable = quotedPrintable;
    _base64 = base64;
  }
  
  public Message CreateFrom(string content, MessageLanguage language)
  {
    if(language.IsLatinBased)
    {
      //each message gets the same instance of encoding:
      return new StmpMessage(content, _quotedPrintable); 
    }
    else
    {
      //each message gets the same instance of encoding:
      return new StmpMessage(content, _base64);
    }
  }
}  
```

The performance and memory saving is not exactly as big as when using a static field (e.g. each `OutboundSmtpMessage` instance must store a separate reference to the received encoding), but it is still a huge improvement over creating a separate encoding object per message. 

### Where statics work?

What I wrote does not mean that statics do not have their uses. They do, but these uses are very specific. I will show you one of such uses in the next chapters after I introduce value objects.

## Summary

In this chapter, I tried to give you some advice on designing classes that does not come so naturally from the concept of composability and interactions as those described in previous chapters. Still, as I hope I was able to show, they enhance composability and are valuable to us.

[^SRPMethods]: This principle can be applied to methods as well, but we are not going to cover this part, because it is not directly tied to the notion of composability and this is not a design book ;-).

[^SRP]: http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod. 

[^srponstackoverflow]: https://stackoverflow.fogbugz.com/default.asp?W29030

[^notrdd]: Note that I am talking about responsibilities the way SRP talks about them, not the way they are understood by e.g. Responsibility Driven Design. Thus, I am talking about responsibilities of a class, not responsibilities of its API.

[^storypoints]: Provided we are not using a measure such as story points.

[^smtp]: SMTP stands for Simple Mail Transfer Protocol and is a standard protocol for sending and receiving e-mail. You can read more on [Wikipedia](http://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol). 

[^rddandsrp]: Note that I'm writing about responsibility in terms of single responsibility principle. In responsibility-driven design, responsibility means something different. See [Rebecca Wirfs-Brock's clarification](http://www.wirfs-brock.com/PDFs/PrinciplesInPractice.pdf).
