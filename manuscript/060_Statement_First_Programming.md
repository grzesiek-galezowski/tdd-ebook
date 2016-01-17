Statement-first programming
===========================

What's the point of writing a specification after the fact? 
--------------------------------------------------------------

The best known thing about TDD is that a failing test for a behavior of a piece of code is written before the behavior is implemented. This concept seems controversial to many.

In the last chapter, I said that in TDD a "test" takes an additional role -- one of a statement that is part of a specification. If we put it this way, then the whole controversial concept of "writing a test before the code" does not pose a problem at all. Quite the contrary -- it only seems natural to specify what we expect from a piece of code to do before we attempt to write it. Does the other way round even make sense? A specification written after completing the implementation is nothing more than an attempt at documenting the existing solution. Sure, such attempts can provide some value when done as a kind of reverse-engineering (i.e. writing the specification for something that was implemented long ago and for which we uncover the previously implicit business rules or policies as we document the existing solution) -- it has an excitement of discovery in it, but doing so just after we made all the decisions ourselves doesn't seem to me like a productive way to spend my time, not to mention that I find it dead boring (You can check whether you're like me on this one. Try implementing a simple calculator app and then write specification for it just after it is implemented and manually verified to work). Anyway, I hardly find specifying how something should work after it works creative. Maybe that's the reason why, throughout the years, I have observed the specifications written after a feature is implemented to be much less complete than the ones written before the implementation.

Oh, and did I tell you that without a specification of any kind we do not really know whether we are done implementing our changes or not. To determine if the change is complete, we need to compare the implemented functionality to "something", even if this "something" is only in the customer’s head).

