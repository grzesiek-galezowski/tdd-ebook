# What's inside the object?

## What are object's peers?

So far I talked a lot about objects being composed in a web and communicating by sending messages to each other. They work together as *peers*.

The name peer comes from the objects working on equal footing -- there is no hierarchical relationship between peers. When two peers collaborate, none of them can be called an "owner" of the other. They are connected by one object receiving a reference to another object - its "address".

Here's an example

```csharp
class Sender
{
 public Sender(Recipient recipient)
 {
  _recipient = recipient;
  //...
 }
}
```

In this example, the `Recipient` is a peer of `Sender` (provided `Recipient` is not a value object or a data structure). The sender doesn't know:

* the concrete type of `recipient`
* when `recipient` was created
* by whom `recipient` was created
* how long will `recipient` object live after the `Sender` instance is destroyed
* which other objects collaborate with `recipient`

## What are object's internals?

Not every object is part of the web. I already mentioned value objects and data structures. They might be part of the public API of a class but are not its peers.

Another useful category are internals -- objects created and owned by other objects, tied to the lifespans of their owners.

Internals are encapsulated inside its owner objects, hidden from the outside world. Exposing internals should be considered a rare exception rather than a rule. They are a part of why their owner objects behave the way they do, but we cannot pass our own implementation to customize that behavior. This is also why we can't mock the internals - there is no extension point we can use. Luckily we also don't want to. Meddling into the internals of an object would be breaking encapsulation and coupling to the things that are volatile in our design.

![An internal vs a peer](images/internals_vs_peers.png)

Internals can be sometimes passed to other objects without breaking encapsulation. Let's take a look at this piece of code:

```csharp
public class MessageChain 
{
 private IReadOnlyList<Message> _messages = new List<Message>();
 private string _recipientAddress;

 public MessageChain(string recipientAddress) 
 {
  _recipientAddress = recipientAddress;
 }

 public void Add(string title, string body) 
 {
  _messages.Add(new Message(_recipientAddress, title, body));
 }

 public void Send(MessageDestination destination) 
 {
  destination.SendMany(_messages);
 }
}
```

In this example, the `_messages` object is passed to the `destination`, but the `destination` doesn't know where it got this list from, so this interaction doesn't necessarily expose structural details of the `MessageChain` class.

The distinction between peers and internals was introduced by Steve Freeman and Nat Pryce in their book Growing Object-Oriented Software Guided By Tests.

## Examples of internals

How to discover that an object should be an internal rather than a peer? Below, I listed several examples of categories of objects that can become internals of other objects. I hope these examples help you train the sense of identifying the internals in your design.

### Primitives

Consider the following `CountingObserver` toy class that counts how many times it was notified and when a threshold is reached, passes that notification further:

```csharp
class ObserverWithThreshold : Observer
{
 private int _count = 0;
 private Observer _nextObserver;
 private int _threshold;

 public ObserverWithThreshold(int threshold, Observer nextObserver)
 {
  _threshold = threshold;
  _nextObserver = nextObserver;
 }
 
 public void Notify()
 {
  _count++;
  if(_count > _threshold)
  {
    _count = 0;
    _nextObserver.Notify();
  }
 }
}
```

The `_count` field is owned and maintained by a `CountingObserver` instance. It's invisible outside an `ObserverWithThreshold` object.

An example Statement of behavior for this class could look like this:

```csharp
[Fact] public void 
ShouldNotifyTheNextObserverWhenItIsNotifiedMoreTimesThanTheThreshold()
{
 //GIVEN
 var nextObserver = Substitute.For<Observer>();
 var observer = new ObserverWithThreshold(2, nextObserver);
 
 observer.Notify();
 observer.Notify();

 //WHEN
 observer.Notify();
 
 //THEN
 nextObserver.Received(1).Notify();
}
```

The current notification count is not exposed outside of the ObserverWithThreshold object. I am only passing the threshold that the notification count needs to exceed. If I really wanted, I could, instead of using an int, introduce a collaborator interface for the counter, e.g. called `Counter`, give it methods like `Increment()` and `GetValue()` and the pass a mock from the Statement, but for me, if all I want is counting how many times something is called, I'd rather make it a part of the class implementation to do the counting. It feels simpler if the counter is not exposed.

