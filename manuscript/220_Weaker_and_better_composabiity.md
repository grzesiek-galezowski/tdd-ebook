Designing for composability
===============================

Some objects are harder to compose with other objects, others are easier. Of course, we are striving for the higher composability. There are numerous factors influencing this. I already discussed some of them indirectly, so time to sum things up and fill in the gaps.

### Classes vs interfaces

As we said, a sender is composed with a recipient by obtaining a reference to it. Also, we said that we want our senders to be able to send messages to many different recipients. This is, of course, done using polymorphism. 

So, one of the questions we have to ask ourselves in our quest for high composability is: on what should a sender depend on to be able to work with as many recipients as possible? Should it depend on classes or interfaces? In other words, when we plug in an object as a message receipient like this:

{lang="csharp"}
~~~
public Sender(Recipient recipient)
{
  this._recipient = recipient;
}
~~~

Should the `Recipient` be a class or an interface?

If we assume that `Recipient` is a class, we can get the composability we want by deriving another class from it and implementing abstract methods or overriding virtual ones. However, depending on a class as a base type for a recipient has the following disadvantages:

1.  The recipient class may have some real dependencies. For example, if `Recipient` class depends on Windows Communication Foundation stack, then all classes depending directly on `Recipient` will indirectly depend on WCF, including our `Sender`. The more damaging version of this problem is where such a `Recipient` class actually opens a connection in a constructor - the subclasses are unable to prevent it, no matter if they like it or not, because a subclass has to call a superclass' constructor.
2.  Each class deriving from `Recipient` must invoke `Recipient`'s constructor, which, depending on the complexity of the superclass, may be smaller or bigger trouble, depending on what kind of parameters the constructor accepts and what it does.
3.  In languages like C\#, where only single inheritance exists, by deriving from `Recipient` class, we use up the only inheritance slot, further constraining our design.
4.  We must make sure to mark all the methods of `Recipient` class as `virtual` to enable overriding them by subclasses. otherwise, we won't have full composability, because subclasses, not being able to override some methods, will be very constrained in what they can do.

As you see, there are some difficulties using classes as "slots for composability", even if composition is technically possible this way. Interfaces are far better, just because they do not have the above disadvantages.

It is decided then, If a sender wants to be composable with different recipients, it has to accept a reference to recipient in form of interface reference. We can say that, by being lightweight and implementationless, **interfaces can be treated as "slots" for plugging in different objects**.

In fact, one way to depict a fact that a class implements an interface on UML diagram looks like the class is exposing a plug. Thus, it seems that the "interface as slot for pluggability" concept is not so unusual.

![ConcreteRecipient class implementing three interfaces in UML. The interfaces are shown as "connectors" meaning the class can be plugged into anything that uses any of the three interfaces](images/lollipop.png)

The big thing about the design approach I am trying to introduce you to is that we are taking this concept to the extreme, making it THE most important aspect of this approach.


### Events/callbacks vs interfaces - few words on roles

Did I just say that composability is "THE most important aspect of our design approach"? Wow, that's quite a statement, isn't it? Unfortunately for me, it also lets you jump with the following argument:
"Hey, interfaces are not the most extreme way of achieving composability! What about events that e.g. C\# supports? Or callbacks that are supported by some other languages? Wouldn't it make the classes even more context-independent, if we connected them using events or callbacks, not interfaces?"

Actually, it would, and we could, but it would also strip us from another very important aspect of our design approach that I did not mention explicitly until now. This aspect is: roles.

When we take an example method that sends some messages to two recipients held as interfaces:

{lang="csharp"}
~~~
private readonly Recipient1 recipient1;
private readonly Recipient2 recipient2;

public void SendSomethingToRecipients()
{
  recipient1.DoX();
  recipient1.DoY();
  recipient2.DoZ();
}
~~~

and we compare it with similar effect achieved using event/callback invocation:

{lang="csharp"}
~~~
private readonly Action DoX;
private readonly Action DoY;
private readonly Action DoZ;

public void SendSomethingToRecipients()
{
  DoX();
  DoY();
  DoZ();
}
~~~

We can see that in the second case we are losing the notion of which message belongs to which recipient - each event is standalone from the point of view of the sender. This is unfortunate, because in our design approach, we want to highlight the roles each receiver plays in the communication, to make the communication itself readable and logical. Also, ironically, decoupling using events or callbacks can make composability harder. This is because roles tell us which sets of behaviors belong together and thus, need to change together. If each behavior is triggered using a separate event or callback, an overhead is placed on us to remember which behaviors should be changed together, and which ones can change independently.