Another thing I mentioned in the previous chapter is that we approach writing a Specification of executable Statements differently from writing a textual design or requirements specification: even though the code follows the Specification, we do not write our Specification entirely up-front. The usual sequence is to specify a bit first and then code a bit, repeating it one Statement at a time. When doing TDD, we are traversing repeatedly through a few phases that make up a cycle. We like these cycles to be short, so that we get feedback early and often. This is essential, because it allows us to move forward, confident that what we already have works as we intended. It also enables us to make the next cycle more efficient thanks to the knowledge we gained in the previous cycle (if you don't believe me that quick feedback is good, ask yourself a question: “how many times a day do I compile the code I'm working on?").

Reading so much about cycles, it is probably no surprise that the traditional illustration of the TDD process is modeled visually as a circular flow:

![Basic TDD cycle](images/RedGreenRefactor.png)

Note that the above form uses the traditional terminology of TDD, so before I explain the steps, here's a similar illustration that uses our terms of Specification and Statements: 

![Basic TDD cycle with changed terminology](images/RedGreenRefactor2.png)

The second version seems more like common sense than the first one -- specifying how something should behave before putting that behavior in place is way more intuitive than testing something that is unspecified.

Anyway, these three steps deserve some explanation. In the coming chapters I'll give you some examples of how this process works in practice and introduce an expanded version, but in the meantime it suffices to say that:

Write a Statement you wish were true but is not
:   means that the Statement evaluates to false. In the test list it appears as failing, which most xUnit frameworks mark with red color.

Add code to make it true
:   means that we write just enough code to make the Statement true. In the test list it appears as passing, which most xUnit frameworks mark with green color. Later in the course of the book you'll see how little can be "just enough".

Refactor
:   is a step that I have silently ignored so far and will do so for several more chapters. Don't worry, we'll get back to it eventually. For now it's important to be aware that the executable Specification acts as a safety net while we are improving the code: by running the Specification often, we quickly discover any mistake we make in the process. 

By the way, this process is sometimes referred to as "Red-Green-Refactor", because of the colors that xUnit tools display for failing and passing test. I am just mentioning it here for the record -- I will not be using this term further in the book.

"Test-First" means seeing a failure
-----------------------------------

Explaining the illustration with the TDD process above, I pointed out that you are supposed to write a Statement that you wish was true **but is not**. It means that not only you have to write a Statement before you provide implementation that makes it true, you also have to evaluate it (i.e. run it) and watch it fail its assertions before you provide the implementation. 

Why is that so important? Is it not just enough to write the Statement first? Why run it and watch it fail? There are several reasons and I will try to outline several of them briefly.

### We can't be sure whether the Statement can ever be false until you see it evaluate as false

Every accurate Statement fails when it isn’t fulfilled and passes when it is. That's one of the main reasons why we write it -- to see this transition from *red* to *green*, which means that what previously was not implemented (and we had a proof for that) is now working (and we have a proof). Seeing the transition tells us that we made progress. 

Another thing to note is that, after being fulfilled, the Statement becomes a part of the executable specification and starts failing as soon as the code stops fulfilling it, for example as the result of a mistake made during code refactoring. 

Seeing a Statement evaluated as false gives us valuable feedback. If you run a Statement only *after* the behavior it describes has been implemented and it is evaluated as true, how do you know whether it really describes a need accurately? You did not ever watch it fail, so how do you know it ever will?

The first time I encountered this argument was before I started thinking of tests as executable specification. “Seriously?" -- I thought -- “I know what I'm writing. If I make my unit tests small enough, it is self-evident that I am describing the correct behavior. This is paranoid". However, life quickly verified my claims and I was forced to withdraw my arguments. Let me describe three ways I experienced of how one can write a Statement that is always evaluated as true, whether the code is correct or not. There are more ways, however, I think giving you three should be an illustration enough. 

Test-first allowed me to avoid the following situations where Statements cheated me into thinking they were fulfilled even when they were not: 

#### 1. Accidental omission of including a Statement in a Specification

It's usually insufficient to just write the code of a Statement - we also have to let the test runner know that a method we wrote is really a Statement (not e.g. just a helper method) and it needs to be evaluated, i.e. run by the runner. 

Most xUnit frameworks have some kind of mechanism to mark methods as Statements, whether by using attributes (C#) or annotations (Java), or by using macros (C and C++) or by inheriting from a common class, or by using a naming convention. 

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

There is a chance that we may forget to decorate a method with the `[Fact]` attribute - in such case, it's never executed by the test runner. However funny it may sound, this is exactly what happened to me several times. Let's take the above Statement as an example and imagine that we are writing this Statement post-factum as a unit test in an environment that has, let's say, more than thirty Statements already written and passing. We have written the code and now we are just creating test after test to ensure the code works. Test -- pass, test -- pass, test -- pass. When I execute tests, I almost always run more than one at a time, since it's easier for me  than selecting what to evaluate each time. Besides, I get more confidence this way that I don't make a mistake and break something that is already working. Let's imagine we are doing the same here. Then the workflow is really: Test -- all pass, test -- all pass, test -- all pass... 

Over the time, I have learned to use code snippets mechanism of my IDE to generate a template body for my Statements. Still, in the early days, I have occasionally written something like this:

```csharp
public class CalculatorSpecification
{
  //... some Statements here

  //oops... forgot to insert the attribute!
  public void ShouldDisplayZeroWhenResetIsPerformed()
  {
    //... 
  }
}
```

As you can see, the `[Fact]` attribute is missing, which means this Statement will not be executed. This has happened not only because of not using code generators -- sometimes -- to create a new Statement -- it made sense to copy-paste an existing Statement, change the name and few lines of code. I didn't always remember to include the `[Fact]` attribute in the copied source code. The compiler was not complaining as well.

The reason I didn't see my mistake was because I was running more than once at a time - when I got a green bar (i.e. all Statements evaluated as true), I assumed that the Statement I just wrote works as well. It was unattractive for me to search for each new Statement in the list and make sure it's there. The more important reason, however, was that the absence of the `[Fact]` attribute did not disturb my work flow: test -- all pass, test -- all pass, test -- all pass... In other words, my process did not give me any feedback that I made a mistake. So, in such case, what we end up with is a Statement that not only will never be evaluated as false -- **it will not evaluated at all**.

How does treating tests as Statements and evaluating them before making them true help here? The fundamental difference is that the workflow of TDD is: test -- fail -- pass, test -- fail -- pass, test -- fail -- pass... In other words, we expect each Statement to be evaluated as false at least once. So every time we miss the “fail" stage, we get feedback from our process that something suspicious is happening. This allows us to investigate and fix the problem if necessary.

TODO maybe change it to misplaced test setup without mocks?

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

Note how the method `PerformForTimeSlotIn()`, which triggers the specified behavior, is accidentally called *before* the mock is set up and the value of `frame.GetTimeSlot_Returns` is not taken into account. Thus this erroneous value does not alter the expected end result, and may go unnoticed. It sometimes turns out like this, most often in case of various boundary values (nulls etc.).

#### 3. Using static data inside production code

Once in a while, you have to jump in and add some new Statements to an existing Specification and some logic to the class it describes. Let's assume that the class and its specification was written by someone else. Imagine this code is a wrapper around your product XML configuration file. You decide to write your Statements *after* applying the changes (“well", you say, “I am all protected by the Specification that is already in place, so I can make my change without risking regression, and then just test my changes and it is all good...").

So, you start writing the new Statement. The Specification class already contains a member field like this:

```csharp
public class XmlConfigurationSpecification
{
  XmlConfiguration config = new XmlConfiguration(xmlFixtureString);
  
  //...
```

What it does is to set up an object used by every Statement. So, each Statement uses a `config` object initialized with the same `xmlConfiguration` string value. The string is already pretty large and messy, since it contains all that is required by the existing Statements. You need to write tests for a little corner case that does not need all this crap inside this string. So, you decide to start afresh and create a separate object of the `XmlConfiguration` class with your own, minimal string. Your Statement begins like this:

```csharp
string customFixture = CreateMyOwnFixtureForThisTestOnly();
var configuration = new XmlConfiguration(customFixture);
...
```

And it passes -- cool... not. Ok, what is wrong with this? Nothing big, unless you read the source code of XmlConfiguration class carefully. Inside, you can see, how the XML string is stored:

```csharp
private static string xmlText; //note the static keyword!
```

What the...? Well, well, here is what happened: the author of this class applied a small optimization. He thought: “In this app, the configuration is only modified by members of the support staff and to do it, they have to shut down the system, so, there is no need to read the XML file every time an XmlConfiguration object is created. I can save some CPU cycles and I/O operations by reading it only once when the first object is created. Later objects will just use the same XML!". Good for him, not so good for you. Why? Because, due to how initialization works in C#, either the original XML string will be used for all Statements or your custom one! Thus the Statements in this Specification may pass or fail for the wrong reason. Writing a Statement first that you expect to fail and see it pass might help to detect this.

“Test-After" ends up as “Test-Never" 
------------------------------------

I will ask this question again: did you ever have to write a requirements or design document for something that you already implemented? Was it fun? Was it valuable? Was it creative? No, I do not think so. The same holds for our executable specification. After we've written the code, we have little motivation to specify what we wrote -- some of the pieces of code “we can just see are correct", other pieces “we already saw working" when we compiled and deployed our changes and ran a few manual checks... The design is ready... Specification? Maybe next time...

Another reason might be time pressure. When pressure becomes too high, it seems to trigger heroic behaviors in us. Then all of a sudden we drop all the “baggage", stop learning and experimenting, revert to all of the old “safe" behaviors and “save what we can!". If the Specification is written at the end, it is sacrificed, since the code already has been written, “and it will be tested anyway by real tests" like box tests, smoke tests and sanity tests. However, when starting with a Statement it is quite the opposite. Here a Statement evaluating to false is **a reason** to write any code. Thus, creating the Specification is an indispensable part of writing code.

"Test-After" leads to design rework
-----------------------------------

I like reading and watching Uncle Bob. One day I was listening to [his keynote at Ruby Midwest 2011, called Architecture The Lost Years](http://www.confreaks.com/videos/759-rubymidwest2011-keynote-architecture-the-lost-years). At the end, Robert makes some digressions, one of them about TDD. He says that writing unit tests after the code is not TDD. It is a waste of time.

My initial thought was that the comment was only about missing all the benefits that starting with a false Statement brings you: the ability to see the Statement fail, the ability to do a clean-sheet analysis etc.. However, now I'm convinced that there's more to it. It is something I got from Amir Kolsky and Scott Bain -- in order to be able to write a maintainable Specification for a piece of code, the code must have a high level of **testability**. We will talk about this quality later on, but for now let's assume that the easier it is to write a Statement for the behavior of a class, the higher testability it has. 

Now, where's the waste? To find out, let's compare the Statement-first and code-first approaches. Here's how dealing with testability looks like in the Statement-first workflow for new (non-legacy) code:

1.  Write a Statement that is false to start with (during this step, detect and correct testability issues even before the tested code is written).
2.  Write code to make the Statement true.

And here's how it often looks like when we write the code first (extra steps marked with **strong text**):

1.  Write some production code (this probably spans a few classes until we are satisfied).
2.  **Start writing a unit test.**
3.  **Notice that unit testing the whole set of classes is cumbersome and unsustainable and contains high redundancy.**
4.  **Restructure the code to be able to isolate objects and use mocks (this step ensures that code has high testability).**
5.  Write unit tests.

What is the equivalent of the marked steps in the Statement-first approach? There is none! Doing these things is a waste of time! Sadly, this is a waste I encounter over and over again.

Do you like wasting your time?
