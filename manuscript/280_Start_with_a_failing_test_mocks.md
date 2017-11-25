# Test-first using mock objects



todo revise how to start with a failing test

remind of the three/four ways.

show how each of them works with a mock object (rethink starting from assertions). Use the behaviors from last chapter

examine the way Steve Freeman and Nat Pryce described in mock roles not objects

explain that interface discovery and outside-in will be in the next chapter (probably featuring Johnny and Benjamin).

## Responsibility and Responsibility

Explain that this chapter will use both meanings of the word responsibility and that Rebecca's responsibility wil be renamed to obligation. (btw, what about the previous chapter - does it need something like that?)

## Start by invoking a method if you have one

This is the basic tool.

Imagine we are in this situation, where we have the `DataDispatch` class, but its implementation is empty - after all, this is what we are going to test-drive. 

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

As we know what class we specify, plus it only has a single method, we may as well write a Statement where we create an object and invoke this method:

```csharp
[Fact] public void
ShouldXXXXXXXXXYYY() //TODO give a better name
{
 //GIVEN
 var dispatch = new DataDispatch();

 //WHEN
 dispatch.ApplyTo(); //doesn't compile

 //THEN
 Assert.True(false); //TODO state expectations
}
```

Note several things:

1. I'm currently using a dummy name and added a TODO item to my list to correct it later, when I define the responsibility of `DataDispatch`.
1. The `ApplyTo()` method takes an argument, but I didn't provide any. For now, I don't want to think too hard, I just want to brain-dump everything I know.
1. the `//THEN` section is empty for now. I will define it once I figure out what is the responsibility of this class.
1. If you remember the `Channel` interface from the last chapter, well, it doesn't exist yet. I will discover it later.

So I have my brain dump. What do I do? First, I reach for the feedback to my compiler - maybe it can give me some hints on what I am missing?

Currently, the compiler complains that I send the `ApplyTo` message without any argument. What's the name of the argument? `data`. Thus, let's pass some data. I don't want to decide what it is yet, so I will asume I have a variable called data and just write its name where the argument is expected:

```csharp
[Fact] public void
ShouldXXXXXXXXXYYY() //TODO give a better name
{
 //GIVEN
 var dispatch = new DataDispatch();

 //WHEN
 dispatch.ApplyTo(data); //still doesn't compile

 //THEN
 Assert.True(false); //TODO state expectations
}
```

The compiler gives me more feedback - it says my `data` variable is not defined anywhere. It might sound funny, but this way I progressed one step further. Now I know I need to define this data. I can use the "quick fix" capability of my IDE to introduce a variable. E.g. in Jetbrains IDEs (IntelliJ IDEA, Resharper, Rider...) this can be done by pressing `ALT` `+` `ENTER` when the cusros is on the name of the variable. The IDE will create the following declaration:

```csharp
byte[] data;
```

Note that the IDE guessed the type of the variable for us. How did it know? Because the definition of the method already has the type declared.

Of course, this will still not compile because C# requires variables to be explicitly initialized. Now is the time to turn on thinking and decide what exactly is the obligation of the `ApplyTo()` method. We decide that it should send the data, but can it do it alone? There are at least two things associated with sending the data:

1. The raw sending logic (i.e. laying our data, pushing it e.g. through the web socket etc.)
1. Keeping the integrity of the connection (i.e. disposing of all allocated resources, even in the face of an exception during the sending).

Putting it all in a single class would violate the Single Responsibility Principle. Thus we decide to delegate the first of the mentioned responsibilities to a collaborator that will be used by the `DataDispatch`. We name this collaborator role `Channel`. What we just did is called interface discover and usually it involves much more thinking, but I'll cover this in the next chapter.

Let's connect this new collaborator to the `DataDispatch`. A `Channel` will receive messages from `DataDispatch` and `DataDispatch` will not work without a `Channel`, so we pass the channel to the constructor of `DataDispatch`. Thus, the following code:

```csharp
//GIVEN
var dispatch = new DataDispatch();
```

becomes

```csharp
//GIVEN
var dispatch = new DataDispatch(channel);
```

Of course, it won't compile, because the `channel` doesn't exist yet. Again, let's use our IDE to generate this variable. This time, however, the variable will be generated like this:

```csharp
Object channel;
```

This is because we haven't created the `Channel` type yet and `DataDispatch` doesn't really take a constructor argument yet. These are the items we need to follow up on. First, let's introduce the `Channel` interface by changing `Object channel;` into `Channel channel;`. This will give us a compiler error, as the `Channel` does not yet exist. Thankfully, it's just one IDE click (e.g. in Resharper, I place my cursor at the non-existent type, press `ALT` `+` `ENTER` and pick an option to create such type.). After this step, we should have something like:

```csharp
public interface Channel
{

}
```

which is enough to pass this compiler error, but then we've got another one - nothing is assigned to the `channel` variable. `Channel` is a role and, as mentioned in the last chapter, we use mocks to play the roles of our collaborators. This makes the following code:

```csharp
Channel channel;
```

look like this:

```csharp
var channel = Substitute.For<Channel>();
```

The full code of our Statement is:

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

For now, our compiler and TODO list point that we still have three things to do: define data, name our Statement and state our expectations. Let's take the last task. As mentioned, the purpose of `DataDispatch` is to manage the channel state. If so, then the one expecting messages is the `channel`. As you remember from the last chapter, there are two behaviors of `DataDispatch` associated with managing this state - a happy path and the one where we get an exception. As we want to specify only one behavior in each Statement, we take the happy path. This, by the way, will allow us to give the Statement a good name, but remember, we don't want to be distracted from our current task and the task to give our Statement a name is on our TODO list so we don't worry about that. Another thing we don't want to worry about is that we have one more behavior to specify, so we add it to the TODO list as well:

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

Time to think about how much does the `DataDispatch` need to know about the data. As its responsibility is to manage connection, validation does not fit without breaking the single-purposeness, so we decide that `DataDispatch` will work with any data and someone needs to be responsible for ensuring valid data. We put that on the `Channel` as it depends on the actual implementation of sending what data can be sent and what cannot. Thus, we will define the `data` variable in our Statement as `Any.Array<byte>()`:

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

The code now compiles, so what we need is to give this Statement a better name.

TODO why a mock? because real channel does not exist and context independence.??

TODO what next - we can specify/implement Channel.

TODO deciding what we start from is about deciding what can give us the best feedback.

TODO I often write everything and then generate code.

So, the responsibility that's left in the `DataDispatch` class is to manage the connection. Thus, it is going to open the channel, send the data and then close the channel, even in case of sending errors.