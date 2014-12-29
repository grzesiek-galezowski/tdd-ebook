# Value Objects

Hi, today I'm gonna tell a bit about value objects, why they're so useful and what rules apply to creating and using them. This post is inspired by some work by Kent Beck, Steve Freeman and Nat Pryce.

## Example problem

Imagine you're developing a web shop for your customer. There are different kinds  of products sold and your customers have the ability to add new products.

Each product has at least two important attributes: name and price (actually there are others like quantity, but let's leave them alone for now).

Let's say that you've decided to use *a decimal to hold the price*, and *a string to hold the name*. Note that both are generic library types, not connected to any domain. Is it a good choice to use "library types" for domain abstractions? We shall soon find out...

### Time passes...

Actually, it turns out that these values must be shared across few subdomains of the system. For example:

1.  The website needs to display them
2.  They are used in calculations
3.  They are taken into account when defining and checking promotion rules (e.g. "buy three, pay for two")
4.  They must be supplied when printing invoices

etc.

The code grows larger and larger and, as the concepts of product name and price are among the main concepts of the application, they tend to land everywhere. 

Now, imagine that one of the following changes must make its way into the system:

1.  The product name must be compared as case insensitive, since the names of the products are always printed in uppercase on the invoice. Thus, creating two products that differ only in a letter case (eg. "laptop" and "LAPTOP") would confuse the customers as both these products look the same on the invoice. Also, the only way one would create two products that differ by letter case only is by mistake and we want to avoid that.
2.  The product name is not enough to differentiate a product. For example, a notebook manufacturers have the same models of notebooks in different configurations (e.g. different amount of RAM or different processor models inside). So each product will receive additional identifier that will have to be taken into account during comparisons.
3.  In order to support customers from different countries, new currencies must be supported everywhere money are already used.

These changes are a horror to make. Why? It's because we're coupled in multiple places to a particular implementation of product name (string) and a particular implementation of money (decimal). This wouldn't be so bad, if not for the fact that we're coupled to implementation we cannot change!

From now on, let's put the money concept aside and consider only the product name, as both of these cases are similar, so it's sufficient to consider just one of them.

### What options do we have?

So, what choice do we have now? In order to support new requirements, we have to find all places where we use the product name and price and make the same change. Every time we need to do something like this, it means that *we've introduced redundancy*.

#### Option one - just modify the implementation in all places

So let's say we want to add comparison with letter case ignored. The worst idea to have would be to find all places where we do something like this:

```csharp
if(productName == productName2))
{
..
```

And change it to:

```csharp
if(String.Equals(productName, productName2, 
   StringComparison.OrdinalIgnoreCase))
{
..
```

This is bad for at least three reasons:

1.  According to [Shalloway's Law](http://www.netobjectives.com/blogs/shalloway%E2%80%99s-law-and-shalloway%E2%80%99s-principle), it will be very hard to find all these places and chances are you'll miss at least one.
2.  Everyone who adds new comparisons of product names to the code in the future, will have to remember to use `IgnoreCase` comparison (TODO). If you want to know my opinion, accidental violation of this convention is just a matter of time.
3.  Even if this time you'll be able to find and correct all the places, every time this aspect changes (e.g. we'll have to support `InvariantIgnoreCase` option instead of OrdinalIgnoreCase for some reasons, or the case I mentioned earlier with comparison including an identifier), you'll have to do it over.
4.  Also, there are other changes that will be tied to the concept of product name (like generating a hash code or something) and you'll need to introduce them too in all the places where the product name value is used.

#### Option two - use a helper class

We can address the third issue of the above list by moving the comparison operation into a helper class. Thus, the comparison would look like this:

```csharp
if(ProductName.Equals(productName, productName2))
{
..
```

Now, the details of the comparison are hidden inside the newly created class. Each time the comparison needs to change, we have to modify only this one class.

However, while it protects us from the change of comparison policy, it's still not enough. The concept of product name is not encapsulated - it's still a string and all its methods are publicly available. Hence, another developer who starts working on the code may not even notice that product names are compared differently than other strings and just use the comparison methods from string type. Other deficiencies of the previous approach apply as well (as I said, except from the issue number 3).

#### Option three - encapsulate the domain concept and create a "Value Object"

I think it's more than clear now that product name is a not "just a string", but a domain concept and as such, it deserves its own class. Given this, the comparison snippet is now:

```csharp
//both are of class ProductName
if(productName.Equals(productName2))
{
..
```

How is it different from the previous approach with helper class? While previously the implementation of a product name (a string) was publicly visible and we only added external functionality that operated on this implementation (and anybody could add their own), this time the nature of the product name is completely hidden from the outside world. The only available way of working with product names is through the `ProductName`'s public interface (which exposes only those methods we want and no more). In other words, whereas before we were dealing with a general-purpose type we couldn't change, now we have a domain-specific type that's completely under our control.

### How value objects help dealing with change

Let's see how this move makes it easier to introduce the changes I already mentioned (ignoring case, comparing by ID as well as by string name and getting uppercase version for printing on invoice).

#### Initial implementation

The first implementation may look like this:

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

### Summary

By examining the above example, we can see the following principle emerging:

I> When you give a value a name that belongs to the problem domain, it means that its type should be a separate domain-specific class which is under your control instead of a general-purpose library class that's out of your control.

And it's a nice one to remember, especially because we often tend to model such values as a library types and wake up when it's already too late to make the transition to value object effectively. I'm an example of this and that's why I re-learned this principle by hard many times.

And that's it for today. I'll be happy to hear your thoughts. Until then, see ya!
