# Protocols

You already know that objects are connected (composed) together and communicate through interfaces, just as in IP network. There is one more similarity, that's as important. It's *protocols*. In this section, we will look at protocols between objects and their place on our design approach.

## Protocols exist

I do not want to introduce any scientific definition, so let's just establish an understanding that protocols are sets of rules about how objects communicate with each other. 

Really? Are there any rules? Is it not enough the the objects can be composed together through interfaces, as I explained in previous sections? Well, no, it's not enough and let me give you a quick example.

Let's imagine a class `Sender` that, in one of its methods, asks `Recipient` (let's assume `Recipient` is an interface) to extract status code from some kind of response object and makes a decision based on that code whether or not to notify an observer about an error:

```csharp
if(recipient.ExtractStatusCodeFrom(response) == -1)
{
  observer.NotifyErrorOccured();
}
```

This design is a bit simplistic, but never mind. Its role is to make a certain point. Whoever the `recipient` is, it is expected to report error by returning a value of `-1`. Otherwise, the `Sender` (which is explicitly checking for this value) will not be able to react to the error situation appropriately. Similarly, if there is no error, the recipient must not report this by returning `-1`, because if it does, the `Sender` will be mistakenly recognize this as error. So for example this implementation of `Recipient`, although implementing the interface required by `Sender`, is wrong, because it does not behave as `Sender` expects it to:

```csharp
public class WrongRecipient : Recipient
{
  public int ExtractStatusFrom(Response response)
  {
    if( /* success */ )
    {
      return -1; // but -1 is for errors!
    }
    else
    {
      return 1; // -1 should be used!
    }
  }
}
```

So as you see, we cannot just write anything in a class implementing an interface, because of a protocol that imposes certain constraints on both a sender and a recipient. 

This protocol may not only determine the return values necessary for two objects to interact properly, it can also determine types of exceptions thrown, or the order of method calls. For example, anybody using some kind of connection object would imagine the following way of using the connection: first open it, then do something with it and close it when finished, e.g.

```csharp
connection.Open();
connection.Send(data);
connection.Close();
```

Assuming the above `connection` is an implementation of `Connection` interface, if we were to implement it like this:

```csharp
public class WrongConnection : Connection
{
  public void Open()
  {
    // imagine implementation 
    // for *closing* the connection is here!! 
  }

  public void Close()
  {
    // imagine implementation for
    // *opening* the connection is here!! 
  }
}
```

it would compile just fine, but fail badly when executed. This is because the behavior would be against the protocol set between `Connection` abstraction and its user. All implementations of `Connection` must follow this protocol.

So, again, there are certain rules that restrict the way two objects can communicate. Both sender and recipient of a message must adhere to the rules, or the they will not be able to work together.

The good news is that, most of the time, *we* are the ones who design these protocols, along with the interfaces, so we can design them to be either easier or harder to follow by different implementations of an interface. Of course, we are wholeheartedly for the "easier" part.

## Protocol stability

Remember the last story about Johnny and Benjamin when they had to make a design change to add another kind of employees (contractors) to the application? To do that, they had to change existing interfaces and add new ones. This was a lot of work. We don't want to do this much work every time we make a change, especially when we introduce a new variation of a concept that is already present in our design (e.g. Johnny and Benjamin already had the concept of "employee" and they were adding a new variation of it, called "contractor"). 

To achieve this, we need the protocols to be more stable, i.e. less prone to change. By drawing some conclusions from experiences of Johnny and Benjamin, we can say that they had problems with protocols stability because the protocols were:

1.  complicated rather than simple
2.  concrete rather than abstract
3.  large rather than small

Based on analysis of the factors that make the stability of the protocols bad, we can come up with some conditions under which these protocols could be more stable:

1.  protocols should be simple
2.  protocols should be abstract
3.  protocols should be logical
4.  protocols should be small

And there are some heuristics that let us get closer to these qualities:

## Craft messages to reflect sender's intention

The protocols are simpler if they are designed from the perspective of the object that sends the message, not the one that receives it. In other words, methods should reflect the intention of senders rather than capabilities of recipients.

As an example, let's look at a code for logging in that uses an instance of an `AccessGuard` class:

```csharp
accessGuard.SetLogin(login);
accessGuard.SetPassword(password);
accessGuard.Login();
```

