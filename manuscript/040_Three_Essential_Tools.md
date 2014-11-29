The three most essential tools
==============================

Ever watched Karate Kid, either the old version or the new one? The
thing they have in common is that when the kid starts learning Karate
(or Kung-Fu) from his master, he is given a basic, repetitive task (like
taking off a jacket, and putting it on again), not knowing yet where it
would lead him. Or look at the first Rocky film (yeah, the one starring
Sylvester Stallone), where Rocky was chasing a chicken in order to train
agility.

When I first tried to learn how to play guitar, I found two advices on
the web: the first was to start by mastering a single, difficult song.
The second was to play with a single string, learn how to make it sound
in different ways and try to play some melodies by ear just with this
one string. Do I have to tell you that the second advice worked better?

Honestly, I could dive right into the core techniques of TDD, but this
would be like putting you on a ring with a demanding opponent - you
would most probably be discouraged before gaining the necessary skills.
So, instead of explaining how to win a race, in this chapter we will
take a look at what shiny cars we will be driving.

In other words, I will give you a brief tour of the three most essential
tools we will be using throughout this book.

Our shiny tools
---------------

### A disclaimer 

In this chapter, I will oversimplify some things just to
get you up and running without getting into the philosophy of TDD yet
(think: physics lessons in primary school). Do not worry about it :-),
we will fix that in the coming chapters!

### xUnit framework

The first and most essential tool we are going to use is an xUnit
framework.

Let us assume that our application looks like this:

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

Now, let us assume we want to check whether it produces correct results.
The most obvious way would be to invoke the application from command
line with some exemplary arguments, check the output to the console and
compare it with what we expect to see. Such session could look like
this:

```text
C:\MultiplicationApp\MultiplicationApp.exe 3 7
21
C:\MultiplicationApp\
```

As you can see, the application produced a result of 21 for
multiplication of 7 by 3. This is correct, so we assume the test is
passed. But what if we produced an application that additionally does
addition, subtraction, division, calculus etc.? How many times would we
have to invoke the application to make sure every operation works
correct?

But wait, we are programmers, right? So we can write programs that can
do this for us! In order to do this, we will create a second application
that will also use the Multiplication class, but in a little different
way:

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

