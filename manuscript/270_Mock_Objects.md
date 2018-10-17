# Mock Objects as a testing tool

Remember one of the first chapters of this book, where I introduced mock objects and mentioned that I had lied to you about their true purpose and nature? Now that we have a lot more knowledge on object-oriented design (at least on a specific, opinionated view on it), we can truly understand where mocks come from and what thay are for.

In this chapter, I won't say anything about the role of mock objects in test-driving object-oriented code yet. For now, I want to focus on justifying their place in the context of testing objects written in the style that I described in part 2.

## A backing example

For the need of this chapter, I will use one toy example. Before I describe it, I need you to know that I don't consider this example a showcase for mock objects. Mocks shine where there are domain-driven interactions between objects and this example is not like that - the interactions here are more implementation-driven. Still, I decided to use it anyway because I consider it something easy to understand and good enough to discuss some mechanics of mock objects. In the next chapter, I will use the same example as an illustration, but after that, I'm dropping it and going into more interesting stuff.

The example is a single class, called `DataDispatch`, which is responsible for sending received data to a channel (represented by a `Channel` interface). The `Channel` needs to be opened before the data is sent and closed after. `DataDispatch` implements this requirement. Here is the full code for the `DataDispatch` class:

```csharp
public class DataDispatch
{
  private Channel _channel;

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

The rest of this chapter will focus on dissecting the behaviors of `DataDispatch` and their context.

I will start describing this context by looking at interface used by `DataDispatch`.

## Interfaces

As shown above, `DataDispatch` depends on a single interface called `Channel`. Here is the full definition of this interface:

```csharp
public interface Channel
{
  void Open();
  void Send(byte[] data);
  void Close();
}
```

An implementation of `Channel` is passed into the constructor of `DataDispatch`. In other words, `DataDispatch` can be composed with anything that implements `Channel` interface. At least from compiler point of view. This is because, as I mentioned in the last part, for two composed objects to be able to work together successfully, interfaces are not enough. They also have to establish and follow a protocol.

## Protocols

Note that when we look at the `DataDispatch` class, there are two protocols it has to follow. I will describe them one by one.

### Protocol between `DataDispatch` and its user

The first protocol is between `DataDispatch` and the code that uses it, i.e. the one that calls the `Dispatch()` method. Someone, somewhere, has to do the following:

```csharp
dataDispatch.Send(messageInBytes);
```

or there would be no reason for `DataDispatch` to exist. Looking further into this protocol, we can note that `DataDispatch` does not require too much from its users -- it doesn't have any kind of return value. The only feedback it gives to the code that uses it is rethrowing any exception raised by a channel, so the user code must be prepared to handle the exception. Note that `DataDispatch` neither knows nor defines the kinds of exceptions that can be thrown. This is a responsibility of a particular channel implementation. The same goes for deciding under which condition should an exception be thrown.

### Protocol between `DataDispatch` and `Channel`

The second protocol is between `DataDispatch` and `Channel`. Here, `DataDispatch` will work with any implementation of `Channel` the allows it to invoke the methods of a `Channel` specified number of times in a specified order:

1. Open the channel -- once,
1. Send the data -- once,
1. Close the channel -- once.

Whatever actual implementation of `Channel` interface is passed to `DataDispatch`, it will operate on the assumption that this indeed is the count and order in which the methods will be called. Also, `DataDispatch` assumes it is required to close the channel in case of error while sending data (hence the `finally` block wrapping the `Close()` method invocation).

### Two conversations

Summing it up, there are two "conversations" a `DataDispatch` object is involved in when fulfilling its responsibilities -- one with its user and one with a dependency passed by its creator. We cannot specify these two conversations separately as the outcome of each of these two conversations depends on the other. Thus, we have to specify the `DataDispatch` class, as it is involved in both of these conversations at the same time.

## Roles

Our conclusion from the last section is that the environment in which behaviors of `DataDispatch` take place is comprised of three roles (arrows show the direction of dependencies, or "who sends messages to whom"):

```text
User -> DataDispatch -> Channel
```

Where `DataDispatch` is the specified class and the rest is its context (`Channel` being the part of the context `DataDispatch` depends on. As much as I adore context-independence, most classes need to depend on some kind of context, even if to a minimal degree).

Let's use this environment to define the behaviors of `DataDispatch` we need to specify.

## Behaviors

The behaviors of `DataDispatch` defined in terms of this context are:

1. Dispatching valid data:

  ```text
  GIVEN User wants to dispatch a piece of data
  AND a DataDispatch instance is connected to a Channel
    that accepts such data
  WHEN the User dispatches the data via the DataDispatch instance
  THEN the DataDispatch object should
    open the channel,
    then send the User data through the channel,
    then close the channel
  ```

1. Dispatching invalid data:

  ```text
  GIVEN User wants to dispatch a piece of data
  AND a DataDispatch instance is connected to a Channel
    that rejects such data
  WHEN the User dispatches the data via the DataDispatch instance
  THEN the DataDispatch object should report to the User
    that data is invalid
  AND close the connection anyway
  ```

For the remainder of this chapter I will focus on the first behavior as our goal for now is not to create a complete Specification of DataDispatch class, but rather to observe some mechanics of mock objects as a testing tool.

## Filling in the roles

As mentioned before, the environment in which the behavior takes place looks like this:

```text
User -> DataDispatch -> Channel
```

Now we need to say who will play these roles. I marked the ones we don't have filled yet with question marks (`?`):

```text
User? -> DataDispatch? -> Channel?
```

Let's start with the role of DataDispatch. Probably not surprisingly, it will be filled by the concrete class `DataDispatch` -- after all, this is the class that we specify.

Our environment looks like this now:

```text
User? -> DataDispatch (concrete class) -> Channel?
```

Next, who is going to be the user of the `DataDispatch` class? For this question, I have an easy answer -- the Statement body is going to be the user -- it will interact with `DataDispatch` to trigger the specified behaviors. This means that our environment looks like this now:

```text
Statement body -> DataDispatch (concrete class) -> Channel?
```

Now, the last element is to decide who is going to play the role of channel. We can express this problem with the following, unfinished Statement (I marked all the current unknowns with a double question mark: `??`):

```csharp
[Fact] public void
ShouldSendDataThroughOpenChannelThenCloseWhenAskedToDispatch()
{
  //GIVEN
  Channel channel = ??; //what is it going to be?
  var dispatch = new DataDispatch(channel);
  var data = Any.Array<byte>();

  //WHEN
  dispatch.ApplyTo(data);

  //THEN
  ?? //how to specify DataDispatch behavior?
}
```

As you see, we need to pass an implementation of `Channel` to a `DataDispatch`, but we don't know what this channel should be. Likewise, we have no good idea of how to specify the expected calls and their order.

From the perspective of `DataDispatch`, it is designed to work with everything that implements the `Channel` interface and follows the protocol, so there is no single "privileged" implementation that is more appropriate than others. This means that we can pretty much pick and choose the one we like best. Which one do we like best? The one that makes writing the specification easiest, of course. Ideally, we'd like to pass a channel that best fulfills the following requirements:

1. Adds as little side effects of its own as possible. If a channel implementation used in a Statement added side effects, we would never be sure whether the behavior we observe when executing our Specification is the behavior of `DataDispatch` or maybe the behavior of the particular `Channel` implementation that is used in this Statement. This is a requirement of trust -- we want to trust our Specification that it specifies what it says it does.
1. Is easy to control -- so that we can easily make it trigger different conditions in the object we are specifying. Also, we want to be able to easily verify how the specified object interacts with it. This is a requirement of convenience.
1. Is quick to create and easy to maintain -- because we want to focus on the behaviors we specify, not on maintaining or creating helper classes. This is a requirement of low friction.

There is a tool that fulfills these three requirements better than others I know of and it's called a mock object. Here's how it fulfills the mentioned requirements:

1. Mocks add almost no side effects of its own. Although they do have some hardcoded default behaviors (e.g. when a method returning `int` is called on a mock, it returns `0` by default), but these behaviors are as default and meaningless as they can possibly be. This allows us to put more trust in our Specification.
1. Mocks are easy to control - every mocking library comes provided with an API for defining pre-canned method call results and for verification of received calls. Having such API provides convenience, at least from my point of view.
1. Mocks can be trivial to maintain. While you can write your own mocks (i.e. your own implementation of an interface that allows setting up and verifying calls), mos of us use libraries that generate them, typically using a reflection feature of a programming language (in our case, C#). Typically, mock libraries free us from having to maintain mock implementations, lowering the friction of writing and maintaining our executable Statements.

 So let's use a mock in place of `Channel`! This makes our environment of the specified behavior look like this:

```text
Statement body -> DataDispatch (concrete class) -> Mock Channel
```

Note that the only part of this environment that comes from production code is the `DataDispatch`, while its context is Statement-specific.

## Using a mock channel

I hope you remember the NSubstitute library for creating mock objects that I introduced way back at the beginning of the book. We can use it now to quickly create an implementation of `Channel` that behaves the way we like, allows easy verification of protocol and between `Dispatch` and `Channel` and introduces as minimal number of side effects as possible.

By using this mock to fill the gaps in our Statement, this is what we end up with:

```csharp
[Fact] public void
ShouldSendDataThroughOpenChannelThenCloseWhenAskedToDispatch()
{
  //GIVEN
  var channel = Substitute.For<Channel>();
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

previously, this Statement was incomplete, because we lacked the answer to the following two questions:

1. Where to get the channel from?
1. How to verify `DataDispatch` behavior?

I answered the question of "where to get the channel from?" by creating it as a mock:

```csharp
var channel = Substitute.For<Channel>();
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

The consequence is that if I rearrange the order of the messages sent to `Channel` in the implementation of the `ApplyTo()` method from this one:

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
  _channel.Send(data); //before Open()!
  _channel.Open();
  _channel.Close();
}
```

The Statement will turn false (i.e. will fail).

## Mocks as yet another context

What we did in the above example was to put our `DataDispatch` in a context that was most trustworthy, convenient and frictionless for us to use in our Statement.

Some say that specifying object interactions in context of mocks is "specifying in isolation" and that providing such mock dependencies is "isolating" the class from its "real" dependencies. I don't identify with this point of view very much. From the point of view of a specified class, mocks are yet another context -- they are neither better, nor worse, they are neither more nor less real than other contexts we want to put our `Dispatch` in. Sure, this is not the context in which it runs in production, but we may have other situations than mere production work -- e.g. we may have a special context for demos, where we count sent packets and show the throughput on a GUI screen. We may also have a debugging context that in each method, before passing the control to a production code, writes a trace message to a log. The `DataDispatch` class may be used in the production code in several contexts at the same time. We may dispatch data through network, to a database and to a file all at the same time in our application and the `DataDispatch` class may be used in all these scenarios, each time connected to a different implementation of `Channel` and used by a different piece of code.

## Summary

The goal of this chapter was only to show you how mock objects fit into testing code written in a "tell don't ask" style, focusing on roles, responsibilities, behaviors, interfaces and protocols of objects. This example was meant as something you could easily understand, not as a showcase for TDD using mocks. For one more chapter, we will work on this toy example and then I will try to show you how I apply mock objects in more interesting cases.
