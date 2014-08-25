Achieving the best composability
===============================

Some classes are harder to compose with other classes, others are
easier. There are numerous factors influencing this:

### Classes vs interfaces

As we said, an object is composed with another object by obtaining a
reference to something. Also, we said that we want the flexibility of
plugging in objects of different classes at different times. This is, of
course, done using polymorphism, as Johnny and Benjamin did when
cleaning up the payroll system. So, what should be the base for
polymorphism? Is a class sufficient, or do we rather want to use an
interface? In other words, when we plug in an object as a message
receipient:

{lang="csharp"}
~~~
public Sender(Recipient recipient)
{
  this._recipient = recipient;
}
~~~

Should the Recipient be a class or an interface?

If we assume that Recipient is a class, we can get the composability we
want by deriving another class from it and overriding methods. However,
using a class as a base for composability has the following weaknesses:

1.  The superclass may have real dependencies. For example, if
    `Recipient` class depends on WCF stack, then everywhere we take our
    Sender to compose it with different recipients, we must also take
    our `Recipient` and its WCF dependency.
2.  We force each recipient class we want to compose our sender with to
    invoke a constructor from superclass, which, depending on the
    complexity of the superclass, may be smaller or bigger trouble.
3.  In languages like C\#, when only single inheritance exists all the
    classes that want to be composed with our `Sender`, we waste the
    only inheritance slot, further constraining the inheriting classes.
4.  We must take care to make all methods of `Recipient` superclass
    virtual to enable overriding by subclasses. otherwise, we won't have
    full composability.

As you see, there are some difficulties using classes as "slots for
composability", even if composition is possible this way. Thus,
interfaces are far better, just because they are easier to use for this
purpose.

It is decided then, If a sender wants to be composable with recipient,
it has to accept a reference to recipient in form of interface
reference. We can say that, by being lightweight and
implementationless, **interfaces can be treated as "slots" for plugging
in different objects**.

In fact, when we look at how interfaces are depicted on UML class
diagrams, it seems that the "interface as slot for composition" notion
is not unusual:

TODO insert a picture showing one notation of interfaces in UML.

It is just that we try to take the notion of composability to its
fullest, as not only a first-class citizen, but as THE most important
aspect of our design approach.

### Events/callbacks vs interfaces - few words on roles

Hey, didn't I just say that composability is "THE most important aspect
of our design approach"? Wow, that's quite a statement, isn't it?
Unfortunately for me, it also lets you jump with the following argument:
"what about events that e.g. C\# supports? Or callbacks that are
supported almost everywhere? Wouldn't it make the classes even more
context-independent, if we made them communicate by events or callbacks,
not by some strange interfaces?"

Actually, it would, and we could, but it would also strip us from
another very important aspect of our design approach that I did not
mention explicitly until now. This aspect is: roles.

When we take an example method that sends some messages to some
recipients:

{lang="csharp"}
~~~
recipient1.DoX();
recipient1.DoY();
recipient2.DoZ();
~~~

and we compare it with similar effect achieved using event/callback
invocation:

{lang="csharp"}
~~~
DoX.Invoke();
DoY.Invoke();
DoZ.Invoke();
~~~

We can see that we are losing the notion of which message belongs to
which recipient - each event is standalone from the point of view of the
sender. This is unfortunate, because in our design approach, we want to
highlight the roles each receiver plays in the communication, to make
the communication itself readable and logical. Also, ironically,
decoupling this way using events or callbacks can hinder composability,
because the set of responsibilities that fits a single role is usually
cohesive. Thus, even if we separated it into several events or
callbacks, their composition would be changing together anyway, and an
overhead would be put on us to remember which events should be changed
together, and which ones separately.

This does not mean that events or callbacks are bad. It's just that they
are not a fit replacement for interfaces - in reality, their purpose is
a little bit different. We use events or callbacks not to do somebody to
do something, but to indicate what happened (that's why we call them
events, after all...). This fits the observer case we talked about quite
well. So, instead of using observer objects, we may consider using
events or callbacks instead (as in everything, there are some tradeoffs
for each of the solutions). In other words, events and callbacks have
their role in the composition, but fit a case so specific, that they
cannot be used as a basis for the composition. The advantage of the
interfaces is that they bind together messages, which should be
implemented cohesively, and symbolize roles in the communication, which
improves readability.

### Small interfaces

Ok, so we said that he interfaces are "the way to go" for reaching the
strong composability we're striving for. Is it enough just to "have
interfaces"? No, actually, it's not.

