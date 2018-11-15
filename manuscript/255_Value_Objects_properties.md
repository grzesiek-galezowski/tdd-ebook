# Value object anatomy

In the previous chapter, we saw a value object - `ProductName` in action. In this chapter, we'll  study its anatomy - line by line, field by field, method after method. After doing this, you'll hopefully have a better feel of some of the more general properties of value objects.

Let's begin our examination by taking a look at the definition of the type `ProductName` from the previous chapter (the code I will show you is not legal C# - I omitted method bodies, putting `;` after each method declaration. I did this because it would be a lot of code to grasp otherwise and I don't necessary want to delve into the code of each method). Each section of the `ProductName` class definition is marked with a comment. These comments mark the topics we'll be discussing throughout this chapter.

So here is the promised definition of `ProductName`:

```csharp
//This is the class we created and used
//in the previous chapter

// class signature
public sealed class ProductName
  : IEquatable<ProductName>
{
  // Hidden data:
  private string _value;

  // Constructor - hidden as well:
  private ProductName(string value);
  
  // Static method for creating new instances:
  public static ProductName For(string value);
  
  // Overridden version of ToString()
  // from Object class
  public override string ToString();
  
  // Non-standard version of ToString().
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

Using the comments, I divided the class into sections and will describe them in order.

## Class signature

There are two things to note about the class signature. The first one is that the class is `sealed` (in Java that would be `final`), i.e. I disallow inheriting from it. This is because I want the ojects of this class to be immutable. On the first sight, sealing the class has nothing to do with immutability. I will explain it in the next chapter when I discuss the aspects of value object design.

The second thing to note is that the class implements an `IEquatable` interface that adds more strongly typed versions of the `Equals(T object)` method. This is not strictly required as in C#, every object has a default `Equals(Object o)` method, but is typically considered a good practice since it allows e.g. more efficient use of value objects with C# collections such as `Dictionary`[^whyuseequatable].

## Hidden data

The actual data is private:

```csharp
private string _value;
```

 Only the methods we publish can be used to operate on the state. This is useful for three things:

1. To restrict allowed operations to what we think makes sense to do with a product name. Everything else (i.e. what we think does not make sense to do) is not allowed. 
2. To achieve immutability of `ProductName` instances (more on why we want the type to be immutable later), which means that when we create an instance, we cannot modify it. If the `_value` field was public, everyone could modify the state of `ProductName` instance by writing something like:
  ```csharp
  productName.data = "something different";
  ```
3. To protect against creating a product name with an invalid state. When creating a product name, we have to pass a string with containing a name through a static `For()` method that can perform the validation (more on this later). If there are no other ways we can set the name, we can rest assured that the validation will happen every time someone wants to create a `ProductName`.

## Hidden constructor

Note that the constructor is made private as well:

```csharp
private ProductName(string value)
{
  _value = value;
}
```

and you probably wonder why. I'd like to decompose the question further into two others:

1. How should we create new instances then?
1. Why private and not public?

Let's answer them one by one.

### How should we create new instances?

The `ProductName` class contains a special static factory method, called `For()`. It invokes the constructor and handles all input parameter validations[^isnullorempty]. An example implementation could be:

```
public static ProductName For(string value)
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

There are several reasons for not exposing a constructor directly, but use a static factory method instead. Below, I briefly describe some of them. 

#### Explaining intention

Just like factories, static factory methods help explaining intention, because, unlike constructors, they can have names, while constructors have the constraint of being named after their class[^constructorsdynamic]. One can argue that the following:
   
 ```csharp
 ProductName.For("super laptop X112")
 ```
   
 is not that more readable than:
      
 ```csharp
 new ProductName("super laptop X112");
 ```
   
 but note that in our example, we have a single, simple factory method. The benefit would be more visible when we would need to support an additional way of creating a product name. Let's assume that in above example of "super laptop X112", the "super laptop" is a model and "X112" is a specific configuration (since the same laptop models are often sold in several different configurations, with more or less RAM, different operating systems etc.) and we find it comfortable to pass these two pieces of information as separate arguments in some places (e.g. because we may obtain them from different sources) and let the `ProductName` combine them. If we used a constructor for that, we would write:
   
 ```csharp
 // assume model is "super laptop"
 // and configuration is "X112"
 new ProductName(model, configuration)
 ```
   
 On the other hand, we can craft a factory method and say:

 ```csharp
 ProductName.CombinedOf(model, configuration)
 ```   
   
 which reads more fluently. Or, if we like to be super explicit:
   
 ```csharp
 ProductName.FromModelAndConfig(model, configuration)
 ```

 which is not my favourite way of writing code, because I don't like repeating the same information in method name and argument names. I wanted to show you that we can do this if we want though.

