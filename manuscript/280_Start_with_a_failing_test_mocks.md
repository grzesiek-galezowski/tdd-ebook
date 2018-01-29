# Test-first using mock objects

Now that we saw mocks in action and placed them in the context of a specific design approach, I'd like to show you how mock objects are used when employing the test-first approach. To do that, I'm going to reiterate the example from the last chapter. I already mentioned how this example is not particularly strong in terms of showcasing the power of mock objects, so I won't repeat myself here. In the next chapter, I will give you an example I consider more suited.

## How to start? -- with mock objects

You probably remember the chapter "How to start?" from part 1 of this book. In that chapter, I described the following ways to kick-start writing a Statement before the actual implementation is in place:

1. Start with a good name.
1. Start by filling the GIVEN-WHEN-THEN structure with the obvious.
1. Start from the end.
1. Start by invoking a method if you have one.

Pretty much all of these strategies work equally well with Statements that use mock objects, so I won't be describing them in detail again. In this chapter, I will focus on "Start by invoking a method if you have one" as it's the one I use most often. This is driven not only  by my choice to use mock objects, but also by the development style I most often use. This style is called "outside-in" and all we need to know about it for now is that following it means starting the development form the input of system and ending on the output. Many consider this counter-intuitive as it means we will write classes collaborating with classes that don't exist yet. I will give you a small taste of it (together with a technique called "interface discovery") in this chapter and will expand on these ideas in the next one.

## Responsibility and Responsibility

In this chapter, I will be using two concepts that, unfortunately, happen to share the same name: "responsibility". One meaning of responsibility was [coined by Rebecca Wirfs-Brock](http://www.wirfs-brock.com/PDFs/PrinciplesInPractice.pdf) to mean "an obligation to perform a task or know certain information", and the other by Robert C. Martin to mean "a reason to change". To avoid this ambiguity, I will try calling the first one "obligation" and the second one "purpose" in this chapter.

The relationship between the two can be described by the following sentences: 

1. A class has obligations towards its clients.
1. The obligations are what the class "promises" to do for its clients.
1. The class does not have to fulfill the obligations alone. Typically, it does so with help from other objects -- its collaborators. Those collaborators, in turn, have have their obligations and collaborators.
1. Each of the collaborators is given a purpose resulting from decomposition of the obligation.

## Channel and DataDispatch one more time

Remember the example from the last chapter? Imagine we are in a situation where we already have the `DataDispatch` class, but its implementation is empty -- after all, this is what we're going to test-drive.

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

Where did I get this class from in this shape? Well, let's assume for now that I am in the middle of development and this class is a result of my previous TDD activities (after reading this and the next chapter, you'll hopefully have a better feel on how it happens).

## The first behavior

A TDD cycle starts with a false Statement. What behavior should it describe? I'm not sure yet, but, as I already know the class that will have the behaviors that I want to specify, plus it only has a single method (`ApplyTo()`), I can almost blindly write a Statement where I create an object of this class and invoke the method:

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

1. I'm currently using a dummy name for the Statement and I added a TODO item to my list to correct it later, when I define the purpose and behavior of `DataDispatch`.
1. According to its signature, the `ApplyTo()` method takes an argument, but I didn't provide any in the Statement. For now, I don't want to think too hard, I just want to brain-dump everything I know.
1. the `//THEN` section is empty for now -- it only contains a single assertion that is designed to fail when the execution flow reaches it (this way I protect myself from mistakenly making the Statement true until I state my true expectations). I will define the `//THEN` section once I figure out what is the purpose that I want to give this class and the behavior that I want to specify.
1. If you remember the `Channel` interface from the last chapter, well, in this continuum it doesn't exist yet and let's assume that, I don't even know that I need it. I will "discover" it later.

### Leaning on the compiler

So I did my brain dump. What do I do now? I don't want to think too hard yet (time will come for that). First, I reach for the feedback to my compiler -- maybe it can give me some hints on what I am missing?

Currently, the compiler complains that I invoke the `ApplyTo()` method without passing any argument. What's the name of the argument? As I look up the signature of the `ApplyTo()` method, it looks like the name is `data`:

```csharp
public void ApplyTo(byte[] data)
```

Hmm, if it's data it wants, then let's pass some data. I don't want to decide what it is yet, so I will act *as if I had* a variable called `data` and just write its name where the argument is expected:

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

The compiler gives me more feedback -- it says my `data` variable is undefined. It might sound funny (as if I didn't know!), but this way I progressed one step further. Now I know I need to define this `data`. I can use a "quick fix" capability of my IDE to introduce a variable. E.g. in Jetbrains IDEs (IntelliJ IDEA, Resharper, Rider...) this can be done by pressing `ALT` `+` `ENTER` when the cursor is on the name of the missing variable. The IDE will create the following declaration:

```csharp
byte[] data;
```

Note that the IDE guessed the type of the variable for me. How did it know? Because the definition of the method where I try to pass it  already has the type declared:

```csharp
public void ApplyTo(byte[] data)
```

Of course, the declaration of `data` that my IDE put in the code will still not compile because C\# requires variables to be explicitly initialized, i.e. the code should look like this:

```csharp
byte[] data = ... /* whatever initialization code*/;
```

### Turning the brain on - what about data?

It looks like I can't continue my brain-dead parade anymore. In order to decide how to define this data, I have to turn on my thought processes and decide what exactly is the obligation of the `ApplyTo()` method and what does it need the `data` for. After some thinking (how convenient of me to exclude this part from the book!) I decide that applying data dispatch should send the data it receives. But... should it do it alone? There are at least two things associated with sending the data:

1. The raw sending logic (i.e. laying out the data, pushing it e.g. through a web socket etc.)
1. Managing the connection lifetime (i.e. deciding when it should be opened and when closed, disposing of all the allocated resources, even in the face of an exception that may be raised while sending).

I decide to not put the entirety of logic in the `DataDispatch` class, because:

1. It would have more than one purpose (as described earlier) -- in other words, it would violate the Single Responsibility Principle.
1. I am mentally unable to figure out how to write a false Statement for so much logic before the implementation. I always treat it as a sign that I'm trying to use a single class for too much[^nextchapterdiscovery].

### Introducing a collaborator

Thus, my decision is to divide and conquer, i.e. find `DataDispatch` some collaborators that will help it achieve its goal and delegate parts of the logic to them. After some consideration, I decide that the purpose of `DataDispatch` should be managing the connection lifetime. The rest of the logic I decide to delegate to a collaborator role that I named `Channel`. The process of coming out with collaborator roles and delegating some obligations to them is called *interface discovery*. I will cover it in the next chapter.

Anyway, since my `DataDispatch` is goind to delegate some logic to the `Channel`, it has to know it. Thus, I'll connect this new collaborator to the `DataDispatch`. A `DataDispatch` will not work without a `Channel`, which means I need to pass the channel to `DataDispatch` as a constructor parameter. It's tempting to just go to the definition of this constructor and add a parameter there, but that's not what I'll do. I will, as usual, start my changes from the Statement. Thus, I will modify the following code:

```csharp
//GIVEN
var dispatch = new DataDispatch();
```

to:

```csharp
//GIVEN
var dispatch = new DataDispatch(channel); //doesn't compile
```

I passed a `channel` object *as if* it was already defined in the Statement body and *as if* the constructor already accepted it. Of course, none of these is the case yet. This makes my compiler give me more compile errors. For me, this is a valuable source of feedback that I need to progress further. The first thing the compiler tells me to do is to introduce a `channel` variable. Again, I use my IDE to generate it for me. This time, however, the result of the generation is:

```csharp
Object channel;
```

The IDE could not guess the correct type of `channel` (which would be `Channel`) and made it an  `Object`, because, obviously, I haven't created the `Channel` type yet.

First, I'll introduce the `Channel` interface by changing the declaration `Object channel;` into `Channel channel;`. This will give me another compile error, as the `Channel` type does not exist. Thankfully, creating it is just one IDE click away (e.g. in Resharper, I place my cursor at the non-existent type, press `ALT` `+` `ENTER` and pick an option to create it as an interface.). Doing this will give me:

```csharp
public interface Channel
{

}
```

which is enough to get past this particular compiler error, but then I get another one -- nothing is assigned to the `channel` variable. Again, I have to turn my thinking on. Luckily, this time I can lean on a simple rule: in my design, `Channel` is a role and, as mentioned in the last chapter, I use mocks to play the roles of my collaborators. So the conclusion is to use a mock. By applying this rule, I change the following line:

```csharp
Channel channel;
```

to:

```csharp
var channel = Substitute.For<Channel>();
```

The last compiler error I need to address to fully introduce the `Channel` collaborator is to make the `DataDispatch` constructor accept the channel as its argument. For now `DataDispatch` uses an implicit parameterless constructor. I need to generate a new one, again, using my IDE, going to the place where the constructor is used with the channel and telling my IDE to correct the constructor signature for me. This way I get a constructor code inside the `DataDispatch` class:

```csharp
public DataDispatch(Channel channel)
{

}
```

Note that the constructor doesn't do anything with the channel. I could create a new field and assign the channel to it, but I wouldn't use the field at this moment anyway. Thus, I decide I can wait a little bit longer before introducing a field.

Taking a bird's-eye view on my Statement, I currently have:

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

This way, I defined a `Channel` collaborator and introduced it first in my Statement, and then in the production code.

### Specifying expectations

The compiler and my TODO list point out that I still have three tasks to accomplish for the current Statement:

* define `data` variable,
* name my Statement and
* state my expectations (the `THEN` section of the Statement)

I can do them in any order I see fit, so I pick the last task from the list - stating the expected behavior.

To specify what is expected from `DataDispatch`, I have to answer myself four questions:

1. What are the obligations of `DataDispatch`?
1. What is the purpose of `DataDispatch`?
1. Who are the collaborators that need to receive messages from `DataDispatch`?
1. What is the behavior of `DataDispatch` that I need to specify?

My answers to these questions are:

1. `DataDispatch` is obligated to sending data as long as it is valid. In case of invalid data, it throws an exception. That's two scenarios. As I only specify a single scenario per Statement, I need to pick one of them. I pick the first one (which I will call "the happy path" from now on), adding the second one to my TODO list:

   ```csharp
   //TODO: specify a behavior where sending data
   //      through a channel raises an exception
   ```

1. The purpose of `DataDispatch` is to manage connection lifetime while sending data received via the `ApplyTo()` method. Putting it together with the answer to the last question, what I would need to specify is how `DataDispatch` manages this lifetime during the "happy path" scenario. The rest of what I need to fulfill the obligation of `DataDispatch` is outside the scope of the current Statement as I decided to push it to collaborators.
1. I already defined one collaborator and called it `Channel`. As mentioned in the last chapter, in unit-level Statements, I fill my collaborators' roles with mocks and specify what messages they should receive. Thus, I know that the `THEN` section will say what are the messages that the `Channel` role (played by a mock object) is expected to receive from my `DataDispatch`.
1. Now that I know the scenario, the purpose and the collaborators, I can define my expected behavior in terms of those things. My conclusion is that I expect `DataDispatch` to properly manage (purpose) a `Channel` (collaborator) in a "happy path" (scenario) where the data is sent without errors (obligation). As channels are typically opened before they are used and are closed afterwards, then what my `DataDispatch` is expected to do is to open the channel, then push data through it, and then close it.

How to implement such expectations? Implementation-wise, what I expect is that `DataDispatch`:

* makes correct calls (open, send, close)
* with correct arguments (the received data)
* in correct order (cannot e.g. call close before open)
* correct number of times (e.g. should not send the data twice)

I can specify that using NSubstitute's `Received.InOrder()` syntax. I will thus use it to state that the three methods are expected to be called in a specific order. Wait, what methods? After all, our `Channel` interface looks like this:

```csharp
public interface Channel
{

}
```

so there are no methods here whatsoever. The answer is -- just like I discovered the need for the `Channel` interface and then brought it to life afterwards, I now discovered that I need three methods: `Open()`, `Send()` and `Close()`. Exactly the same way as I did with the `Channel` interface, I will use them in my Statement *as if* they existed:

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

and then pull them into existence using my IDE and its shortcut for generating missing classes and methods. This way, I get:

```csharp
public interface Channel
{
 void Open();
 void Send(byte[] data);
 void Close();
}
```

Now I have only two things left on my list -- giving the Statement a good name and deciding what the `data` variable should hold. I'll go with the latter as it is the last thing that prevents the compiler from compiling and running my Statement and I expect it will give me more useful feedback.

### The `data` variable

What should I assign to the `data` variable? Time to think about how much does the `DataDispatch` need to know about the data it needs to push through the channel. I decide that `DataDispatch` should work with any data -- its purpose is to manage the connection after all -- it does not need to read or manipulate the data to do this. Someone, somewhere, probably needs to validate this data, but I decide that if I added validation logic to the `DataDispatch`, it would break the single-purposeness. So I push validation further to the `Channel` interface, as whether a channel can accept the data or not depends on the actual implementation of sending logic. Thus, I define the `data` variable in my Statement as just `Any.Array<byte>()`:

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

### Good name

The Statement now compiles and runs (it is currently false, of course, but I'll get to that), so what I need is to give this Statement a better name. I'll go with `ShouldSendDataThroughOpenChannelThenCloseWhenAskedToDispatch`. This was the last TODO on the Specification side, so let's see the full Statement code:

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

### Failing for the correct reason

The Statement I just wrote can now be evaluated and, as expected, it is false, because for now, the implementation throws a `NotImplementedException`:

```csharp
public class DataDispatch
{
 public DataDispatch(Channel channel)
 {

 }

 public void ApplyTo(byte[] data)
 {
  throw new NotImplementedException();
 }
}
```

What I'd like to see before I start implementing the correct behavior is that the Statement is false because assertions (in this case -- mock verifications) fail. So the part of the Statement that I would like to see throwing an exception is this one:

```csharp
Received.InOrder(() =>
{
 channel.Open();
 channel.Send(data);
 channel.Close();
});
```

but instead, I get an exception as early as:

```csharp
//WHEN
dispatch.ApplyTo(data);
```

To make progress past the `WHEN` section, I need to push the production code a little bit further towards the correct behavior, but only as much as to see the expected failure. Thankfully, I can achieve it easily, by going into the `ApplyTo()` method and removing the `throw` clause, making it:

```csharp
public void ApplyTo(byte[] data)
{

}
```

This alone is enough to see the mock verification making my Statement false. Now that I can see that the Statement is false for the correct reason, my next step is to put the correct implementation to make the Statement true.

### Making the Statement true

I start with the `DataDispatch` constructor, which currently takes a `Channel` as a parameter, but doesn't do anything with it:

```csharp
public DataDispatch(Channel channel)
{

}
```

I want to assign the channel to a newly created field (this can be done using a single command in most IDEs). The code then becomes:

```csharp
private readonly Channel _channel;

public DataDispatch(Channel channel)
{
 _channel = channel;
}
```

This allows me to use the `_channel` in the `ApplyTo()` method that I'm trying to implement. Remembering that my goal is to open the channel, push the data and the close the channel, I type:

```csharp
public void ApplyTo(byte[] data)
{
 _channel.Open();
 _channel.Send(data);
 _channel.Close();
}
```

T> To tell you the truth, usually before writing the correct implementation, I play a bit, making the Statement wrong in several ways, just to see if I can correctly guess the reason why the Statement will turn false and to make sure the error messages are informative enough. For example, I may only implement opening the channel at first and observe whether the Statement is still false and if the reason for that is changed as I expected. Then I may add sending the data, but pass something other than `_data` to the `Send()` method (e.g. a `null`) etc. This way, I "test my test", not only for correctness (whether it will fail for the right reason) but also for diagnostics (will it give me enough information when it fails?). Finally, this is also a way I learn about how my test automation tools inform me of issues in such cases.

## Second behavior -- specifying an error

The first Statement is implemented, so time for the second one -- remember I put it on the TODO list a while ago so that I don't forget about it:

```csharp
//TODO: specify a behavior where sending data
//      through a channel raises an exception
```

This second behavior is that in case the sending fails with exception, the user of `DataDispatch` should receive this exception and the connection should be safely closed. Note that the notion of what "closing the connection" means is delegated to the `Channel` implementations, so when specifying the behaviors of `DataDispatch` I only need to care whether `Channel`'s `Close()` method is invoked correctly. The same goes for the meaning of "errors while sending data" -- this is also the obligation of `Channel`. What we need to specify about `DataDispatch` is how it handles the sending errors in regard to its user and its `Channel`.

### Starting with a good name

This time, I choose the strategy of starting with a good name, because I feel I have a much better understanding of what behavior I need to specify than with my previous Statement. I pick the following name to state the expected behavior:

```csharp
public void
ShouldRethrowExceptionAndCloseChannelWhenSendingDataFails()
{
 //...
}
```

Before I start dissecting the name into useful code, I start by stating the bleedy obvious (note that I'm mixing two strategies of starting from false Statement now -- I didn't say you can't do that now, did I?). Having learned a lot by writing and implementing the previous Statement, I know for sure that:

1. I need to work with `DataDispatch` again.
1. I need to pass a mock of `Channel` to `DataDispatch` constructor.
1. `Channel` role will be played by a mock object.
1. I need to invoke the `ApplyTo()` method.
1. I need some kind of invalid data (although I don't know yet what to do to make it "invalid").

I write that down in a form of code:

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
 Assert.True(false); //no expectations yet
}
```

### Expecting that channel is closed

I also know that one aspect of the expected behavior is closing the channel. I know how to write this expectation -- I can use the `Received()` method of NSubstitute on the channel mock. This will, of course, go into the `//THEN` section:

```csharp
 //THEN
 channel.Received(1).Close(); //added
 Assert.True(false); //not removing this yet
}
```

I used `Received(1)` instead of just `Received()`, because attempting to close the channel several times might cause trouble, so I want to be explicit on the expectaton that the `DataDispatch` should close the channel exactly once. Another thing -- I am not removing the `Assert.True(false)` yet, as the current implementation already closes the channel and so the Statement could become true if not for this assertion (if it compiled, that is). I will remove this assertion only after I fully define the behavior.

### Expecting exception

Another thing I expect `DataDispatch` to do in this behavior is to rethrow any sending errors, which are reported as exceptions thrown by `Channel` from the `Send()` method.

T> Typically, I rarely write Statements about rethrown exceptions, but here I have no choice -- if I don't catch the exception in my Statement, I won't be able to evaluate whether the channel was closed or not, since the uncaught exception will stop executing the Statement.

To specify that I expect an exception in my Statement, I need to use a special assertion called `Assert.Throws<>()` and pass the code that should throw the exception as a lambda:

```csharp
 //WHEN
Assert.Throws<Exception>(() =>
  dataDispatch.ApplyTo(invalidData));
```

### Defining invalid data

My compiler shows me that the `data` variable is undefined. OK, now the time has come to decide what actually is invalid data.

First of all, remember that `DataDispatch` cannot tell the difference between valid and invalid data - this is the purpose of the `Channel` as each `Channel` implementation might have different criteria for data validation. In my Statement, I use a mock to play the channel role, so I can just tell my mock that it should treat the data I define in my Statement as invalid. Thus, the value of the `data` itself is irrelevant as long as I configure my `Channel` mock to act as if it was invalid. As a conclusion, I define the `data` as any byte array:

```csharp
var invalidData = Any.Array<byte>();
```

I also need to write down the assumption of how the `channel` will behave given this data:

```csharp
//GIVEN
...
var exceptionFromChannel = Any.Exception();
channel.When(c => c.Send(invalidData)).Throw(exceptionFromChannel);
```

Note that the place where I configure the mock to throw an exception is the `//GIVEN` section. This is because any predefined mock behavior is my assumption. By pre-canning the method outcome in this case, I say "given that channel for some reason rejects this data".

Now that I have the full Statement code, I can get rid of the `Assert.True(false)` assertion. The full Statement looks like this:

```csharp
public void
ShouldRethrowExceptionAndCloseChannelWhenSendingDataFails()
{
 //GIVEN
 var channel = Substitute.For<Channel>();
 var dataDispatch = new DataDispatch(channel);
 var data = Any.Array<byte>();
 var exceptionFromChannel = Any.Exception();

 channel.When(c => c.Send(data)).Throw(exceptionFromChannel);

 //WHEN
 var exception = Assert.Throws<Exception>(() =>
  dataDispatch.ApplyTo(invalidData));

 //THEN
 Assert.Equal(exceptionFromChannel, exception);
 channel.Received(1).Close();
}
```

Now, it may look a bit messy, but given my toolset, this will have to do. This Statement will now turn false on the second assertion. Wait, the second? What about the first one? Well, the first assertion says that an exception should be rethrown and methods in C# rethrow the exception by default, not requiring any implementation on my part[^idonotthrow]. Should I just acept it and go on? Well, I don't want to. Remember what I wrote in the first part of the book -- we need to see each assertion fail at least once. An assertion that passes straight away is something we should be suspicious about. What I need to do now is to temporary break the behavior do that I can see the failure. I can do that in (at least) two ways:

1. By going to the Statement and commenting out the line that configures the `Channel` mock to throw an exception.
1. By going to the production code and surrounding the `channel.Send(data)` statement with a try-catch block.

Either way would do, but I typically prefer to change the production code and not alter my Statements, so I chose the second way. By wrapping the `Send()` invocation with `try` and empty `catch`, I can now observe the assertion fail, because an exception was expected but none came out of the `dataDispatch.ApplyTo()` invocation. Now I'm ready to undo my last change, confident that my Statement describes this part of the behavior well and I can focus on the second assertion, which is:

```csharp
channel.Received(1).Close();
```

This assertion fails because my current implementation of the `ApplyTo()` method is:

```csharp
_channel.Open();
_channel.Send(data);
_channel.Close();
```

and an exception thrown from the `Send()` method interrupts the processing, instantly exiting the method, so `Close()` is never called. We can change this behavior by using `try-finally` block to wrap the call to `Send()`[^idiomatictryfinally]:

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

This makes my second Statement true and concludes this example. If I were to go on, my next step would be to implement the newly discovered `Channel` interface, as currently it has no implementation at all.

## Summary

In this chapter, we delved into writing mock-based Statements and developing classes in a test-first manner. This example is not a strict prescription or any kind of "one true way" of test-driving such implementation - some things could've been done differently. For example, there were many situations where I got several TODO items pointed by my compiler or my false Statement. Depending on many factors, I might've approached them in a different order. For example, in the second behavior, I could've defined `data` as `Any.Array<byte>()` right from the start (and left a TODO item to check on it later and confirm whether it can stay this way) to get the Statement to compiling state quicker.

Another interesting point was the moment when I discovered the `Channel` interface -- I'm aware that I slipped over it by saying something like "we can see that the class has too many purposes, then magic happens and then we've got an interface to delegate parts of the logic to". This "magic happens" part is often called "interface discovery" and we will dig a little deeper into it in the next chapter.

You might've noticed that this chapter was longer than the last one, which may lead you to a conclusion that TDD complicates things rather than simplifying them. There were, however, several factors that made this chapter longer:

1. In this chapter, we specified two behaviors (a "happy path" plus error handling), whereas in the last chapter we only specified one (the "happy path").
1. In this chapter, we designed and implemented the `DataDispatch` class and discovered the `Channel` interface whereas in the last chapter they were given to us right from the start.
1. Because I assume the test-first way of writing Statements may be less familiar to you, I took my time to explain it in more detail.

So don't worry -- when one gets used to it, the process I described typically takes several minutes at worst.

[^nextchapterdiscovery]: more on this in further chapters.

[^idonotthrow]: that's why typically I don't specify that something should rethrow an exception -- I do it this time because otherwise it would not let me specify how `DataDispatch` uses a `Channel`.

[^idiomatictryfinally]: of course, the idiomatic way to do it in C# would be to use the `IDisposable` interface and a `using` block.