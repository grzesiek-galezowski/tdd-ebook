Statement-first programming
===========================

What is the point of writing specification after the fact? 
----------------------------------------------------------

In the last chapter, I said that in TDD a ‘test’ takes another role -
one of a statement being a part of a specification. If we put things
this way, then the whole controversial concept of “writing a test before
the code" does not pose a problem at all. Quite the contrary - it only
seems natural to specify what we are going to write before we attempt to
write it. Does the other way round even make sense? A specification
written after completing the implementation is nothing more than an
attempt at documenting the existing solution. Sure, such attempts can
provide some value when done as a kind of reverse-engineering (i.e.
writing specification for something that was implemented long ago and we
do not really know the exact business rules or policies, which we
discover as we document the existing solution) - it has an excitement of
discovery in it, but doing it just after we, ourselves, made all the
decisions seems like a waste of time, not to mention that it is dead
boring (Do not believe me? Try implementing a simple calculator app and
the write specification for it just after it is implemented and
working). Anyway, specifying how something should work after the fact
can hardly be considered creative.

Oh, and did I tell you that without a specification of any kind we do
not really know whether we are done implementing our changes or not
(because in order to know it, we need to compare the implemented
functionality to ‘something’, even if this ‘something’ is only in the
customer’s head).

Another thing I mentioned in the previous chapter was that one of the
differences between a textual specification and our Specification
consisting of executable Statements is that, although the code follows
the Specification, we do not write our Specification fully up-front. The
usual sequence is to specify a bit first and then code a bit, then
repeat one Statement at a time. When doing TDD, we are traversing
repeatedly through few phases that make up a cycle. We like these cycles
to be short, so that we can get a quick feedback. Being able to get this
quick feedback is essential, because it allows us to move forward with
confidence that what we already have works as we intended. Also, it
allows us to use the knowledge we gained in the previous cycle to make
the next cycle more efficient (if you do not believe me that quick
feedback is good, ask yourself a question: “how many times a day do
I compile the code I work on?").

Reading so much about cycles, it is probably no surprise to you that the
traditional illustration of the TDD process is modeled visually as
a circle-like flow:

![Basic TDD cycle](images/RedGreenRefactor.png)

Note that the above form uses the traditional terminology of TDD, so
before I explain the steps, I will translate it to use our terms of
Specification and Statements:

![Basic TDD cycle with changed terminology](images/RedGreenRefactor2.png)

The second version seems more like common sense than the first one -
specifying how something should behave before putting that behavior in
place is way more intuitive than testing something that does not exist.

Anyway, these three steps demand some explanation. In the coming
chapters, I will give you some examples of how this process works in
practice and introduce an expanded version, but in the meantime, its
sufficient to say that:

Write a Statement you wish was true but is not
:   means that the Statement evaluates to false (it shows on the test list as failing - in most xUnit frameworks, it will be marked with red color)

Add code to make it true
:   means that we write just enough code to make the Statement true (in most xUnit frameworks, the true Statement will be marked with green color). Later in the course of the book, you will see how small can be “just enough"

Refactor
:   is a step that I have silently discarded so far (and will do so for at least few next chapters. Do not worry, we will get back to it     eventually). Basically, it boils down to using the safety net of executable specification we already have in place to safely enhance the quality of the covered code while all mistakes we make in the process are quickly discovered by the running Specification.

By the way, this process is sometimes referred to as
“Red-Green-Refactor". I am just mentioning it here for the record - I am
not planning to use this term further in the book.

The benefit of failure
----------------------

When I showed you a drawing with a TDD process, I specifically said 
that you are supposed to write a Statement that you wish was true **but 
is not**. It means that when you write a Statement, you have to 
evaluate it (i.e. run it) and watch it fail its assertions before 
providing implementation that makes this Statement true. Why is that so 
important? Is it not just enough to write the Statement first? Why run it and watch it fail?

There are multiple reasons and I will try to outline few of them
briefly.

### You do not know whether the Statement can ever be false until you see it evaluate as false

Every accurate Statement (do I have to tell you that such Statements are
what we are interested in?) fails when it isn’t fulfilled and passes
when it is. That is one of the main reasons we write it - to receive
this feedback. Also, after being fulfilled, the Statement becomes a part
of the executable specification and starts failing as soon as the code
stops fulfilling it (e.g. as a result of mistake made during code
rework). When your run a Statement after it is implemented and it is
evaluated as true, how do you know whether it really describes a need
accurately? You did not ever watch it fail, so how do you know it ever
will?

The first time I encountered this argument (it was before I started
thinking of unit tests as executable specification), it quickly raised
my self-defense mechanism: “seriously?" - I thought - “I am a wise
person, I know what I am writing. If I make my unit tests small enough,
it is self-evident that I am describing the correct behavior. This is
paranoid". However, life quickly verified my claims and I was forced to
withdraw my arguments. Let me describe, from my experience, three ways
(there are more, I just forgot the rest :-D) one can really put in
a Statement that is always evaluated as true, regardless of the code
being correct or not (i.e. a Statement that cheats you into thinking it
is fulfilled even when it is not):

#### 1. Accidental omission of adding a Statement to Specification

However funny this may sound, it happened to me few times. The example
I am going to give is from C\#, but almost every xUnit framework in
almost every language has some kind of mechanism of marking methods as
Statements, whether by attributes (C\#, e.g. xUnit.Net’s `Fact`
attribute) or annotations (Java) or with macros (C and C++) or by
inheriting from common class, or just a naming convention.

Let us take xUnit.Net as an example. As I stated previously, In
xUnit.Net, to turn a method into a Statement, you mark it with `[Fact]`
attribute the following way:

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

Now, imagine that you are writing this Statement post-factum as a unit
test in an environment that has, let us say, more than thirty Statements
- you have written the code, now you are just creating a test after test
“to ensure" (as you see, this is not my favorite reason for writing unit
tests) the code works. Code, test - pass, test - pass, test - pass. You
almost always evaluate your code against the whole Specification, since
it is usually easier than selecting what to evaluate each time, plus,
you get more confidence this way that you did not break by mistake
something that is already working. So, this is really: Code, Test - all
pass, test - all pass, test - all pass... Hopefully, you use some kind of
snippets mechanism for creating new Statements, but if not (and many do
not actually do this), once in a while, you do something like this:

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

