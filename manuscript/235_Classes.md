# Classes

We already covered interfaces and protocols. In our quest for composability, We need to look at classes as well.

Classes implement and use interfaces, and communicate using protocols, so it may seem we are already done with them. The truth is that classes are still interesting on their own and there are few concepts related to them that need explanation.

## Single Responsibility

I already said that we want our system to be a web of composable objects. Obviously, an object is a granule of composability - we cannot e.g. unplug a half of an object and plug in another half. Thus, a valid question to ask is this: how big should an object be to make the composability comfortable - to let us unplug as much logic as we want, leaving the rest untouched and ready tow rok with the new things we plug in.

The answer comes with a Single Responsibility Principle for classes[^SRPMethods], that basically says[^SRP]:

A> A code of a Class should have only one reason to change.

There has been a lot written about the principle on the web, so I am not going to be wiser than google. Still, I believe it is useful to explain this principle in terms of composability.

Usually, the hard part about this principle is the what is "a reason to change". Robert C. Martin explains[^srponstackoverflow] that this is about a single source of entropy that generates changes to the class. And we will study it on an example we already know.

### Separating responsibilities

Remember the code Johnny and Benjamin used to apply incentine plans to employees? In case not, here it is (it's just a single method, but it will suffice):

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

So... how many reasons to change does this piece of code have? If "reason to change" was defined as a "way to change", there would be multiple such ways. For example, someone may decide that we are not giving raises anymore and the `employee.EvaluateRaise()` line would be gone. Likewise, a decision could be made that we are not giving bonuses, then the `employee.EvaluateBonus()` line would have to be removed. So, there are undoubtedly many ways this method could change. But would it be for different reasons? Actually, no. The reason in both cases would be that the CEO approved a new incentive plan. So, there is one reason to change, although there are many ways the code can change.

Now happens the more interesting discussion: what about saving the employees - is the reason for changing the way we save employees the same as for the bonuses and pays? For example, we may decide that we are not saving each employee separately, because it would cause a huge load on our data store, but instead, we will save them together in a single batch. This causes the code to change, e.g. like this:

```csharp
public void ApplyYearlyIncentivePlan()
{
  var employees = _repository.CurrentEmployees();

  foreach(var employee in employees)
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
  }
  
  _repository.SaveAll(employees);
}
```

So, as you might've already guessed, the reason for this change is different, thus, it is a separate responsibility and the logic for reading and storing employees should be separated from this class. The method would look something like this:

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

Reading and writing would be handled by different code - thus, the responsibilities are separated. Do we now have a code that adheres to Single Reponsibility Principle? We may, but consider this situation: the evaluation of the raises and bonuses begins getting slow and, instead of doing this for all employees in a `for` loop, we would rather parallelize it. After this change, the code could look like this (this will the the C# parallel looping):

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

Is this a new reason to change? Of course it is! So, we may say we have encountered another responsibility and separate it. The code looks like this now:

```csharp
public void ApplyYearlyIncentivePlanTo(Employee employee)
{
  employee.EvaluateRaise();
  employee.EvaluateBonus();
}
```

The looping, which is a separate responsibility, is handled by a different class.
 
### How far do we go?

The above example begs some questions:

1.  Is there a point where we are sure we have separated all responsibilities?
2.  If there is, how can we be sure we have reached it?

The answer to the first question is: probably no. While some reasons to change are common sense, others can be drawn from our experience as developers, there are always some that are unexpected and until they surface, we cannot foresee them. Thus, the answer for the second question is: "there is no way". Which does not mean we should not try to separate the different reasons we see - quite the contrary.

I like the comparison to our usage of time in real life. Brewing time of black tea is usually around three to five minutes. This is what is printed on the package we buy: "3 --- 5 minutes". Nobody gives the time in seconds, because such granularity is not needed. If seconds made a difference in the process of brewing tea, we would probably be given time in seconds. But they don't. When we estimate tasks in software engineering, we also use different time granularity depending on the need.

A simplest software program that prints "hello world" on the screen may fit into a single "main" method we will probably not see it as several responsibilities. But as soon as we get a requirement to write "hello world" in a native language of the currently running operating system, obtaining the text becomes a separate responsibility from putting it on the screen. It all depends on what granularity we need at the moment (which, as I said, may be spotted from code or, in some cases, known up-front from our experience as developers).

### The mutual relationship between Single Responsibility Principle and composability

The reason I am writing all this is that responsibilities are the real granules of composability. The composability of objects that I talked about a lot already is actually a mean to achieve composability of responsibilities, which is our real goal. If we have two collaborating objects, each having a single responsibility, we can easily replace the way our application achieves one of these responsibilities without touching the other. Thus, objects conforming to SRP are the most comfortably composable. As the real reason for change in application is the change of responsibilities and the real reuse is reuse of responsibilities, this is a concept that determines the size of our objects[^notrdd].

## Static recipients

While static fields may sometimes seem like a good idea of "sharing" recipient references between objects of the same class and something that is more "memory efficient", they actually hurt composability. Let's take a look at a simple example to get a feeling of how this may be.

### SMTP Server

Let's consider a scenario where we need to write an e-mail server that receives and send SMTP messages. In our code, have an `OutboundSmtpMessage` class which symbolizes SMTP messages we send to other parties. To send the message, we need to encode it. We always use a Base64 encoding, so we have the class `OutboundSmtpMessage` declare a private field of type `Base64Encoding`:

```csharp
public class OutboundSmtpMessage
{
  //... other code
  
  private Encoding _encoding = new Base64Encoding();
  
  //... other code
}
```  

One day we notice that it is a waste for each message to define its own encoding objects, since they are plain algorithms and each use of encoding does not affect further uses in any way - so we can as well have a single instance and use it in all messages. Also, it may save us some performance, since creating an encoding each time we create a new message has its cost in high throughput scenarios. Thus, it seems like a good idea to use static field for this purpose, so we modify our `OutboundSmtpMessage` message class to hold `Base64Encoding` instance as static field:

```csharp
public class OutboundSmtpMessage
{
  //... other code
  
  private static Encoding _encoding = new Base64Encoding();
  
  //... other code
}
```  

There, we fixed it! But didn't our mommies tell us not to optimize prematurely? Oh well...

### Welcome, change!

One day it turns out that we need to support not only Base64 encoding but also another one, called Quoted-Printable. With our current design, we cannot do that, because single encoding is shared between all messages. Thus, if we change the encoding for message that requires Quoted-Printable encoding, it will also change the encoding for the messages that require Base64. Thus, we constraint the composability with this premature optimization.

### So what about optimizations?

So, are we doomed to return to the previous solution to have one encoding per message? What if this really becomes a performance of memory problem? Is our observation that we don't need to create the same encoding many times useless?

Not at all. We can still use this observation and get a lot (albeit not all) of the benefits of static field. How do we do it? Well, we already answered this question few chapters ago - create a single instance of each encoding in composition root and pass it to each message in constructor.

Let's examine this solution. First, we need to create the encodings in the composition root:

```csharp
//...other initialization

var base64Encoding = new Base64Encoding();
var quotedPrintableEncoding = new QuotedPrintableEncoding();

//...other initialization
``` 
Now, in our case, we need to create new messages dynamically, on demand, so we need a factory for them. We will also instantiate this factory in the composition root and pass both encodings inside:

```csharp
//...other initialization

var messageFactory 
  = new StmpMessageFactory(base64Encoding, quotedPrintableEncoding);

//...other initialization
```  

The factory itself, when asked to create a message with a given encoding, will just pass the single instances received from composition root: 

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

The performance and memory saving is not exactly as big as when using a static field (e.g. each `SmtpMessage` instance uses must store a separate reference to the received encoding), but it is still a huge improvement over creating a separate encoding for each message. 

### Where statics work?

What I wrote does not mean that statics do not have their uses. They do, but these uses are very specific. I will show you one of such uses in the next chapters after I introduce value objects.

## No work in constructors

A constructor of a class should do little or no work. This is a conclusion from Single Responsibility Principle and also enhances composability.

If, aside from implementing the methods a class exposes, you feel you need to do additional work in a constructor, that may be a sign that this "additional work" changes for other reason than the main logic. Thus it should be put elsewhere.

### What can a constructor do?

Most of the times, we can get away using the following guideline: assigning fields or null checks. 

### What a constructor cannot do?

if it does too much, it means it's a separate responsibility. Move it to the factory.



TODO give open connection instead of opening it in constructor
TODO validation - put in factories, except nulls - an object requires valid peers.
http://misko.hevery.com/code-reviewers-guide/flaw-constructor-does-real-work/

TODO static collaborators - not context independent - each service cannot obtain its own context, but rather context is forced on them.
TODO independent deployability

TODO principle at different level of abstraction - single level of abstraction principle

TODO small amount of private methods

TODO how are we to determine responsibility? From experience: we know to count something in hours, not minutes. Second way: composition becomes awkward. Third way: tests (Statements) will tell us.



[^SRPMethods]: This principle can be applied to methods as well, but we are not going to cover this part, because it is not directly tied to the notion of composability and this is not a design book ;-).

[^SRP]: http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod. 

[^srponstackoverflow]: https://stackoverflow.fogbugz.com/default.asp?W29030

[^notrdd]: note that I am talking about responsibilities the way SRP talks about them, not the way they are understood by e.g. Responsibility Driven Design. Thus, I am talking about responsibilities of a class, not responsibilities of its API.
