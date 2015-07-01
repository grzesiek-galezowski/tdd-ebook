# Value Objects

I spent several chapters talking about composing objects in a web where real objects were hidden and only interfaces were exposed. These objects exchanged messages and modeled roles in our domain.
 
However, this is just a part of object-oriented design approach that I'm trying to explain. Another part of the object-oriented world, complementary to what we have been talking about, are values. They have their own set of design constraints and ideas, so most of the concepts from the previous chapters do not apply to them,or apply in a different way.

## What is a value? 

In short, values are usually seen as immutable quantities or measurements[^addreference] that are compared by their content, not their identity. There are some examples of values in the libraries of our programming languages. For example, `String` class in Java or C# is a value, because it is immutable and every two strings are considered equal when they contain the same data. Other examples are the primitive types that are built-in into most programming languages, like numbers or characters. 

Most of the values shipped with general purpose libraries are quite primitive and general purpose. There are many times, however, when we want to model a domain abstraction as a value. Some examples include: date and time (which nowadays is usually a part of standard library, because it is usable in so many domains), money, temperature, but also things such as file paths or resource identifiers.

As you may have already spotted when reading this book, I'm really bad at explaining things without examples, so here is one:

## Example (TODO name this differently!)

Imagine we are developing a web store for a customer. There are different kinds  of products sold and the customer wants to have the ability to add new products.