Sounds easy, right? Let us take another step and extract the result
check into something more reusable - after all, we will be adding
division in a second, remember? So here goes:

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
      "Failed! Expected: " + expected + " but was: " + actual);
  }
}
```

Note that I started the name of the method with “Assert" - we will get
back to the naming soon, for now just assume that this is just a good
name for the method. Let us take one last round and put the test into
its own method:

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

And we are finished. Now if we need another test, e.g. for division, we
can just add a new method call to the `Main()` method and implement it.
When implementing it, we can reuse the `AssertTwoIntegersAreEqual()`
method, since the check for division would be analogous.

As you can see, we can easily write automated checks like this, but this
way has some disadvantages:

1.  Every time we add new test, we have to maintain the `Main()` method,
    adding a call to the new test. If you forget to add such a call, the
    test will never be run. At first it isn’t a big deal, but as soon as
    we have dozens of tests, it will get really hard to notice.
2.  Imagine your system consists of more than one application - you
    would have some problems trying to gather summary results for all of
    the applications that your system consists of.
3.  A need will very quickly arise to write a lot of other checks like
    the existing `AssertTwoIntegersAreEqual()` - this one compares two
    integers for equality, but what if you wanted to checka different
    condition, e.g. that one integer is greater than another? What if
    you wanted to check equality not for integers, but for characters,
    strings, floats etc.? What if you wanted to check some conditions on
    collections, e.g. that a collection is sorted or that all items in
    the collection are unique?
4.  Given that a test fails, it would be hard to navigate from the
    commandline output to the line in your IDE. Would it not be easier
    if you could click on the call stack to take you immediately to the
    code where the failure took place?

For these and other reasons, automated testing tools were born. Those
testing tools are generally referenced to as **xUnit family**, because
many of them have names that end with the word “Unit", e.g. CppUnit (for
C++), JUnit (for Java), NUnit (for .NET) etc.

To be honest, I cannot wait to show you how the test we wrote just
a minute ago looks like when xUnit framework is used, however, before
I do this, I would like to recap quickly what we have in our brute-force
naive approach to writing automated tests:

1.  The `Main()` method serves as a **Test List**
2.  The
    `Multiplication_ShouldResultInAMultiplicationOfTwoPassedNumbers()`
    method is a **Test Method**
3.  The `AssertTwoIntegersAreEqual()` method is **an Assertion**

Quite to our joy, those three elements are present in xUnit frameworks
as well. To illustrate it, here is (finally!) the same test we wrote,
but with an xUnit framework (this one is called XUnit.Net):

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

As you can see, it looks like two methods that we previously had are
gone now and the test is the only thing that is left. Well, to tell you
the truth, they are not gone - it is just that the framework handles
these for us. Let us reiterate through the three elements of the
previous version of the test that I promised would be there after the
transition to xUnit framework:

1.  **Test List** is now created automatically by the framework from all
    methods marked with a [Fact] attribute, so no need to maintain one
    or more central lists. Thus, the `Main()` method is gone.
2.  The **Test Method is here and looks almost the same as the last
    time.**
3.  The **Assertion** took the form of a call to static `Assert.Equal()`
    method - the xUnit.NET framework is bundled with a wide range of
    pre-made assertions for your convenience. Of course, no one stops
    you from writing your own custom one if you do not find what you are
    looking for in a default set.

Phew, I hope I made the transition quite painless for you. Now the last
thing to add - as there is not `Main()` method anymore in the last
example, you surely must wonder how we run those tests, right? Ok, the
last big secret unveiled - we use an external application for this (we
will refer to it using a term **Test Runner**) - we tell it which
assemblies to run and it loads them, runs them, reports results etc. It
can take various forms, e.g. it can be a console application, a GUI
application or a plugin to our IDEs. Here is an example of a stand-alone
runner for xUnit.NET framework:

![XUnit.NET window](images/XUnit_NET_Window.png)

### Mocking framework

Mocking frameworks are libraries that automate runtime creation of
objects (called “mocks") that adhere to specified interface. Aside from
the creation itself, the frameworks provide an API to configure our
mocks on how they behave when certain methods are called on them and to
let us inspect which calls they received.

Mocking frameworks are not as old as xUnit frameworks and were not
present in TDD at very beginning. As you might be wondering why
on earth do we need something like this, I will let you in on a secret:
they were born with a goal of aiding a specific approach to object
oriented design in mind. This kind of design is what TDD can support quite well 
as you will soon experience.

For now, however, let us try to keep things easy. I will defer
explaining the actual rationale for mocking frameworks until later and
instead give you a quick example where you can see them in action.
Ready? Let us go!

Let us pretend that we have the following code for adding new set of
orders for products to a database and handling exceptions (by writing
a message to a log) when it fails:

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

Now, imagine we need to test it - how do we do it? I can already see you
shaking your head and saying: “Let us just create this database, invoke
this method and see if the record is added properly". In such case, the
first test would look like this:

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

As you see, at the beginning of the test, we are opening a connection
and cleaning all existing orders (more on that shortly!), then creating
an order object, inserting it into a database and then querying the
database to give us all of the held instances. At the end, we make an
assertion that the order we tried to insert must be inside all orders in
a database.

Why do we clean up the database? Remember a database is a persistent
storage, so if we did not clean it up and run this test again, the
database may have already contained the item (maybe another test already
added it?) and would probably not allow us to add the same item again.
Thus, the test would fail. Ouch! It hurts so bad, because we wanted our
tests to prove something works, but looks like it can fail even when the
logic is coded correctly. What use is such a test if it cannot reliably
provide the information we demand from it (whether the implemented logic
is correct or not)? Thus, we clean up before each run to make sure the
state of the persistent storage is the same every time we run this test.

So, got what you want? Well, I did not. Personally, I would not go this
way. There are several reasons:

1.  The test is going to be slow. It is not uncommon to have more than
    thousand tests in a suite and I do not want to wait half an hour for
    results every time I run them. Do you?
2.  Everyone running this test will have to set up a local database on
    their machine. What if their setup is slightly different than yours?
    What if the schema gets outdated - will everyone manage to notice it
    and update schema of their local databases accordingly? Will you
    re-run your database creation script only to ensure you have got the
    latest schema available to run your tests against?
3.  There may not be an implementation of the database engine for the
    operating system running on your development machine if your target
    is an exotic or mobile platform.
4.  Note that this test you wrote is only one out of two. You will have
    to write another one for the scenario where inserting an order ends
    with exception. How do you setup your database in a state where it
    throws an exception? It is possible, but requires significant effort
    (e.g. deleting a table and recreating it after the test for other
    tests that might need the table to run correctly), which may lead
    you to a conclusion that it is not worth to write such tests at all.

Now, let us try something else. Let us assume that our database works OK
(or will be tested by black-box tests) and the only thing we want to
test is our implementation. In this situation, we can create fake
object, which is an instance of another custom class that implements the
same interface as MySqlOrderDatabase, but does not write to a database
at all - it only stores the inserted records in a list:

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

Now, we can substitute the real implementation of order database with
the fake instance:

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
Note that we do not clean the fake database object, since we create it
as fresh each time the test is run. Also, the test is going to be much
quicker now. But, that is not the end! We can easily write a test for an
exception situation. How do we do it? Just make another fake object
implemented like this:

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

Ok, so far so good, but the bad is that now we have got two classes of
fake objects to maintain (and chances are we will need even more). Any
method or argument added will need to be propagated to all these
objects. We can spare some coding by making our mocks a little more
generic so their behavior can be configured using lambda expressions:

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

Now, we do not have to create additional classes for new scenarios, but
our syntax gets awkward. See for yourself how we configure the fake
order database to remember and yield the inserted order:

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

Thankfully, some smart programmers created frameworks that provide
further automation in such scenarios. One of them is called
**NSubstitute** and provides an API in a form of extension methods (that
is why it might seem a bit magical at first. Do not worry, you will get
used to it).

Using NSubstitute, our first test can be rewritten as such:

```csharp
[Fact] public void 
ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = new Substitute.For<OrderDatabase>();
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

