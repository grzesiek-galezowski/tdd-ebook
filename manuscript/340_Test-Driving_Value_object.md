# Test-driving value object

In this stage, we skip further ahead in time. Johnny and Benjamin just extracted a value object type for a train ID and will work further to specify it.

## Initial value object

**Johnny**: Oh, you're back. The refactoring is over -- we've got a nice value object type extracted from the current code. Here's the source code of the `TrainId` class:

```csharp
public class TrainId
{
 private readonly string _value;

 public static TrainId From(string trainIdAsString)
 {
  return new TrainId(trainIdAsString);
 }

 private TrainId(string value)
 {
  _value = value;
 }
 
 public override bool Equals(object obj)
 {
  return _value == ((TrainId) obj)._value;
 }

 public override string ToString()
 {
  return _value;
 }
}
```

**Benjamin**: Wait, but we don't have any Specification for this class yet. Where did all of this implementation come from?

**Johnny**: That's because while you were drinking your tea, I extracted this type from an existing implementation that was already a response to false Statements.

**Benjamin**: I see. So we didn't mock this class in other Statements, right?

**Johnny**: No. This is a general rule -- we don't mock value objects. They don't represent abstract, polymorphic behaviors. For the same reasons we don't create an interface and mocks for `string` or `int`, we don't do that for `TrainId`.

**Benjamin**: So is there anything for us left to write?

**Johnny**: Yes. I decided that this `TrainId` should be a value object and my design principles for value objects demand it to hold some more guarantees than results from a mere refactoring. Also, don't forget that the comparison of train ids needs to be case insensitive. This is something we've not specified anywhere.

**Benjamin**: You mentioned "more guarantees". Do you mean equality?

**Johnny**: Yes, C# as a language expects equality to follow certain rules. I want this object to implement them. Also, I want to implement `GetHashCode` properly and make sure instances of this class are immutable.

**Benjamin**: Sounds like a lot of Statements to write.

**Johnny**: Not really. Look -- I downloaded a library that checks all of that for me. This way, all I need to write is:

```csharp
[Fact] public void
ShouldHaveValueSemantics()
{
 Assert.HasValueSemantics<TrainId>();
}
```

After evaluating this Statement, I get the following output:

```txt
- TrainId must be sealed, or derivatives will be able to override GetHashCode() with mutable code.
- a.GetHashCode() and b.GetHashCode() should return same values when both are created with same arguments.
- a.Equals(null) should return false, but instead threw System.NullReferenceException: Object reference not set to an instance of an object.
- '==' and '!=' operators are not implemented
```

**Benjamin**: Very clever. So these are the rules that our `TrainId` doesn't follow yet. Are you going to implement them one by one?

**Johnny**: Hehe, no. The implementation would be so schematic (TODOOOOOO) that I'd either use my IDE to generate the necessary implementation of use a library. Lately, I prefer the latter. So let me just download a library called [Value](https://www.nuget.org/packages/Value/) and use it on our `TrainId`.

First off, the `TrainId` needs to inherit from `ValueType` generic class like this:

```csharp
public class TrainId : ValueType<TrainId>
```

This ingeritance requires us to implement the following method:

```csharp
protected override IEnumerable<object> GetAllAttributesToBeUsedForEquality
{
 throw new NotImplementedException();
}
```

**Benjamin**: Weird, what does that do?

**Johnny**: It's how the library automates equality implementation. We just need to return an array of values we want to be compared between two instances. As our equality is based solely on the `_value` field, we need to return just that:

```csharp
protected override IEnumerable<object> GetAllAttributesToBeUsedForEquality
{
 yield return _value;
}
```

We also need to remove the existing Equals() method.

**Benjamin**: Great, now the only reason for the assertion to fail is:

```txt
- TrainId must be sealed, or derivatives will be able to override GetHashCode() with mutable code.
```

I am impressed that the library took care of the equality methods, equality operators and `GetHashCode()`.

Other libraries - mutability detector and equalsverifier

TODO value library (Value)
TODO sealed
 
```csharp
public sealed class TrainId : ValueType<TrainId>
{
 private readonly string _value;

 public static TrainId From(string trainIdAsString)
 {
  return new TrainId(trainIdAsString);
 }

 private TrainId(string value)
 {
  _value = value;
 }

 protected override IEnumerable<object> GetAllAttributesToBeUsedForEquality
 {
  yield return _value;
 }

 public override string ToString()
 {
  return _value;
 }
}
```

TODO lowercase test

Before:

```csharp
protected override IEnumerable<object> GetAllAttributesToBeUsedForEquality
{
 yield return _value;
}
```

After:

```csharp
protected override IEnumerable<object> GetAllAttributesToBeUsedForEquality
{
 yield return _value;
}
```

TODO validations

Before:

```csharp
public static TrainId From(string trainIdAsString)
{
 return new TrainId(trainIdAsString);
}
```

After:

```csharp
public static TrainId From(string trainIdAsString)
{
 if(trainIdAsString == null)
 {
  throw new ArgumentNullException(nameof(trainIdAsString));
 }
 return new TrainId(trainIdAsString);
}
```

Do we specify the `ToString()`? Not necessarily... There is already a Statement that will turn false.






Driven by design principles, already covered by an existing test, because we don't mock value objects.