In this little snippet, the sender must send three messages to the `accessGuard` object: `SetLogin()`, `SetPassword()` and `Login()`, even though there is no real need to divide the logic into three steps -- they are all executed in the same place anyway. The maker of the `AccessGuard` class might have thought that this division makes the class more "general purpose", but it seems this is a "premature optimization" that only makes it harder for the sender to work with the `accessGuard` object. Thus, the protocol that is simpler from the perspective of a sender would be: 

```csharp
accessGuard.LoginWith(login, password);
```

### Naming by intention

Another lesson learned from the above example is: setters (like `SetLogin` and `SetPassword` in our example) rarely reflect senders' intentions -- more often they are artificial "things" introduced to directly manage object state. This may also have been the reason why someone introduced three messages instead of one -- maybe the `AccessGuard` class was implemented to hold two fields (login and password) inside, so the programmer might have thought someone would want to manipulate them separately from the login step... Anyway, setters should be either avoided or changed to something that reflects the intention better. For example, when dealing with observer pattern, we don't want to say: `SetObserver(screen)`, but rather something like `FromNowOnReportCurrentWeatherTo(screen)`.

The issue of naming can be summarized as this: a name of an interface should be assigned after the *role* that its implementations play and methods should be named after the *responsibilities* we want the role to have. I love the example that Scott Bain gives in his Emergent Design book[^emergentdesign]: if I asked you to give me your driving license number, you might've reacted differently based on whether the driving license is in your pocket, or your wallet, or your bag, or in your house (in which case you would need to call someone to read it for you). The point is: I, as a sender of this "give me your driving license number" message, do not care how you get it. I say `RetrieveDrivingLicenseNumber()`, not `OpenYourWalletAndReadTheNumber()`. 

This is important, because if the name represents the sender's intention, the method will not have to be renamed when new classes are created that fulfill this intention in a different way.

## Model interactions after the problem domain

Sometimes at work, I am asked to conduct a design workshop. The example I often give to my colleagues is to design a system for order reservations (customers place orders and shop deliverers can reserve who gets to deliver which order). The thing that struck me the first few times I did this workshop was that even though the application was all about orders and their reservation, nearly none of the attendees introduced any kind of `Order` interface or class with `Reserve()` method on it. Most of the attendees assume that `Order` is a data structure and handle reservation by adding it to a "collection of reserved items" which can be imagined as the following code fragment:

```csharp
// order is just a data structure,
// added to a collection
reservedOrders.Add(order)
```

While this achieves the goal in technical terms (i.e. the application works), the code does not reflect the domain. 

If roles, responsibilities and collaborations between objects reflect the domain, then any change that is natural in the domain is natural in the code. If this is not the case, then changes that seem small from the perspective of the problem domain end up touching many classes and methods in highly unusual ways. In other words, the interactions between objects becomes less stable (which is exactly what we want to avoid).

On the other hand, let's assume that we have modeled the design after the domain and have introduced a proper `Order` role. Then, the logic for reserving an order may look like this:

```csharp
order.ReserveBy(deliverer);
```

Note that this line is as stable as the domain itself. It needs to change e.g. when orders are not reserved anymore, or someone other than deliverers starts reserving the orders. Thus, I'd say the stability of this tiny interaction is darn high. 

Even in cases when the understanding of the domain evolves and changes rapidly, the stability of the domain, although not as high as usually, is still one of the highest the world around us has to offer. 

### Another example

Let's assume that we have a code for handling alarms. When an alarm is triggered, all gates are closed, sirens are turned on and a message is sent to special forces with the highest priority to arrive and terminate the intruder. Any error in this procedure leads to shutting down power in the building. If this workflow is coded like this:

```csharp
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
```

Then the risk of this code changing for other reasons than the change of how domain works (e.g. we do not close the gates anymore but activate laser guns instead) is small. Thus, interactions that use abstractions and methods that directly express domain rules are more stable.

So, to sum up -- if a design reflects the domain, it is easier to predict how a change of domain rules will affect  the design. This contributes to maintainability and stability of the interactions and the design as a whole.

## Message recipients should be told what to do, instead of being asked for information

Let's say we are paying an annual income tax yearly and are too busy (i.e. have too many responsibilities) to do this ourselves. Thus, we hire a tax expert to calculate and pay the taxes for us. He is an expert on paying taxes, knows how to calculate everything, where to submit it etc. but there is one thing he does not know -- the context. In other word, he does not know which bank we are using or what we have earned this year that we need to pay the tax for. This is something we need to give him.