I met a lot developers that find using factory methods somehow unfamiliar, but the good news is that factory methods for value objects are getting more and more mainstream. Just to give you two examples, `TimeSpan` type in C# uses them (e.g. we can write `TimeSpan.FromSeconds(12)` and `Period` type in Java (e.g. `Period.ofNanos(2222)`). 

#### Ensuring consistent initialization of objects

In case where we have different ways of initializing an object that share a common part (i.e. whichever way we choose, part of the initialization must always be done the same), having several constructors that delegate to one common seems like a good idea. For example, we can have two constructors, one delegating to the other, that holds a common initialization logic:

```csharp
// common initialization logic
public ProductName(string value)
{
  _value = value;
}

//another constructor that uses the common initialization
public ProductName(string model, string configuration)
 : this(model + " " + configuration) //delegation to "common" constructor
{
}
```

Thanks to this, the field `_value` is initialized in a single place and we have no duplication.

The issue with this approach is this binding between constructors is not enforced - we can use it if we want, otherwise we can skip it. For example, we can as well use a totally separate set of fields in each constructor:

```csharp
public ProductName(string value)
{
  _value = value;
}

public ProductName(string model, string configuration)
 //oops, no delegation to the other constructor
{
}
```

which leaves room for mistakes - we might forget to initialize all the fields all the time and allow creating objects with invalid state.

I argue that using several static factory methods while leaving just a single constructor is safer in that it enforces every object creation to pass through this single constructor. This constructor can then ensure all fields of the object are properly initialized. There is no way in such case that we can bypass this constructor in any of the static factory methods, e.g.:

```csharp
public ProductName CombinedOf(string model, string configuration)
{
  // no way to bypass the constructor here,
  // and to avoid initializing the _value field
  return new ProductName(model + " " + configuration);
}
```

What I wrote above might seem an unnecessary complication as the example of product names is trivial and we are unlikely to make a mistake like the one I described above, however:

1. There are more complex cases when we can indeed forget to initialize some fields in multiple constructors.
1. It is always better to be protected by the compiler than not when the price for the protection is considerably low. At the very least, when something happens, we'll have one place less to search for bugs.

#### Better place for input validation

Let's look again at the `For()` factory method:

