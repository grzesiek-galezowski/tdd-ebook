Statement-first programming
===========================

What is the point of writing the specification after the fact? 
--------------------------------------------------------------

In the last chapter, I said that in TDD a ‘test’ takes another role -- one of a statement that is part of a specification. If we put it this way, then the whole controversial concept of “writing a test before the code" does not pose a problem at all. Quite the contrary -- it only seems natural to specify what we are going to write before we attempt to write it. Does the other way round even make sense? A specification written after completing the implementation is nothing more than an attempt at documenting the existing solution. Sure, such attempts can provide some value when done as a kind of reverse-engineering (i.e. writing the specification for something that was implemented long ago and for which we which we uncover the previously implicit business rules or policies as we document the existing solution) -- it has an excitement of discovery in it, but doing so just after we made all the decisions ourselves seems like a waste of time, not to mention that it is dead boring (Don't believe me? Try implementing a simple calculator app and then write specification for it just after it is implemented and working). Anyway, specifying how something should work after the fact can hardly be considered creative. 

Oh, and did I tell you that without a specification of any kind we do not really know whether we are done implementing our changes or not. To determine if the change is complete, we need to compare the implemented functionality to ‘something’, even if this ‘something’ is only in the customer’s head).

Another thing I mentioned in the previous chapter is that we approach writing a Specification of executable Statements differently from writing a textual design specification: even though the code follows the Specification, we do not write our Specification entirely up-front. The usual sequence is to specify a bit first and then code a bit, repeating it for one Statement at a time. When doing TDD, we are traversing repeatedly through a few phases that make up a cycle. We like these cycles to be short, so that we get feedback early and often. This is essential, because it allows us to move forward, confident that what we already have works as we intended. It also enables us to make the next cycle more efficient thanks to the knowledge we gained in the previous cycle (if you do not believe me that quick feedback is good, ask yourself a question: “how many times a day do I compile the code I'm working on?").

Reading so much about cycles, it is probably no surprise that the traditional illustration of the TDD process is modeled visually as a circular flow:

![Basic TDD cycle](images/RedGreenRefactor.png)

Note that the above form uses the traditional terminology of TDD, so before I explain the steps, here's a similar illustration that uses our terms of Specification and Statements: 

![Basic TDD cycle with changed terminology](images/RedGreenRefactor2.png)

The second version seems more like common sense than the first one -- specifying how something should behave before putting that behavior in place is way more intuitive than testing something that is unspecified.

Anyway, these three steps deserve some explanation. In the coming chapters I'll give you some examples of how this process works in practice and introduce an expanded version, but in the meantime it suffices to say that:

Write a Statement you wish were true but is not
:   means that the Statement evaluates to false. In the test list it appears as failing, which most xUnit frameworks mark with red color.

Add code to make it true
:   means that we write just enough code to make the Statement true. In the test list it appears as passing, which most xUnit frameworks mark with green color. Later in the course of the book you'll see how little can be “just enough".

Refactor
:   is a step that I have silently ignored so far and will do so for several more chapters. Don't worry, we'll get back to it eventually. For now it's important to be aware that the executable Specification acts as a safety net while we are improving the code: by running the Specification often, we quickly discover any mistake we make in the process. 

By the way, this process is sometimes referred to as “Red-Green-Refactor". I am just mentioning it here for the record -- I'll not use this term further in the book.

"Test-First" means seeing a failure
-----------------------------------

Explaining the illustration with the TDD process above, I pointed out that you are supposed to write a Statement that you wish were true **but is not**. It means that when you write a Statement, you have to evaluate it (i.e. run it) and watch it fail its assertions before you provide an implementation that makes this Statement true. Why is that so important? Is it not just enough to write the Statement first? Why run it and watch it fail?

There are several reasons and I will try to outline a few of them briefly.

### You do not know whether the Statement can ever be false until you see it evaluate as false

Every accurate Statement fails when it isn’t fulfilled and passes when it is. That is one of the main reasons why we write it -- to receive this feedback. Also, after being fulfilled, the Statement becomes a part of the executable specification and starts failing as soon as the code stops fulfilling it, for example as the result of a mistake made during code rework. If you run a Statement for the first time only after it has been implemented and it evaluates to true, how do you know whether it really describes a need accurately? You did not ever watch it fail, so how do you know it ever will?

The first time I encountered this argument was before I started thinking of unit tests as executable specification). “Seriously?" -- I thought -- “I know what I'm writing. If I make my unit tests small enough, it is self-evident that I am describing the correct behavior. This is paranoid". However, life quickly verified my claims and I was forced to withdraw my arguments. Let me describe three ways I experienced of how one can write a Statement that always evaluates to true, regardless if the code is correct or not. There are more ways, I just forgot the rest :-D). Avoid the following situations where Statements cheat you into thinking they are fulfilled even when they are not: 

