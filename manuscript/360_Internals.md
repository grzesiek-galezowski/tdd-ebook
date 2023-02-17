# What's inside the object?

## What are object's peers?

So far we talked a lot about communication between objects by sending messages to each other and being composed in a web. This is how peer object work with each other.

The name peer comes from the objects being on the same level of visibility - there is no hierarchical relationship between peers. When two peers collaborate, none of them can be called an owner of the other. They are connected by one object receiving a reference to another object.

Here's an example

```csharp
class Sender
{
 public Sender(Recipient recipient)
 {
  _recipient = recipient
  //...
 }
}
```

In this example, the `Recipient` is a peer of `Sender` (provided `Recipient` is not a value object or a data structure). The sender doesn't know 

* the concrete type of `recipient`
* when `recipient` was created
* by whom `recipient` was created
* how long will `recipient` object live after the `Sender` instance is destroyed

## What are object's internals?

Not every object is part of the web. I already mentioned value objects and data structures. They might be part of the public API of a class but are not its peers.

Another useful category are internals -- objects created and owned by other objects, tied to the lifespans of their owners.

Internals are encapsulated inside its owner objects, hidden from the outside world. Exposing internals should be considered a rare exception rather than a rule. They are a part of why their owner objects behave the way they do, but we cannot pass our own implementation to customize that behavior. This is why we can't mock the internals. Luckily we also don't want to. Meddling into the internals of an object would be breaking encapsulation and coupling to the things that are volatile in our design.

Internals can be sometimes passed to other objects without breaking encapsulation. Let's take a look at this piece of code:

```csharp
public class MessageChain 
{
  private IReadOnlyList<Message> _messages = new List<Message>();
  private string _recipientAddress;

  public MessageChain(String recipientAddress) 
  {
    _recipientAddress = recipientAddress;
  }

  public void Add(String title, String body) 
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

## Examples of internals

Below, I listed several examples of categories of objects that can become internals of other objects.

### Primitive fields

Consider the following `CountingObserver` toy class that counts how many times it was notified and allows passing that further:

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

The `_count` field is owned and initialized by a `CountingObserver` instance. It's only exposed when its copy is passed to the `Handle` method of the `out` object. Sure, we could introduce a collaborator interface, e.g. called `Counter`, give it methods like `Increment()` and `GetValue()`, but for me, if all I want is counting how many times something is called, I'd rather make it a part of the class implementation to do the counting.

### Value object fields

The counter from the last example was already a value, but I thought I'd mention about richer value objects.

```csharp
class CommandlineSession
{
 private AbsolutePath _workingDirectory;

 public X(PathRoot root)
 {
  _workingDirectory = root.AsAbsolutePath();
 }

 public void Enter(DirectoryName dirName)
 {
  _workingDirectory = _workingDirectory.Append(dirName);
 }

 public void Execute(Command command)
 {
  command.ExecuteIn(_currentPath);
 }
 //...
}
```

This `CommandlineSession` class has a private field called `_workingDirectory`, symbolizing the working directory of the current console session. Even though the initial value is based on passed argument, the field is managed internally and only passed to a command so that it knows where to execute.

### Collections

Raw collections of items (like lists, hashsets, arrays etc.) aren't viewed as peers. Even if I write classed that accept collection interfaces as parameters (e.g. IList in C#), I never mock them, but rather, just use one of the built-in classes.

Here's an example of a `InMemorySessions` class initializing and utilizing a collection:

```csharp
public class InMemorySessions : Sessions
{
 private Dictionary<SessionId, Session> _sessions 
  = new Dictionary<SessionId, Session>();

 public void StartNew(SessionId id)
 {
  var session = _sessionFactory.CreateNewSession(id)
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

The dictionary used here is not exposed at all to the external world. It's only used internally. I can't pass a mock implementation and even if I could, I'd rather leave the behavior as owned by the `InMemorySessions`.

### Toolbox classes and objects

These classes and objects are not really abstractions of any specific domain, but they help make the implementation more concise, reducing the number of lines of code I have to write to get the job done. One example is a C# `Regex` class for regular expressions. Here's an example that utilizes a `Regex` instance to count the number of lines in a piece of text:

```csharp
class LocCalculator
{
 private static readonly Regex NewlineRegex 
  = new Regex(@"\r\n|\r|\n", RegexOptions.Compiled);

 public uint CalculateLinesCount(string content)
 {
  return NewlineRegex.Split(contentText).Length;
 }
}
```

Again, I feel like the knowledge on how to split a string into several lines should belong to the `LocCalculator` class. I wouldn't introduce and mock an abstraction (e.g. called a `LineSplitter` unless there were some kind of domain rules associated with splitting the text).

### Some third-party library classes

Below is an example that uses a C# fault injection framework, Simmy. The class decorates a real storage class and allows to configure throwing exceptions instead of talking to the storage object. The example might seem a little convoluted and the class isn't production-ready anyway, the only thing I need you to note is that there are a lot of classes and methods only used inside the class and not visible from the outside.

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

### I/O, threading etc.

TODO:

Explain what peers are and how they differ from internals. It's important to provide a clear definition of what peers are and how they differ from internals in order to help readers understand the concept.

Provide examples of peers. Just like you have examples of internals, it would be helpful to provide examples of peers as well. For example, you could discuss classes that collaborate with the class you're describing, or other objects that the class interacts with.

Address common misconceptions or confusion points. You could discuss common misconceptions or confusion points that people might have about the concept of peers vs internals, and explain why those misconceptions are incorrect. For example, some people might think that all dependencies should be considered internals, when in fact some dependencies should be treated as peers.

Discuss the benefits of separating peers and internals. It would be helpful to explain why it's beneficial to separate peers and internals, and how doing so can make your code more maintainable, testable, and easier to understand.

Provide best practices for identifying and separating peers and internals. You could provide some tips or best practices for identifying which parts of your code should be considered peers or internals, and how to separate them effectively.


Clock, BackgroundJobs.Run()

Steve Freeman: small clusters of objects.

What internals do we have?

1. Value objects, ints etc.
2. Collections
3. Utils (e.g. I wrote my util for generating hash code or my own class for joining strings or calculations)
4. library classes (if communication with library class is important, maybe wrap it with another class where it becomes an internal)
5. synchronization primitives?
6. I/O

can value be internal?
can data structure be internal?
Can value be a peer?