```
public static ProductName For(string value)
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

and note that it contains some input validation, while the constructor did not. Is it a wise decision to move the validation to such a method and leave constructor for just assigning fields? The answer to this questions depends on the answer to another one: are there cases where we do not want to validate constructor arguments? If no, then the validation should go to the constructor, as its purpose is to ensure an object is properly initialized.

Apparently, there are cases when we want to keep validations out of the constructor. Consider the following case: we want to create bundles of two product names as one. For this purpose, we introduce a new method on `ProductName`, called `BundleWith()`, which takes another product name:

```csharp
public ProductName BundleWith(ProductName other)
{
  return new ProductName(
    "Bundle: " + _value + other._value);
}
```

Note that the `BundleWith()` method doesn't contain any validations but instead just calls the constructor. It is safe to do so in this case, because we know that:

1. The string will be neither null nor empty, since we are appending values of both product names to the constant value of `"Bundle: "`. The result of such append operation will never give us an empty string or a `null`.
2. The `_value` fields of both `this` and the `other` product name components must be valid, because if they were not, the two product names that contain those values would fail to be created in the first place.

This was a case where we didn't need the validation because we were sure the input was valid. There may be another case - when it is more convenient for a static factory method to provide a validation on its own. Such validation may be more detailed and helpful as it is in a factory method made for specific case and knows more about what this case is. For example, let's look at  the method we already saw for combining the model and configuration into a product name. If we look at it again (it does not contain any validations yet):

```csharp
public ProductName CombinedOf(string model, string configuration)
{
  return ProductName.For(model + " " + configuration);
}
```

We may argue that this method would benefit from a specialized set of validations, because probably both model and configuration need to be validated separately (by the way, it sometimes may be a good idea to create value objects for model and configuration as well - it depends on where we get them and how we use them). We could then go as far as to throw a different exception for each case, e.g.:

```csharp
public ProductName CombinedOf(string model, string configuration)
{
  if(!IsValidModel(model))
  {
    throw new InvalidModelException(model);
  }
  
  if(!IsValidConfiguration(configuration))
  {
    throw new InvalidConfigurationException(configuration);
  }
  
  return ProductName.For(model + " " + configuration);
}
```

What if we need the default validation in some cases? We can still put them in a common factory method and invoke it from other factory methods. This looks a bit like going back to the problem with multiple constructors, but I'd argue that this issue is not as serious - in my mind, the problem of validations is easier to spot than mistakenly missing a field assignment as in the case of constructors. You may have different preferences though.

Remember we asked two questions and I have answered just one of them. Thankfully, the other one - why the constructor is private not public - is much easier to answer now. 

### Why private and not public?

My personal reasons for it are: validation and separating use from construction.

#### Validation

Looking at the constructor of `ProductName` - we already discussed that it does not validate its input. This is OK when the constructor is used internally inside `ProductName` (as I just demonstrated in the previous section), because it can only be called by the code we, as creators of `ProductName` class, can trust. On the other hand, there probably is a lot of code that will create instances of `ProductName`. Some of this code is not even written yet, most of it we don't know, so we cannot trust it. For such code, we want to use only the "safe" methods that validate input and raise errors, not the constructor.

#### Separating use from construction[^essentialskills]

I already mentioned that most of the time, we do not want to use polymorphism for values, as they do not play any roles that other objects can fill. Even though, I consider it wise to reserve some degree of flexibility to be able to change our decision more easily in the future, especially when the cost of the flexibility is very low. 

Static factory methods provide more flexibility when compared to constructors. For example, when we have a static factory method like this:

```csharp
public static ProductName For(string value)
{
  //validations skipped for brevity
  return new ProductName(value);
}
```

and all our code depends on it for creating product names rather than on the constructor, we are free to make the `ProductName` class abstract at some point and have the `For()` method return an instance of a subclass of `ProductName`. This change would impact just this static method, as the constructor is hidden and accessible only from inside the `ProductName` class. Again, this is something I don't recommend doing by default, unless there is a very strong reason. But if there is, the capability to do so is here.

## String conversion methods

The overridden version of `ToString()` usually returns the internally held value or its string representation. It can be used to interact with third party APIs or other code that does not know about our `ProductName` type. For example, if we want to save the product name inside the database, the database API has no idea about `ProductName`, but rather accepts library types such as strings, numbers etc. In such case, we can use `ToString()` to make passing the product name possible:

```csharp
// let's assume that we have a variable 
// productName of type ProductName.

var dataRecord = new DataRecord();
dataRecord["Product Name"] = productName.ToString();

//...

