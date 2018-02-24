# Value Objects

I spent several chapters talking about composing objects in a web where real implementation was hidden and only interfaces were exposed. These objects exchanged messages and modeled roles in our domain.

However, this is just one part of object-oriented design approach that I'm trying to explain. Another part of the object-oriented world, complementary to what we have been talking about, are values. They have their own set of design constraints and ideas, so most of the concepts from the previous chapters do not apply to them,or apply in a different way.

## What is a value?

In short, values are usually seen as immutable quantities, measurements[^goosvalues] or other objects that are compared by their content, not their identity. There are some examples of values in the libraries of our programming languages. For example, `String` class in Java or C# is a value, because it is immutable and every two strings are considered equal when they contain the same data. Other examples are the primitive types that are built-in into most programming languages, like numbers or characters.

Most of the values that are shipped with general-purpose libraries are quite primitive or general. There are many times, however, when we want to model a domain abstraction as a value. Some examples include: date and time (which nowadays is usually a part of standard library, because it is usable in so many domains), money, temperature, but also things such as file paths or resource identifiers.

As you may have already spotted when reading this book, I'm really bad at explaining things without examples, so here is one:

## Example: money and names

Imagine we are developing a web store for a customer. There are different kinds  of products sold and the customer wants to have the ability to add new products.