One of the other things we need to consider is the size of interfaces.
Let's state one thing that is obvious in regard to this:

**All other things equal, smaller interfaces are easier to implement
that bigger interfaces.**

The obvious conclusion from this is that if we want to have really
strong composability, our "slots", i.e. interfaces, have to be as small
as possible (but not smaller - see previous section on interfaces vs
events/callbacks. Interfaces must bind together messages that should be
handled cohesively). Of course, we cannot achieve this by just removing
methods that are needed from the interfaces, e.g. when someone is using
an interface implementation like this:

{lang="csharp"}
~~~
recipient.SomethingHappened();
recipient.SomethingElseHappened();
~~~

It is impossible to just remove either method from the interface, or the
client will stop compiling.

So, what do we do then? We try to separate different interfaces per
client. After all, a class can implement more than one interface, like
this:

{lang="csharp"}
~~~
public class ImplementingObject 
: InterfaceForClient1, 
  InterfaceForClient2,
  InterfaceForClient3
{ ... }
~~~

This notion of using a separate interface per client and not one bigger
interface for different clients is known as the Interface Segregation
Principle.

#### A simple example: separation of reading from writing

For example, we may have a class representing organizational structure
in our application. On one hand, the application is notified on any
changes that are made from administration interface. On the other hand,
it supports client-side operations for ordinary users, e.g. listing all
users. The interface for this organizational structure class may look
like this:

{lang="csharp"}
~~~
public interface 
OrganizationStructure
{
  //administrative part:
  void Make(Change change);
  
  //client-side part:
  void ListAllEmployees(
    EmployeeDestination destination);
}
~~~

but, most certainly, the two sets of methods will be used by different
code - one related to handling administrative requests, another related
to handling ordinary user requests. Thus, we can use this knowledge to
separate the interface into two:

{lang="csharp"}
~~~
public interface
OrganizationalStructureAdminCommands
{
  void Make(Change change);
}

public interface
OrganizationalStructureClientCommands
{
  void ListAllEmployees(
    EmployeeDestination destination);
}
~~~

And a real class can implement both of them:

{lang="csharp"}
~~~
public class InMemoryOrganizationalStructure
: OrganizationalStructureAdminCommands,
  OrganizationalStructureClientCommands
{
  //...
}
~~~

Sure, there are more interfaces, but that doesn't bother us much,
because in return, each interface is easier to implement. In other
words, it is easier to make new implementations we can compose users of
those interfaces with. This means that composability is enhanced, which
is what we want the most. After all, nobody said there will always be a
single class implementing both interfaces. One day, we maye get a
requirement that all writes to the organizational structure have to be
traced. In such case, All we have to do is to create new class
implementing `OrganizationalStructureAdminCommands` which will wrap the
original method with a notification to a change observer (that can be
either the trace that is required or anything else we like):

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
}
~~~

If we did not separate interfaces for admin and client access, in our
`NotifyingAdminComands` class, we would have to implement the
`ListAllEmployees` method and make it delegate to the original wrapped
instance. Splitting the interface into two smaller ones spared us this
trouble.

#### Interfaces should be depend on abstractions, not implementation details

Some might think that interface is an abstraction by definition. I
believe otherwise - while interfaces abstract away the concrete type of
the class that is implementing the interface, it may still contain some
other things not abstracted, especially implementation details. Let's
look at the following interface:

{lang="csharp"}
~~~
public interface Basket
{
  void WriteTo(SqlConnection sqlConnection);
  bool IsAllowedToEditBy(SecurityPrincipal user);
}
~~~

See the arguments of those methods? `SqlConnection` is a library object
for interfacing directly with SQL Server database, so it is a very
concrete dependency. `SecurityPrincipal` is one of the core classes of
.NET's authentication and authorization model for local users database
and Active Directory, so again, a very concrete dependency. With
dependencies like that, it will be very hard to write other
implementations of this interface, because we will be forced to drag
around concrete dependencies and mostly will not be able to work around
that if we want something different. Thus, it is essential to rely on
abstractions:

{lang="csharp"}
~~~
public interface Basket
{
  void WriteTo(ProductOutput output);
  bool IsAllowedToEditBy(BasketOwner user);
}
~~~

This is better. For example, as `ProductOutput` is a higher level
abstraction (most probably an interface, as we discussed earlier), the
implementations of the `Basket` interface can be developed independently
from the specific output type and the `WriteTo()` method is more useful
as it can be reused with different kinds of outputs.

### Protocols

