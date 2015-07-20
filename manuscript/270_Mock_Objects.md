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

I hope I succeeded in making my point that protocols are very important. Our goal is to design them so that we can reuse them in different contexts. Thus, it makes a lot of sense to specify (remember, that's the word we are using for "test") whether an object adheres to its part of the protocol. For example, our `DataDispatcher` must first open a destination, then send the data and at last, close the connection. If we rely on these calls being made in this order when we write our implementations of the `Destination` interface, we'd better specify what calls we expect and in which order, using executable Statements.

TODO 
 
when we have an object that uses something implementing a `Connection` interface, it makes a lot of sense to specify that this object should first open the connection, then send data and then close it. We cannot just specify how it works in the context in which it is currently used, because we want the class of the object to be context-independent - we care about how it interacts with its context, whatever it is.

TODO we need to choose SOME context. which context do we choose?

Thus, objects of a single class can appear in our application (e.g. in composition root) many times, each time in a context of different peer objects playing the roles that it interacts with. Thus, we don't have to specify it in any particular context, because when designing the class, we did not care about what the context really was, but what services it provides to our object and what it expects from it.

If we can choose the context in which to put an object when specifying its protocols, we'd better choose a context that:

* does not add side effects of its own - when we are specifying a protocol of an object, we want to be sure that what we are making assertions on are the actions of this object itself, not its context. This is a requirement of trust - you want to trust your specifications that they are specifying what they say they do.
* is easy to control - so that we can easily make it trigger different behaviors in the object we are specifying, Also, we want to be able to easily verify how the specified object interacts with its context. This is a requirement of convenience.

There is a tool that fulfills these two requirements - you guessed it - mock objects!



## Mocks as yet another context

Some say that specifying object interactions in a context consisting of mocks is "specifying in isolation". I disagree with this assessment. From the point of view of a specified object, mocks are just another context - they are not better, nor worse, not more or less real than other contexts. 



it makes sense to test protocols as we want to reuse them

objects are independent of context - which context should we use for testing?

TODO many say that testing with mocks is testing "isolated from dependencies". I disagree. Each object is designed to be independent of context and mocks are just another context. We can have more context not for production - trace context, demo context etc.

TODO why mocks do not need tests themselves?

TODO how to create new objects? Placeholder, refactor, during writing of the test when we discover that a test is too complex. 