Each product has at least two important attributes: name and price (there are others like quantity, but let's leave them alone for now).

Now, imagine how you would model these two things - would the name be modeled as a mere `string` and price be a `double` or a `decimal` type?

Let's say that we have indeed decided to use a `decimal` to hold a price, and a `string` to hold a name. Note that both are generic library types, not connected to any domain. Is it a good choice to use "library types" for domain abstractions? We shall soon find out...

### Time passes...

One day, it turns out that these values must be shared across a few subdomains of the system. For example:

1.  The website needs to display them
2.  They are used in income calculations
3.  They are taken into account when defining and checking discount rules (e.g. "buy three, pay for two")
4.  They must be supplied when printing invoices

etc.

The code grows larger and larger and, as the concepts of product name and price are among the main concepts of the application, they tend to land in many places.

### Change request

Now, imagine that one of the following changes must make its way into the system:

1.  The product name must be compared as case insensitive, since the names of the products are always printed in uppercase on the invoice. Thus, creating two products that differ only in a letter case (eg. "laptop" and "LAPTOP") would confuse the customers as both these products look the same on the invoice. Also, the only way one would create two products that differ by letter case only is by mistake and we want to avoid that.
2.  The product name is not enough to differentiate a product. For example, a notebook manufacturers have the same models of notebooks in different configurations (e.g. different amount of RAM or different processor models inside). So each product will receive additional identifier that will have to be taken into account during comparisons.
3.  To support customers from different countries, new currencies must be supported.

In current situation, these changes are really painful to make. Why? It's because we used primitive types to represent the things that would need to change, which means we're coupled in multiple places to a particular implementation of product name (`string`) and a particular implementation of money (e.g. `decimal`). This wouldn't be so bad, if not for the fact that we're coupled to implementation we cannot change!

Are we sentnced to live with issues like that in our code and cannot do anything about it? Let's find out by exploring the options we have.

From now on, let's put the money concept aside and focus only on the product name, as both name and price are similar cases with similar solutions, so it's sufficient for us to consider just one of them.

### What options do we have to address product name changes?

To support new requirements, we have to find all places where we use the product name (by the way, an IDE will not help us much in this search, because we would be searching for all the occurences of type `string`) and make the same change. Every time we need to do something like this (i.e. we have to make the same change in multiple places an there is a non-zero possibility we'll miss at least one of those places), it means that we have introduced redundancy. Remember? We talked about redundancy when discussing factories and mentioned that redundancy is about conceptual duplication that forces us to make the same change (not literally, but conceptually) in several places.

Al Shalloway coined a humouristic "law" regarding redundancy, called *The Shalloway's Law*, which says:

> Whenever the same change needs to be applied in N places and N > 1, Shalloway will find at most N-1 such places.

An example of an application of this law would be:

> Whenever the same change needs to be applied in 4 places, Shalloway will find at most 3 such places.

While making fun of himself, Al described something that I see common of myself and some other programmers - that conceptual duplication makes us vulnerable and when dealing with it, we have no advanced tools to help us - just our memory and patience.

Thankfully, there are multiple ways to approach this redundancy. Some of them are better and some are worse[^everydecisionistradeoff].

#### Option one - just modify the implementation in all places

This option is about leaving the redundancy where it is and just making the change in all places, hoping that this is the last time we change anything related to product name.

So let's say we want to add comparison with letter case ignored. Using this option would lead us to find all places where we do something like this:

```csharp
if(productName == productName2)
{
..
```

or

```csharp
if(String.Equals(productName, productName2))
{
..
```

And change them to a comparisong that ignores case, e.g.:

```csharp
if(String.Equals(productName, productName2,
   StringComparison.OrdinalIgnoreCase))
{
..
```

This deals with the problem, at least for now, but in the long run, it can cause some trouble:

1.  [It will be very hard](http://www.netobjectives.com/blogs/shalloway%E2%80%99s-law-and-shalloway%E2%80%99s-principle) to find all these places and chances are you'll miss at least one. This is an easy way for a bug to creep in.
2.  Even if this time you'll be able to find and correct all the places, every time the domain logic for product name comparisons changes (e.g. we'll have to use `InvariantIgnoreCase` option instead of `OrdinalIgnoreCase` for some reasons, or handle the case I mentioned earlier where comparison includes an identifier of a product), you'll have to do it over. And Shalloway's Law applies the same every time. In other words, you're not making things better.
3.  Everyone who adds new logic that needs to compare product names in the future, will have to remember that character case is ignored in such comparisons. Thus, they will need to keep in mind that they should use `OrdinalIgnoreCase` option whenever they add new comparisons somewhere in the code. If you want to know my opinion, accidental violation of this convention in a team that has either a fair size or more than minimal staff turnover rate is just a matter of time.
4.  Also, there are other changes that will be tied to the concept of product name equality in a different way (for example, hash sets and hash tables determine equality based on hash code, not plain comparisons of data) and you'll need to find those places and make changes there as well.

So, as you can see, this approach does not make things any better. In fact, it is this approach that led us to the trouble we are trying to get away in the first place.

#### Option two - use a helper class

We can address the issues #1 and #2 of the above list (i.e. the necessity to change multiple places when the comparison logic of product names changes) by moving this comparison into a static helper method of a helper class, (let's simply call it `ProductNameComparison`) and make this method a single place that knows how to compare product names. This would make each of the places in the code when comparison needs to be made look like this:

```csharp
if(ProductNameComparison.AreEqual(productName, productName2))
{
..
```

Note that the details of what it means to compare two product names is now hidden inside the newly created static `AreEqual()` method. This method has become the only place that has knowledge of these details and each time the comparison needs to be changed, we have to modify this method alone. The rest of the code just calls this method without knowing what it does, so it won't need to change. This frees us from having to search and modify this code each time the comparison logic changes.

However, while it protects us from the change of comparison logic indeed, it's still not enough. Why? Because the concept of a product name is still not encapsulated - a product name is still a `string` and it allows us to do everything with it that we can do with any other `string`, even when it does not make sense for product names. This is because in the domain of the problem, product names are not sequences of characters (which `strings`s are), but an abstraction with a special set of rules applicable to it. By failing to model this abstraction appropriately, we can run into a situation where another developer who starts adding some new code may not even notice that product names need to be compared differently than other strings and just use the default comparison of a `string` type.

Other deficiencies of the previous approach apply as well (as I said, except from the issues #1 and #2).

#### Option three - encapsulate the domain concept and create a "value object"

I think it's more than clear now that a product name is a not "just a string", but a domain concept and as such, it deserves its own class. Let us introduce such a class then, and call it `ProductName`. Instances of this class will have `Equals()` method overridden[^csharpoperatorsoverride] with the logic specific to product names.  Given this, the comparison snippet is now:

```csharp
// productName and productName2
// are both instances of ProductName
if(productName.Equals(productName2))
{
..
```

How is it different from the previous approach where we had a helper class, called `ProductNameComparison`? Previously the data of a product name was publicly visible (as a string) and we used the helper class only to store a function operating on this data (and anybody could create their own functions somewhere else without noticing the ones we already added). This time, the data of the product name is hidden[^notcompletelyhidden] from the outside world. The only available way to operate on this data is through the `ProductName`'s public interface (which exposes only those methods that we think make sense for product names and no more). In other words, whereas before we were dealing with a general-purpose type we couldn't change, now we have a domain-specific type that's completely under our control. This means we can freely change the meaning of two names being equal and this change will not ripple throughout the code.

In the following chapters, I will further explore this example of product name to show you some properties of value objects.

[^goosvalues]: S. Freeman, N. Pryce, Growing Object-Oriented Software Guided by Tests, Addison-Wesley Professional, 2009

[^csharpoperatorsoverride]: and, for C#, overriding equality operators (`==` and `!=`) is probably a good idea as well, not to mention `GetHashCode()` (See https://docs.microsoft.com/en-us/dotnet/standard/design-guidelines/equality-operators)

[^everydecisionistradeoff]: All engineering decisions are trade offs anyway, so I should really say "some of them make better trade-offs in our context, and some make worse".

[^notcompletelyhidden]: In reality this is only partially true. For example, we will have to override `ToString()` somewhere anyway to ensure interoperability with 3rd party libraries that don't know about our `ProductName` type, but will accept string arguments. Also, one can always use reflection to get private data. I hope you get the point though :-).