And you do not even notice that this will not be evaluated with the rest
of the Specification, because it already consists of so many Statements
that it is almost irrational to search for your added Statement in the
list and make sure it is there each time. Also, note that the fact that
you omitted the addition, does not disturb your work flow: test - all
pass, test - all pass, test - all pass... In other words, your process
does not give you any feedback on your mistake. So, what you end up is
a Statement that not only will never be false - **it will never be
evaluated**.

How does treating tests as Statements and evaluating them before making
them true help here? **Because then, a Statement that starts off being
evaluated as true is what DOES disturb your work flow.** In TDD, the
work flow is: Statement - unfulfilled - fulfilled (ok, and refactor, but
for the sake of THIS discussion, it does not matter so much), Statement
- unfulfilled - fulfilled, Statement - unfulfilled - fulfilled... So every
time you fail to see the “unfulfilled" stage, you get feedback from your
process that something suspicious is happening. This lets you
investigate and, if necessary, fix the situation at hand.

#### 2. Misplacing mock setup

Ok, this may sound even funnier (well, honestly, most mistakes sound
funny), but it also happened to me a couple of times, so it makes sense
to mention it. The example I am going to show uses manual mocks, but
this can happen with dynamic mocks as well, especially if you are in
a hurry.

Let us take a look at the following Statement saying that setting
a value higher than allowed to a field of a frame should produce error
result:

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

Note how the method `PerformForTimeSlotIn()`, which triggers the
specified behavior is accidentally called BEFORE the mock is actually
set up and the set up return value is never taken into account. By some
strange coincidence, this error did not alter the expected end result so
we did not even notice. It sometimes turns out like this, most often in
case of various boundary values (nulls etc.).

#### 3. Using static data inside production code

