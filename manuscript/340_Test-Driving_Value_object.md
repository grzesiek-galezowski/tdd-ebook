# Test-driving value object

## Initial value object

Driven by design principles, already covered by an existing test, because we don't mock value objects.


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

TODO assertion library

```csharp
Assert.HasValueSemantics<TrainId>();
```

Other libraries - mutability detector and equalsverifier

Messages:

```
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