This does not mean that events or callbacks are bad. It's just that they are not a fit replacement for interfaces - in reality, their purpose is a little bit different. We use events or callbacks not to do somebody to do something, but to indicate what happened (that's why we call them events, after all...). This fits well the observer pattern we already talked about in the previous chapter. So, instead of using observer objects, we may consider using events or callbacks instead (as in everything, there are some tradeoffs for each of the solutions). In other words, events and callbacks have their role in the composition, but they are fit for a case so specific, that they cannot be used as a default choice for the composition. The advantage of the interfaces is that they bind together messages, which should be implemented cohesively, and convey roles in the communication, which improves readability.

### Small interfaces

Ok, so we said that he interfaces are "the way to go" for reaching the strong composability we're striving for. Does merely using interfaces guarantee us that the composability is going to be strong? The answer is "no" - while using interfaces is a necessary step in the right direction, it alone does not produce the best composability.

One of the other things we need to consider is the size of interfaces. Let's state one thing that is obvious in regard to this:

**All other things equal, smaller interfaces (i.e. with less methods) are easier to implement that bigger interfaces.**

The obvious conclusion from this is that if we want to have really strong composability, our "slots", i.e. interfaces, have to be as small as possible (but not smaller - see previous section on interfaces vs
events/callbacks). Of course, we cannot achieve this just by blindly removing methods from the interfaces, because this would break classes that actually use these methods e.g. when someone is using an interface implementation like this:

{lang="csharp"}
~~~
public void Process(Recipient recipient)
{
  recipient.DoSomething();
  recipient.DoSomethingElse();
}
~~~

It is impossible to remove either of the methods from the `Recipient` interface, because it would cause a compile error saying that we are trying to use a method that does not exist.

So, what do we do then? We try to separate groups of methods used by different senders and move them to separate interfaces, so that each sender has access only to the methods it needs. After all, a class can implement more than one interface, like this:

{lang="csharp"}
~~~
public class ImplementingObject 
: InterfaceForSender1, 
  InterfaceForSender2,
  InterfaceForSender3
{ ... }
~~~

This notion of creating a separate interface per sender instead of a single big interface for all senders is known as the Interface Segregation Principle[^interfacesegregation].

#### A simple example: separation of reading from writing

Let's assume we have a class representing organizational structure in our application. This application exposes two APIs. Through the first one, it is notified on any changes made to the organizational structure by an administrator. The second one is for client-side operations on the organizational data, like listing all employees. The interface for the organizational structure class may contain methods used by both these APIs:

{lang="csharp"}
~~~
public interface 
OrganizationStructure
{
  //////////////////////
  //administrative part:
  //////////////////////  
  
  void Make(Change change);
  //...other administrative methods
  
  //////////////////////
  //client-side part:
  //////////////////////
  
  void ListAllEmployees(
    EmployeeDestination destination);
  //...other client-side methods  
}
~~~

However, the administrative API handling is done by a different code than the client-side API handling.  Thus, the administrative part has no use of the knowledge about listing employees and vice-versa - the client-side one has no interest in making administrative changes. We can use this knowledge to separate our interface into two:

{lang="csharp"}
~~~
public interface
OrganizationalStructureAdminCommands
{
  void Make(Change change);
  //... other administrative methods
}

public interface
OrganizationalStructureClientCommands
{
  void ListAllEmployees(
    EmployeeDestination destination);
  //... other client-side methods
}
~~~

Note that this does not constrain the implementation of these interfaces - a real class can still implement both of them if this is desired:

{lang="csharp"}
~~~
public class InMemoryOrganizationalStructure
: OrganizationalStructureAdminCommands,
  OrganizationalStructureClientCommands
{
  //...
}
~~~

In this approach, we create more interfaces (which some may not like), but that shouldn't bother us much, because in return, each interface is easier to implement. In other words, if a class is using one of the interfaces, it is easier to write another implementation of it, because there is less methods to implement. This means that composability is enhanced, which is what we want the most. 

It pays off. For example, one day, we may get a requirement that all writes to the organizational structure have to be traced. In such case, All we have to do is to create new class implementing `OrganizationalStructureAdminCommands` which will wrap the original methods with a notification to an observer (that can be either the trace that is required or anything else we like):

