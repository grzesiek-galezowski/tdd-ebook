# Test-first using mock objects

Now that we saw mocks in action and placed them in the context of our design approach, I'd like to show you how it works in the context of test-first approach. To do that, I'm going to reiterate the example from the last chapter. I already described how this example is not particularly strong in terms of showcasing the power of mock objects, so I won't repeat myself here. In the next chapter, I will give you an example I consider more suited.

## How to start? - with mock objects

You probably remember the chapter "How to start?" from part 1 of this book. In that chapter, I described the following ways to kickstart writing a Statement before the actual implementation is in place:

1. Start with a good name.
1. Start by filling the GIVEN-WHEN-THEN structure with the obvious.
1. Start from the end.
1. Start by invoking a method if you have one.

Pretty much all of these strategies work equally well with Statements that use mock objects, so I won't be describing them in detail again. In this chapter, I will focus on "Start by invoking a method if you have one" as it's the one I use most often. This is not driven by my choice to use mock objects, but by the development style I most often use. This style is called "outside-in" and all we need to know about it for now is that following it means starting the development form the input of a use case and ending on the output. Many consider this counter-intuitive as it means we will write classes collaborating with other objects before we even have these objects. I will give you a small taste of it (together with a technique called "interface discovery") in this chapter and will expand on these ideas in the next one.

## Responsibility and Responsibility

In this chapter, I will be using two concepts that, unfortunately, happen to share the same name: responsibility. One meaning of responsibility was [coined by Rebecca Wirfs-Brock](http://www.wirfs-brock.com/PDFs/PrinciplesInPractice.pdf) to mean "an obligation to perform a task or know certain information", and the other by Robert C. Martin to mean "a reason to change". To avoid this ambiguity, I will try calling the first one "obligation" and the second one "purpose" in this chapter.

The relationship between the two can be described by the following sentences: 

1. A class has obligations towards its clients.
1. The obligations are what the class "promises" to do for its clients.
1. The class does not have to fulfill the obligations alone. Typically, it does so with help from other objects - its collaborators. Those collaborators, in turn, have have their collaborators.
1. Each of the collaborators is given a purpose resulting from decomposition of the obligation.

## Channel and DataDispatch one more time

Remember the example from the last chapter? Imagine we are in a situation where we already have the `DataDispatch` class, but its implementation is empty - after all, this is what we are going to test-drive.

So for now, the `DataDispatch` class looks like this

```csharp
public class DataDispatch
{
 public void ApplyTo(byte[] data)
 {
  throw new NotImplementedException();
 }
}
```

Where did we get this class from in this shape? Well, let's assume for now that are in the middle of development and this class is a result of our previous TDD activities (after reading this and the next chapter, you'll hopefully have a better feel on how it happens).

## The first behavior

As I already know class which behaviors I need to specify, plus it only has a single method (`ApplyTo()`), I may almost blindly write a Statement where I create an object of this class and invoke the method:

```csharp
[Fact] public void
ShouldXXXXXXXXXYYY() //TODO give a better name
{
 //GIVEN
 var dispatch = new DataDispatch();

 //WHEN
 dispatch.ApplyTo(); //TODO doesn't compile

 //THEN
 Assert.True(false); //TODO state expectations
}
```

Note several things:

1. I'm currently using a dummy name for the Statement and I added a TODO item to my list to correct it later, when I define the purpose and behaviors of `DataDispatch`.
1. According to its signature, the `ApplyTo()` method takes an argument, but I didn't provide any in the Statement. For now, I don't want to think too hard, I just want to brain-dump everything I know.
1. the `//THEN` section is empty for now - it only contains a single assertion that will fail when the execution flow reaches it (this way I protect myself from mistakenly making the Statement true until I state my true expectations). I will define the `//THEN` section once I figure out what is the purpose that I want to give this class.
1. If you remember the `Channel` interface from the last chapter, well, it doesn't exist yet and let's assume that in this continuum, I don't even know that I need it. I will "discover" it later.

So I did my brain dump. What do I do now? I don't want to think too hard yet (time will come for that). First, I reach for the feedback to my compiler - maybe it can give me some hints on what I am missing?

