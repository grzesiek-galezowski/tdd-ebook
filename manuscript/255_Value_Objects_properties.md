# Properties of value objects

TODO add some introduction
TODO mention in previous chapter that values do not play roles


TODO remove this:
Let's get back to the list of four possible changes I mentioned (just to remind you, these were: ignoring case, comparing by ID as well as by string name and getting uppercase version for printing on invoice) see how creating a value object makes it easier to introduce these changes.

First, let's take a look at the definition of the type to see how it looks like before answering how it solves our problems. The following code is not legal C# - I omitted method bodies, putting `;` after each method declaration. I did this because it would be a lot of code to grasp and we don't necessary want to delve into code of each method. I added a comment to each section of the code and we'll explain them one by one later.

```csharp
public class ProductName 
  : IEquatable<ProductName>
{
  // Hidden data:
  private string _value;

  // Constructor - hidden as well:
  private ProductName(string value);
  
  // Static method for creating new instances:
  public static ProductName For(string value);
  
  // Standard version of ToString():
  public void ToString();
  
  // Non-standard version of ToString()
  // I will explain its purpose later
  public string ToString(Format format);

  // For value types, we need to implement all the equality
  // methods and operators, plus GetHashCode():     
  public override bool Equals(Object other);
  public bool Equals(ProductName other);
  public override int GetHashCode();
  public static bool operator ==(ProductName a, ProductName b);
  public static bool operator !=(ProductName a, ProductName b);
}
```

As you see, the class can be divided into six sections. Let's take them on one by one.

## Hidden data

```csharp
private string _value;
```

The actual data, as I already said, is private to hide it from illegal modification. Only the methods we publish can be used to operate on the state. This is used for three things:

1. To restrict legal operations to the set that makes sense for a product name abstraction. 
1. To achieve immutability (more on why we want the type to be immutable later). If the data was public, everyone could modify the state of `ProductName` instance by writing this:
  ```csharp
  productName.data = "something different"; 
  ```
1. Both of the thing described above help protect against creating a product name with an invalid value. When creating a product name from a string, we have to pass this string through a method that can perform the validation.

## Hidden constructor

Note that the constructor is made private:

```csharp
private ProductName(string value)
{
  _value = value;
}
```

and you probably wonder why. This question can be further decomposed to two others: 

1. What should we create new instances?
1. Why private and not public?

Let's answer them one by one.

### How should we create new instances?

The `ProductName` class contains special static factory method[^factorymethods], called `WithValue()`. If we look at the body of th method, we'll see that it invokes a constructor and handles all input parameter validations[^isnullorempty]:

```
public static ProductName WithValue(string value)
{
  if(string.IsNullOrWhiteSpace(value))
  {
    //validation failed
    throw new ArgumentException(
      "Product names must be human readable!");
  }
  else
  {
    //here we call the constructor
    return new ProductName(value);
  }
}
```

There are several purposes of not exposing a constructor directly, but instead use this kind of method.

#### Explaining intention

Just like factories, static factory methods help explain intention, because, unlike constructors, they have names. One can argue that the following:
   
 ```csharp
 ProductName.WithValue("super laptop X112")
 ```
   
 is not that more readable than:
      
 ```csharp
 new ProductName("super laptop X112");
 ```
   
 but note that in our example, we have a single, simple factory method. The game changes when we need to support an additional way of creating a product name. Let's assume that in above example of "super laptop X112", the "super laptop" is a model and "X112" is a specific configuration (since the same models are often sold in several different configurations, with more or less RAM, different operating systems etc.) and we find it comfortable to pass these two pieces of information as separate arguments in some places (e.g. because we obtain the from different sources) and let the `ProductName` combine them. If we used a constructor for that, we would write:
   
 ```csharp
 // assume model is "super laptop"
 // and configuration is "X112"
 new ProductName(model, configuration)
 ```
   
 On the other hand, we can craft a factory method and say:

 ```csharp
 ProductName.CombinedOf(model, configuration)
 ```   
   
 which reads more fluent. Or, if we like to be super explicit (which is not my favourite way of writing code, but I want to show you that we can do this), we can write:
   
 ```csharp
 ProductName.FromModelAndConfig(model, configuration)
 ```

Some developers are not used to using factory methods, but the good news is that they are getting more and more mainstream. Just to give you two examples, `TimeSpan` type in C# uses them (e.g. we can write `TimeSpan.FromSeconds(12)` and `Period` type in Java (e.g. `Period.ofNanos(2222)`). 

