## Data Transfer Objects

While looking at the initial data structures, Johnny and Benjamin callded them Data Transfer Objects.

A Data Transfer Object is a pattern to describe objects responsible for exchanging information between process boundaries (TODO: confirm with the book). So, we can have DTOs representing input that our process receives and DTOs representing output that our process sends out.

As you might have seen, DTOs are typically just data structures. That may come as surprising, because for several chapters now, I have repeatedly stressed how we should bundle data and behavior together. Isn't this breaking all the rules that I mentioned?

Yes, it does and it does so for good reason. But before I explain that, let's take a look at two ways of decoupling.

## Decoupling by abstracting behavior

TODO: this applies not only to interfaces but also to functions

This is the way of decoupling I described when talking about the web of objects. Let's take a look at a simple class representing a document that can be printed on a printer:

```csharp
public class Document
{
    private string _content = string.Empty;

    public Add(string additionalText)
    {
        _content += additionalText;
    }

    public void PrintWith(PopularBrandPrinter printer)
    {
        printer.Print(_content);
    }
}
```

Note that the document'a `PrintWith()` method requires an instance of `PopularBrandPrinter`, which, for the sake of this example, is a concrete class that itself is dependent on a third-party vendor-specific library (let's assume it's called `ThirdPartyLib`). This makes our `Document` class indirectly coupled to this library as well. The direction of the dependencies goes like this:

```text
Document --> PopularBrandPrinter --> ThirdPartyLib
```

Why is such a dependency an issue? After all, the `Document` class itself does not directly know about the `ThirdPartyLib`? The answer comes when we think about components. The direction of dependencies as it is now says: "`Document` will not work without `PopularBrandPrinter` which will not work without the `ThirdPartyLib`". So If we wanted to release a `Document` class in a separate library, every user of this library would also need to reference the `ThirdPartyLib`.

We can resolve this issue by using an interface. All we need to do is to make a `PopularBrandPrinter` implement an interface (e.g. called `Printer`):

```csharp
public interface Printer
{
    void Print(string text);
}

public class PopularBrandPrinter : Printer
{
    //...
}
```

And make our `Document` depend on that interface instead of the `PopularBrandPrinter`:

```csharp
public class Document
{
    private string _content = string.Empty;

    public Add(string additionalText)
    {
        _content += additionalText;
    }

    public void PrintWith(Printer printer)
    {
        printer.Print(_content);
    }
}
```

This changes the direction of compile-time dependencies[^DIP] to the following:

```text
Document --> Printer <| -- PopularBrandPrinter --> ThirdPartyLib
```

Note that this time, the `Document` is not dependent on `PopularBrandPrinter` in any way. On the other hand, The `PopularBrandPrinter` is dependent on the interface, because it has to implement it.

Given what we achieved so far, let's try again to do our exercise of partitioning this code into libraries. This time, we can do this by putting the `Document` together with the `Printer` interface in one library, and the `PopularBrandPrinter` in another:

```text
|| Document --> Printer || <|-- PopularBrandPrinter --> || ThirdPartyLib ||
```

Now, the library holding `PopularBrandPrinter` becomes an optional dependency - every user of `Document` can decide whether to use `PopularBrandPrinter` or implement the `Printer` interface in another way. Other vendors can also release their own libraries holding their own implementations of the `Printer` interface which users of the `Document` class can then choose from.

This is possible because we made the `Document` class independent of the implementation details of a particular printer, and dependent only on the abstract signatures that are in the interface. Thus, the only source of additional dependencies for the `Document` class results from the signatures of the interface methods (by the way, we can expose implementation details and unwanted dependencies even this way, which I wrote about in past chapters).

## Decoupling by abstracting data

Another way of decoupling the `Document` from implementation details of a particular printer is by defining an intermediate data exchange format.

Let's take the example of document and printer and turn it around. Let's say that now the `PopularBrandPrinter` class depends on the `Document`:

```csharp
public class PopularBrandPrinter
{
    private ThirdPartyPrintingDriver _driver 
      = new ThirdPartyPrintingDriver();

    public void Print(Document document)
    {
        _driver.Send(document.GetContent());
    }
}
```

and the `Document` class is defined as:

```csharp
public class Document
{
    private string _content = string.Empty;

    public Add(string additionalText)
    {
        _content += additionalText;
    }

    public string GetContent()
    {
        return _content;
    }
}
```

//TODO

The direction of dependencies is like this:

```text
PopularBrandPrinter --> Document
                    --> ThirdPartyLibrary
```

What we would want is to package the `PopularBrandPrinter` in a separate library. To do this, we need to make it independent from the `Document`. Furthermore, we would also like the Document to remain independent of the printer. What can we do? We can make the printer accept not a document, but a string, which is a data type. So the `Printer`'s `Print()` method would need to change from:

```csharp
public void Print(Document document)
{
    _driver.Send(document.GetContent());
}
```

to:

```csharp
public void Print(string content)
{
    _driver.Send(content);
}
```

and the code that uses the printer would no longer look like this:

```csharp
var document = //... get the document
var printer = //... get the printer
printer.Print(document);
```

but rather:

```csharp
var document = //... get the document
var printer = //... get the printer
printer.Print(document.GetContent());
```