{lang="csharp"}
~~~
public class NotifyingAdminComands : OrganizationalStructureAdminCommands
{
  public NotifyingCommands(
    OrganizationalStructureAdminCommands wrapped,
    ChangeObserver observer)
  {
    _wrapped = wrapped;
    _observer = observer;
  }

  void Make(Change change)
  { 
    _wrapped.Make(change);
    _observer.NotifyAbout(change);
  }
  
  //...other administrative methods
}
~~~

If we did not separate interfaces for admin and client access, in our `NotifyingAdminComands` class, we would have to implement the `ListAllEmployees` method (and others) and make it delegate to the original wrapped instance. This is not difficult, but it's unnecessary effort. Splitting the interface into two smaller ones spared us this trouble.

#### Interfaces should depend on abstractions, not implementation details

You might think that interface is an abstraction by definition. I believe otherwise - while interfaces abstract away the concrete type of the class that is implementing the interface, they may still contain some
other things not abstracted, exposing some implementation details. Let's look at the following interface:

{lang="csharp"}
~~~
public interface Basket
{
  void WriteTo(SqlConnection sqlConnection);
  bool IsAllowedToEditBy(SecurityPrincipal user);
}
~~~

See the arguments of those methods? `SqlConnection` is a library object for interfacing directly with SQL Server database, so it is a very concrete dependency. `SecurityPrincipal` is one of the core classes of
.NET's authentication and authorization model for local users database and Active Directory, so again, a very concrete dependency. With dependencies like that, it will be very hard to write other implementations of this interface, because we will be forced to drag around concrete dependencies and mostly will not be able to work around that if we want something different. Thus, we may say that these are implementation details exposed in the interface that, for this reason, cannot be abstract. It is essential to abstract these implementation details away, e.g. like this:

{lang="csharp"}
~~~
public interface Basket
{
  void WriteTo(ProductOutput output);
  bool IsAllowedToEditBy(BasketOwner user);
}
~~~

This is better. For example, as `ProductOutput` is a higher level abstraction (most probably an interface, as we discussed earlier) no implementation of the `WriteTo` method must be tied to any particular storage kind. This means that we are more free to develop different implementations of this method. In addition, each implementation of the `WriteTo` method is more useful as it can be reused with different kinds of `ProducOutput`s.

So the general rule is: make interfaces real abstractions by abstracting away the implementation details from them. Only then are you free to create different implementations of the interface that are not constrained by dependencies they do not want or need.

### Protocols

You already know that objects are connected (composed) together and communicate through interfaces, just as in IP network. There is another similarity though, that's as important as this one. It's *protocols*. In this section, we will look at protocols between objects and their place on our design approach.

#### Protocols exist

I do not want to introduce any scientific definition, so let's just establish an understanding that protocols are sets of rules about how objects communicate with each other. Really? Are there any rules? Is it
not enough the the objects can be composed together through interfaces, as I explained in previous sections? Well, no, it's not enough and let me give you a quick example.