#### Ensuring initialization

When there is a single constructor, using static factory methods ensures it is called. When we create an instance and there is only one constructor, we have to call it. Why is this important? In languages like C#, it helps avoiding uninitialized fields problem. For example, when we have two constructors, they can delegate to each other:
  
```csharp
public ProductName(string value)
{ 
  _value = value;
}
  
public ProductName(string model, string onfiguration)
 : this(model + " " + configuration) //delegation to other constructor
{
}
```

ensuring the field initialization is done in a single place, but there is literally nothing forcing us to do this. We can as well write something like this:
  
```csharp
public ProductName(string value)
{ 
  _value = value;
}
  
public ProductName(string model, string onfiguration)
 //oops, no delegation to other constructor
{
}
```
  
and the compiler will accept it. On the other hand, if the second constructor was a static factory method, we would not be able to bypass calling the constructor inside it:
  
```csharp
public ProductName CombinedOf(string model, string configuration)
{
  // no way to bypass the constructor here,
  // and to avoid initializing the _value field
  return new ProductName(model + " " + configuration);
}
```

By the way, there are some validations missing here as well, but let's skip them for now. And sure, the example of product names is super-simple and we are unlikely to make such a mistake, however:

1. There are more complex cases when we can indeed forget to initialize some fields in multiple constructors. 
2. It is always better to be protected by the compiler than not when the price for the protection is considerably low.

#### Better place for input validation

The `WithValue()` factory method contained input validation, and the constructor did not.Is it a wise decision to move the validation to such a method and leave constructor for just filling fields? The answer to this questions depends on an answer to another one: are there cases where we do not want to validate constructor arguments?

Acually, yes, there are. Consider the following case: we want to create bundles of two product names as one. For this purpose, we introduce a new method on `ProductName`, called `BundleWith()`, which takes another product name:

```csharp
public ProductName BundleWith(ProductName other)
{
  return new ProductName(
    "Bundle: " + _value + other._value);
}
```

Note that we are calling the constructor directly, instead of passing it through method that contains validations. We do that, because we know that:

1. the string will be neither null nor empty, since we are creating a literal string here
2. `_value` fields of both `this` and the `other` product name components must be valid, because if they were not, thease two product names would fail to be created in the first place.

Another example is the method we already saw for combining the model and configuration into a product name. If we look at it again:

```csharp
public ProductName CombinedOf(string model, string configuration)
{
  return ProductName.WithValue(model + " " + configuration);
}
```

We will note that this method needs different validations, because probably both model and configuration need to be validated separately (by the way, maybe a good idea would be to create value objects for those as well - it depends on where we get them and how we use them).

Oh, and when we want to reuse the validations, remember that one factory method is free to call another, so we can reuse them!

That's about it as far as factory methods go. Remember we asked three questions and I have answered just one of them. Thankfully, the remaining two are easy to answer now.

### Why private and not public?

There are two reasons: validation and separating use from construction:

#### Validations

Well, remember the constructor of `ProductName` does not validate its input. This is OK when the constructor is used internally inside `ProductName` (as I just demonstrated in the previous section), because this is the code we can trust. On the other hand, for all the code we do not trust, we want it to use the "safe" methods that validate input and raise errors. After all, this is what we made those methods for, isn't it?

#### Separating use from construction[^essentialskills]

I already mentioned that we do not want to use polymorphism for values, as they do not play any roles that other objects can fill. Even though, we still want to reserve some degree of flexibility to be able to change our decision easily. When we have a static method like this:

```
public static ProductName WithValue(string value)
{
  //validations skipped for brevity
  return new ProductName(value);
}
```

and all code depends on it instead of constructor, we can make the `ProductName` abstract at some point and return some subclasses depending on some factors. This change would impact just this static method, as the constructor is hidden. Again, this is something I don't recommend doing by default, unless there is a very strong reason.

## String conversion methods

There is not much to say about `ToString()`, but the overload (the `ToString(Format format)`) method is more interesting. Its purpose is to  be able to format the product name differently for different outputs, e.g. reports and on-screen printing. True, we could introduce a special method for each of the cases (e.g. `ToStringForScreen()` and `ToStringForReport()`), but that could make the `ProductName` know too much about how it is used and each possible output would need a new method. Instead, the `ToString()` accepting a `Format` (which is an interface,  by the way) ensures flexibility.