Now we have a situation where the `Document` class is decoupled from the `PopularBrandPrinter` (it only has a method that returns its content as a string) and `PopularBrandPrinter` is also decoupled from the `Document` (it only has a method that accepts a `string`). By using a `string` as an intermediate data exchange format, we have decoupled the two classes from each other.

Note that this technique is not about using strings. The decoupling may be done using our custom data structure. The point is that the data does not encapsulate any behaviors (even their definitions), so we are not coupled to them. So, for example, when the `Document`, instead of aggregating text passed to it, starts reading the content from database and its `GetContent()` signature changes to being an asynchronous method:

```csharp
var document = //... get the document
var printer = //... get the printer
printer.Print(await document.GetContent());
```

The printer does not need to change as it is coupled to the data abstraction, not the behavior abstraction.





This may seem like a stronger and better decoupling than using an abstract behavior, but it also comes with a price:

### Issues with data-oriented decoupling

First of all, the code coordinating the exchange between `Document` and `PopularBrandPrinter` must become more complex. As described earlier, when a printer is coupled to a document, the line of code that tells printer to print looks like this:

```csharp
printer.Print(document);
```

while in the case where the printer accepts a string, the coordinating code must also call the `GetContent()` method.

The other reason is that this data-centric approach also limits our ability to use polymorphism. To illustrate this, I would like to go back to the example we used when talking about decoupling by abstracting behavior. There, we had the following line responsible for printing:

```csharp
document.PrintWith(printer);
```

When the document is responsible for deciding how to print, it might make a decision not to print at all. Imagine that our `Document` class implements an interface like this:

```csharp
public interface Printable
{
  void Print(Printer printer);
}
```

Then we could have another class implementing this interface, e.g. called `IgnoredPrintable` that would have this implementation:

```csharp
public class IgnoredPrintable : Printable
{
  public void Print(Printer printer)
  {
    //deliberately left empty
  }
}
```

By using this class, we could change the behavior of this code:

```csharp
document.PrintWith(printer);
```

without having to change it.

Now, let's get back to the data-centric approach:

```csharp
printer.Print(document.GetContent());
```

Can we use polymorphism in this case to achieve the same result? Well, let's try. Again, let's imagine we have an interface called `Printable`, but this time it is structured like this:

```csharp
public interface Printable
{
  string GetContent();
}
```

Again, we want to create an implementation that does not print anything, but then we stumble upon a problem:

```csharp
public class IgnoredPrintable : Printable
{
  public string GetContent()
  {
    return ????; //!!!
  }
}
```

Note that when implementing the `GetContent()`, we have to return *something*. This is because in this case, the `Printable` implementations don't make the decision whether to print or not. This decision must be made by the code that coordinates the printing logic:

```csharp
printer.Print(document.GetContent());
```

It can, e.g. check for null:

```csharp
if(document.GetContent() != null)
{
  printer.Print();
}
```

but the point is that we cannot leverage the polymorphism of documents to hide this decision.

This is because, by decoupling documents from the printing behavior, we lost the ability to hide the implementation of that behavior. By losing the ability to hide the implementation, we also lost the ability to hide the variability of the behavior. Thus, this variability must go somewhere else. This can lead to lots of complexity aggregating in the places that coordinate the use case logic.




1. more work for coordinators - TODO an example with an if
2. no polymorphism
3. imagine the string was mutable

## Use both

In reality, by showing you two examples and labelling the first one as behavior-centered decoupling and the other as data-centered decoupling, I lied a bit. The first example contained them both. On one hand, `Document` was decoupled from real printer implementation through an abstract interface, on the other hand, the `PopularBrandPrinter` was decoupled from the document becase it only accepted its data. So the true choice is often between the proportion in using each of the types.

## DTO as data-centric decoupling mechanism

For object-oriented code, the behavior-centric decoupling is the default and more important one as without a strong pressure on it, we would have a much harder time leveraging polymorphism.

On the other hand, when exchanging information between the process boundaries, there are several reasons why we prefer data-centric decoupling:

1. the information typically go into binary or textual format.
1. Performance.
1. Bounded contexts
1. No danger of mutating data


TODO: interface is definition of behavior

In a way, it is and it is because of decoupling. There are two main ways of decoupling.

TODO: every system is procedural at the boundaries.

DTO:

1. Two types of decoupling 
    1. with interfaces (pure behavior descriptions, decouple from the data)
    1. with data (decouples from behavior)
1. As it's very hard to pass behavior and quite easy to pass data, thus typically services exchange data, not behavior.
1. DTOs are for data interchange between processes
1. Typically represent an external data contract
1. Data can be easily serialized into text or bytes and deserialized on the other side.
1. DTOs can contain values, although this may be hard because these values need to be serializable. This may put some constraints on our value types depending on the parser
1. differences between DTOs and value objects (value objects can have behavior, DTOs should not, although the line is blurred e.g. when a value objecy is part of a DTO. String contains lots of behaviors but they are not domain-specific). Can DTOs implement equality?
1. Also, for this reason, application logic should be kept away from DTOs to avoid coupling them to external constract and making serialization/deserialization difficult.
1. Mapping vs. Wrapping
1. We do not mock DTOs
1. input DTOs best read only and immutable but can have builders

[^DIP]: and is, in fact, an example of using Dependency Inversion Principle.