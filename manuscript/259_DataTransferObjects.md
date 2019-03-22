## Data Transfer Objects

While looking at the initial data structures, Johnny and Benjamin callded them Data Transfer Objects.

A Data Transfer Object is a pattern to describe objects responsible for exchanging information between process boundaries (TODO: confirm with the book). So, we can have DTOs representing input that our process receives and DTOs representing output that our process sends out.

As you might have seen, DTOs are typically just data structures. That may come as surprising, because for several chapters now, I have repeatedly stressed how we should bundle data and behavior together. Isn't this breaking all the rules that I mentioned?

Yes, it does and it does so for good reason. But before I explain that, let's take a look at two ways of decoupling.

## Decoupling by abstracting behavior

TODO: this applies not only to interfaces but also to functions

This is the way of decoupling I described when talking about the web of objects. Maybe example wth printer?
Let's take a look at a simple class definition:

```csharp
public class Document
{
    private string _content = string.Empty;

    public Add(string content)
    {
        _content += content;
    }

    public void PrintWith(PopularBrandPrinter printer)
    {
        printer.Print(_content);
    }
}
```

Note that the document'a `PrintWith()` method requires an instance of `PopularBrandPrinter`, which, for the sake of this example, is a concrete class that itself is dependent on a third-party vendor-specific library (let's assume it's called `ThirdPartyLib`). This makes our `Document` class indirectly coupled to this library as well. The direction of dependencies goes like this:

```text
Document --> PopularBrandPrinter --> ThirdPartyLib
```

Why is such a dependency an issue? After all, the `Document` class itself does not directly know about the `ThirdPartyLib`? The answer comes when we think about components. The direction of dependencies as it is now says: "`Document` will not work without `PopularBrandPrinter` which will not work without the `ThirdPartyLib`". So If we wanted to release a `Document` class in a separate library, every user of this library would also need to reference the `ThirdPartyLib`.

We could resolve this issue by using an interface. All we need to do is to make a `PopularBrandPrinter` implement an interface:

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

    public Add(string content)
    {
        _content += content;
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

Let's try again to do our exercise of partitioning this code into libraries. We can not put the `Document` together with the `Printer` interface in one library, and the `PopularBrandPrinter` in another:

```text
|| Document --> Printer || <|-- PopularBrandPrinter --> || ThirdPartyLib ||
```

Now, the library holding `PopularBrandPrinter` becomes an optional dependency - every user of `Document` can decide whether to use `PopularBrandPrinter` or implement the `Printer` interface in another way. Other vendors can also release their own libraries holding their own implementations of the `Printer` interface which users of the `Document` class can then choose from.

This could happen because we made `Document` independent of the implementation, and dependent=only on the abstract signatures that are in the interface. Thus, the only source of additional dependencies for `Document` result from the signatures of the interface methods (by the way, we can expose implementation details even this way, which I wrote about in past chapters).

## Decoupling by abstracting data

Another way of decoupling is by abstracting data.

Let's take the example of document and printer and turn it around. Let's say that now the printer depends on the document:

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

    public Add(string content)
    {
        _content += content;
    }

    public string GetContent()
    {
        return _content;
    }
}
```

The direction of dependencies is like this:

```text
PopularBrandPrinter --> Document
                    --> ThirdPartyLibrary
```

What we would want is to package the `PopularBrandPrinter` in a separate library. To do this, we need to make it independent from the `Document`. We would also like the Document to remain independent of the printer. What can we do? We can make the printer accept not document, but a string. So the `Printer`'s `Print()` method would need to change from:  

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

Now we have a situation where `Document` is decoupled from the `PopularBrandPrinter` (it only has a method that returns its content as a string) and `PopularBrandPrinter` is also decoupled from the `Document` (it only has a method that accepts a string). By using a `string` as an intermediate data exchange format, we have decoupled the two classes from each other.

This may seem like a stronger and better decoupling decoupling than using an abstract behavior, but it comes with a price:

1. The code coordinating the exchange between `Document` and `PopularBrandPrinter` must become more complex. As described earlier, when a printer is coupled to a document, the line of code that tells printer to print looks like this:

  ```csharp
  printer.Print(document);
  ```

while in the case where the printer accepts a string, the coordinating code must also call the `GetContent()` method.

1. This data-centric approach also limits our ability to use polymorphism. To illustrate this, I would like to go back to the example we used when talking about decoupling by abstracting behavior. There, we had the following line responsible for printing:

  ```csharp
  document.PrintWith(printer);
  ```

TODO we can use null object

1. more work for coordinators
2. no polymorphism
3. imagine the string was mutable

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