When we need to print the product name on screen, we can say:

```csharp
var name = productName.ToString(screenFormat);
```

and for reports, we can say:

```csharp
var name = productName.ToString(reportingFormat);
```

Of course, nothing forces us to call this method `ToString()` - we can use our own name if we want to.

## Equality members

For values such as `ProductName`, we need to implement all equality operations plus `GetHashCode()`. The purpose of equality operations should be obvious - this is what gives product names value semantics and allow the following operations:

```csharp
ProductName.WithValue("a").Equals(ProductName.WithValue("a"));
ProductName.WithValue("a") == ProductName.WithValue("a");
```

both return `true`. In Java, of course, we are not able to override equality operators - they always compare references, but Java programmers are so used to this, that it usually isn't a problem.

One thing to note about the implementation of `ProductName` is that it implements `IEquatable<ProductName>` interface, which in C# is considered a good practice. I won't go into the details here, but you can always look it up in the documentation.

`GetHashCode()` needs to be overridden as well. In short, all objects that are considered equal should return the same hash code and all objects considered not equal should return different hash codes. This is because hash codes are used to determine equality in hash tables or hash sets - these data structures won't work properly with values if `GetHashCode()` is not properly implemented. That would be too bad, because values are often used as keys in various hash-based dictionaries.

## How product names are better against the changes?

There are some more aspects of values that are not visible on the `ProductName` example, but before I delve into them, I would like to remind you that I introduced a value object to limit impact of some changes that could occur to codebase dealing with product names. As it's been a long time, let me remind you the changes we wanted to have the most limited impact:

1. We wanted to change the comparison of product names to case-insensitive
2. We wanted the comparison to take into account not only a product name, but also a configuration.

### First change - case-insensitivity

This is actually very easy to perform - we just have to modify the equality operators, `Equals()` and `GetHashCode()` operations, so that they return true for an additional case when product names are the same, just printed in different letter case. I won't go over the code now as it's not too interesting, I hope you imagine how that implementation would look like.

Thanks to this, no change outside the `ProductName` class is necessary. Several methods need to be modified, but in just one place, which means that the encapsulation we've introduced works out pretty well.

### Second change - additional identifier

This change is more complicated, but having a value object will help us bevertheless. In order to perform the change, we'll have to modify the creation of `ProductName` class to take an additional parameter:

```csharp
private ProductName(string value, string config)
{
  _value = value;
  _config = config;
}
```

Then, we have to add additional validations to the factory method:

```csharp
public static ProductName CombinedOf(string value, string config)
{
  if(string.IsNullOrWhiteSpace(value))
  {
    throw new ArgumentException(
          "Product names must be human readable!");
  }
  else if(string.IsNullOrWhiteSpace(config))
  {
    throw new ArgumentException(
          "Configs must be human readable!");
  }
  else
  {
    return new ProductName(value, config);
  }
}
```

Note that this modification requires changes all over the code base (because additional argument is needed to create an object), however, this is not the kind of change that we're afraid of. That's because the compiler will create a nice little TODO list (i.e. compile errors) for us and won't let us go further without addressing it first, so there's no chance the Shalloway's Law (TODO did I write about it?) might come to effect. Thus, we're pretty much safe. By the way, if the requirements change in the future so that we will have to support product names without an ID, this is the only place we'll need to change.

In addition, equality operators, `Equals()` and `GetHashCode()` will have to be changed again, to compare instances not only by name, but also by configuration. And again, I will leave the code of those methods as an exercise to you.  Note that this modification won't require any changes to the code outside `ProductName` class.

## Summary

The two chapters talked about value objects on a specific example. The next one will delve into some more general concepts. Don't worry, it will be short ;-).

[^addreference]: TODO add reference

[^csharpoperatorsoverride]: and, for C#, overriding equality operators is probably a good idea, not to mention `GetHashCode()`

[^factorymethods]: TODO explain factory methods

[^isnullorempty]: by the way, the code contains a call to `IsNullOrEmpty()`. There are several valid arguments against using this method, e.g. by Mark Seemann (TODO check surname) (TODO add link), but in this case, I put it in to make the code shorter as the validation logic itself is not that important at the moment. 

[^essentialskills]: TODO fill in the reference

TODO shalloway's law - wasn't it already mentioned?