So, we said that objects are connected (composed) together and
communicate through interfaces, just as in IP network. There is another
similarity though, that's as important. It's protocols (you can also
encounter them by the name of contracts).

#### Protocols exist

I do not want to introduce any scientific definition, so let's just
establish an understanding that protocols are sets of rules about how
objects communicate with each other. Really? Are there any rules? Is it
not enough the the objects can be composed together through interfaces?
Well, not, it's not enough and let me give you a quick example.

Let us imagine a class `Sender` that uses `Recipient` like this:

{lang="csharp"}
~~~
if(recipient.ExtractStatusCodeFrom(response) == -1)
{
  observer.NotifyErrorOccured();
}
~~~

Stupid as it is, the example shows one important thing. Whoever the
recipient is, it is expected to report error as -1. Otherwise, the
`Sender` will not be able to react to the error situation appropriately.
Similarly, the recipient must not report "no error" situation as -1,
because if it does, this will be mistakenly recognized as error by
`Sender`. So for example this implementation of `Recipient`, although
implementing the required interface, is wrong from the point of view of
`Sender`:

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

So as you see, we cannot just write anything in a class implementing an
interface, because of protocol that imposes certain contract on both the
sender and recipient. This contract may not only be about return values,
it can also be on types of exceptions thrown, or the order of method
calls. For example, anybody using some kind of connection object would
imagine the following way of using the connection:

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
    //...close connection
  }

  public void Close()
  {
    //...open connection
  }
}
~~~

it would compile just fine, but fail badly when executed.

So, again, there are certain rules that restrict the way two objects can
communicate. Both sender and recipient of a message must adhere to the
rules, or the they will not be able to work together.

The good news is that WE are the ones who design these protocols, along
with the interfaces, so we can design them to be harder or easier to
adhere to by different implementations of an interface. Of course, we
are wholeheartedly for the "easier" part. Thus, we want the
communication between objects to be as stable as possible (see next
section on the explanation of "as possible").

#### Communication patterns stability

Remember the change Johnny and Benjamin had to make in order to add
another kind of employees to the application? In order to do that, they
had to change existing interfaces and add new ones. This was a lot of
work. We don't want to do this much work every time we make a change.
The reason they had to do so much changes was that the protocol between
the objects they were dealing with was unstable. And they were unstable
because they were:

1.  complicated rather than simple
2.  concrete rather than abstract
3.  large rather than small

Driven by why the stability of the protocols is bad, we can come up with
some qualities that make protocols stable:

1.  protocols should be simple
2.  protocols should be abstract
3.  protocols should be logical
4.  protocols should be small

And there are some heuristics that let us get closer to these qualities:

#### Short interactions

TODO may be many small interfaces we interact with. Constructor bloat

#### Method calls crafted from the perspective of senders

The protocols are simpler if they are designed from the perspective of
the object that sends the signal, not the one that receives it. In other
words, methods should be adjusted to exactly meet the needs of the
senders.

As an example, let us look at a code for logging in:

{lang="csharp"}
~~~
accessGuard.SetLogin(login);
accessGuard.SetPassword(password);
accessGuard.Login();
~~~

In this little snippet, the sender must invoke three methods, even
though there is no real need to divide the logic into three steps - they
are all executed in the same place anyway. The maker of this class might
have thought that this division makes the class more "general purpose",
but it seems this is a "premature optimization" that only makes it
harder for the sender to work with the `accessGuard` object. Thus, the
protocol that is simpler from the perspective of sender would be:

{lang="csharp"}
~~~
accessGuard.LoginWith(login, password);
~~~

Another lesson from the above example is: setters rarely reflect
senders' intention. Most often, they reflect the structure of the
recipient. `myObject.SetX(x)` call suggests that `myObject` holds value
X. But it is rarely the intention of objects that use `myObject` to
store information in it (unless it is a data structure, e.g. a
collection or a data persistence abstraction), rather, they want
`myObject` to do something for them and the setter is just an
intermediate step required by `myObject`. In such cases, setters should
be either avoided or changed to something that reflects the intention
better. For example, when dealing with observer pattern, we don't want
to say: `object.SetObserver(screen)`, but rather
`object.RegisterObserver(screen)`.