#### 1. Accidental omission of adding a Statement to the Specification

However funny it may sound, this happened to me a few times. The example uses C#, but most xUnit frameworks have some kind of mechanism to mark methods as Statements, whether by using attributes (C#) or annotations (Java), or by using macros (C and C++) or by inheriting from a common class, or by using just a naming convention.

Let's take xUnit.Net as an example. To turn a method into a Statement in xUnit.Net, you mark it with the `[Fact]` attribute in the following way: 

```csharp
public class CalculatorSpecification
{
  [Fact]
  public void ShouldDisplayAdditionResultAsSumOfArguments() 
  {
    //... 
  }
}
```

Now, imagine that you are writing this Statement post-factum as a unit test in an environment that has, let's say, more than thirty Statements. You have written the code and now you are just creating test after test “to ensure" the code works. Code, test -- pass, test -- pass, test -- pass. Usually you evaluate your code against the whole Specification, since it is easier than selecting what to evaluate each time. Besides you get more confidence this way that you don't make a mistake and break something that is already working. So, this is really: Code, Test -- all pass, test -- all pass, test -- all pass... Hopefully, you use some kind of snippets mechanism for creating new Statements, otherwise you might write something like this once in a while:

```csharp
public class CalculatorSpecification
{
  //... some Statements here

  //oops... forgot to copy-paste the attribute!
  public void ShouldDisplayZeroWhenResetIsPerformed()
  {
    //... 
  }
}
```

You will not even notice that the new Statement is not evaluated with the rest of the Specification, because that already contains so many Statements that it is unattractive to search for each new Statement in the list and make sure it's there. Also, note that the absence of the `[Fact]` attribute does not disturb your work flow: test -- all pass, test -- all pass, test -- all pass... In other words, your process does not give you any feedback that you made a mistake. So, what you end up with is a Statement that not only will never be false -- **it will never be evaluated**.