Let us imagine a class `Sender` that, in one of its methods, asks `Recipient` (let's assume `Recipient` is an interface) for status code extracted from some kind of response and makes a decision based on that code whether or not to notify an observer about an error:

{lang="csharp"}
~~~
if(recipient.ExtractStatusCodeFrom(response) == -1)
{
  observer.NotifyErrorOccured();
}
~~~

Simplistic as it is, the example shows one important thing. Whoever the `recipient` is, it is expected to report error by returning a value of `-1`. Otherwise, the `Sender` (which is explicitly checking for this value) will not be able to react to the error situation appropriately. Similarly, if there is no error, the recipient must not report this using `-1`, because if it does, the `Sender` will be mistakenly recognize this as error. So for example this implementation of `Recipient`, although implementing the interface required by `Sender`, is wrong, because it does not behave as `Sender` expects it to:

{lang="csharp"}
~~~
public class WrongRecipient : Recipient
{
  public int ExtractStatusFrom(Response response)
  {
    if( /* success */ )
    {
      return -1; // but other than -1 should be used!
    }
    else
    {
      return 1; // -1 should be used!
    }
  }
}
~~~

So as you see, we cannot just write anything in a class implementing an interface, because of a protocol that imposes certain constraints on both a sender and a recipient. 

This contract may not only be about return values, it can also be on types of exceptions thrown, or the order of method calls. For example, anybody using some kind of connection object would imagine the following way of using the connection: first open it, then do something with it and close it when finished, e.g.

{lang="csharp"}
~~~
connection.Open();
connection.Send(data);
connection.Close();
~~~

Again, if we were to implement a connection that behaves like this:

{lang="csharp"}
~~~
public class WrongConnection : Connection
{
  public void Open()
  {
    // implementation 
    // for closing the connection!! 
  }

  public void Close()
  {
    // implementation for
    // opening the connection!! 
  }
}
~~~

it would compile just fine, but fail badly when executed. This is, because the behavior would be against the protocol set between `Connection` abstraction and its user.

So, again, there are certain rules that restrict the way two objects can communicate. Both sender and recipient of a message must adhere to the rules, or the they will not be able to work together.

The good news is that, most of the time, WE are the ones who design these protocols, along with the interfaces, so we can design them to be harder or easier to adhere to by different implementations of an interface. Of course, we are wholeheartedly for the "easier" part.

#### Communication patterns stability

Remember our last story about Johnny and Benjamin when they had to make a design change in order to add another kind of employees to the application? In order to do that, they had to change existing interfaces and add new ones. This was a lot of work. We don't want to do this much work every time we make a change, especially when we introduce a new variation of a concept that is already present in our design (e.g. Johnny and Benjamin already had the concept of "employee" and they were adding a new variation of it, called "contractor"). 

In order to achieve this, we need the protocols to be more stable, i.e. less prone to change. By drawing some conclusions from experiences of Johnny and Benjamin, we can say that they had problems with protocols stability because the protocols were:

1.  complicated rather than simple
2.  concrete rather than abstract
3.  large rather than small

Based on analysis of the factors that make the stability of the protocols bad, we can come up with some conditions under which these protocols could be more stable:

1.  protocols should be simple
2.  protocols should be abstract
3.  protocols should be logical
4.  protocols should be small

And there are some heuristics that let us get closer to these qualities:

#### Craft messages to reflect sender's intention

The protocols are simpler if they are designed from the perspective of the object that sends the message, not the one that receives it. In other words, methods should reflect the intention of senders rather than capabilities of recipients.

As an example, let us look at a code for logging in that uses an instance of an `AccessGuard` class:

{lang="csharp"}
~~~
accessGuard.SetLogin(login);
accessGuard.SetPassword(password);
accessGuard.Login();
~~~

In this little snippet, the sender must send three messages to the `accessGuard` object: `SetLogin()`, `SetPassword()` and `Login()`, even though there is no real need to divide the logic into three steps - they are all executed in the same place anyway. The maker of the `AccessGuard` class might have thought that this division makes the class more "general purpose", but it seems this is a "premature optimization" that only makes it harder for the sender to work with the `accessGuard` object. Thus, the protocol that is simpler from the perspective of a sender would be: 

{lang="csharp"}
~~~
accessGuard.LoginWith(login, password);
~~~

Another lesson learned from the above example is: setters rarely reflect senders' intention - more often they are artificial "things" introduced to directly manage object state. This may also have been the reason why someone introduced three messages instead of one - maybe the `AccessGuard` class has two fields inside, so the programmer might have thought someone would want to manipulate them separately... Anyway, setters should be either avoided or changed to something that reflects the intention better. For example, when dealing with observer pattern, we don't want to say: `object.SetObserver(screen)`, but rather something like `object.FromNowOnReportCurrentWeatherTo(screen)`.

The issue of naming can be summarized as: the names of interfaces should be named after the *roles* that their implementations play and methods should be named after the *responsibilities* we want them to have. I love the example that Scott Bain gives in his Emergent Design book[^emergentdesign]: if I told you "give me your driving license number", you might've reacted differently based on whether the driving license is in your pocket, or your wallet, or your bag, or in your home (in which case you would need to call someone to give it to you). The point is: I, as a sender of this "give me your driving license number" message, do not care how you get it. I say `RetrieveDrivingLicenseNumber()`, not `OpenYourWalletAndReadTheNumber()`. This is important, because if the name represents the sender's intention, the method will not have to be renamed when new classes are created that fulfill this intention in a different way.

#### Model interactions after the problem domain

Sometimes at work, I am asked to conduct a design workshop. The example I often give to my colleagues is to design a system for order reservation (customers place orders and shop deliverers can reserve who gets to deliver which order). The thing that struck me the first few times I did this workshop was that even though the application was all about orders and their reservation, nearly none of the attendees introduced any kind of `Order` interface or class with `Reserve()` method on it. Most of the attendees assume that `Order` is a data structure and handle reservation by adding it to a "collection of reserved items" which can be imagined as the following code fragment:

{lang="csharp"}
~~~
// order is just a data structure,
// added to a collection
reservedOrders.Add(order)
~~~

While this achieves the goal in technical terms (i.e. the application works), the code does not reflect the domain. 

If roles, responsibilities and collaborations between objects reflect the domain, then any change that is natural in the domain is natural in the code. If this is not the case, then changes that seem small from the perspective of the problem domain end up touching many classes and methods in highly unusual ways. In other words, the interactions between objects become less stable (which is exactly not what we want).

On the other hand, let's assume that we have modeled the design after the domain and have introduced a proper `Order` role. Then, the logic for reserving an order may look like this:

{lang="csharp"}
~~~
order.ReserveBy(deliverer);
~~~

Note that this line is as stable as the domain itself. It needs to change e.g. when orders are not reserved anymore, or it is not deliverers that reserve the orders. I'd say the stability of this tiny interaction is darn high. Even in cases when the understanding of the domain evolves and changes rapidly, the stability of the domain, although not as high, is still one of the highest the world around us has to offer. 

Let's illustrate this with another example. Let's assume that we have a code for handling alarms. When alarm is triggered, all gates are closed, sirens are turned on and message is sent to special forces with highest priority to arrive and terminate the intruder. Any error in this procedure leads to shutting down power in the building. If this workflow is coded like this:



{lang="csharp"}
~~~
try
{
  gates.CloseAll();
  sirens.TurnOn();
  specialForces.NotifyWith(Priority.High);
} 
catch(SecurityFailure failure)
{
  powerSystem.TurnOffBecauseOf(failure);
}
~~~

Then the risk of this code changing for other reasons than the change of how domain works (e.g. we do not close the gates anymore but activate laser guns instead) is small. Thus, interactions that use abstractions
and methods that directly express domain rules are more stable.

So, to sum up - if a design reflects the domain, it is easier to predict how a change of domain rules affects 
the design. This contributes to maintainability and stability of the interactions and the design as a whole.

#### Message recipients should be told what to do, instead of being asked for information

Let's say we are paying an annual income tax yearly and are too busy (i.e. have too many responsibilities) to do this ourselves. Thus, we hire a tax expert to calculate and pay the taxes for us. He is an expert on paying taxes, knows how to calculate everything, where to submit it etc. But there is one thing he does not know - the context. In other word, he does not know which bank we are using or what we have earned this year that we need to pay the tax for. This is something we need to give him.

Here's the deal between us and the tax expert summarized as a table:

| Who?       | Needs                             |     Can provide                          |
|------------|-----------------------------------|------------------------------------------|
| Us         | The tax paid                      | context (bank, income documents), salary |
| Tax Expert | context (bank, income documents)  | The service of paying the tax            |

It is us who hire the expert and us who initiate the deal. If we were to model this deal as an interaction between two objects, it could e.g. look like this:

{lang="csharp"}
~~~
taxExpert.PayAnnualIncomeTax(
  ourIncomeDocuments,
  ourBank);
~~~

One day, our friend, Joan, tells us she needs a tax expert as well. We are happy with the one we hired, so we recommend him to Joan. She has her own income documents, but they are the same as ours, just with different numbers here and there. Also, Joan uses a different bank, but interacting with any bank these days is almost identical. If we model this as interaction between objects, it may look like this: 

{lang="csharp"}
~~~
taxExpert.PayAnnualIncomeTax(
  joansIncomeDocuments,
  joansBank);
~~~

Thus, when interacting with Joan, the tax expert can still use his abilities to calculate and pay taxes the same way as in our case. This is because his abilities are independent of the context.

Another day, we decide we are not happy anymore with our tax expert, so we decide to make a deal with a new one. Thankfully, we do not need to know how the tax experts do their work - we just tell them to do it, so we can interact with the new one just as with the previous one:

{lang="csharp"}
~~~
//this is the new tax expert, 
//but no change to communication:

taxExpert.PayAnnualIncomeTax(
  ourIncomeDocuments,
  ourBank);
~~~

This small example should not be taken literally. Social interactions are far more complicated and complex than what objects usually do. But I hope I managed to illustrate with it an important aspect of the communication style that is preferred in object oriented design: the Tell Don't Ask heuristic. 

Tell Don't Ask basically means that we, as experts in our job, are not doing what is not our job, but instead relying on other objects that are experts in their respective jobs and provide them with all the context they need to achieve the tasks we want them to do as parameters of the messages we send to them.

This way, a double benefit is gained:
1. Our recipient (e.g. `taxExpert`) can be used by other senders (e.g. pay tax for Joan) without needing to change. All it needs is a different context passed inside a constructor and messages.
2. We, as senders, can easily use different recipients (e.g. different tax experts that do the task they are assigned with differently) without learning how to interact with each new one. 
Actually, if you look at it, as much as bank and documents are a context for the tax expert, the tax expert is a context for us. Thus, we may say that *a design that follows the Tell Don't Ask principle creates classes that are context-independent*.

This has very profound influence on the stability of the protocols. As much as objects are context-independent, they (and their interactions) do not need to change when context changes.

Again, quoting Scott Bain, "what you hide, you can change". Thus, telling an object what to do requires less knowledge than asking for data and information. Going back to the driver license example: I may ask another person for a driving license number to actually make sure they have the license and that it is valid (by checking the number somewhere). I may also ask another person to provide me with the directions to the place I want the first person to drive. But isn't it easier to just tell "buy me some bread and butter"? Then, whoever I ask, has the freedom to either drive, or walk (if they know a good store nearby) or ask yet another person to do it instead. I don't care as long as tomorrow morning, I find the bread and butter in my fridge.

All of these benefits are, by the way, exactly what Johnny and Benjamin were aiming at when refactoring the payroll system. They went from this code, where they *asked* `employee` a lot of questions:

{lang="csharp"}
~~~
var newSalary 
  = employee.GetSalary() 
  + employee.GetSalary() 
  * 0.1;
employee.SetSalary(newSalary);
~~~

to this design that *told* `employee` do do its job:

{lang="csharp"}
~~~
employee.EvaluateRaise();
~~~

This way, they were able to make this code interact with both `RegularEmployee` and `ContractorEmployee` the same way. 

This guideline should be treated very, very seriously and applied in almost an extreme way. There are, of course, few places where it does not apply and we'll get back to them later.

Oh, I almost forgot one thing! The context that we are passing is not necessarily data. It is even more frequent to pass around behavior. For example, in our interaction with the tax expert:

{lang="csharp"}
~~~
taxExpert.PayAnnualIncomeTax(
  ourIncomeDocuments,
  ourBank);
~~~

Bank is probably not a piece of data. Rather, I would imagine Bank to implement an interface that looks like this:

{lang="csharp"}
~~~
public interface Bank
{
  void TransferMoney(
    Amount amount, 
    AccountId sourceAccount,
    AccountId destinationAccount); 
}
~~~

So as you can see, this is behavior, not data, and it itself follows the Tell Don't Ask style as well.

There is one nice advice about creating interactions following this style.

TODO

#### Getters should be removed, return values should be avoided

The above stated guideline of "Tell Don't Ask" has a practical implication of getting rid of (almost) all the getters.

For me, this was very extreme at first, but in a short time I learned that this is actually how I am supposed to write object-oriented code. You see, I started learning programming using structural languages such
as C, where a program was divided into procedures or functions and data structures. Then I moved on to object-oriented languages that allowed far better abstraction, but my style of coding didn't really change
much. I would still have procedures and functions, but now more abstract (divided into objects) and data structures, but now more abstract (i.e. objects with setters, getters and some other query methods).

But what alternatives do we have? Let's say that we have a piece of software that handles user sessions (e.g. modeled using a `Session` class). We want to be able to display the sessions on the GUI, send the
sessions through the network and persist them. How can we do this without getters? Should we put all the code for displaying, sending and storing inside the `Session` class? If we did that, we would couple a
core domain concept (session) to a nasty set of third-party libraries (e.g. a particular GUI library), which would force us to tinker in core domain rules every time some GUI displaying concept changed. Also, if we
did that, the `Session` would be hard to reuse, because every place we would want to reuse the class, we would need to take all these heavy libraries it depends on with us. So, our (not so good, as we will see)
remedy may be to introduce getters for the information pieces stored inside a session:

{lang="csharp"}
~~~
public interface Session
{
  string GetOwner();
  string GetTarget();
  DateTime GetExpiryTime();
}
~~~

So yeah, in a way, we have achieved context independence, because we can
now pull all the data e.g. in a GUI code and display the data and the
`Session` does not know anything about it:

{lang="csharp"}
~~~
// inside GUI code
foreach(var session in sessions)
{
  var tableRow = TableRow.Create();
  tableRow["owner"] = session.GetOwner();
  tableRow["target"] = session.GetTarget();
  tableRow["expiryTime"] = session.GetExpiryTime();
  table.Add(tableRow);
}
~~~

It seems we solved the problem, by pulling data to a place that has the
context, i.e. knows what to do with this data. Are we happy? We may be
unless we look at how the other parts look like - the sending one:

{lang="csharp"}
~~~
//part of sending logic
foreach(var session in sessions)
{
  var message = Message.Blank();
  message.Owner = session.GetOwner();
  message.Target = session.GetTarget();
  message.ExpiryTime = session.GetExpiryTime();
  connection.Send(message);
}
~~~

and the storing one:

{lang="csharp"}
~~~
//part of storing logic
foreach(var session in sessions)
{
  var record = Record.Blank();
  dataRecord.Owner = session.GetOwner();
  dataRecord.Target = session.GetTarget();
  dataRecord.ExpiryTime = session.GetExpiryTime();
  database.Save(record);
}
~~~

See anything disturbing here? If no, then imagine what happens when we
add another piece of information to the `Session`, say, priority. We now
have three places to update and we have to remember to update all of
them every time. This is called "redundancy" or "asking for trouble".
Also, composability of this class is pretty bad, because it will change
a lot just because data in a session changes.

The reason for this is that we made the `Session` class effectively as a
data structure. It does not implement any domain-related behaviors, just
exposes data. There are two implications of this:

this forces all users of this class to define session-related behaviors
on behalf of the `Session`, meaning these behaviors are scattered all
over the place. If one is to make change to the session, they must find
all related behaviors and correct them.

as a set of object behaviors is generally more stable than its internal
data (e.g. a session might have more than one target one day, but we
will always be starting and stopping sessions), this leads to brittle
interfaces and protocols - certainly the opposite of what we are
striving for.

As we see, the solution is pretty bad. But we seem to be out of
solutions. Shouldn't we just accept that there will be problems with
this implementation and move on? Thankfully, no. So far, we have found
the following options to be troublesome:

1.  The `Session` class containing the display, store and send logic,
    i.e. all the context needed - too much coupling to heavy
    dependencies
2.  The `Session` class to expose its data so that we may pull it where
    we have enough context to know how to use it - communication is too
    brittle and redundancy creeps in (by the way, this design will also
    be bad for multithreading, but that's something for another time)

Thankfully, we have a third alternative, which is better than the two we
already mentioned. We can just **pass** the context **into** the
`Session` class. "Isn't this just another way to do what we outlined in
point 1? If we pass the context in, isn't `Session` still coupled to
this context?", you may ask. The answer is: no, because we can make
`Session` class depend on interfaces only to make it
context-independent.

Let's see how this plays out in practice. First let's remove those ugly
getters from the `Session` and introduce new method called `Dump()` that
will take the `Destination` interface as parameter:

{lang="csharp"}
~~~
public interface Session
{
  void DumpInto(Destination destination);
}
~~~

Its implementation can pass all fields into this destination like so:

{lang="csharp"}
~~~
public class TimedSession : Session
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
~~~

And the looping through sessions now looks like this:

{lang="csharp"}
~~~
foreach(var session : sessions)
{
  var newDestination = destinationFactory.Create();
  session.DumpInto(newDestination);
}
~~~

In this design, `Session` itself decides which parameters to pass - no
one is asking for its data. This `Dump()` method is fairly general, so
we can use it to implement all three mentioned behaviors (displaying,
storing, sending), by creating adapters for each type of destination,
e.g. for GUI, it might look like this:

{lang="csharp"}
~~~
public class GuiDestination : Destination
{
  private TableRow _row;
  private Table _table;
  
  public GuiDestination(Table table, TableRow row)
  {
    _table = table;
    _row = row;
  }

  public void AcceptOwner(string owner)
  {
    _row["owner"] = owner;
  }

  public void AcceptTarget(string target)
  {
    _row["target"] = target;
  }

  public void AcceptExpiryTime(DateTime expiryTime)
  {
    _row["expiryTime"] = expiryTime;
  }

  public void Done()
  {
    _table.Add(_row);
  }

}
~~~

Note that with the current design, adding new property to the `Session`
that would need to be displayed, stored or sent, means adding new method
to the `Destination` interface. All implementing classes must implement
this new method, or they stop compiling, so there is no way to
mistakenly forget about one of them.

Also, unnoticeably, the protocol got more stable. Previously, when we
had the getters in the `Session` class:

{lang="csharp"}
~~~
public class Session
{
  string GetOwner();
  string GetTarget();
  DateTime GetExpiryTime();
}
~~~

the getters **had to** return **something**. So what if we didn't want
to display, send and store expired timed sessions anymore? we would have
to add another getter, called `IsExpired()` and checking it
everywhere... you see where this is going. On the other hand, with the
current design of the `Session` interface, we can e.g. introduce a
feature where the expired sessions are not processed at all:

{lang="csharp"}
~~~
public class TimedSession : Session
{
  //...

  public void DumpInto(Destination destination)
  {
    if(!IsExpired())
    {
      destination.AcceptOwner(this.owner);
      destination.AcceptTarget(this.target);
      destination.AcceptExpiryTime(this.expiryTime);
      destination.Done();
    }
  }

  //...
}
~~~

and there is no need to change any other code to get this working.

Another added bonus of this situation that we do not have to return
anything from methods is that we are free to apply proxy and decorator
patterns more freely. For example, we may have hidden sessions, that are
not displayed at all, but retain the rest of the session functionality.
We may implement it as a proxy, that forwards all messages received to
the original, wrapped `Session` object, while discarding the Dump calls:

{lang="csharp"}
~~~
public class HiddenSession : Session
{
  private Session _innerSession;

  public HiddenSession(Session innerSession)
  {
    _innerSession = innerSession;
  }

  public void DoSomethig()
  {
    // forward the message:
    _innerSession.DoSomething();
  }

  //...

  public void DumpInto(Destination destination)
  {
    // discard the message - do nothing
  }

  //...
}
~~~

The most important thing is that when we are not forced to return
anything, we are more free to do as we like. Again, "Tell, don't ask".

The notion of passing context where the data is instead of pulling the
data right into the context is often referred to as "context
independence". Context independence is not only about passing context in
methods - it applies to constructors the same way. Being context
independent is one of the most important requirements for a class to be
composable with other classes.

### Single Responsibility

I already said that we want our system to be a web of composable
objects. Also, I said that we want to be able to unplug a cluster of
objects at any place and plug in something different. TODO

TODO

#### Law of Demeter

As we discovered, exposing return values makes the protocols more
complex and should be avoided if possible. TODO do we need this at all?

Law of Demeter. Coupling to details of return values.

Size of protocols. Even interface with a single method can return a lot
of values. Example: different reports produced.

#### Context independence

TODO

#### Instead of pulling the data where context is, pass the context where the data is

If you are like me, you probably learned programming starting from
procedural languages.

this may sound like something non obvious

1.  data - the information
2.  context - what we want to do with information

e.g. for employees:

1.  data - employee name surname etc.
2.  context - we want to print it on the screen

TODO example: with employees loop getters refactoring

May be more coupling, but the coupling is very light - just an abstract
interface, especially if we were following the rest guidelines. On the
other hand, better information hiding and decoupling users from details.

#### Protocols should rely on abstractions

e.g. Id abstraction can be either in or string or a combination of
those. The protocol stays stable regardless of these changes

Plural is also an abstraction

--------------------------------

#### Interactions are not an implementation detail

Todo interfaces checked by compiler, protocols not

### multiple interfaces multiple roles

Protocols must be published! They are not private internal details

### Tell Don't Ask

### Level of abstraction of protocols

weaker = harder to implement another implementation

stad wynika ze lepiej uzywac interfejsow niz klas

TOOODOOO

1.  Composition through constructor - a reference is passed by
    constructor
2.  Composition through factory
3.  Composition through setter
4.  Composition through passed in a method parameter

Why did I leave out inline creation and singletons? context independence!
-------------------------------------------------------------------------

1.  composability - learned from previous chapters
2.  what does it mean to compose - obtain reference. Plug objects
    together - show UML version of composition first, then the version
    with "plugs".
3.  composability long term (through constructor or setter) or short
    term (through parameter)?
4.  composability - strong or weak a) class vs interface, b)(continuum
    -public field, getter, method that does something)
5.  In order to compose - Protocols vs interfaces
6.  Abstract protocols are better
7.  web of composable objects - like a real web - metaphor (when?)
8.  Tell Don't Ask (when?)
9.  Why not events? Roles!!!
10. discover interfaces - from inside or outside?
11. need driven development

TODO

[^interfacesegregation]: http://www.objectmentor.com/resources/articles/isp.pdf

[^emergentdesign]: Scott Bain, Emergent Design

[^humanprotocols]: Of course, human interactions are way more complex, so I am not trying to tell you "object interaction is like human interaction", just using this example as a nice illustration. 
