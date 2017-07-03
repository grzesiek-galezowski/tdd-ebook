# Composing a web of objects

## Three important questions

Now that we know that such thing as a web of objects exists, that there are connections, protocols and such, time to mention the one thing I left out: how does a web of objects come into existence?

This is, of course, a fundamental question, because if we are unable to build a web, we don't have a web. In addition, this is a question that is a little more tricky than it looks like at first glance. To answer it, we have to find the answer to three other questions:

1. When are objects composed (i.e. when are the connections made)?
1. How does an object obtain a reference to another one in the web (i.e. how are the connections made)?
1. Where are objects composed (i.e. where are connections made)?

At first sight, finding the difference between these questions may be tedious, but the good news is that they are the topic of this chapter, so I hope we'll have that cleared shortly.

## A preview of all three answers

Before we take a deep dive, let's try to answer these three questions for a really naive example code of a console application:

```csharp
public static void Main(string[] args)
{
  var sender = new Sender(new Recipient());

  sender.Work();
}
```

This is a piece of code that creates two objects and connects them together, then it tells the `sender` object to work on something. For this code, the answers to the three questions I raised are:

1. When are objects composed? Answer: during application startup (because `Main()` method is called at console application startup).
1. How does an object (`Sender`) obtain a reference to another one (`Recipient`)? Answer: the reference is obtained by receiving a `Recipient` as a constructor parameter.
1. Where are objects composed? Answer: at application entry point (`Main()` method)

Depending on circumstances, we may have different sets of answers. Also, to avoid rethinking this topic each time we create an application, I like to have a set of default answers to these questions. I'd like to demonstrate these answers by tackling each of the three questions in-depth, one by one, in the coming chapters.