database.Save(dataRecord);
``` 

Things get more complicated when a value object has multiple fields or when it wraps another type like `DateTime` or an `int` - we may have to implement other accessor methods to obtain this data. `ToString()` can then be used for diagnostic purposes to allow printing user-friendly data dump.

Apart from the overridden `ToString()`, our `ProductName` type has an overload with signature `ToString(Format format)`. This version of `ToString()` is not inherited from any other class, so it's a method we made to fit our goals. The `ToString()` name is used only out of convenience, as the name is good enough to describe what the method does and it feels familiar. Its purpose is to  be able to format the product name differently for different outputs, e.g. reports and on-screen printing. True, we could introduce a special method for each of the cases (e.g. `ToStringForScreen()` and `ToStringForReport()`), but that could make the `ProductName` know too much about how it is used - we would have to extend the type with new methods every time we wanted to print it differently. Instead, the `ToString()` accepts a `Format` (which is an interface,  by the way) which gives us a bit more flexibility.

When we need to print the product name on screen, we can say:

```csharp
var name = productName.ToString(new ScreenFormat());
```

and for reports, we can say:

```csharp
var name = productName.ToString(new ReportingFormat());
```

Nothing forces us to call this method `ToString()` - we can use another name if we want to.

## Equality members

For values such as `ProductName`, we need to implement all equality operations plus `GetHashCode()`. The purpose of equality operations to give product names value semantics and allow the following expressions:

```csharp
ProductName.For("a").Equals(ProductName.For("a"));
ProductName.For("a") == ProductName.For("a");
```

to return `true`, since the state of the compared objects is the same despite them being separate instances in terms of references. In Java, of course, we can only override `equals()` method - we are unable to override equality operators as their behavior is fixed to comparing references (with the exception of primitive types), but Java programmers are so used to this, that it's rarely a problem.

One thing to note about the implementation of `ProductName` is that it implements `IEquatable<ProductName>` interface. In C#, overriding this interface when we want to have value semantics is considered a good practice. The `IEquatable<T>` interface is what forces us to create a strongly typed `Equals()` method:

```csharp
public bool Equals(ProductName other);
```

while the one inherited from `object` accepts an `object` as a parameter. The use and existence of `IEquatable<T>` interface is mostly C#-specific, so I won't go into the details here, but you can always [look it up in the documentation](https://msdn.microsoft.com/en-us/library/ms131187.aspx). 

When we override `Equals()`, the `GetHashCode()` method needs to be overridden as well. The rule is that all objects that are considered equal should return the same hash code and all objects considered not equal should return different hash codes. The reason is that hash codes are used to intentify objects in hash tables or hash sets - these data structures won't work properly with values if `GetHashCode()` is not properly implemented. That would be too bad, because values are often used as keys in various hash-based dictionaries.

## The return of investment

There are some more aspects of values that are not visible on the `ProductName` example, but before I explain them in the next chapter, I'd like to consider one more thing.

Looking into the `ProductName` anatomy, it may seem like it's a lot of code just to wrap a single string. Is it worth it? Where is the return of investment?

To answer that, I'd like to get back to our original problem with product names and remind you that I introduced a value object to limit the impact of some changes that could occur to the codebase where product names are used. As it's been a long time, here are the changes that we wanted to impact our code as little as possible:

1. Changing the comparison of product names to case-insensitive
2. Changing the comparison to take into account not only a product name, but also a configuration in which a product is sold.

Let's find out whether introducing a value object would pay off in these cases.

### First change - case-insensitivity

This one is easy to perform - we just have to modify the equality operators, `Equals()` and `GetHashCode()` operations, so that they treat names with the same content in different letter case equal. I won't go over the code now as it's not too interesting, I hope you imagine how that implementation would look like. We would need to change all comparisons between strings to use an option to ignore case, e.g. `OrdinalIgnoreCase`. This would need to happen only inside the `ProductName` class as it's the only one that knows how what it means for two product names to be equal. This means that the encapsulation we've introduced with out `ProductName` class has paid off.

### Second change - additional identifier

This change is more complex, but having a value object in place makes it much easier anyway over the raw string approach. To make this change, we need to modify the creation of `ProductName` class to take an additional parameter, called `config`:

```csharp
private ProductName(string value, string config)
{
  _value = value;
  _config = config;
}
```

Note that this is an example we mentioned earlier. There is one difference, however. While earlier we assumed that we don't need to hold value and configuration separately inside a `ProductName` instance and concatenated them into a single string when creating an object, this time we assume that we will need this separation between name and configuration later.

After modifying the constructor, the next thing is to add additional validations to the factory method:

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

Note that this modification requires changes all over the code base (because additional argument is needed to create an object), however, this is not the kind of change that we're afraid of too much. That's because changing the signature of the method will trigger compiler errors. Each of these errors will need to be fixed before the compilation can pass (we can say that the compiler creates a nice TODO list for us and makes sure we address each and every item on that list). This means that we don't fall into the risk of forgetting to make one of the places where we need to make a change. This greatly reduces the risk of violating the Shalloway's Law. 

The last part of this change is to modify equality operators, `Equals()` and `GetHashCode()`, to compare instances not only by name, but also by configuration. And again, I will leave the code of those methods as an exercise to the reader. I'll just briefly note that this modification won't require any changes outside the `ProductName` class.

## Summary

So far, we have talked about value objects using a specific example of product names. I hope you now have a feel of how such objects can be useful. The next chapter will complement the description of value objects by explaining some of their general properties.   

[^isnullorempty]: By the way, the code contains a call to `IsNullOrEmpty()`. There are several valid arguments against using this method, e.g. by Mark Seemann (http://blog.ploeh.dk/2014/11/18/the-isnullorwhitespace-trap/), but in this case, I put it in to make the code shorter as the validation logic itself is not that important at the moment. 

[^essentialskills]: A. Shalloway et al., Essential Skills For The Agile Developer.

[^constructorsdynamic]: This is literally true for languages like Java, C# or C++. There are other languages (like Ruby), with different rules regarding object construction. Still, the original argument - that the naming of methods responsible for object creation is constrained - holds.

[^whyuseequatable]: https://stackoverflow.com/questions/2734914/whats-the-difference-between-iequatable-and-just-overriding-object-equals

