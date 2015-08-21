The essential tools
===================

Ever watched Karate Kid, either the old version or the new one? The thing they have in common is that when the kid starts learning Karate (or Kung-Fu) from his master, he is given a basic, repetitive task (like taking off a jacket, and putting it on again), not knowing yet where it would lead him. Or look at the first Rocky film (yeah, the one starring Sylvester Stallone), where Rocky was chasing a chicken in order to train agility.

When I first tried to learn how to play guitar, I found two pieces of advice on the web: the first was to start by mastering a single, difficult song. The second was to play with a single string, learn how to make it sound in different ways and try to play some melodies by ear just with this one string. Do I have to tell you that the second advice worked better?

Honestly, I could dive right into the core techniques of TDD, but this would be like putting you on a ring with a demanding opponent -- you would most probably be discouraged before gaining the necessary skills. So, instead of explaining how to win a race, in this chapter we will take a look at what shiny cars we will be driving.

In other words, I will give you a brief tour of the three tools we will use throughout this book.

In this chapter, I will oversimplify some things just to get you up and running without getting into the philosophy of TDD yet (think: physics lessons in primary school). Do not worry about it :-), we will fix that in the coming chapters!

Test framework
--------------

The first tool we'll use is a test framework. A test framework allows us to specify and execute our tests.

Let's assume that our application looks like this:

```csharp
public static void Main(string[] args) 
{
  try
  {
    int firstNumber = Int32.Parse(args[0]);
    int secondNumber = Int32.Parse(args[1]);

    var result = 
      new Multiplication(firstNumber, secondNumber).Perform();

    Console.WriteLine("Result is: " + result);
  }
  catch(Exception e)
  {
    Console.WriteLine("Addition failed because of: " + e);
  } 
}
```

Now, let's assume we want to check whether it produces correct results. The most obvious way would be to invoke the application from the command line with some exemplary arguments, check the output to the console and compare it with what we expect to see. Such a session could look like this:

```text
C:\MultiplicationApp\MultiplicationApp.exe 3 7
21
C:\MultiplicationApp\
```

As you can see, the application produces a result of 21 for the multiplication of 7 by 3. This is correct, so we assume the test has passed. But what if the application also performs addition, subtraction, division, calculus etc.? How many times would we have to invoke the application to make sure every operation works correctly?

But wait, we are programmers, right? So we can write programs to do this for us! We will create a second application that also uses the Multiplication class, but in a slightly different way:

```csharp
public static void Main(string[] args) 
{
  var multiplication = new Multiplication(3,7);
  
  var result = multiplication.Perform();
  
  if(result != 21)
  {
    throw new Exception("Failed! Expected: 21 but was: " + result);
  }
}
```

Sounds easy, right? Let's take another step and extract the check of the result into something more reusable -- after all, we will be adding division in a second, remember? So here goes:

```csharp
public static void Main(string[] args) 
{
  var multiplication = new Multiplication(3,7);
  
  var result = multiplication.Perform();
  
  AssertTwoIntegersAreEqual(expected: 21, actual: result);
}

public static void AssertTwoIntegersAreEqual(
  int expected, int actual)
{
  if(actual != expected)
  {
    throw new Exception(
      "Failed! Expected: " 
        + expected + " but was: " + actual);
  }
}
```

Note that I started the name of the method with “Assert" -- we will get back to the naming soon, for now just assume that this is a good name for the method. Let's take one last round and put the test into its own method:

```csharp
public static void Main(string[] args) 
{
  Multiplication_ShouldResultInAMultiplicationOfTwoPassedNumbers();
}

public void 
Multiplication_ShouldResultInAMultiplicationOfTwoPassedNumbers()
{
  //Assuming...
  var multiplication = new Multiplication(3,7);
  
  //when this happens:
  var result = multiplication.Perform();
  
  //then the result should be...
  AssertTwoIntegersAreEqual(expected: 21, actual: result);
}

public static void AssertTwoIntegersAreEqual(
  int expected, int actual)
{
  if(actual != expected)
  {
    throw new Exception(
    "Failed! Expected: " + expected + " but was: " + actual);
  }
}
```

And we are finished. Now if we need another test, e.g. for division, we can just add a new method call to the `Main()` method and implement it. In it, we can reuse the `AssertTwoIntegersAreEqual()` method, since the check for division would be analogous. 

As you see, we can easily write automated checks like this. However, this approach has some disadvantages:

1.  Every time we add new test, we have to update the `Main()` method, adding a call to the new test. If you forget to add such a call, the test will never be run. At first it isn’t a big deal, but as soon as we have dozens of tests, an omission will become hard to notice. 
2.  Imagine your system consists of more than one application -- you would have some problems trying to gather summary results for all of the applications that your system consists of. 
3.  Soon you'll need to write a lot of other methods like  `AssertTwoIntegersAreEqual()` -- this one compares two integers for equality, but what if you wanted to check a different condition, e.g. that one integer is greater than another? What if you wanted to check equality not for integers, but for characters, strings, floats etc.? What if you wanted to check some conditions on collections, e.g. that a collection is sorted or that all items in the collection are unique?
4.  Given that a test fails, it would be hard to navigate from the commandline output to the corresponding line of the source in your IDE. Wouldn't it be easier if you could click on the error message to take you immediately to the code where the failure occurred?

For these and other reasons, automated testing tools were created such as CppUnit (for C++), JUnit (for Java) and NUnit (C#). These frameworks derive their structure and functionality from Smalltalk's SUnit and are collectively referred to as **xUnit family** of test frameworks.  

To be honest, I cannot wait to show you how the test we just wrote looks like when a test framework is used. But first let's recap what we have got in our straightforward approach to writing automated tests:

1.  The `Main()` method serves as a **Test List**
2.  The `Multiplication_ShouldResultInAMultiplicationOfTwoPassedNumbers()` method is a **Test Method**
3.  The `AssertTwoIntegersAreEqual()` method is an **Assertion**

To our joy, those three elements are present as well when we use a test framework. To illustrate this, here is (finally!) the same test we wrote above, now using the [xUnit.Net](http://xunit.github.io/) test framework:

```csharp
[Fact] public void 
Multiplication_ShouldResultInAMultiplicationOfTwoPassedNumbers()
{
  //Assuming...
  var multiplication = new Multiplication(3,7);
  
  //when this happens:
  var result = multiplication.Perform();
  
  //then the result should be...
  Assert.Equal(21, result);
}
```

It looks like two methods that we previously had are gone now and that the test is the only thing that's left. Well, to tell you the truth, they are not gone -- it's just that the framework handles these for us. Let's reiterate the three elements of the previous version of the test that I promised would be there after the transition to the test framework:

1.  The **Test List** is now created automatically by the framework from all methods marked with a [Fact] attribute. There's no need anymore to maintain one or more central lists and the `Main()` method has gone.
2.  The **Test Method** is present and looks almost the same as before.
3.  The **Assertion** takes the form of a call to the static `Assert.Equal()` method -- the xUnit.NET framework is bundled with a wide range of assertion methods. Of course, no one stops you from writing your own if the provided assertion methods do not offer what you are looking for.

Phew, I hope I made the transition quite painless for you. Now the last thing to add -- as there is no `Main()` method anymore in the last example, you surely must wonder how we run those tests, right? Ok, the last big secret unveiled -- we use an external application for this (we will refer to it using the term **Test Runner**) -- we tell it which assemblies to run and it loads them, runs them, reports results etc. It can take various forms, e.g. it can be a console application, a GUI application or a plugin for an IDE. Here is an example of a stand-alone runner for the xUnit.NET framework:

![xUnit.NET window](images/XUnit_NET_Window.png)

Mocking framework
-----------------

A mocking framework lets us create objects at runtime (called “mocks") that adhere to a certain interface. That interface is specified when the mock is created. Aside from the creation, the framework provides an API to configure the mocks on how they behave when certain methods are called on them and to let us inspect which calls they received.

Mocking frameworks are not as old as test frameworks and they were not present in TDD at the very beginning. Why on earth do we need something like this? Well, the idea of mocks grew out of the desire to do object-oriented design using TDD without the need to adapt our code only to make it testable.

I'll give you a quick example of a mocking framework in action now and defer further explanation for their rationale to a later chapter.

Ready? Let's go!

Let's pretend that we have the following code to add a set of orders for products to a database and handle exceptions (by writing a message to a log) when it fails:

```csharp
public class OrderProcessing
{
  //other code...

  public void Place(Order order)
  {
    try
    {
      this.orderDatabase.Insert(order);
    }
    catch(Exception e)
    {
      this.log.Write("Could not insert an order. Reason: " + e);
    }
  }

  //other code...
}
```

Now, imagine we need to test it -- how do we do that? I can already see you shake your head and say: “Let's just create this database, invoke this method and see if the record is added properly". Then, the first test would look like this:

```csharp
[Fact]
public void ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = new MySqlOrderDatabase();
  orderDatabase.Connect();
  orderDatabase.Clean();
  var orderProcessing = new OrderProcessing(orderDatabase, new FileLog());
  var order = new Order(
    name: "Grzesiek", 
    surname: "Galezowski", 
    product: "Agile Acceptance Testing", 
    date: DateTime.Now,
    quantity: 1);

  //WHEN
  orderProcessing.Place(order);

  //THEN
  var allOrders = orderDatabase.SelectAllOrders();
  Assert.Contains(order, allOrders);
}
```

At the beginning of the test we open a connection to the database and clean all existing orders in it (more on that shortly), then create an order object, insert it into the database and query the database for all orders it contains. At the end, we make an assertion that the order we tried to insert is among all orders in the database.

Why do we clean up the database? Remember that a database provides persistent storage. If we do not clean it up and run this test again, the database already contains the item if the insertion in the previous test succeeded. The database might not allow us to add the same item again and the test would fail. Ouch! It hurts so bad, because we wanted our tests to prove something works, but it looks like it can fail even when the logic is coded correctly. What use is such a test if it cannot reliably answer our question whether the implemented logic is correct or not? So, to make sure that the state of the persistent storage is the same every time we run this test, we clean up the database before each run.

Now, did you get what you want? Well, I did not. There are several reasons for that:

1.  The test is going to be slow. It is not uncommon to have more than thousand tests in a suite and I do not want to wait half an hour for results every time I run them. Do you?
2.  Everyone who wants to run this test will have to set up a local database on their machine. What if their setup is slightly different from yours? What if the schema gets outdated -- will everyone manage to notice it and update the schema of their local databases accordingly? Will you re-run your database creation script only to ensure you have got the latest schema available to run your tests against?
3.  There may not be an implementation of the database engine for the operating system running on your development machine if your target is an exotic or mobile platform.
4.  Note that the test you wrote is only one out of two. You will have to write another one for the scenario where inserting an order ends with an exception. How do you setup your database in a state where it throws an exception? It is possible, but requires significant effort (e.g. deleting a table and recreating it after the test for other tests that might need the table to run correctly), which may lead you to the conclusion that it is not worth to write such tests at all.

Now, let's try something else. Let's assume that our database works OK (or will be tested by black-box tests) and that the only thing we want to test is our own code. In this situation we can create a fake object that does not write to a database at all -- it only stores the inserted records in a list: 

```csharp
public class FakeOrderDatabase : OrderDatabase
{
  public Order _receivedArgument;

  public void Insert(Order order)
  {
    _receivedArgument = order;
  }

  public List<Order> SelectAllOrders()
  {
    return new List<Order>() { _receivedOrder; };
  }
}
```
Note that the fake order database is an instance of a custom class that implements the same interface as `MySqlOrderDatabase`.

Now, we can substitute the real implementation of the order database with the fake instance:

```csharp
[Fact] public void 
ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = new FakeOrderDatabase();
  var orderProcessing = new OrderProcessing(orderDatabase, new FileLog());
  var order = new Order(
    name: "Grzesiek", 
    surname: "Galezowski", 
    product: "Agile Acceptance Testing", 
    date: DateTime.Now,
    quantity: 1);

  //WHEN
  orderProcessing.Place(order);

  //THEN
  var allOrders = orderDatabase.SelectAllOrders();
  Assert.Contains(order, allOrders);
}
```
Note that we do not clean the fake database object, since we create a fresh one each time the test is run. The test will also be much quicker now. What's more, we can now easily write a test for an exception situation. How? Just make another fake object, implemented like this:

```csharp
public class ExplodingOrderDatabase : OrderDatabase
{
  public void Insert(Order order)
  {
    throw new Exception();
  }

  public List<Order> SelectAllOrders()
  {
  }
}
```

Ok, so far so good, but now we have two classes of fake objects to create (and chances are we will need even more). Any method added to the `OrderDatabase` interface must also be added to each of these fake objects. We can spare some coding by making our mocks a little more generic so that their behavior can be configured using lambda expressions:

```csharp
public class ConfigurableOrderDatabase : OrderDatabase
{
  public Action<Order> doWhenInsertCalled;
  public Func<List<Order>> doWhenSelectAllOrdersCalled;

  public void Insert(Order order)
  {
    doWhenInsertCalled(order);
  }

  public List<Order> SelectAllOrders()
  {
    return doWhenSelectAllOrdersCalled();
  }
}
```

Now, we do not have to create additional classes for new scenarios, but our syntax becomes awkward. Here's how we configure the fake order database to remember and yield the inserted order:

```csharp
var db = new ConfigurableOrderDatabase();
Order gotOrder = null;
db.doWhenInsertCalled = o => {gotOrder = o;};
db.doWhenSelectAllOrdersCalled = () => new List<Order>() { gotOrder };
```

And if we want it to throw an exception when anything is inserted:

```csharp
var db = new ConfigurableOrderDatabase();
db.doWhenInsertCalled = o => {throw new Exception();};
```

Thankfully, some smart programmers created libraries that provide further automation in such scenarios. One such a library is [**NSubstitute**](http://nsubstitute.github.io/). It provides an API in the form of extension methods, which is why it might seem a bit magical at first. Don't worry, you'll get used to it.

Using NSubstitute, our first test can be rewritten as:

```csharp
[Fact] public void 
ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = Substitute.For<OrderDatabase>();
  var orderProcessing = new OrderProcessing(orderDatabase, new FileLog());
  var order = new Order(
    name: "Grzesiek", 
    surname: "Galezowski", 
    product: "Agile Acceptance Testing", 
    date: DateTime.Now,
    quantity: 1);

  //WHEN
  orderProcessing.Place(order);

  //THEN
  orderDatabase.Received(1).Insert(order);
}
```

Note that we do not need the `SelectAllOrders()` method. If no other test needs it, we can delete the method and spare us some more maintenance trouble. The last line of this test is actually a camouflaged assertion that checks whether the `Insert()` method was called once with the order object as parameter.

We'll get back to mocks later as we've only scratched the surface here.

Anonymous values generator
--------------------------

Looking at the test in the previous section we see many values that suggest that they have importance to the tested object. Well, they do not. They do have importance to the database, but we already got rid of that. Doesn't it trouble you that we fill the order object with so many values that are irrelevant to the test logic itself and that mask the structure of the test? To remove the clutter let's introduce a method with a descriptive name to create the order:

```csharp
[Fact] public void 
ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = Substitute.For<OrderDatabase>();
  var orderProcessing = new OrderProcessing(orderDatabase, new FileLog());
  var order = AnonymousOrder();

  //WHEN
  orderProcessing.Place(order);

  //THEN
  orderDatabase.Received(1).Insert(order);
}

public Order AnonymousOrder()
{
  return new Order(
    name: "Grzesiek", 
    surname: "Galezowski", 
    product: "Agile Acceptance Testing", 
    date: DateTime.Now,
    quantity: 1);
}
```

Now that is better. Not only did we make the test shorter, we also provided a hint to the reader that the actual values used to create an order do not matter from the perspective of tested order-processing logic. Hence the name `AnonymousOrder()`.

By the way, wouldn't it be nice if we did not have to provide the anonymous objects ourselves, but can rely on another library to generate these for us? Susprise, surprise, there is one! It is called [**Autofixture**](https://github.com/AutoFixture/AutoFixture). It is an example of an anonymous values generator (although its creator likes to say that it is an implementation of Test Data Builder pattern, but let's skip this discussion here). After changing our test to use AutoFixture, we arrive at the following:

```csharp
[Fact] public void 
ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = Substitute.For<OrderDatabase>();
  var orderProcessing = new OrderProcessing(orderDatabase, new FileLog());
  var order = any.Create<Order>();

  //WHEN
  orderProcessing.Place(order);

  //THEN
  orderDatabase.Received(1).Insert(order);
}

private Fixture any = new Fixture();
```

Nice, huh? AutoFixture has a lot of advanced features, but to keep things simple I like to hide its use behind a static class called `Any`:

```csharp
public static class Any
{
  private static any = new Fixture();
  
  public static T ValueOf<T>()
  {
    return any.Create<T>();
  }
}
```

In the next chapters, we'll see many different methods from the `Any` type. The more you use this class, the more it grows with other methods for creating customized objects. For now, let's leave it by this.

Summary 
-------

This chapter introduced the three tools we'll use in this book that, when mastered, will make your test-driven development smoother. If this chapter leaves you with insufficient justification for their use, don't worry -- we will dive into the philosophy behind them in the coming chapters. For now, I just want you to get familiar with the tools themselves and their syntax. Go on, download these tools, launch them, try to write something simple with them. You do not need to understand their full purpose yet, just go out and play :-).
