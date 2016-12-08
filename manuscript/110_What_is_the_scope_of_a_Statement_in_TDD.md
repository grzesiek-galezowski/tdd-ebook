# What is the scope of a unit-level Statement in TDD?

In previous chapters, I tried to explain how tests for a kind of excutable Specification consisting of many Statements. If so, then some fundamental questions regarding these Statements need to be raised, e.g.:

1. What goes into a single Statement?
1. Gow do I know that I need to write another Statement instead of expanding existing one?
1. When I see a Statement, how do I know whether it is too big, too small, or just enough?

This can be summarized as one more general question: what should be the scope of a single Statement?

## Scope and level

The software we write usually has two things: structure and functionality. Structure is how the code is organized, e.g. subsystems, services, components, classes, methods etc. Functionality is about the features - things something does and does not given certain circumstances. 

A structural element can easily handle several functionalities (either by itself or in cooperation with other elements). For example, many lists implement retrieving added items as well as some kind of searching. On the other hand, a single feature can easily span several structural elements (e.g. paying for a product in an online store will likely span at least several classes and may even touch some kind of database).

Thus, when deciding what should go into a single Statement, we have to consider both structure and functionality:
- structure - do we specify what a class should do, what the whole component should do, or maybe a Statement should be about the whole system? I will refer to such structural decision as "level".
- functionality - should a single Statement specify everything that structural element does, or maybe only a part of it? If only a part, then which part and how big should that part be? I will refer to such functional decision as "scope".

Our questions from the beginning of the chapter can be rephrased as:
1. On what level do we specify our software?
1. What should be the scope of a single Statement?

## On what level do we specify our software?

The answer to the first question is relatively simple - we specify on multiple levels. How many levels there are and which ones we're interested in depends very much on the specific type of application that we write. In this (and next) chapter, I focus mostly on class level (I will refer to it as unit level, since a class is a unit of behavior), i.e. every Statement was written against a public API of a specified class. 

Does that mean that we can only use a single class in our executable Statement? Let's look at the first example of a well-written Statement and try to answer this question:

```csharp
[Fact] public void
ShouldThrowValidationExceptionWithFatalErrorLevelWhenValidatedStringIsEmpty()
{
  //GIVEN
  var validation = new Validation();

  //WHEN
  var exceptionThrown = Assert.Throws<CustomException>(
    () => validation.ApplyTo(string.Empty) 
  );
  
  //THEN
  Assert.True(exceptionThrown.IsFatalError);
}
```

Ok, so let's see... how many real classes take part in this Statement? Three: a string, an exception and the validation. So even though this is a Statement written against the public API of `Validation` class, the API itself demands using objects of additional classes. 

## What should be the functional scope of a single Statement?

The short answer to this question is: behavior. Putting it together with the previous section, we can say that each unit-level Statement specifies a single behavior of a class written against public API of that class. I like how [Liz Keogh](https://lizkeogh.com/2012/05/30/showcasing-the-language-of-bdd/) says that a unit-level Statement shows one example of how a class is valuable to its users. Also, [Amir Kolsky and Scott Bain](http://www.sustainabletdd.com/) say that each Statement should "introduce a behavioral distinction not existing before".

If you read this book from the beginning, you've probably seen a lot of Statements that specify behaviors. Let me give you another one, though. 

Let's consider the following example of a "business rule" for some kind of queue. A single bahvior we can specify is that the rule is considered fulfilled when it is notified three times of something being queued on a queue (so from a bigger-picture point of view, it's an observer of a queue):

```csharp
[Fact] public void 
ShouldBeFulfilledWhenEventOccursThreeTimes()
{
  //GIVEN
  var rule = new FullQueueRule();
  rule.Queued();
  rule.Queued();
  rule.Queued();
  
  //WHEN
  var isRuleFulfilled = rule.IsFulfilled();

  //THEN
  Assert.True(isRuleFulfilled);
}
```

