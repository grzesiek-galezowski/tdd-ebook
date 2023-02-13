# What's inside the class?

TODO reference to GOOS

Design follows RDD process (lol). This way we discover a lot of peers of the current class.

Internals are not stereotypes

So far I said that an object exchanges messages with its peers.

```csharp
class Sender
{
    public Sender(Recipient c)
    {
        //...
    }
}
```

In this example, the `Recipient` is a peer of `Sender` in the web of objects (provided `Recipient` is not a value object or a data structure). Both `Sender` and `Recipient` are part of the web of objects I described in object-oriented primer. But not every class is part of the web. I already mentioned value objects and data structures. They might be part of the public API of a class but are not its peers.

Another category are internals - objects created and owned by other objects, tied to the lifespans of their owners.

## Internals are implementation details

Internals are encapsulated inside the object, hidden from the outside world - exposing them should be considered a rare exception rather than a rule. They are a part of why their owner objects behave the way they do, but we cannot pass our own implementation to customize that behavior. This is why we can't mock the internals. Luckily we also don't want to. Meddling into the internals of an object would be breaking encapsulation and coupling to the things that are volatile.

Internals can be sometimes passed to other objects without breaking encapsulation. Let's take a look at this piece of code:

```csharp
public class MessageChain 
{
  private List<Message> _messages = new List<Message>();
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
    //let's assume SendMany() accepts an IReadOnlyList<Message>
    destination.SendMany(_messages);
  }
}
```

In this example, the `_messages` object is passed to the `destination`, but the `destination` doesn't know where it got the list from, so this interaction doesn't necessarily expose structural details of the `MessageChain` class.

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