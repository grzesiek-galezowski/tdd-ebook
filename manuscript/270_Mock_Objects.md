# Mock Objects as a testing tool

Remember one of the first chapters of this book, where I introduced mock objects and mentioned that I had lied to you about their true purpose and nature? Now that we have a lot more knowledge on object-oriented design (at least a specific, opinionated view on it), we can truly understand where mocks come from and what thay are for.

In this chapter, I won't say anything about the role of mock objects in test-driving object-oriented code yet. For now, I want to focus on justifying their place in the context of testing objects.

## A backing example

For the need of this chapter, I will use a simple example. Before I describe it, I need you to know that I don't consider this example a showcase for mock objects. Mocks shine where there are domain-driven interactions between objects and this example will not be like that. I picked this example because this is something you should understand easily and should be enough to discuss some mechanics of mock objects. In the next chapter, I will use the same example as an illustration, but after that, I'm dropping it and going into more interesting stuff.

 Our example is a single class, called `DataDispatch`, which has the responsibility of sending received data to a channel (represented by a `Channel` interface). The `Channel` needs to be opened before the data is sent and closed after. `DataDispatch` implements this requirement. Here is the full code for the `DataDispatch` class:

```csharp
public class DataDispatch
{
  Channel _channel;

  public DataDispatch(Channel channel)
  {
    _channel = channel;
  }

  public void Dispatch(byte[] data)
  {
    _channel.Open();
    try
    {
      _channel.Send(data);
    }
    finally
    {
      _channel.Close();
    }
  }
}
```

## Interfaces

As shown above, `DataDispatch` depends on a single interface called `Channel`. Here is the full interface definition:

```csharp
public interface Channel
{
  void Open();
  void Send(byte[] data);
  void Close();
}
```

## Protocols

Note that when we look at the `DataDispatch` class, there are two protocols it has to follow. The first one is between `DataDispatch` and the code that uses it, i.e. the one that calls the `Dispatch()` method. Someone, somewhere, has to do the following:

```csharp
dataDispatch.Send(messageInBytes);
```

or there would be no reason for `DataDispatch` to exist. Note that `DataDispatch` itself does not require too much form its users - it just passes the received byte array further to the `Channel`. Also, it rethrows any exception raised by a channel, so its user must be prepared to handle the exception. The rest of the story is a responsibility of a particular channel object.

The second protocol is between `DataDispatch` and `Channel`. Here, `DataDispatch` is required to invoke the methods of a `Channel` in the correct order:

1. Open the channel,
1. Send the data,
1. Close the channel.

Whatever actual implementation of `Channel` interface is passed to `DataDispatch`, it will operate on the assumption that this indeed is the order in which the methods will be called. Also, `DataDispatch`is required to close the channel in case of error while sending data (hence the `finally` block wrapping the `Close()` method invocation).

Summing it up, there are two "conversations" a `DataDispatch` object is involved in when fulfilling its responsibilities - one with its user and one with a dependency passed by its creator. We cannot specify these two conversations separately as the outcome of each of these two conversations depends on the other. Thus, we have to specify the `DataDispatch` class, as it is involved in both of these conversations at the same time.

## Roles

The conclusion is that the environment we need is comprised of three roles (arrows show the direction of dependencies):

```text
User -> DataDispatch -> Channel
```

Where `DataDispatch` is the concrete, specified class and the rest is its context.

## Behaviors

The behaviors of `DataDispatch` defined in terms of this context are:

1. Dispatching valid data:
  
  ```text
  GIVEN User wants to dispatch a piece of data
  AND a DataDispatch instance connected to a Channel
    that accepts such data
  WHEN the User dispatches the data via the DataDispatch instance
  THEN the DataDispatch object should
    open the channel,
    then send the data,
    then close the channel
  ```

1. Dispatching invalid data:

  ```text
  GIVEN User wants to dispatch some data
  AND a DataDispatch instance connected to a Channel
    that rejects such data
  WHEN the User dispatches the data via the DataDispatch instance
  THEN the DataDispatch object should report to the User
    that data is invalid
  AND close the connection anyway
  ```

For the remainder of this chapter I will focus on the first behavior as our goal is not to create a complete Specification of DataDispatch class, but rather to make a case for mock objects as a testing tool.

## Filling in the roles

As mentioned before, the whole context of the specified behavior looks like this:

```text
User <-> DataDispatch <-> Channel
```

Now we need to fill in the roles. First of all - the role of DataDispatch will befilled by the concrete class `DataDispatch` - after all, this is the class that we specify. Next, who is going to be the user of the `DataDispatch` class? For this question, I have an easy answer - the Statement body is going to be the user. This means that our environment looks like this now:

```text
Statement body -> DataDispatch (concrete class) -> Channel
```

