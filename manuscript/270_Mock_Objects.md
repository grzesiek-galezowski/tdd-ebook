# Mock Objects as a testing tool

## TODO all below are notes

Remember the beginning of this book, where I introduced mock objects and said that I lied to you about their true purpose and nature? Now that we have a lot more knowledge about the view on object-oriented design, we can truly understand where mocks come from and what thay are for.

In this chapter, I will not yet say anything about the role of mock objects in test-driving object-oriented code, just justify their place in the context of testing objects.

## A backing example

Believe me I tried to write this chapter without leaning on any particular example, but the outcome was so dry and abstract, that I decided it could really use a backing example.

So for the needs of this chapter, I will use a single class, called `DataDispatcher`, which has the responsibility of sending data to a destination (modeled using a `Destination` interface) which needs to be opened before the sending operation and closed after sending. Its design is very naive, but that's the purpose - to not let the example itself get in the way of explaining mock objects.

Anyway, the `DataDispatcher` class is defined like this:

```csharp
public class DataDispatcher
{
  Destination _destination;
  
  public DataDispatcher(Destination destination)
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
 
Now we are ready to introduce mocks! Let's go!

## Specifying protocols

I hope in previous chapters, I succeeded in making my point that protocols are very important. Our goal is to design them so that we can reuse them in different contexts. Thus, it makes a lot of sense to specify (remember, that's the word we are using for "test") whether an object adheres to its part of the protocol. For example, our `DataDispatcher` must first open a destination, then send the data and at last, close the connection. If we rely on these calls being made in this order when we write our implementations of the `Destination` interface, we'd better specify what calls they expect to receive from `DataDispatcher` and in which order, using executable Statements.

Remember from the previous chapters then I told you that we strive for context-independence when designing objects? This is true, however, it's impossible most of the time to attain complete context-independence. In case of `DataDispatcher`, it knows very little of its context, which id a `Destination`, but nevertheless, it needs to know *something* about it. Thus, when writing a Statement, we need to pass an object of a class implementing `Destination` into `DataDispatcher`. But which context should we use? 

In other words, we can express our problem with the following, unfinished Statement (I marked all the unknowns with a double question mark: `??`):

```csharp
[Fact] public void 
ShouldSendDataToOpenedDestinationThenCloseWhenAskedToDispatch()
{
  //GIVEN
  var destination = ??;
  var dispatcher = new DataDispatcher(destination);
  var data = Any.Array<byte>();
  
  //WHEN
  dispatcher.Dispatch(data);
  
  //THEN
  ??
}
```

As you see, we need to pass a `Destination` to a `DataDispatcher`, but we don't know what that destination should be. Likewise, we have no good idea of how to specify the expected calls and their orders.

From the perspective of `DataDispatcher`, it is designed to work with different destinations, so no context is more appropriate than other. This means that we can pick and choose the one we like. Ideally, we'd like to pass a context that best fulfills two requirements:

1. Does not add side effects of its own - when we are specifying a protocol of an object, we want to be sure that what we are making assertions on are the actions of this object itself, not its context. This is a requirement of trust - you want to trust your specifications that they are specifying what they say they do.
1. Is easy to control - so that we can easily make it trigger different behaviors in the object we are specifying, Also, we want to be able to easily verify how the specified object interacts with its context. This is a requirement of convenience.

There is a tool that fulfills these two requirements - you guessed it - mock objects!

## Using a mock destination

TODO TODO TODO

TODO make a remark about strict mocks and loose mocks


## Mocks as yet another context

Some say that specifying object interactions in a context consisting of mocks is "specifying in isolation". I disagree with this assessment. From the point of view of a specified object, mocks are just another context - they are not better, nor worse, not more or less real than other contexts. 



it makes sense to test protocols as we want to reuse them

objects are independent of context - which context should we use for testing?

TODO many say that testing with mocks is testing "isolated from dependencies". I disagree. Each object is designed to be independent of context and mocks are just another context. We can have more context not for production - trace context, demo context etc.

TODO why mocks do not need tests themselves?

TODO how to create new objects? Placeholder, refactor, during writing of the test when we discover that a test is too complex. 