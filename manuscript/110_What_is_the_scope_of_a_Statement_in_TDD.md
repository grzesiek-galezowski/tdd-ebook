# What is the scope of a unit-level Statement in TDD?

TODO add a short discussion about what is a scope.

Ha, now I have to admit that I have deferred for a long time the answer a pretty fundamental question: what should be the scope of a single Statement? If I put the whole system together, can I write a Statement for its behavior? Or maybe the other way round -- there should be a Statement for each method of each class, including the private ones? Well, first thing I want to explain is that there are multiple levels we can write our Statements on. This varies depending on the context of a specific system or solution. There seems to be no single answer to this question. In this book, we will cover two of such levels -- unit level and component level. For now, let's stick to the unit level, which is what we have done so far anyway. The time will come for the rest. For now, let's consider what should be the "scope" of a single unit-level Statement in TDD. Is it method scope? Class scope? Feature scope?

Let's try to answer the question by examining some TDD unit-level Statements:

## Is it class scope? 

Does a TDD Statement cover no more or less than a single class? Let's look at the first example of a valid Statement and try to answer this question:

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

This is an example of a well-written unit-level Statement. Ok, so let's see... how many real classes take part in this spec? Three: a string, an exception and the validation. On the other hand, there may be other features in the `Validation` class that are not specified in this Statement. So "specifying a class" (class scope) is not the most accurate description.

## Or a method scope?

So, maybe the scope covers a single method, meaning a Statement always exercises one method of a specified object?

Let's consider the following example of a "business rule" for some kind of queue. This rule is considered fulfilled when it is notified three times of something being queued on the queue (so in a bigger piucture, it's an observer of the queue) :

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

Count with me: how many methods are called? Depending on how we count, it is two methods (`Queued()` and `IsFulfilled()`) or four calls (`Queued(), Queued(), Queued(), IsFulfilled()`). In any case, not one. So it's not like we specify a single method here. Henve, a "method scope" is not an accurate explanation either.

## It is the scope of a behavior!

The proper answer is: behavior! Each TDD Statement specifies a single behavior (on unit level it means a class behavior). I like how [Amir Kolsky and Scott Bain](http://www.sustainabletdd.com/) phrase it, by saying that each unit-level Statement should "introduce a behavioral distinction not existing before".

Most of the time, I specify behaviors using the "GIVEN-WHEN-THEN" thinking framework. A behavior occurs in some kind of context and there are always some kind of results of that behavior.

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

There is no decisive answer to the second question as well. A behavior may span several classes (in part 2 of this book I'll tell you how I decide which classes should be included in such Statement) behavior scope does not necessarily have to be broader than class scope. Let's take the following example that proves it:

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

  //WHEN-THEN
  Assert.Throws<Exception>(
    () => call.Transmit(Any.InstanceOf<Frame>())
  );
}
```

Again, there are two behaviors here: reporting the call status after start and not being able to transmit frames after start. That is why this test should be split into two.

How to catch that you are writing a Statement about two or more behaviors rather than one? First, take a look at the test name -- if it looks strange and contains some "And" or "Or" words, it may (but does not have to) be about more than one behavior. Another way is to write the description of a behavior in a Given-When-Then way. If you have more than one item in the "When" section or the structure is not Given-When-Then, but rather a "Given-When-Then-When-Then" -- that is also a signal.


//TODO three rules by ken pugh