Each product has at least two important attributes: name and price (actually there are others like quantity, but let's leave them alone for now).

Now, imagine how you would model these two things - would name be modeled by a mere string and price be a double or a decimal type?

Let's say that we have indeed decided to use a `decimal` to hold a price, and a `string` to hold a name. Note that both are generic library types, not connected to any domain. Is it a good choice to use "library types" for domain abstractions? We shall soon find out...

### Time passes...

Actually, it turns out that these values must be shared across few subdomains of the system. For example:

1.  The website needs to display them
2.  They are used in income calculations
3.  They are taken into account when defining and checking promotion rules (e.g. "buy three, pay for two")
4.  They must be supplied when printing invoices

etc.

The code grows larger and larger and, as the concepts of product name and price are among the main concepts of the application, they tend to land everywhere. 

### Change request

Now, imagine that one of the following changes must make its way into the system:

1.  The product name must be compared as case insensitive, since the names of the products are always printed in uppercase on the invoice. Thus, creating two products that differ only in a letter case (eg. "laptop" and "LAPTOP") would confuse the customers as both these products look the same on the invoice. Also, the only way one would create two products that differ by letter case only is by mistake and we want to avoid that.
2.  The product name is not enough to differentiate a product. For example, a notebook manufacturers have the same models of notebooks in different configurations (e.g. different amount of RAM or different processor models inside). So each product will receive additional identifier that will have to be taken into account during comparisons.
3.  In order to support customers from different countries, new currencies must be supported.

These changes are a horror to make. Why? It's because we're coupled in multiple places to a particular implementation of product name (string) and a particular implementation of money (decimal). This wouldn't be so bad, if not for the fact that we're coupled to implementation we cannot change!

From now on, let's put the money concept aside and focus only on the product name, as both name and price are similar cases with similar solutions, so it's sufficient for us to consider just one of them.

### What options do we have?

So, what choice do we have now? In order to support new requirements, we have to find all places where we use the product name and price and make the same change (and, by the way, an IDE will not help us much in this search, because we would be searching for all the occurences of type `string`). Every time we need to do something like this (i.e. we have to make the same change in multiple places an there is a non-zero possibility we'll miss at least one of those places), it means that we have introduced redundancy.

There are multiple ways to approach this redundancy.

#### Option one - just modify the implementation in all places

This option is about leaving the redundancy where it is and making the change in all places, hoping for the best. 

So let's say we want to add comparison with letter case ignored. Using this option would lead us to find all places where we do something like this:

```csharp
if(productName == productName2)
{
..
```

or

```csharp
if(productName.Equals(productName2))
{
..
```


And change them to:

```csharp
if(String.Equals(productName, productName2, 
   StringComparison.OrdinalIgnoreCase))
{
..
```

This deals with the case, at least for now, but in the long run, it can cause some trouble:

1.  According to [Shalloway's Law](http://www.netobjectives.com/blogs/shalloway%E2%80%99s-law-and-shalloway%E2%80%99s-principle), it will be very hard to find all these places and chances are you'll miss at least one. If so, a bug might creep in.
2.  Even if this time you'll be able to find and correct all the places, every time the domain logic for product name comparisons changes (e.g. we'll have to use `InvariantIgnoreCase` option instead of `OrdinalIgnoreCase` for some reasons, or the case I mentioned earlier with comparison including an identifier), you'll have to do it over.
3.  Everyone who adds new code that compares product names in the future, will have to remember that character case is ignored in such comparisons. Thus, they will have to remember to use `IgnoreCase` option whenever they add new comparisons. If you want to know my opinion, accidental violation of this convention in a team that has either a fair size or some staff rotation (TODO - better term) is just a matter of time.
4.  Also, there are other changes that will be tied to the concept of product name (like generating a hash code in places such product names are stored in a hash set or are keys in a hash table) and you'll need to introduce them too in all the places where the product name value is used.

#### Option two - use a helper class

We can address the issues #1 and #2 of the above list (i.e. the necessity to change multiple places when the comparison logic of product names changes) by moving the comparison operation into a helper method of a helper class, say, `ProductName` and make this static method a single place that knows how to compare product names. This would make each of the comparisons scattered across the code look like this:

```csharp
if(ProductName.Equals(productName, productName2))
{
..
```

Note that the details of the comparison are hidden inside the newly created `Equals()` method. This method has become the only place that has knowledge of these details and each time the comparison needs to change, we only have to modify the method. This frees us from having to search and modify all comparisons each time the comparison logic changes.

However, while it protects us from the change of comparison logic indeed, it's still not enough. Why? Because the concept of a product name is still not encapsulated - it's still a `string` and it allows you to do everything with it that we can do with a `string`, even when it does not make sense for product names. Hence, another developer who starts adding some new code may not even notice that product names are compared differently than other strings and just use the default comparison of a `string` type. Other deficiencies of the previous approach apply as well (as I said, except from the issues #1 and #2).

#### Option three - encapsulate the domain concept and create a "Value Object"

I think it's more than clear now that product name is a not "just a string", but a domain concept and as such, it deserves its own class. Let us introduce such a class, then, and call it `ProductName`. Instances of this class will have `Equals()` method overridden[^csharpoperatorsoverride] with the logic specific to product names.  Given this, the comparison snippet is now:

```csharp
// productName and productName2
// are both instances of ProductName
if(productName.Equals(productName2))
{
..
```

How is it different from the previous approach with helper class? Previously the data of a product name was publicly visible (as a string) and we only added external functionality that operated on this data (and anybody could add their own without asking us for permission). This time, the data of the product name is completely hidden from the outside world. The only available way to operate on this data is through the `ProductName`'s public interface (which exposes only those methods that we think make sense for product names and no more). In other words, whereas before we were dealing with a general-purpose type we couldn't change, now we have a domain-specific type that's completely under our control.

### How value objects help dealing with change

Let's get back to the list of four possible changes I mentioned (just to remind you, these were: ignoring case, comparing by ID as well as by string name and getting uppercase version for printing on invoice) see how creating a value object makes it easier to introduce these changes.

First, let's take a look at the definition of the type to see how it looks like before answering how it solves our problems. The following code is not legal C# - I omitted method bodies, putting :

```csharp
public class ProductName 
  : IEquatable<ProductName>
{
  // hidden data:
  private string _value;

  // constructor - hidden as well:
  internal ProductName(string value);
  
  // static method for creating new instances:
  public static ProductName For(string value);
  
  // standard version of ToString():
  public void ToString();
  
  // non-standard version of ToString()
  // I will explain its purpose later
  public string ToString(Format format);

  // for value types, we need to implement all the equality
  // methods and operators, plus GetHashCode():     
  public override bool Equals(Object other);
  public bool Equals(ProductName other);
  public override int GetHashCode();
  public static bool operator ==(ProductName a, ProductName b);
  public static bool operator !=(ProductName a, ProductName b);
}
```

aaaaaaaaaaaaaa TODO

```csharp
public class ProductName
{
  string _value;

  internal ProductName(string value)
  {
    _value = value;
  }

  public static ProductName For(string value)
  {
    if(string.IsNullOrWhiteSpace(value))
    {
      throw new ArgumentException(
        "Product names must be human readable!");
    }
    else
    {
      return new ProductName(value);
    }
  }
  
  //for on-screen printing
  public string HumanReadablePart
  {
    get
    {
      return _value;
    }
  }

  //for invoices
  public string ToNameForInvoice()
  {
    return _value.ToUpper();
  }

  public override bool Equals(Object obj)
  {
    if (obj == null)
    {
      return false;
    }

    var otherProductName = obj as ProductName;
    if ((Object)otherProductName == null)
    {
      return false;
    }

    return _value.Equals(otherProductName._value);
  }

  public override int GetHashCode()
  {
    return _value.GetHashCode();
  }

  public static bool operator ==(ProductName a, ProductName b)
  {
    if (System.Object.ReferenceEquals(a, b))
    {
      return true;
    }

    if (((object)a == null) || ((object)b == null))
    {
      return false;
    }

    return a.Equals(b);
  }

  public static bool operator !=(ProductName a, ProductName b)
  {
    return !(a == b);
  }
}
```

Note few things about this implementation:

1.  The class has internal constructor and static factory method for general use. The factory method holds all the rules that must be satisfied in order to create a valid object and the constructor just sets the fields. This is a preferred way for value objects to be created. One reason for this is that the rules for creating valid objects might grow and we don't want it to cause maintenance burden on our unit tests (we usually don't mock value objects, so they will be all over our unit testing suite). Thus, the clients will always use the factory methods and unit tests will have the freedom to use the constructor if they wish so. Also, it's good for readability (e.g. you can write `ProductName.For("Soap")`)
2.  It looks like the effort on creating such a wrapper around just one value is huge, however, most of the methods are straightforward and others can be auto-generated by an IDE (like Equals(), GetHashCode() and equality operators).
3.  Objects of `ProductName` class behave as if they were values, e.g. comparison is state-based instead of reference-based. Note that this is similar as in case of C# strings, which are a canonical example of value objects.
4.  Product names are immutable. There is no operation that can overwrite its state once the object is created. This is on purpose and is a design constraint that we want to maintain. For example, we may want to sell sets of products in the future ("2 in 1" etc.) and treat it as a separate product with a name being a merger of the component names. In such case, we could write:

    ```csharp
    var productSetName = productName1.MergeWith(productName2);
    ```
and this operation would create a new product name instead of modifying any of the component product names. Note that this is also the same as in case of strings, which, in C#, are immutable (every operation like `Trim()`, `Replace()` etc. creates a new object).
5.  While being freshly created, the ProductName abstraction already contains bits that are domain-specific, namely the `ToNameForInvoice()` method. Whether it's a good decision to put such method in here is heavily dependent on the context (there are other interesting options, but I'll leave this topic for another time).

Ok, now for the first change:

#### First change - case-insensitivity

This is actually very easy to perform - we just have to modify the `Equals()` and `GetHashCode()` operations like so:

```csharp
public override bool Equals(Object obj)
{
  if (obj == null)
  {
    return false;
  }

  var otherProductName = obj as ProductName;
  if ((Object)otherProductName == null)
  {
    return false;
  }

  return string.Equals(this._value, 
                       otherProductName._value,
                       StringComparison.OrdinalIgnoreCase);
}

public override int GetHashCode()
{
  return _value.ToUpper(
    CultureInfo.InvariantCulture).GetHashCode();
}
```

(a disclaimer - I'm not 100% sure that this implementation deals with all of the weird locale-specific issues, so don't treat it as a reference implementation, but rather as a simple example)

Thanks to this, no change outside the ProductName class is necessary. Two methods need to be modified, but in just one place, which means that the encapsulation we've introduced works out pretty well.

#### Second change - additional identifier

In order to do this, we'll have to modify the creation of `ProductName` classes:

```csharp
internal ProductName(string value, string id)
{
  _value = value;
  _id = id;
}

public static ProductName For(string value, string id)
{
  if(string.IsNullOrWhiteSpace(value))
  {
    throw new ArgumentException(
          "Product names must be human readable!");
  }
  else if(string.IsNullOrWhiteSpace(id))
  {
    throw new ArgumentException(
          "Identifiers must be human readable!");
  }
  else
  {
    return new ProductName(value, id);
  }
}
```

Note that this modification requires changes all over the code base (because additional argument is needed to create an object), however, this is not the kind of change that we're afraid of. That's because the compiler will create a nice little TODO list (i.e. compile errors) for us and won't let us go further without addressing it first, so there's no chance the Shalloway's Law might come to effect. Thus, we're pretty much safe. By the way, if the requirements change in the future so that we will have to support product names without an ID, this is the only place we'll need to change.

In addition, `Equals()` and `GetHashCode()` will have to be changed again:

```csharp
public override bool Equals(Object obj)
{
  if (obj == null)
  {
    return false;
  }

  var otherProductName = obj as ProductName;
  if ((Object)otherProductName == null)
  {
    return false;
  }

  var valuesEqual = string.Equals(this._value, 
                       otherProductName._value,
                       StringComparison.OrdinalIgnoreCase);
  var identifiersEqual = this._id.Equals(otherProductName._id);

  return valuesEqual && identifiersEqual;
}

public override int GetHashCode()
{
  return 
    _value.ToUpper(CultureInfo.InvariantCulture).GetHashCode()
      ^ _id.GetHashCode();;
}
```

This modification won't require any changes to the code outside `ProductName` class.

The last change is adding a new member for the ID to allow printing on invoices or on screen:

```csharp
public string Identifier
{
  get
  {
    return _id;
  }
}
```

This will probably require changes to the rest of the code base but the change will be for different reason (i.e. that we want to display product identifiers on web page and print them on the invoice), which is OK, since they're connected to responsibilities beyond those of product name.

### TODO implementing value objects

factory methods, equals, why immutable, gethashcode, implicit values or explicit values, narrowing down the interface, passing multiple strings can cause the order of the arguments to be confused, treating time as integer, treating strings as paths, Title type instead of strings or utils.


### Summary

By examining the above example, we can see the following principle emerging:

I> When you give a value a name that belongs to the problem domain, it means that its type should be a separate domain-specific class which is under your control instead of a general-purpose library class that's out of your control.

And it's a nice one to remember, especially because we often tend to model such values as a library types and wake up when it's already too late to make the transition to value object effectively. I'm an example of this and that's why I re-learned this principle by hard many times.

And that's it for today. I'll be happy to hear your thoughts. Until then, see ya!


TODO talk about static const value objects. const can be used only for types that have literals. Thus static readonly is used. Todo: interfaces let us treat related objects the same, and values let us separate unrelated objects.


[^addreference]: TODO add reference

[^csharpoperatorsoverride]: and, for C#, overriding equality operators is probably a good idea, not to mention `GetHashCode()`

TODO shalloway's law - wasn't it already mentioned?