The first thing to note is that at two methods are called on the `rule` object: `Queued()` (three times) and `IsFulfilled()` once. I consider this example important because I have seen people misunderstand unit level as "specifying a single method". Sure, there is usually a single method triggering the behavior (in this case it's `isFulfilled()`, placed in the `//WHEN` section), but sometimes, more calls are necessary to set up a preconditions for a given behavior (hence the three `Queued()` calls placed in the `//GIVEN` section).

The second thing to note is that the Statement only says what happens when the `rule` object is notified three times. This is a single behavior. What about the scenario where the `rule` is only notified two times and when asked afterwards, should say it isn't fulfilled? This is a separate behavior and should be written as a separate Statement. The ideal to which we strive is characterized by three rules by Amir Kolsky and cited by Ken Pugh in his book Lean-Agile Acceptance Test-Driven Development:

1. A Statement should turn false for well-defined reason.
1. No other Statement should turn false for the same reason.
1. A Statement should not turn false for any other reason.

While it's impossible to achieve it in literal sense (e.g. all Statements specifying the `FullQueueRule` behaviors must call a constructor, so when I put a `throw new Exception()` inside it, all Statements turn false), however we want to keep as close to this goal as possible. This way, each Statement will introduce that "behavioral distinction" we talked before, i.e. show a new way the class can be valuable to its users.

Most of the time, I specify behaviors using the "GIVEN-WHEN-THEN" thinking framework. A behavior is triggered (`WHEN`) in some kind of context (`GIVEN`) and there are always some kind of results (`THEN`) of that behavior.


## Failing to adhere to the three rules

The three rules I mentioned are derived from practical means. Let's see what happens if we don't follow them.

//TODO
//TODO
//TODO
//TODO
//TODO
//TODO
//TODO

Here goes the first example of a Statement that specifies something about some kind.........

```csharp
[Fact] public void 
ShouldReportItCanHandleStringWithLengthOf3ButNotOf4AndNotNullString()
{
  //GIVEN
  var bufferSizeRule = new BufferSizeRule();
  
  //WHEN
  var resultForLength3 
    = bufferSizeRule.CanHandle(Any.StringOfLength(3));
  //THEN
  Assert.True(resultForLength3);

  //WHEN - again?
  var resultForLength4 
    = bufferSizeRule.CanHandle(Any.StringOfLength(4))
  //THEN - again?
  Assert.False(resultForLength4);

  //WHEN - again??
  var resultForNull = bufferSizeRule.CanHandle(null);
  //THEN - again??
  Assert.False(resultForNull);
}
```

Note that it specifies three (or two -- depending on how you count) behaviors: 

1. acceptance of string of allowed size
1. refusal of handling string above the allowed size 
1. special case of null string. 

I consider the above example a good one for showing why I (and many others) prefer behavior scope over a method scope. The issue with the above Statement is that it can turn false for at least two reasons -- when the allowed string size changes and when the reaction to null input is different. Also, xUnit tools by default stop execution on first error, so, assuming that the first assertion fails, we won't know the outcome of the next assertion unless we fix the previous one (does that mean we always have to use a single `Assert` per Statement? We will take care of this question in a second. For now, let the answer be: "not necessarily").

By the way, this Statement is an example of an antipattern that some call a ["check-it-all test"](http://blog.typemock.com/2012/08/the-test-you-regret-the-check-it-all.html)




## It is the scope of a behavior!



## How does behavior scope relate to other scopes?

Both examples (validation and filling a queue) I gave in this chapter were Statements that described behaviors and showed that this kind of scope is different from method or class scope. Two more interesting questions about behavior scope may arise from all this discussion:

1. Is it broader or narrower than method scope?
1. Is it broader or narrower than class scope?

As usual, let's try to answer these questions one by one.

### behavior scope vs method scope

It may look that behavior scope is broader than method scope, since such behaviors may span multiple classes and multiple methods. In some situations this may be right, but not in the general case. That is because a Statement with method scope can span multiple behaviors (which, by the way, is a sign of a very poorly written Statement). Let's take a look at an example:

```csharp
[Fact] public void 
ShouldReportItCanHandleStringWithLengthOf3ButNotOf4AndNotNullString()
{
  //GIVEN
  var bufferSizeRule = new BufferSizeRule();
  
  //WHEN
  var resultForLength3 
    = bufferSizeRule.CanHandle(Any.StringOfLength(3));
  //THEN
  Assert.True(resultForLength3);

  //WHEN - again?
  var resultForLength4 
    = bufferSizeRule.CanHandle(Any.StringOfLength(4))
  //THEN - again?
  Assert.False(resultForLength4);

  //WHEN - again??
  var resultForNull = bufferSizeRule.CanHandle(null);
  //THEN - again??
  Assert.False(resultForNull);
}
```

Note that it specifies three (or two -- depending on how you count) behaviors: 

1. acceptance of string of allowed size
1. refusal of handling string above the allowed size 
1. special case of null string. 

I consider the above example a good one for showing why I (and many others) prefer behavior scope over a method scope. The issue with the above Statement is that it can turn false for at least two reasons -- when the allowed string size changes and when the reaction to null input is different. Also, xUnit tools by default stop execution on first error, so, assuming that the first assertion fails, we won't know the outcome of the next assertion unless we fix the previous one (does that mean we always have to use a single `Assert` per Statement? We will take care of this question in a second. For now, let the answer be: "not necessarily").

By the way, this Statement is an example of an antipattern that some call a ["check-it-all test"](http://blog.typemock.com/2012/08/the-test-you-regret-the-check-it-all.html)

### behavior scope vs class scope

There is no decisive answer to the second question as well. A behavior may span several classes (in part 2 of this book I'll tell you how I decide which classes should be included in such Statementand which should not) and a single class may contain many behaviors. 

As an example, let's imagine we have a class that represents a telecom call (in this case, it's a digital call). Let's call it  `DigitalCall`. Instances of this class can be used to start and monitor the status of a real call as well as transmit a voice frame over the wire.

Now, a Statement with a class scope for a `DigitalCall` class would look like this:

```csharp
[Fact] public void
ShouldReportItIsStartedAndItDoesNotYetTransmitVoiceWhenItStarts()
{
  //GIVEN
  var call = new DigitalCall();
  call.Start();
 
  //WHEN
  var callStarted = call.IsStarted;
  
  //THEN 
  Assert.True(callStarted);

  //WHEN-THEN - second behavior
  Assert.Throws<Exception>(
    () => call.Transmit(Any.InstanceOf<Frame>())
  );
}
```

Again, there are two behaviors here: reporting the call status after it's started and not being able to transmit voice frames after start. That's why this test should be split into two.

## How do we know we specify more than one behavior?

I don't know a strict answer to this question. In the end, there are always some cases where I have a dillema. Still, there are some guidelines that help me make my decision most of the time.

1. Take a look at the test name -- if it looks strange (e.g. is very long or very generic) and contains some "And" or "Or" words, it may (but does not have to) be about more than one behavior. 
2. You can try to write (or imagine) the description of a behavior in a Given-When-Then way. If you have more than one item in the "When" section or the structure is not Given-When-Then, but rather a "Given-When-Then-When-Then" -- that is also a signal.
3. If we have a Statement that specifies several behaviors, the whole Specification usually violates the three  


//TODO three rules cited by ken pugh from Amir Kolsky
//a test should fail for well-defined reason
//no other test should fail for the same reason
//a test should not fail for any other reason

//////////////////////////////////////////////////////////////////////////////////
## What should be the scope of a single Statement?

On the other hand, there may be other features in the `Validation` class that are not specified in this Statement. So "specifying a class" (class scope) is not the most accurate description.


TODO add a short discussion about what is a scope.

I have to admit that I have deferred for a long time the answer to very fundamental question: what should be the scope of a single Statement? If I put the whole system together, can I write a Statement for its behavior? Or maybe the other way round -- there should be a Statement for each method of each class, including the private ones? Well, first thing I want to explain is that there are multiple levels we can write our Statements on and each has its scope. This varies depending on the context of a specific system or solution. There seems to be no single answer to this question. In this book, we will cover two of such levels -- unit level and component level. For now, let's stick to the unit level, which is what we have done so far anyway. The time will come for the rest. For now, let's consider what should be the "scope" of a single unit-level Statement in TDD. Is it method scope? Class scope? Feature scope?

Let's try to answer the question by examining some TDD unit-level Statements:

## Is it class scope? 

Does a TDD Statement cover no more or less than a single class? 