How does treating tests as Statements and evaluating them before making them true help here? **Because then, a Statement that starts off being evaluated as true is what DOES disturb your work flow.** In TDD, the work flow is: Statement -- unfulfilled -- fulfilled (and refactor, but that doesn't matter much for this discussion), Statement -- unfulfilled -- fulfilled, Statement -- unfulfilled -- fulfilled... So every time you miss the “unfulfilled" stage, you get feedback from your process that something suspicious is happening. This lets you investigate and fix the situation if necessary.

#### 2. Misplacing mock setup

Ok, this may sound even funnier, but it also happened to me a couple of times, so it makes sense to mention it. This example uses manual mocks, but it can happen with dynamic mocks as well, especially if you are in a hurry.

Let's take a look at the following Statement which states that setting a value higher than allowed to a field of a `frame` should produce a `result` that indicates the error:

```csharp
[Fact]
public void ShouldRecognizeTimeSlotAboveMaximumAllowedAsInvalid()
{
  //GIVEN
  var frame = new FrameMock(); //manual mock
  var validation = new Validation();
  var timeSlotAboveMaximumAllowed = TimeSlot.MaxAllowed + 1;

  //WHEN
  var result = validation.PerformForTimeSlotIn(frame);
  frame.GetTimeSlot_Returns 
    = timeSlotAboveMaximumAllowed;

  //THEN
  Assert.False(result.Passed);
  Assert.Equal(
    ValidationFailureReasons.AboveAcceptableLimit, 
    result.Reason);
}
```

Note how the method `PerformForTimeSlotIn()`, which triggers the specified behavior, is accidentally called *before* the mock is actually set up and the value of `frame.GetTimeSlot_Returns` is not taken into account. Thus this erroneous value does not alter the expected end result, but we'll not notice it. It sometimes turns out like this, most often in case of various boundary values (nulls etc.).

#### 3. Using static data inside production code

Once in a while, you have to jump in and add some new Statements to an existing class Specification and some logic to the class itself. Let's assume that the class and its specification was written by someone else. Imagine this code is a wrapper around your product XML configuration file. You decide to write your Statements *after* applying the changes (“well", you say, “I am all protected by the Specification that is already in place, so I can make my change without risking regression, and then just test my changes and it is all good...").

So, you start writing the new Statement. The Specification class already contains a member field like this:

```csharp
public class XmlConfigurationSpecification
{
  XmlConfiguration config = new XmlConfiguration(xmlFixtureString);
  
  //...
```

What it does is to set up an object used by every Statement. So, each Statement uses a `config` object initialized with the same `xmlConfiguration` string value. The string is already pretty large and messy, since it contains all what is required by the existing Statements. You need to write tests for a little corner case that does not need all this crap inside this string. So, you decide to start afresh and create a separate object of the `XmlConfiguration` class with your own, minimal string. Your Statement begins like this:

```csharp
string customFixture = CreateMyOwnFixtureForThisTestOnly();
var configuration = new XmlConfiguration(customFixture);
...
```

And it passes -- cool... not. Ok, what is wrong with this? Nothing big, unless you read the source code of XmlConfiguration class carefully. Inside, you can see, how the XML string is stored:

```csharp
private static string xmlText; //note the static keyword!
```

What the...? Well, well, here is what happened: the author of this class applied a small optimization. He thought: “In this app, the configuration is only modified by members of the support staff and to do it, they have to shut down the system, so, there is no need to read the XML file every time an XmlConfiguration object is created. I can save some CPU cycles and I/O operations by reading it only once when the first object is created. Later objects will just use the same XML!". Good for him, not so good for you. Why? Because your custom XML string will never actually be used! (Unless your Statement is evaluated prior to being fulfilled.)

“Test-After" ends up as “Test-Never" 
------------------------------------

I will ask this question again: did you ever have to write a requirements or design document for something that you already implemented? Was it fun? Was it valuable? Was it creative? No, I do not think so. The same holds for our executable specification. After we've written the code, we have little motivation to specify what we wrote -- some of the pieces of code “we can just see are correct", other pieces “we already saw working" when we copied the code over to our development machine and ran a few sanity checks... The design is ready... Specification? Maybe next time...

Another reason might be time pressure. When pressure becomes too high, it seems to trigger heroic behaviors in us. Then all of a sudden we drop all the “baggage", stop learning and experimenting, revert to all of the old “safe" behaviors and “save what we can!". If the Specification is written at the end, it is sacrificed, since the code already has been written, “and it will be tested anyway by real tests" like box tests, smoke tests and sanity tests. However, when starting with a Statement it is quite the opposite. Here a Statement evaluating to false is **a reason** to write any code. Thus, creating the Specification is an indispensable part of writing code.

"Test-After" leads to design rework
-----------------------------------

I like reading and watching Uncle Bob. One day I was listening to [his keynote at Ruby Midwest 2011, called Architecture The Lost Years](http://www.confreaks.com/videos/759-rubymidwest2011-keynote-architecture-the-lost-years). At the end, Robert makes some digressions, one of them about TDD. He says that writing unit tests after the code is not TDD. It is a waste of time.

My initial thought was that the comment was only about missing all the benefits that starting with a false Statement brings you: the ability to see the Statement fail, the ability to do a clean-sheet analysis etc.. However, now I'm convinced that there's more to it. It is something I got from Amir Kolsky and Scott Bain -- in order to be able to write a maintainable Specification for a piece of code, the code must have a high level of **testability**. We will talk about this quality later on, but for now let's assume that the easier it is to write a Statement for the behavior of a class, the higher testability it has. 

Now, where's the waste? To find out, let's compare the Statement-first and code-first approaches. Here's how dealing with testability looks like in the Statement-first workflow for new (non-legacy) code:

1.  Write false Statement (this step ensures that code has high testability)
2.  Write code to make the Statement true

And here's how it often looks like when we write the code first (extra steps marked with **strong text**):

1.  Write some production code (this probably spans a few classes until we are satisfied)
2.  **Start writing unit tests**
3.  **Notice that unit testing the whole set of classes is cumbersome and unsustainable and contains high redundancy.**
4.  **Restructure the code to be able to isolate objects and use mocks (this step ensures that code has high testability)**
5.  Write unit tests

What is the equivalent of the marked steps in the Statement-first approach? There is none! Doing these things is a waste of time! Sadly, this is a waste I encounter over and over again.

Do you like wasting your time?