Here's the deal between us and the tax expert summarized as a table:

| Who?       | Needs                             |     Can provide                          |
|------------|-----------------------------------|------------------------------------------|
| Us         | The tax paid                      | context (bank, income documents)         |
| Tax Expert | context (bank, income documents)  | The service of paying the tax            |

It is us who hire the expert and us who initiate the deal, so we need to provide the context, as seen in the above table. If we were to model this deal as an interaction between two objects, it could e.g. look like this:

```csharp
taxExpert.PayAnnualIncomeTax(
  ourIncomeDocuments,
  ourBank);
```

One day, our friend, Joan, tells us she needs a tax expert as well. We are happy with the one we hired, so we recommend him to Joan. She has her own income documents, but they are functionally similar to ours, just with different numbers here and there and maybe some different formatting. Also, Joan uses a different bank, but interacting with any bank these days is almost identical. Thus, our tax expert knows how to handle her request. If we model this as interaction between objects, it may look like this: 

```csharp
taxExpert.PayAnnualIncomeTax(
  joansIncomeDocuments,
  joansBank);
```

Thus, when interacting with Joan, the tax expert can still use his abilities to calculate and pay taxes the same way as in our case. This is because his skills are independent of the context.

Another day, we decide we are not happy anymore with our tax expert, so we decide to make a deal with a new one. Thankfully, we do not need to know how tax experts do their work -- we just tell them to do it, so we can interact with the new one just as with the previous one:

```csharp
//this is the new tax expert, 
//but no change to the way we talk to him:

taxExpert.PayAnnualIncomeTax(
  ourIncomeDocuments,
  ourBank);
```

This small example should not be taken literally. Social interactions are far more complicated and complex than what objects usually do. But I hope I managed to illustrate with it an important aspect of the communication style that is preferred in object-oriented design: the *Tell Don't Ask* heuristic. 

Tell Don't Ask basically means that each object, as an expert in its job, is not doing what is not its job, but instead relying on other objects that are experts in their respective jobs and provide them with all the context they need to achieve the tasks it wants them to do as parameters of the messages it sends to them.

This can be illustrated with a generic code pattern:

```csharp
recipient.DoSomethingForMe(allTheContextYouNeedToKnow);
```

This way, a double benefit is gained:

 1.  Our recipient (e.g. `taxExpert` from the example) can be used by other senders (e.g. pay tax for Joan) without needing to change. All it needs is a different context passed inside a constructor and messages.
 1.  We, as senders, can easily use different recipients (e.g. different tax experts that do the task they are assigned with differently) without learning how to interact with each new one. 

If you look at it, as much as bank and documents are a context for the tax expert, the tax expert is a context for us. Thus, we may say that *a design that follows the Tell Don't Ask principle creates classes that are context-independent*.

This has very profound influence on the stability of the protocols. As much as objects are context-independent, they (and their interactions) do not need to change when context changes.

Again, quoting Scott Bain, "what you hide, you can change". Thus, telling an object what to do requires less knowledge than asking for data and information. Again using the driver license metaphor: I may ask another person for a driving license number to make sure they have the license and that it is valid (by checking the number somewhere). I may also ask another person to provide me with the directions to the place I want the first person to drive. But isn't it easier to just tell "buy me some bread and butter"? Then, whoever I ask, has the freedom to either drive, or walk (if they know a good store nearby) or ask yet another person to do it instead. I don't care as long as tomorrow morning, I find the bread and butter in my fridge.

All of these benefits are, by the way, exactly what Johnny and Benjamin were aiming at when refactoring the payroll system. They went from this code, where they *asked* `employee` a lot of questions:

```csharp
var newSalary 
  = employee.GetSalary() 
  + employee.GetSalary() 
  * 0.1;
employee.SetSalary(newSalary);
```

to this design that *told* `employee` do do its job:

```csharp
employee.EvaluateRaise();
```

This way, they were able to make this code interact with both `RegularEmployee` and `ContractorEmployee` the same way.

This guideline should be treated very, very seriously and applied in almost an extreme way. There are, of course, few places where it does not apply and we'll get back to them later.