### Value object fields

The counter from the last example was already a value, but I thought I'd mention about richer value objects.

Consider a class representing a commandline session. It allows executing commands within the scope of a working directory. An implementation of this class could look like this:

```csharp
public class CommandlineSession
{
 private AbsolutePath _workingDirectory;

 public CommandlineSession(PathRoot root)
 {
  _workingDirectory = root.AsAbsolutePath();
 }

 public void Enter(DirectoryName dirName)
 {
  _workingDirectory = _workingDirectory.Append(dirName);
 }

 public void Execute(Command command)
 {
  command.ExecuteIn(_workingDirectory);
 }
 //...
}
```

This `CommandlineSession` class has a private field called `_workingDirectory`, representing the working directory of the current commandline session. Even though the initial value is based on the constructor argument, the field is managed internally from there on and only passed to a command so that it knows where to execute. An example Statement for the behavior of the `CommandLineSession` could look like this:

```csharp
[Fact] public void
ShouldExecuteCommandInEnteredWorkingDirectory()
{
 //GIVEN
 var pathRoot = Any.Instance<PathRoot>();
 var commandline = new CommandLineSession(pathRoot);
 var subDirectoryLevel1 = Any,Insytance<DirectoryName>();
 var subDirectoryLevel2 = Any,Insytance<DirectoryName>();
 var subDirectoryLevel3 = Any,Insytance<DirectoryName>();
 var command = Substitute.For<Command>();

 commandline.Enter(subDirectoryLevel1);
 commandline.Enter(subDirectoryLevel2);
 commandline.Enter(subDirectoryLevel3);
 
 //WHEN
 commandLine.Execute(command);

 //THEN
 command.Received(1).Execute(
  AbsolutePath.Combine(
   pathRoot, 
   subDirectoryLevel1,
   subDirectoryLevel2,
   subDirectoryLevel3));
}
```

Again, I don't have any access to the internal `_workingDirectory` field. I can only predict its value and create an expected value in my Statement. Note that I am not even using the same methods to combine the paths in both the Statement and the production code - while the production code is using the `Append()` method, my Statement is using a static `Combine` method on an `AbsolutePath` type. This shows that my Statement is oblivious to how exactly the internal state is managed by the `CommandLineSession` class.

### Collections

Raw collections of items (like lists, hashsets, arrays etc.) aren't typically viewed as peers. Even if I write a class that accepts a collection interface (e.g. `IList` in C#) as a parameter, I never mock the collection interface, but rather, use one of the built-in collections.

Here's an example of a `InMemorySessions` class initializing and utilizing a collection:

```csharp
public class InMemorySessions : Sessions
{
 private Dictionary<SessionId, Session> _sessions 
  = new Dictionary<SessionId, Session>();
 private SessionFactory _sessionFactory;

 public InMemorySessions(SessionFactory sessionFactory)
 {
  _sessionFactory = sessionFactory;
 }

 public void StartNew(SessionId id)
 {
  var session = _sessionFactory.CreateNewSession(id);
  session.Start();
  _sessions[id] = session;
 }

 public void StopAll()
 {
  foreach(var session in _sessions.Values())
  {
   _session.Stop();
  }
 }
 //...
}
```

The dictionary used here is not exposed at all to the external world. It's only used internally. I can't pass a mock implementation and even if I could, I'd rather leave the behavior as owned by the `InMemorySessions`. An example Statement for the `InMemorySessions` class demonstrated how the dictionary is not visible outside the class:

```csharp
[Fact] public void
ShouldStopAddedSessionsWhenAskedToStopAll()
{
 //GIVEN
 var sessionFactory = Substitute.For<SessionFactory>();
 var sessions = new InMemorySessions(sessionFactory);
 var sessionId1 = Any.Instance<SessionId>();
 var sessionId2 = Any.Instance<SessionId>();
 var sessionId3 = Any.Instance<SessionId>();
 var session1 = Substitute.For<Session>();
 var session2 = Substitute.For<Session>();
 var session3 = Substitute.For<Session>();
 
 sessionFactory.CreateNewSession(sessionId1)
  .Returns(session1);
 sessionFactory.CreateNewSession(sessionId2)
  .Returns(session2);
 sessionFactory.CreateNewSession(sessionId3)
  .Returns(session3);

 sessions.StartNew(sessionId1);
 sessions.StartNew(sessionId2);
 sessions.StartNew(sessionId3);

 //WHEN
 sessions.StopAll();

 //THEN
 session1.Received(1).Stop();
 session2.Received(1).Stop();
 session3.Received(1).Stop();
}
```

### Toolbox classes and objects

Toolbox classes and objects are not really abstractions of any specific problem domain, but they help make the implementation more concise, reducing the number of lines of code I have to write to get the job done. One example is a C# `Regex` class for regular expressions. Here's an example of a line count calculator that utilizes a `Regex` instance to count the number of lines in a piece of text:

```csharp
class LocCalculator
{
 private static readonly Regex NewlineRegex 
  = new Regex(@"\r\n|\n", RegexOptions.Compiled);

 public uint CountLinesIn(string content)
 {
  return NewlineRegex.Split(contentText).Length;
 }
}
```

Again, I feel like the knowledge on how to split a string into several lines should belong to the `LocCalculator` class. I wouldn't introduce and mock an abstraction (e.g. called a `LineSplitter` unless there were some kind of domain rules associated with splitting the text). An example Statement describing the behavior of the calculator would look like this:

```csharp
[Fact] public void
ShouldCountLinesDelimitedByCrLf()
{
 //GIVEN
 var text = $"{Any.String()}\r\n{Any.String()}\r\n{Any.String()}";
 var calculator = new LocCalculator();
 
 //WHEN
 var lineCount = calculator.CountLinesIn(text);

 //THEN
 Assert.Equal(3, lineCount);
}
```

The regular expression object is nowhere to be seen - it remains hidden as an implementation detail of the `LocCalculator` class.

### Some third-party library classes

Below is an example that uses a C# fault injection framework, Simmy. The class decorates a real storage class and allows to configure throwing exceptions instead of talking to the storage object. The example might seem a little convoluted and the class isn't production-ready anyway. Note that a lot of classes and methods are only used inside the class and not visible from the outside.

```csharp
public class FaultInjectablePersonStorage : PersonStorage
{
 private readonly PersonStorage _storage;
 private readonly InjectOutcomePolicy _chaosPolicy;

 public FaultInjectablePersonStorage(bool injectionEnabled, PersonStorage storage)
 {
  _storage = storage;
  _chaosPolicy = MonkeyPolicy.InjectException(with =>
    with.Fault(new Exception("thrown from exception attack!"))
     .InjectionRate(1)
     .EnabledWhen((context, token) => injectionEnabled)
  );
 }

 public List<Person> GetPeople()
 {
  var capturedResult = _chaosPolicy.ExecuteAndCapture(() => _storage.GetPeople());
  if (capturedResult.Outcome == OutcomeType.Failure)
  {
   throw capturedResult.FinalException;
  }
  else
  {
   return capturedResult.Result;
  }
 }
}
```

An example Statement could look like this:

```csharp
[Fact] public void
ShouldReturnPeopleFromInnerInstanceWhenTheirRetrievalIsSuccessfulAndInjectionIsDisabled()
{
 //GIVEN
 var innerStorage = Substitute.For<PersonStorage>();
 var peopleInInnerStorage = Any.List<Person>();
 var storage = new FaultInjectablePersonStorage(false, innerStorage);

 innerStorage.GetPeople().Returns(peopleFromInnerStorage);

 //WHEN
 var result = storage.GetPeople();

 //THEN
 Assert.Equal(peopleInInnerStorage, result);
}
```

and it has no trace of the Simmy library.

## Summary

In this chapter, I argued that not all communication between objects should be represented as public protocols. Instead, some of it should be encapsulated inside the object. I also provided several examples to help you find such internal collaborators.