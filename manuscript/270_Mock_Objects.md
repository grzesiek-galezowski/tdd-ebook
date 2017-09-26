# Mock Objects as a testing tool

Remember the beginning of this book, where I introduced mock objects and mentioned that I had lied to you about their true purpose and nature? Now that we have a lot more knowledge on object-oriented design (at least a specific, opinionated view on it), we can truly understand where mocks come from and what thay are for.

In this chapter, I won't say anything about the role of mock objects in test-driving object-oriented code yet. For now, I want to focus on justifying their place in the context of testing objects.

## A backing example

Believe me I tried to write this chapter without leaning on any particular example, but the outcome was so dry and abstract, that I decided it could really use one.

So for the needs of this chapter, I will use a single class, called `DataDispatch`, which has the responsibility of sending data to a destination (modeled using a `Destination` interface). The `Destination` needs to be opened before the data is sent and closed after. Its design is very naive, but that's the purpose - to not let the example itself get in the way of explaining the mechanics of mock objects.

Anyway, the `DataDispatch` class is defined like this:

```csharp
public class DataDispatch
{
  Destination _destination;
  
  public DataDispatch(Destination destination)
  {
    _destination = destination;
  }
  
  public void Dispatch(byte[] data)
  {
    _destination.Open();
    _destination.Send(data);
    _destination.Close();
  }
}
```

And the `Destination` interface is defined like this:

```csharp
public interface Destination
{
  void Open();
  void Send(byte[] data);
  void Close();
}
```
 
Finally, we are ready to introduce mocks! Let's go!

## Specifying protocols

I hope that in part 2, I succeeded in explaining why protocols play a big part in my thinking about object-oriented design. My goal is to design these protocols so that they can be used in many contexts. Thus, if I consider protocols important, I see a lot of sense in specifying (remember, that's the word we are using for "test") these protocols, both from the perspective of sender and recipient of the messages. For example, when we look at the protocol between `DataDispatch` and `Destination`, our `DataDispatch` must:

1. open a destination
2. then send the data 
3. and at last, close the destination.

TODO rewrite it - there are two protocols: DataDispatch as a recipient (the protocol and interface it offers) and DataDispatch as a sender (the protocol and interface that it expects).

If so, we need to document this order in our executable Specification. TODO 

If we rely on these calls being made in this order when we write our implementations of the `Destination` interface, we'd better specify what calls they expect to receive from `DataDispatch` and in which order, using executable Statements.

Remember from the previous chapters when I describe how we strive for context-independence when designing objects? This is true, however, it's impossible most of the time to attain complete context-independence. In case of `DataDispatch`, it knows very little of its context, which is a `Destination`, but nevertheless, it needs to know *something* about it. Thus, when writing a Statement, we need to pass an object of a class implementing `Destination` into `DataDispatch`. But which context should we use? 

In other words, we can express our problem with the following, unfinished Statement (I marked all the unknowns with a double question mark: `??`):

```csharp
[Fact] public void 
ShouldSendDataToOpenedDestinationThenCloseWhenAskedToDispatch()
{
  //GIVEN
  var destination = ??;
  var dispatch = new DataDispatch(destination);
  var data = Any.Array<byte>();
  
  //WHEN
  dispatch.ApplyTo(data);
  
  //THEN
  ??
}
```

As you see, we need to pass a `Destination` to a `DataDispatch`, but we don't know what that destination should be. Likewise, we have no good idea of how to specify the expected calls and their orders.

From the perspective of `DataDispatch`, it is designed to work with different destinations, so no context is more appropriate than other. This means that we can pick and choose the one we like. Ideally, we'd like to pass a context that best fulfills the following requirements:

1. Does not add side effects of its own - when we are specifying a protocol of an object, we want to be sure that what we are making assertions on are the actions of this object itself, not its context. This is a requirement of trust - you want to trust your specifications that they are specifying what they say they do.
1. Is easy to control - so that we can easily make it trigger different behaviors in the object we are specifying. Also, we want to be able to easily verify how the specified object interacts with its context. This is a requirement of convenience.
1. Is quick to create and easy to maintain - because we want to focus on the behaviors we specify, not on maintaining or creating helper context. Also, we don't want to write special Statements for the behaviors of this context. This is a requirement of low friction.

There is a tool that fulfills these three requirements - you guessed it - mock objects!

## Using a mock destination

I hope you remember the NSubstitute library for creating mocks objects that we introduce way back at the beginning of the book. We can use it now to quickly create an implementation of `Destination` that behaves the way we like, allows easy verification of protocol and between `Dispatch` and `Destination` and introduces as minimal number of side effects as possible.

Filling the gap, this is what we get:

```csharp
[Fact] public void 
ShouldSendDataToOpenedDestinationThenCloseWhenAskedToDispatch()
{
  //GIVEN
  var destination = Substitute.For<Destination>;
  var dispatch = new DataDispatch(destination);
  var data = Any.Array<byte>();
  
  //WHEN
  dispatch.ApplyTo(data);
  
  //THEN
  Received.InOrder(() =>
  {
    destination.Open();
    destination.Send(data);
    destination.Close();
  };
}
```

There, it did the trick![^noexception] The only thing that might seem new to you is this:

```csharp
Received.InOrder(() =>
{
  destination.Open();
  destination.Send(data);
  destination.Close();
};
```

What it does is checking whether the `Destination` got the messages (remember? Objects send messages to each other) in the right order. If we changed the implementation of the `ApplyTo()` method from this one:

```csharp
public void Dispatch(byte[] data)
{
  _destination.Open();
  _destination.Send(data);
  _destination.Close();
}
```

to this one (note the changed call order):

```csharp
public void Dispatch(byte[] data)
{
  _destination.Send(data);
  _destination.Open();
  _destination.Close();
}
```

The Statement will turn false (i.e. will fail).

## Mocks as yet another context

What we have done in the above example was to put our `DataDispatch` in a context that was most convenient for us to use in our Statement.

Some say that specifying object interactions in a context consisting of mocks is "specifying in isolation" and that providing such mock context is "isolating". I don't like this point of view very much. From the point of view of a specified object, mocks are just another context - they are not better, nor worse, not more or less real than other contexts we want to put our `Dispatch` in. Sure, this is not the context in which it runs in production, but we may have other situations than mere production work - e.g. we may have a special context for demos, where we count sent packets and show the throughput on a GUI screen. We may also have a debugging context that in each method, before passing the control to a production code, writes a trace message to a log.

## Summary

Now, wasn't this a painless introduction to mock objects! In the next chapters, we will examine how mock objects help in test-driven development.

[^noexception]: By the way, note that this protocol we are specifying is very naive, since we assume that sending data through destination will never throw any exception.
 

//TODO TODO TODO