Once in a while, you have to jump in and add some new Statements to some
class Specification and some logic to the class itself. Let us assume
that the class and its existing specification was written by someone
else. Imagine this code is a wrapper around your product XML
configuration file. You decide to write your Statements AFTER applying
the changes (“well", you can say, “I am all protected by the
Specification that is already in place, so I can make my change without
risking regression, then just test my changes and it is all good...").

So, you start writing the new Statement. The Specification class already
contains a field member like this:

```csharp
public class XmlConfigurationSpecification
{
  XmlConfiguration config = new XmlConfiguration(xmlFixtureString);
  
  //...
  //...
```

What it does is to set up an object used by every Statement. So, each
Statement uses a `config` object initialized with the same
`xmlConfiguration` string value. The string is already pretty huge and
messy, since it was made to contain what is required by all existing
Statements. You need to write tests for is a little corner case that
does not need all this crap that is inside this string. So, you decide
to start fresh and create a separate object of `XmlConfiguration` class
with your own, minimal string. Your Statement begins like this:

```csharp
string customFixture = CreateMyOwnFixtureForThisTestOnly();
var configuration = new XmlConfiguration(customFixture);
...
```

And it passes - cool... not. Ok, what is wrong with this? Nothing big,
unless you read the source code of XmlConfiguration class carefully.
Inside, you can see, how the xml string is stored:

```csharp
private static string xmlText; //note the static keyword!
```

What the...? Well, well, here is what happened: the author of this class
coded in a small little optimization. He thought: “In this app, the
configuration is only modified by members of the support staff and to do
it, they have to shut down the system, so, there is no need to read the
XML file every time an XmlConfiguration object is created. I can save
some CPU cycles and I/O operations by reading it only once when the
first object is created. Another created object will just use the same
XML!". Good for him, not so good for you. Why? Because (unless your
Statement is evaluated prior to being fulfilled), your custom xml string
will never actually be used!

### “Test-After" ends up as “Test-Never" 

I will ask this question again: ever had to write a requirement or
design document for something that you already implemented? Was it fun?
Was it valuable? Was it creative? No, I do not think so. The same is
with our executable specification. After we write the code, we have
little motivation to specify what is already written - some of the
pieces of code “we can just see are correct", other pieces “we already
saw working" when we copied our code over to our deployment machine and
ran few sanity checks... The design is ready... Specification? Maybe next
time...

Another reason might be time pressure. Let us be honest - we are all in
a hurry, we are all under pressure and when this pressure is too high,
it triggers heroic behaviors in us, especially when there is a risk of
not making it with the sprint commitment. Such heroic behavior usually
goes by the following rules: drop all the “baggage", stop learning and
experimenting, revert to all of the old “safe" behaviors and “save what
we can!". If Specification is written at the end, it is often sacrificed
on the altar of making it with the commitment, since the code is already
written, “and it will be tested anyway by real tests" (box tests, smoke
tests, sanity tests etc.). It is quite the contrary when starting with
a Statement, where the Statement evaluating to false is **a reason** to
write any code. Thus, if we want to write code, Specification become
irremovable part of your development. By the way, I bet in big
corporations no one sane ever thinks they can abandon checking in the
code to source control, at the same time treating Specification as “an
optional addition".

### Not starting from specification leads to waste of time on making objects testable

It so happens, that I like watching and reading Uncle Bob. One day,
I was listening to [his keynote at Ruby Midwest 2011, called
Architecture The Lost
Years](http://www.confreaks.com/videos/759-rubymidwest2011-keynote-architecture-the-lost-years).
At the end, Robert made some digressions, one of them being about TDD.
He said that writing unit tests after the code is not TDD. It is a waste
of time.

My initial thought was that the comment was only about missing all the
benefits that starting with false Statement brings you: the ability to
see the Statement fail, the ability to do a clean-sheet analysis etc.,
however, now I am of opinion that there is more to it. It is something
I got from Amir Kolsky and Scott Bain - in order to be able to write
maintainable Specification for a piece of code, the code has to have
a high level of a quality called **testability** (we will talk about
testability later on, do not worry - for now let us assume that the
easier it is to write a Statement for a behavior of a class, the higher
testability it has). That does not tell us much about where is the waste
I mentioned, does it? To see it, let us see how dealing with testability
looks like in Statement-first workflow (let us assume that we are
creating new code, not adding stuff to dirty, ugly legacy code):

1.  Write false Statement (this step ensures that code has high
    testability)
2.  Write code to make the Statement true

Now, how does it usually look like when we write the code first (extra
steps marked with **strong text**):

1.  Write some production code (probably spans few classes until we are
    satisfied)
2.  **Start writing unit tests**
3.  **Notice that unit testing the whole set of classes is cumbersome
    and unsustainable and contains high redundancy.**
4.  **Restructure the code to be able to isolate objects and use mocks
    (this step ensures that code has high testability)**
5.  Write unit tests

What is the equivalent of the marked steps in Statement-first approach?
Nothing! Doing these things is a waste of time! Sadly, this is a waste
I see done over and over again.

Do you like wasting your time?
