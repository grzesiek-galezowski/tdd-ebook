# Test-driving value object

In this stage, we skip further ahead in time. Johnny and Benjamin just extracted a value object type for a train ID and will work further to specify it.

## Initial value object

Johnny: Oh, you're back. The refactoring is over -- we've got a nice value object type extracted from the current code. Here's the source code of the `TrainId` class:

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

Benjamin: Wait, but we don't have any Specification for this class yet. Where did all of this implementation come from?

Johnny: That's because while you were drinking your tea, I extracted this type from an existing implementation that was already a response to false Statements.

Benjamin: I see. So we didn't mock this class in other Statements, right?

Johnny: No. This is a general rule -- we don't mock value objects. They don't represent abstract, polymorphic behaviors. For the same reasons we don't create an interface and mocks for `string` or `int`, we don't do that for `TrainId`.

Benjamin: So is there anything for us left to write?



```csharp
Assert.HasValueSemantics<TrainId>();
```

Other libraries - mutability detector and equalsverifier

Messages:

```txt
TrainId must be sealed, or derivatives will be able to override GetHashCode() with mutable code
a.GetHashCode() and b.GetHashCode() should return same values when both are created with same arguments
a.Equals(null) should return false, but instead threw System.NullReferenceException: Object reference not set to an instance of an object.
```

TODO value library (Value)
 
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