Another thing is naming. The names of the methods (and interfaces for
that matter) should be crafted from the perspective of the sender as
well. In other words, the name of the method should not tell how thing
is done (unless that matters from the perspective of the sender), but
rather what is the intention of the sender that invokes the method. I
love the example that Scott Bain gives in his Emergent Design book: if I
told you "give me your driving license number", you might've reacted
differently based on whether the driving license is in your pocket, or
your wallet, or your bag, or in your home and you have to call someone
to give it to you. The point is: I, as a sender of this "give me your
driving license number" message, do not care how you get it. I say
`RetrieveDrivingLicenseNumber()`, not
`OpenYourWalletAndReadTheNumber()`. This is important, because if the
name represents the sender's intention, the method will not have to be
renamed when new classes are created that fulfill this intention in a
different way.

#### Interactions should reflect the domain

Sometimes at work, I am asked to conduct a design workshop. The example
I often give to my colleagues is to design a system for order
reservation. The thing that struck me the first few times I did this
workshop was that nearly none of the attendees had an `Order`
abstraction with `Reserve()` method on it. Most of the attendees assume
that `Order` is a data structure and handle reservation by adding it to
a "collection of reserved items":

{lang="csharp"}
~~~
reservedOrders.Add(order)
~~~

While this achieves the functionality they need to implement, it does
not reflect the domain. Thus, it can be affected by changes other than
domain changes. Thus, the interactions between objects become less
stable.

On the other hand, let's assume that we have a code for handling alarms.
On each alarm, all gates are closed, sirens are turned on and message is
sent to special forces with highest priority. Any error in this
procedure leads to shutting down power in the building. If this workflow
is coded like this:

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

Then the risk of this code changing for other reasons than the change of
how domain works (e.g. we do not close the gates anymore but activate
laser guns instead) is small. Thus, interactions that use abstractions
and methods that directly express domain rules are more stable.

Object responsibilities change less often than their data and if they
do, they affect the design in a more predictable way. If a design
reflects the domain, a change in design that is a result of domain rules
change is easier to predict. This contributes to maintainability and
stability of the interactions and the design as a whole.

#### Objects should be told what to do, instead of asked for information

This is probably one of the most important guidelines, known under the
name of Tell Don't Ask. When an object is asked to perform a task
instead of asked questions, we have a change of switching the
implementation of this task with another one.

So remember the payroll system that Johnny and Benjamin were working on?
As long as their code for giving raise looked like this:

{lang="csharp"}
~~~
if(employee.GetSalary() < payGrade.Maximum)
{
 var newSalary 
  = employee.GetSalary() 
  + employee.GetSalary() 
  * 0.1;
  employee.SetSalary(newSalary);
}
~~~

They were unable to compose this code with another employees that had
different raise rules applied to them, including voluntary employees
that would not have raises, but may have bonuses.

Again, quoting Scott Bain, "what you hide, you can change". Thus,
telling an object what to do requires less knowledge than asking for
data and information. Going back to the driver license example: I may
ask another person for a driving license number to actually make sure
they have the license and that it is valid (by checking the number
somewhere). I may also ask another person to provide me with the
directions to the place I want the first person to drive. But isn't it
easier to just tell "buy me some bread and butter"? Then, whoever I ask,
has the freedom to either drive, or walk (if they know a good store
nearby) or ask yet another person to do it instead. I don't care as long
as tomorrow morning, I find the bread and butter in my fridge.

This guideline should be trated very, very seriously and applied in
almost an extreme way. There are few places where it does not apply and
we'll get back to them later.

#### Getters should be removed, return values should be avoided

The above stated guideline of "Tell Don't Ask" has a practical
implication of getting rid of (almost) all the getters.

For me, this was very extreme at first, but in a short time I learned
that this is actually how I am supposed to write object-oriented code.
You see, I started learning programming using structural languages such
as C, where a program was divided into procedures or functions and data
structures. Then I moved on to object-oriented languages that allowed
far better abstraction, but my style of coding didn't really change
much. I would still have procedures and functions, but now more abstract
(divided into objects) and data structures, but now more abstract (i.e.
objects with setters, getters and some other query methods).

But what alternatives do we have? Let's say that we have a piece of
software that handles user sessions (e.g. modeled using a `Session`
class). We want to be able to display the sessions on the GUI, send the
sessions through the network and persist them. How can we do this
without getters? Should we put all the code for displaying, sending and
storing inside the `Session` class? If we did that, we would couple a
core domain concept (session) to a nasty set of third-party libraries
(e.g. a particular GUI library), which would force us to tinker in core
domain rules every time some GUI displaying concept changed. Also, if we
did that, the `Session` would be hard to reuse, because every place we
would want to reuse the class, we would need to take all these heavy
libraries it depends on with us. So, our (not so good, as we will see)
remedy may be to introduce getters for the information pieces stored
inside a session:

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