Note that we do not need the `SelectAllOrders()` method. If no one
except this test needs it, we can delete it and spare some more
maintainability trouble. The last line of this test is actually
a camouflaged assertion that checks whether Insert method was called
once with order object as parameter.

I will get back to mocks, since, as I said, there is a huge philosophy
behind them and we have only scratched the surface here.

### Anonymous values generator

Look at the test in the previous section. Does it not trouble you that
we fill the order object with so many values that are totally irrelevant
to the test logic itself? They actually hinder readability of the test.
Also, they make us believe that the tested object really cares what
these values are, although it does not (the database does, but we
already got rid of it from the test). Let us move it to a method with
descriptive name:

```csharp
[Fact] public void 
ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = new Substitute.For<OrderDatabase>();
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

Now that is better. Not only did we make the test shorter, we also
provided a hint to the test reader that the actual values used to create
an order do not matter from the perspective of tested order processing
logic, hence the name `AnonymousOrder()`.

By the way, would it not be nice if we did not have to provide the
anonymous objects ourselves, but rely on another library to generate
them for us? Susprise, surprise, there is one! It is called
**Autofixture**. It is an example of an anonymous values generator
(although its creator likes to say that it is an implementation of Test
Data Builder pattern, but let us skip this discussion here). After
refactoring our test to use AutoFixture, we arrive at the following:

```csharp
[Fact] public void 
ShouldInsertNewOrderToDatabase()
{
  //GIVEN
  var orderDatabase = new Substitute.For<OrderDatabase>();
  var orderProcessing = new OrderProcessing(orderDatabase, new FileLog());
  var order = any.Create<Order>();

  //WHEN
  orderProcessing.Place(order);

  //THEN
  orderDatabase.Received(1).Insert(order);
}

private Fixture any = new Fixture();
```

Nice, huh? AutoFixture has a lot of advanced features, but personally
I am conservative and wrap it behind a static class called `Any`:

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

In the next chapters, you will see me using a lot of different methods
from the `Any` type. The more you use this class, the more it grows with
other methods for creating customized objects. For now, however, let us
stop here.

### Summary 

In this chapter, I tried to show you the three essential tools which we
will be using in this book and which, when mastered, will make your
test-driven development smoother. If this chapter leaves you with
insufficient justification for their use, do not worry - we will dive
into the philosophy behind them in the coming chapters. For now, I just
want you to get familiar with the tools themselves and their syntax. Go
on, download these tools, launch them, try to write something simple
with them. You do not need to understand their full purpose yet, just go
out and play :-).