Oh, I almost forgot one thing! The context that we are passing is not necessarily data. It is even more frequent to pass around behavior than to pass data. For example, in our interaction with the tax expert:

```csharp
taxExpert.PayAnnualIncomeTax(
  ourIncomeDocuments,
  ourBank);
```

Bank is probably not a piece of data. Rather, I would imagine Bank to implement an interface that looks like this:

```csharp
public interface Bank
{
  void TransferMoney(
    Amount amount, 
    AccountId sourceAccount,
    AccountId destinationAccount); 
}
```

So as you can see, this `Bank` is a piece of behavior, not data, and it itself follows the Tell Don't Ask style as well (it does something well and takes all the context it needs from outside).

### Where Tell Don't Ask does not apply

As I already said, there are places where Tell Don't Ask does not apply. Here are some examples from the top of my head: 

1. Factories -- these are objects that produce other objects for us, so they are inherently "pull-based" -- they are always asked to deliver objects.
2. Collections -- they are merely containers for objects, so all we want from them is adding objects and retrieving objects (by index, by predicate, using a key etc.). Note however, that when we write a class that wraps a collection inside, we want this class to expose interface shaped in a Tell Don't Ask manner.
3. Data sources, like databases -- again, these are storage for data, so it is more probable that we will need to ask for this data to get it.
4. Some APIs accessed via network -- while it is good to use as much Tell Don't Ask as we can, web APIs have one limitation -- it is hard or impossible to pass behaviors as polymorphic objects through them. Usually, we can only pass data.
5. So called "fluent APIs", also called "internal domain-specific languages"[^domainspecificlanguages]

Even in cases where we obtain other objects from a method call, we want to be able to apply Tell Don't Ask to these other objects. For example, we want to avoid the following chain of calls:

```csharp
Radio radio = radioRepository().GetRadio(12);
var userName = radio.GetUsers().First().GetName();
primaryUsersList.Add(userName);
```

This way we make the communication tied to the following assumptions:

1.  Radio has many users
2.  Radio must have at least one user
3.  Each user must have a name
4.  The name is not null

On the other hand, consider this implementation:

```csharp
Radio radio = radioRepository().GetRadio(12);
radio.AddPrimaryUserNameTo(primaryUsersList);
```

It does not have any of the weaknesses of the previous example. Thus, it is more stable in face of change.
 

## Most of the getters should be removed, return values should be avoided

The above stated guideline of "Tell Don't Ask" has a practical implication of getting rid of (almost) all the getters. We did say that each object should stick to its work and tell other objects to do their work, passing context to them, didn't we? If so, then why should we "get" anything from other objects?

For me the idea of "no getters" was very extreme at first, but in a short time I learned that this is in fact how I am supposed to write object-oriented code. You see, I started learning programming using structural languages such as C, where a program was divided into procedures or functions and data structures. Then I moved on to object-oriented languages that had far better mechanisms for abstraction, but my style of coding didn't really change much. I would still have procedures and functions, just divided into objects. I would still have data structures, but now more abstract, e.g. objects with setters, getters and some other query methods.

But what alternatives do we have? Well, I already introduced Tell Don't Ask, so you should know the answer. Even though you should, I want to show you another example, this time specifically about getters and setters. 

Let's say that we have a piece of software that handles user sessions. A session is represented in code using a `Session` class. We want to be able to do three things with our sessions: display them on the GUI, send them through the network and persist them. In our application, we want each of these responsibilities handled by a separate class, because we think it is good if they are not tied together. 

So, we need three classes dealing with data owned by the session. This means that each of these classes should somehow obtain access to the data. Otherwise, how can this data be e.g. persisted? It seems we have no choice and we have to expose it using getters. 

Of course, we might re-think our choice of creating separate classes for sending, persistence etc. and consider a choice where we put all this logic inside a `Session` class. If we did that, however, we would make a core domain concept (a session) dependent on a nasty set of third-party libraries (like a particular GUI library), which would mean that e.g. every time some GUI displaying concept changes, we will be forced to tinker in core domain code, which is pretty risky. Also, if we did that, the `Session` would be hard to reuse, because every place we would want to reuse this class, we would need to take all these heavy libraries it depends on with us. Plus, we would not be able to e.g. use `Session` with different GUI or persistence libraries. So, again, it seems like our (not so good, as we will see) only choice is to introduce getters for the information pieces stored inside a session, like this:

```csharp
public interface Session
{
  string GetOwner();
  string GetTarget();
  DateTime GetExpiryTime();
}
```

So yeah, in a way, we have decoupled `Session` from these third-party libraries and we may even say that we have achieved context-independence as far as `Session` itself is concerned -- we can now pull all its data e.g. in a GUI code and display it as a table. The `Session` does not know anything about it. Let's see that:

```csharp
// Display sessions as a table on GUI
foreach(var session in sessions)
{
  var tableRow = TableRow.Create();
  tableRow.SetCellContentFor("owner", session.GetOwner());
  tableRow.SetCellContentFor("target", session.GetTarget());
  tableRow.SetCellContentFor("expiryTime", session.GetExpiryTime());
  table.Add(tableRow);
}
```

It seems we solved the problemr by separating the data from the context it is used in and pulling data to a place that has the context, i.e. knows what to do with this data. Are we happy? We may be unless we look at how the other parts look like -- remember that in addition to displaying sessions, we also want to send them and persist them. The sending logic looks like this:

```csharp
//part of sending logic
foreach(var session in sessions)
{
  var message = SessionMessage.Blank();
  message.Owner = session.GetOwner();
  message.Target = session.GetTarget();
  message.ExpiryTime = session.GetExpiryTime();
  connection.Send(message);
}
```

and the persistence logic like this:

```csharp
//part of storing logic
foreach(var session in sessions)
{
  var record = Record.Blank();
  dataRecord.Owner = session.GetOwner();
  dataRecord.Target = session.GetTarget();
  dataRecord.ExpiryTime = session.GetExpiryTime();
  database.Save(record);
}
```

See anything disturbing here? If no, then imagine what happens when we add another piece of information to the `Session`, say, priority. We now have three places to update and we have to remember to update all of them every time. This is called "redundancy" or "asking for trouble". Also, composability of these three classes is pretty bad, because they will have to change a lot just because data in a session changes.

The reason for this is that we made the `Session` class effectively a data structure. It does not implement any domain-related behaviors, just exposes data. There are two implications of this:

1.  This forces all users of this class to define session-related behaviors on behalf of the `Session`, meaning these behaviors are scattered all over the place[^featureenvy]. If one is to make change to the session, they must find all related behaviors and correct them.
2.  As a set of object behaviors is generally more stable than its internal data (e.g. a session might have more than one target one day, but we will always be starting and stopping sessions), this leads to brittle interfaces and protocols -- certainly the opposite of what we are striving for.

Bummer, this solution is pretty bad, but we seem to be out of options. Should we just accept that there will be problems with this implementation and move on? Thankfully, we don't have to. So far, we have found the following options to be troublesome:

1.  The `Session` class containing the display, store and send logic, i.e. all the context needed -- too much coupling to heavy dependencies.
2.  The `Session` class to expose its data via getters, so that we may pull it where we have enough context to know how to use it -- communication is too brittle and redundancy creeps in (by the way, this design will also be bad for multithreading, but that's something for another time).

Thankfully, we have a third alternative, which is better than the two we already mentioned. We can just **pass** the context **into** the `Session` class. "Isn't this just another way to do what we outlined in point 1? If we pass the context in, isn't `Session` still coupled to this context?", you may ask. The answer is: not necessarily, because we can make `Session` class depend on interfaces only instead of the real thing to make it context-independent enough.

Let's see how this plays out in practice. First let's remove those ugly getters from the `Session` and introduce new method called `DumpInto()` that will take a `Destination` interface implementation as a parameter:

```csharp
public interface Session
{
  void DumpInto(Destination destination);
}
```

The implementation of `Session`, e.g. a `RealSession` can pass all fields into this destination like so:

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

And the looping through sessions now looks like this:

```csharp
foreach(var session : sessions)
{
  session.DumpInto(destination);
}
```

In this design, `RealSession` itself decides which parameters to pass and in what order (if that matters) -- no one is asking for its data. This `DumpInto()` method is fairly general, so we can use it to implement all three mentioned behaviors (displaying, persistence, sending), by creating a implementation for each type of destination, e.g. for GUI, it might look like this:

```csharp
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
    _row.SetCellContentFor("owner", owner);
  }

  public void AcceptTarget(string target)
  {
    _row.SetCellContentFor("target", target);
  }

  public void AcceptExpiryTime(DateTime expiryTime)
  {
    _row.SetCellContentFor("expiryTime", expiryTime);
  }

  public void Done()
  {
    _table.Add(_row);
  }
}
```

The protocol is now more stable as far as the consumers of session data are concerned. Previously, when we had the getters in the `Session` class:

```csharp
public class Session
{
  string GetOwner();
  string GetTarget();
  DateTime GetExpiryTime();
}
```

the getters **had to** return **something**. So what if we had sessions that could expire and decided we want to ignore them when they do (i.e. do not display, store, send or do anything else with them)? In case of the "getter approach" seen in the snippet above, we would have to add another getter, e.g. called `IsExpired()` to the session class and remember to update each consumer the same way -- to check the expiry before consuming the data... you see where this is going, don't you? On the other hand, with the current design of the `Session` interface, we can e.g. introduce a feature where the expired sessions are not processed at all in a single place:

```csharp
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
```

and there is no need to change any other code to get this working[^statemachine]. 

 Another advantage of designing/making `Session` to not return anything from its methods is that we have more flexibility in applying patterns such as proxy and decorator to the `Session` implementations. For example, we can use proxy pattern to implement hidden sessions that are not displayed/stored/sent at all, but at the same time behave like another session in all the other cases. Such a proxy forwards all messages it receives to the original, wrapped `Session` object, but discards the `DumpInto()` calls: 

```csharp
public class HiddenSession : Session
{
  private Session _innerSession;

  public HiddenSession(Session innerSession)
  {
    _innerSession = innerSession;
  }

  public void DoSomethig()
  {
    // forward the message to wrapped instance:
    _innerSession.DoSomething();
  }

  //...

  public void DumpInto(Destination destination)
  {
    // discard the message - do nothing
  }

  //...
}
```

The clients of this code will not notice this change at all. When we are not forced to return anything, we are more free to do as we like. Again, "Tell, don't ask".

## Protocols should be small and abstract

I already said that interfaces should be small and abstract, so am I not just repeating myself here? The answer is: there is a difference between the size of protocols and the size of interfaces. As an extreme example, let's take the following interface:

```csharp
public interface Interpreter
{
  public void Execute(string command);
}
```

Is the interface small? Of course! Is it abstract? Well, kind of, yes. Tell Don't Ask? Sure! But let's see how it's used by one of its collaborators:

```csharp
public void RunScript()
{
  _interpreter.Execute("cd dir1");
  _interpreter.Execute("copy *.cs ../../dir2/src");
  _interpreter.Execute("copy *.xml ../../dir2/config");
  _interpreter.Execute("cd ../../dir2/");
  _interpreter.Execute("compile *.cs");
  _interpreter.Execute("cd dir3");
  _interpreter.Execute("copy *.cs ../../dir4/src");
  _interpreter.Execute("copy *.xml ../../dir4/config");
  _interpreter.Execute("cd ../../dir4/");
  _interpreter.Execute("compile *.cs");
  _interpreter.Execute("cd dir5");
  _interpreter.Execute("copy *.cs ../../dir6/src");
  _interpreter.Execute("copy *.xml ../../dir6/config");
  _interpreter.Execute("cd ../../dir6/");
  _interpreter.Execute("compile *.cs");
}
```
The point is: the protocol is neither abstract nor small. Thus, making implementations of interface that is used as such can be pretty painful.

## Summary

In this lengthy chapter I tried to show you the often underrated value of designing communication protocols between objects. They are not a "nice thing to have", but rather a fundamental part of the design approach that makes mock objects useful, as you will see when finally we get to them. But first, I need you to swallow few more object-oriented design ideas. I promise it will pay off. 

[^emergentdesign]: Scott Bain, Emergent Design

[^humanprotocols]: Of course, human interactions are way more complex, so I am not trying to tell you "object interaction is like human interaction", just using this example as a nice illustration. 

[^domainspecificlanguages]: This topic is outside the scope of the book, but you can take a look at: M. Fowler, Domain-Specific Languages, Addison-Wesley 2010

[^featureenvy]: This is sometimes called Feature Envy. It means that a class is more interested in other class' data than in its own.

[^statemachine]: We can even further refactor this into a state machine using a Gang of Four *State* pattern. There would be two states in such a state machine: started and expired.