//todo rewrite this paragraph::
Now, the last element is to decide who is going to play the role of channel. But which context should we use?

In other words, we can express our problem with the following, unfinished Statement (I marked all the current unknowns with a double question mark: `??`):

```csharp
[Fact] public void
ShouldSendDataToOpenedChannelThenCloseWhenAskedToDispatch()
{
  //GIVEN
  var channel = ??; //what is it going to be?
  var dispatch = new DataDispatch(channel);
  var data = Any.Array<byte>();

  //WHEN
  dispatch.ApplyTo(data);

  //THEN
  ?? //how to verify DataDispatch behavior?
}
```

As you see, we need to pass an implementation of `Channel` to a `DataDispatch`, but we don't know what that channel should be. Likewise, we have no good idea of how to specify the expected calls and their order.

From the perspective of `DataDispatch`, it is designed to work with everything that implements the `Channel` interface and follows the protocol, so no particular implementation is more appropriate than other. This means that we can pick and choose the one we like best. Which one do we like best? The one that makes writing the specification easiest, of course. Ideally, we'd like to pass a channel that best fulfills the following requirements:

1. Adds as little side effects of its own as possible. If a channel implementation added side effects, we would never be sure whether we are specifying the behavior of `DataDispatch` or maybe the behavior of the particular `Channel` implementation that is used in the Statement. This is a requirement of trust - we want to trust our specifications that they are specifying what they say they do.
1. Is easy to control - so that we can easily make it trigger different behaviors in the object we are specifying. Also, we want to be able to easily verify how the specified object interacts with it. This is a requirement of convenience.
1. Is quick to create and easy to maintain - because we want to focus on the behaviors we specify, not on maintaining or creating helper context. Also, we don't want to write special Statements for the behaviors Statement-specific implementation. This is a requirement of low friction.

There is a tool that fulfills these three requirements and it's called a mock object. This makes our context of specified behavior look like this:

```text
Statement body -> DataDispatch (concrete class) -> Mock Channel
```

Note that the only part of this context that is real production code is the `DataDispatch`. The rest of the context is Statement-specific.

## Using a mock channel

I hope you remember the NSubstitute library for creating mock objects that we introduced way back at the beginning of the book. We can use it now to quickly create an implementation of `Channel` that behaves the way we like, allows easy verification of protocol and between `Dispatch` and `Channel` and introduces as minimal number of side effects as possible.

Filling the gap, this is what we get:

```csharp
[Fact] public void 
ShouldSendDataToOpenedChannelThenCloseWhenAskedToDispatch()
{
  //GIVEN
  var channel = Substitute.For<Channel>;
  var dispatch = new DataDispatch(channel);
  var data = Any.Array<byte>();

  //WHEN
  dispatch.ApplyTo(data);

  //THEN
  Received.InOrder(() =>
  {
    channel.Open();
    channel.Send(data);
    channel.Close();
  };
}
```

I answered the question of "where to get the channel from?" by creating it as a mock:

```csharp
var channel = Substitute.For<Channel>;
```

Then the second question: "how to verify DataDispatch behavior?" was answered by using the NSubstitute API for verifying that the mock received three calls (or three messages) in a specific order:

```csharp
Received.InOrder(() =>
{
  channel.Open();
  channel.Send(data);
  channel.Close();
};
```

If rearranged the order of messages sent to `Channel` in the implementation of the `ApplyTo()` method from this one:

```csharp
public void Dispatch(byte[] data)
{
  _channel.Open();
  _channel.Send(data);
  _channel.Close();
}
```

to this one (note the changed call order):

```csharp
public void Dispatch(byte[] data)
{
  _channel.Send(data);
  _channel.Open();
  _channel.Close();
}
```

The Statement will turn false (i.e. will fail).

## Mocks as yet another context

What we did in the above example was to put our `DataDispatch` in a context that was most trustworthy, convenient and frictionless for us to use in our Statement.

Some say that specifying object interactions in context of mocks is "specifying in isolation" and that providing such mock context is "isolating". I don't like this point of view very much. From the point of view of a specified object, mocks are just another context - they are neither better, nor worse, they are neither more nor less real than other contexts we want to put our `Dispatch` in. Sure, this is not the context in which it runs in production, but we may have other situations than mere production work - e.g. we may have a special context for demos, where we count sent packets and show the throughput on a GUI screen. We may also have a debugging context that in each method, before passing the control to a production code, writes a trace message to a log.

## Summary

The goal of this chapter was only to show you how mock objects fit into testing a "tell don't ask" -- style, focusing on responsibilities, behaviors, interfaces and protocols of objects. This example was meant as something you could easily understand, not as a showcase for TDD using mocks. For one more chapter, we will work on this toy example and then I will try to show you how I apply mock objects in real-life code.