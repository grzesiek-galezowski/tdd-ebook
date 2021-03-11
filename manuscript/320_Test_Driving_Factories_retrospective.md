# Test-driving object creation -- a retrospective

In the last chapter, Johnny and Benjamin specified behavior of a factory, by writing a Specification Statement about object creation. This chapter will hopefully answer some questions you may have about what they did and what you should be doing in similar situations.

## Limits of creation specification

Object creation might mean different things, but in the style of design I am describing, it is mostly about creating abstractions. These abstractions usually encapsulate a lot, exposing only narrow interfaces. An example might be the `ReservationCommand` from our train reservation system -- it contains a single method called `Execute()`, that returns nothing. The only thing Johnny and Benjamin could specify about the created command in the Statement was its concrete type. They could not enforce the factory method arguments being passed into the created instance, so their implementation just left that away. Still, at some point they would need to pass the correct arguments or else the whole logic would not work.

To enforce the Statement to be false when correct parameters are not passed, they could try using techniques like reflection to inspect the created object graph and verify whether it contains the right objects, but that would soon turn the specification into a fragile mirror of the production code. The object composition is a mostly declarative definition of behavior, much the same as HTML is a declarative description of a GUI. We should specify behavior rather than the structure of what makes the behavior possible.

So how do we know whether the command was created exactly as we intended? Can we specify this at all?

I mentioned that the object composition is meant to provide some kind of higher-level behavior -- one resulting from how the objects are composed. The higher-level Statements can describe that behavior. For example, when we specify the behavior of the whole component, These Statements will indirectly force us to get the object composition right -- both in our factories and at the composition root level.

For now, I'll leave it at that, and I'll go over higher-level Specification in the further parts of the book.

## Why specify object creation?

So if we rely on the higher-level Specification to enforce the correct object composition, why do we write a unit-level Specification for object creation? The main reason is: progress. Looking back at the Statement Johnny and Benjamin wrote -- it forced them to create a class implementing the `ReservationCommand` interface. This class then needed to implement the interface method in a way that would satisfy the compiler. Just to remind you, it ended up like this:

```csharp
public class NewReservationCommand : ReservationCommand
{
 public void Execute()
 {
  throw new NotImplementedException();
 } 
}
```

This way, they got a new class to test-drive, and the `NotImplementedException` that appeared in the generated `Execute` method, landed on their TODO list. As their next step, they could pick this TODO item and begin working on it. 

So as you can see, a Statement specifying the factory's behavior, although not perfect as a test, allowed continuing the flow of TDD.

## What do we specify in the creational Statements?

Johnny and Benjamin specified what should be the type of the created object. Indirectly, they also specified that the created object should not be a null. Is there anything else we might want to include in a creational specification?

### Choice

Sometimes, factories make a decision on what kind of object to return. In such cases, we might want to specify the different choices that the factory can make. For example if a factory looks like this:

```csharp
public class SomeKindOfFactory
{
 public Command CreateFrom(string commandName)
 {
  if(commandName == "command1")
  {
   return new Command1();
  }
  if(commandName == "command2")
  {
   return new Command2();
  }
  else
  {
   throw new InvalidCommandException(commandName);
  }
 }
}
```

then we would need three Statements to specify its behavior: 

1. For the scenario where an instance of `Command1` is returned.
1. For the scenario where an instance of `Command2` is returned.
1. For the scenario where an exception is thrown.

### Collection content

Likewise, if our factory needs to return a collection - we need to state what we expect it to contain. Consider the following Statement about a factory that needs to create a sequence of processing steps:

```csharp
[Fact] public void
ShouldCreateProcessingStepsInTheRightOrder()
{
 //GIVEN
 var factory = new ProcessingStepsFactory();
 
 //WHEN
 var steps = factory.CreateStepsForNewItemRequest();

 //THEN
 Assert.Equal(3, steps.Count);
 Assert.IsType<ValidationStep>(steps[0]);
 Assert.IsType<ExecutionStep>(steps[1]);
 Assert.IsType<ReportingStep>(steps[2]);
}
```

It says that the created collection should contain three items in a specific order and states the expected types of those items.

Last but not least, sometimes we specify the creation of value objects

## Value object creation

Value objects are typically created using factory methods. Depending on whether the constructor of a such value object is public or not, we can accommodate these factory methods differently in our Specification.

### Value object with a public constructor

When a public constructor is available, we can state the expected equality of an object created using a factory method to another object created using the constructor:

```csharp
[Fact] public void
ShouldBeEqualToIdWithGroupType()
{
 //GIVEN
 var groupName = Any.String();
 
 //WHEN
 var id = EntityId.ForGroup(groupName);
 
 //THEN
 Assert.Equal(new EntityId(groupName, EntityTypes.Group), id);
}
```

### Value object with a non-public constructor

When factory methods are the only means of creating value objects, we just use these methods in our Statements and either state the expected data or expected behaviors. For example, the following Statement says that an absolute directory path should become an absolute file path after appending a file name:

```csharp
[Fact]
public void ShouldBecomeAnAbsoluteFilePathAfterAppendingFileName()
{
 //GIVEN
 var dirPath = AbsoluteDirectoryPath.Value("C:\\");
 var fileName = FileName.Value("file.txt");
 
 //WHEN
 AbsoluteFilePath absoluteFilePath = dirPath.Append(fileName);

 //THEN
 Assert.Equal(
     AbsoluteDirectoryPath.Value("C:\\file.txt"), 
     absoluteFilePath);
}
```

Note that the Statement creates the values using their respective factory methods. This is inevitable as these methods are the only way the objects can be created.

### Validation

The factory methods for value objects may have some additional behavior like validation -- we need to specify it as well. For example, the Statement below says that an exception should be thrown when I try to create an absolute file path from a null string:

```csharp
[Fact]
public void ShouldNotAllowToBeCreatedWithNullValue()
{
 Assert.Throws<ArgumentNullException>(() => AbsoluteFilePath.Value(null));
}
```

## Summary

That was a quick ride through writing creational Statements. Though not thorough as tests, they create needs to new abstractions, allowing us to continue the TDD process. When we start our TDD process from higher-level Statements, we can defer specifying factories and sometimes even avoid it altogether.