Currently, the compiler complains that I send the `ApplyTo` message without passing any argument. What's the name of the argument? `data`. Hmm, so let's pass some data. I don't want to decide what it is yet, so I will act as if I had a variable called `data` and just write its name where the argument is expected:

```csharp
[Fact] public void
ShouldXXXXXXXXXYYY() //TODO give a better name
{
 //GIVEN
 var dispatch = new DataDispatch();

 //WHEN
 dispatch.ApplyTo(data); //TODO still doesn't compile

 //THEN
 Assert.True(false); //TODO state expectations
}
```

The compiler gives me more feedback - it says my `data` variable is not defined anywhere. It might sound funny (as if I didn't know!), but this way I progressed one step further. Now I know I need to define this `data`. I can use the "quick fix" capability of my IDE to introduce a variable. E.g. in Jetbrains IDEs (IntelliJ IDEA, Resharper, Rider...) this can be done by pressing `ALT` `+` `ENTER` when the cursor is on the name of the missing variable. The IDE will create the following declaration:

```csharp
byte[] data;
```

Note that the IDE guessed the type of the variable for us. How did it know? Because the definition of the method where I try to pass it  already has the type declared:

```csharp
public void ApplyTo(byte[] data)
```

Of course, the declaration of `data` that my IDE put in the code will still not compile because C\# requires variables to be explicitly initialized, i.e. the code should look like this:

```csharp
byte[] data = ... /* whatever initialization code*/;
```

It looks like I can't continue my brain-dead parade anymore. In order to decide how to define this data, I have to turn on thinking and decide what exactly is the obligation of the `ApplyTo()` method and what does it need the `data` for. After some thinking (how convenient of me to exlude this thought process from the book!) I decide that it should send the data it receives, but should it do it alone? There are at least two things associated with sending the data:

1. The raw sending logic (i.e. laying out the data, pushing it e.g. through a web socket etc.)
1. Managing the connection lifetime (i.e. deciding when it should be opened and when closed, disposing of all the allocated resources, even in the face of an exception that may be raised during the sending).

I decide to not put the entirety of logic in the `DataDispatch` class, because:

1. It would have more than one purpose (as described earlier) - in other words, it would violate the Single Responsibility Principle.
1. I am unable to figure out how to write a false Statement for this much logic before the implementation. I always treat it as a sign that I'm trying to use a single class for too much.

Thus, my decision is to divide and conquer, i.e. find `DataDispatch` some collaborators that will help it achieve its goal and delegate parts of the logic there. After some consideration, I decide that the purpose of `DataDispatch` should be managing the connection lifetime. The rest of the logic I decide to delegate to a collaborator role that I named `Channel`. The process of coming out with collaborator roles and delegating some obligations to them is called *interface discovery*. I will cover it in the next chapter.

Anyway, since our `DataDispatch` is goind to delegate some logic to the `Channel`, it has to know it. Thus, let's connect this new collaborator to the `DataDispatch`. A `Channel` will receive messages from `DataDispatch` and `DataDispatch` will not work without a `Channel`, which means I need to pass the channel to `DataDispatch` as a constructor parameter. Thus, the following code:

```csharp
//GIVEN
var dispatch = new DataDispatch();
```

becomes:

```csharp
//GIVEN
var dispatch = new DataDispatch(channel); //doesn't compile
```

Of course, this code doesn't compile, because the `channel` variable isn't declared yet. By showing me the compilation error, the compiler gives me the feedback I need to progress further. Again, let's use our IDE to generate the `channel` variable. This time, however, the result of the generation is:

```csharp
Object channel;
```

The IDE could not guess the correct type of `channel` (which would be `Channel`) and made it an  `Object`, because, obviously, I haven't created the `Channel` type yet. Furthermore, `DataDispatch` doesn't really take a constructor argument yet, which would raise another compiler error even if I had the `Channel` type. These two errors are what I need to follow up on (again, useful, early feedback).

First, I'll introduce the `Channel` interface by changing the declaration `Object channel;` into `Channel channel;`. This will give me another compiler error, as the `Channel` does not yet exist. Thankfully, creating it is just one IDE click away (e.g. in Resharper, I place my cursor at the non-existent type, press `ALT` `+` `ENTER` and pick an option to create it as an interface.). Doing this will give me:

```csharp
public interface Channel
{

}
```

which is enough to get past this compiler error, but then I get another one - there is nothing assigned to the `channel` variable. Again, I have to turn my thinking on.Luckily, this time I can lean on a simple rule: in my design, `Channel` is a role and, as mentioned in the last chapter, I use mocks to, play the roles of my collaborators. So the conclusion is to use a mock. This makes the following line:

```csharp
Channel channel;
```

look like this:

```csharp
var channel = Substitute.For<Channel>();
```

Taking a bird's-eye view on the Statement, I currently have:

```csharp
[Fact] public void
ShouldXXXXXXXXXYYY() //TODO give a better name
{
 //GIVEN
 byte[] data; // does not compile yet
 var channel = Substitute.For<Channel>();
 var dispatch = new DataDispatch(channel);

 //WHEN
 dispatch.ApplyTo(data);

 //THEN
 Assert.True(false); //TODO state expectations
}
```

The compiler and my TODO list point out that I still have three things to do:

* define `data` variable,
* name my Statement and
* state my expectations (the `THEN` section of the Statement)

I can do them in any order I see fit, so I pick the last task from the list. To specify what is expected from `DataDispatch`, I have to answer myself four questions:

1. What are the obligations of `DataDispatch`?
1. What is the purpose of `DataDispatch`?
1. Who are the collaborators that need to receive messages from `DataDispatch`?
1. What is the behavior of `DataDispatch` that I need to specify?

My answers are as follows:

1. `DataDispatch` is obligated to sending data as long as it is valid. In case of invalid data, it throws an exception. That's two behaviors. As I only specify a single behavior per Statement, I pick the first one (adding the second one to my TODO list), which I will call "the happy path" from now on. This, by the way, will allow me to give the Statement a good name, but remember, I don't want to be distracted from my current task and the task to give our Statement a name is on my TODO list so I don't worry about it yet.
1. The purpose of `DataDispatch` is to manage connection lifetime while sending received data. So what I would need to specify is how `DataDispatch` manages this lifetime during the "happy path" scenario. The rest of what is needed to fulfill the obligation of `DataDispatch` is outside the scope of my Statement as it is pushed to collaborators.
1. I already defined one collaborator and called it `Channel`. As mentioned in the last chapter, in unit-level Statements, I use mock for my collaborators to specify what messages they receive. Thus, I know that the `THEN` section will say what messages is the  `Channel` role (played by a mock object) expected to receive from my `DataDispatch`.
1. My conclusion from the three above points is that I expect a `Channel` to be used correctly in a scenario where the data is send without errors. As channels are typically opened and closed, then what my `DataDispatch` is expected to do is to open the channel, then push data through it, and then close it.

//todo todo todo todo todo todo todo todo  the below is a propos point 1 above~!~~!!!!!!!!!!!!

```csharp
//TODO: specify a behavior where sending data
//      through a channel raises an exception
```

Now we can get back to our task at hand, which is specifying the happy path behavior. In the typical scenario, managing the connection means that the channel is open, then the data is send, then the channel is closed. We can specify that using NSubstitute's `Received.InOrder()` syntax. With this, we will specify that the three methods should be called in a specific order. Wait, what methods? After all, our `Channel` interface looks like this:

```csharp
public interface Channel
{

}
```

so there are not methods here whatsoever. The answer is - just like we discovered the need for the `Channel` interface and then brought it to life afterwards, we now discovered that we need three methods: `Open()`, `Send()` and `Close()`. So now we can do with these methods exactly the same thing as we did with the `Channel` interface - we can use them in our Statement as if they existed and then pull them into existence using our IDE and its magical shortcut for generating missing classes and methods.

When the three methods are used in a Statement, it takes the following shape:

```csharp
[Fact] public void
ShouldXXXXXXXXXYYY() //TODO give a better name
{
 //GIVEN
 byte[] data; // does not compile yet
 var channel = Substitute.For<Channel>();
 var dispatch = new DataDispatch(channel);

 //WHEN
 dispatch.ApplyTo(data);

 //THEN
 Received.InOrder(() =>
 {
  channel.Open(); //doesn't compile
  channel.Send(data); //doesn't compile
  channel.Close(); //doesn't compile
 });
}
```

using our IDE, we can add these methods to our `Channel` interface:

```csharp
public interface Channel
{
 void Open();
 void Send(byte[] data);
 void Close();
}
```

Now we have only two things left on our list - giving the Statement a good name and deciding what the `data` variable should hold. Let's do the latter as it gives more feedback and stops the compiler and prevents evaluating the Statement.

Time to think about how much does the `DataDispatch` need to know about the data. As its purpose is to manage connection, validation does not fit without breaking the single-purposeness, so we decide that `DataDispatch` will work with any data and someone needs to be responsible for ensuring valid data. We put that on the `Channel` as it depends on the actual implementation of sending what data can be sent and what cannot. Thus, we will define the `data` variable in our Statement as `Any.Array<byte>()`:

```csharp
[Fact] public void
ShouldXXXXXXXXXYYY() //TODO give a better name
{
 //GIVEN
 var data = Any.Array<byte>();
 var channel = Substitute.For<Channel>();
 var dispatch = new DataDispatch(channel);

 //WHEN
 dispatch.ApplyTo(data);

 //THEN
 Received.InOrder(() =>
 {
  channel.Open();
  channel.Send(data);
  channel.Close();
 });
}
```

The code now compiles, so what we need is to give this Statement a better name. Let's go with `ShouldSendDataThroughOpenChannelThenCloseWhenAskedToDispatch`. This was the last TODO on the Specification side, so let's see the full Statement code:

```csharp
[Fact] public void
ShouldSendDataThroughOpenChannelThenCloseWhenAskedToDispatch()
{
 //GIVEN
 var data = Any.Array<byte>();
 var channel = Substitute.For<Channel>();
 var dispatch = new DataDispatch(channel);

 //WHEN
 dispatch.ApplyTo(data);

 //THEN
 Received.InOrder(() =>
 {
  channel.Open();
  channel.Send(data);
  channel.Close();
 });
}
```

The Statement now is false, because the implementation throws a `NotImplementedException`. Remember, what we would like to see before we start implementing the right behavior is that the assertions (in this case - mock verifications) fail. So the lines that we would like to see an exception from are these:

```csharp
Received.InOrder(() =>
{
 channel.Open();
 channel.Send(data);
 channel.Close();
});
```

but instead, we get an exception as early as:

```csharp
//WHEN
dispatch.ApplyTo(data);
```

What do we do? We push the implementation a little bit further, only as much as to see the expected failure. In our case, all we need to do is take the `ApplyTo()` method from the specified class:

```csharp
public void ApplyTo(byte[] data)
{
 throw new NotImplementedException();
}
```

and remove the `throw` clause, making it:

```csharp
public void ApplyTo(byte[] data)
{

}
```

This alone is enough to see the mock verification make our Statement false. Now we can just put the correct implementation. Let's start with `DataDispatch` constructor, which currently takes a `Channel` as a parameter, but doesn't do anything with it. What we need to do is to assign the channel to a newly created field (this can be done using a single command in most IDEs). The code becomes:

```csharp
private readonly Channel _channel;

public DataDispatch(Channel channel)
{
 _channel - channel;
}
```

Now what we have this channel, we can implement the `ApplyTo()` method:

```csharp
public void ApplyTo(byte[] data)
{
 _channel.Open();
 _channel.Send(data);
 _channel.Close();
}
```

T> To tell you the truth, usually before writing the correct implementation, I play a bit, making it wrong in several ways, just to see if I can correctly guess the reason why the Statement will turn false and to make sure the error messages are informative enough. For example, I may write only the first line and observe whether the Statement is still false and if the reason is changed. Then I may add the second, but pass something other than `_data` to the `Open()` method (e.g. a `null`) etc. This way, I "test my test", not only for correctness (whether it will fail for the right reason) but also for diagnostics (will it give me enough information when it fails?). Also, this is the way I learn about feedback that I receive from my tools should such a Statement turn false later.

### Second behavior - specifying an error

The first Statement is implemented, so time for the second one. (XXX TODO TODO TODO TODO TODO it comes from TODO list XXX) Our second behavior was that in case the sending failed, the user of `DataDispatch` should receive this error and the connection should be safely closed. Note that the notion of what "closing the connection" means is placed in the `Channel` implementations, because we consciously delegated the implementation details there. The same goes for the meaning of "errors while sending data -- this is also the responsibility of `Channel`. What we need to specify about `DataDispatch` is how it handles the sending errors in regard to its user and its `Channel`.

Let's start writing the Statement by stating the obvious. This time, we'll use the strategy of starting with a good name. I picked the following name to state the expected behavior:

```csharp
public void
ShouldRethrowExceptionAndCloseChannelWhenSendingDataFails()
{
 //...
}
```

Before we start dissecting the name into useful code, let's start by stating the bleedy obvious (note that I'm mixing two strategies now - this is OK, of course). We know that:

1. We need to work with `DataDispatch` again.
1. We need to pass a mock of `Channel`.
1. We need to send the `ApplyTo()` message.
1. We need some kinf of invalid data (although we don't know yet what to do to make it invalid).

Let's write that down in the form of code:

```csharp
public void
ShouldRethrowExceptionAndCloseChannelWhenSendingDataFails()
{
 //GIVEN
 var channel = Substitute.For<Channel>();
 var dataDispatch = new DataDispatch(channel);
 byte[] invalidData; //doesn't compile

 //WHEN
 dataDispatch.ApplyTo(invalidData);

 //THEN
 Assert.True(false);
}
```

Now, we know that one aspect of the expected behavior is closing the channel. We know how to write this - we use the `Received()` method of NSubstitute on the channel mock. So let's write that in the `//THEN` section:

```csharp
 //THEN
 channel.Received(1).Close();
 Assert.True(false); //not removing this yet
}
```

I used `Received(1)`, because attempting to close the channel several times might cause trouble, so I want to make sure that the `DataDispatch` closes the channel exactly once. Another thing - I am not removing the `Assert.True(false)` yet, as the Statement could become true otherwise (if it compiled, that is). This is not OK, because this Statement does not yet specify correctly the intended scenario. What are we missing? Specifying that an exception resulting from invalid data is rethrown. Normally, I rarely write Statements about rethrown exceptions, but here I have no choice - if we don't somehow catch the exception in our Statement, we won't be able to evaluate whether the channel was closed or not, since the uncaught exception will make our Statement false before that.

To specify that exception should be thrown, we don't need to decide on what the invalid data is yet. We just need to use (TODO verify the assertion) `Assert.Throws<>()` assertion and pass the code that should throw the exception as lambda:

```csharp
 //WHEN
Assert.Throws<Exception>(() =>
  dataDispatch.ApplyTo(invalidData));
```

OK, now the time has come to decide what actually is invalid data. I will do that by remembering that I pushed the responsibility of detecting valid and invalid data into the `Channel` when I discovered this interface. Then, I will conclude that invalid data is data that is recognized as such by a particular `Channel` implementation. As we use a mock implementation of the `Channel` interface, we will just have to configure it so that it throws an exception given the particular data that we use in our Statement. Thus, the value of the `data` itself is irrevelant as long as it's the one that a `Channel` recognizes as invalid. So first, let's define the `data` as any byte array:

```csharp
byte[] invalidData = Any.Array<byte>();
```

Then let's write down the assumption of how the `channel` will behave given this data:

```csharp
//GIVEN
...
var exceptionFromChannel = Any.Exception();
channel.When(c => c.Send(invalidData)).Throw(exceptionFromChannel);
```

Note that the place where we configure the mock to throw an exception is the `//GIVEN` section. This is because any mock pre-configuration is our assumption. By pre-canning the method outcome in this case, we say "given that channel for some reason rejects this data".

Now that we have the full Statement code, we can get rid of the `Assert.True(false)` assertion. The full Statement looks like this:

```csharp
public void
ShouldRethrowExceptionAndCloseChannelWhenSendingDataFails()
{
 //GIVEN
 var channel = Substitute.For<Channel>();
 var dataDispatch = new DataDispatch(channel);
 var data = Any.Array<byte>();
 var exceptionFromChannel = Any.Exception();

//toooodooo Throw or Throws???????????
 channel.When(c => c.Send(data)).Throw(exceptionFromChannel);

 //WHEN
 var exception = Assert.Throws<Exception>(() =>
  dataDispatch.ApplyTo(invalidData));

 //THEN
 Assert.Equal(exceptionFromChannel, exception);
 channel.Received(1).Close();
}
```

Now, it looks a bit messy, but given our toolset, this has to do. This Statement will now run and fail on the second assertion. Wait, the second? What about the first one? Well, the first assertion says that an exception should be rethrown, but methods in C# rethrow the exception by default (that's why typically I don't specify that something should rethrow an exception - I do it this time because otherwise it would not let me specify how `DataDispatch` uses a `Channel`). Thus, this behavior is implemented by doing nothing. Should we just acept it? No, we should not. Remember what I wrote in the first part - we need to see each assertion fail at least once. An assertion that passes straight away is something we should be suspicious about. What we need to do now is to temporary break the behavior and see the failure. We can do that (at least) in two ways:

1. By going to the Statement and commenting out the line that configures the `Channel` mock to throw an exception.
1. By going to the production code and surrounding the `channel.Send(data)` statement with a try-catch block.

Either way is fine with me, so I chose the first way. By commenting the mock configuration in the Statement, I can now observe the assertion fail, because an exception was expected but none came out of the `dataDispatch.ApplyTo()` invocation. Now I'm ready the uncomment this line again, confident that my Statement describes this part of the behavior well and I can focus on the second assertion:

```csharp
channel.Received(1).Close();
```

This assertion fails because our current implementation of the `ApplyTo()` method is:

```csharp
_channel.Open();
_channel.Send(data);
_channel.Close();
```

and an exception throw from the `Send()` method interrupts the processing, instantly exiting the method, so `Close()` is never called. We can change this behavior by using try-finally block to wrap the call to `Send()`:

```csharp
_channel.Open();
try
{
 _channel.Send(data);
}
finally
{
 _channel.Close();
}
```

This makes our second Statement true and concludes this example.

## Summary

In this chapter, we delved into writing mock-based Statement in a test-first manner. It demonstrated an example of how I would approach developing a class in a test-first way. I consider it important to remember that this is an example of how it can be done, not "the true way" or the right path. There were many situations where I got several TODO items pointed by my compiler or the failing test. Depending on many factors, I might've approached them in a different order. For example, in the second behavior, I could've defined `data` as `Any.Array<byte>()` right from the start (and left a TODO item to check on it later) to get the Statement to compiling state quicker.

Another interesting point was the moment when I discovered the `Channel` interface - I'm aware that I slipped over it by saying something "we can see that the class has too many purposes, then magic happens and then we've got an interface to delegate parts of the logic to". This "magic happens" part is often called "interface discovery" and we will dig a little deeper into it in the next chapter.

You might've noticed that this chapter was longer than the last one and jump to a conclusion that it means that TDD complicates things rather than simplifying them. There were, however, several factors that made this chapter longer:

1. In this chapter, we specified both behaviors (happy path plus error handling), whereas in the last chapter we only specified one (happy path).
1. In this chapter, we designed and implemented the `DataDispatch` class and discovered the `Channel` interface whereas in the last chapter they were given to us right from the start.
1. As I assume the test-first way of writing Statements is less familiar to you, I took my time to explain it in more detail.
1. The through process I described usually takes seconds in writing and maybe several minutes in thinking.

TODO why is this way of test-first usual? let's try to implement the channel.

TODO write that this process usually takes seconds.

TODO why a mock? because real channel does not exist and context independence.??

TODO what next - we can specify/implement Channel.

TODO deciding what we start from is about deciding what can give us the best feedback.

TODO I often write everything and then generate code.

TODO specifying the negative - quote from Kent Beck.
"I often optimize for the mistakes that I make or we collectively make"

TODO examine the way Steve Freeman and Nat Pryce described in mock roles not objects
