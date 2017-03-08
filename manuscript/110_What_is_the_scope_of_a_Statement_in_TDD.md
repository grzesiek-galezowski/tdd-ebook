# What is the scope of a unit-level Statement in TDD?

In previous chapters, I described how tests form a kind of excutable Specification consisting of many Statements. If so, then some fundamental questions regarding these Statements need to be raised, e.g.:

1. What goes into a single Statement?
1. How do I know that I need to write another Statement instead of expanding existing one?
1. When I see a Statement, how do I know whether it is too big, too small, or just enough?

This can be summarized as one more general question: what should be the scope of a single Statement?

## Scope and level

The software we write can be viewed in terms of structure and functionality. Functionality is about the features -- things something does and does not given certain circumstances. Structure is how this functionality is organized and divided between many subelements, e.g. subsystems, services, components, classes, methods etc. 

A structural element can easily handle several functionalities (either by itself or in cooperation with other elements). For example, many lists implement retrieving added items as well as some kind of searching or sorting. On the other hand, a single feature can easily span several structural elements (e.g. paying for a product in an online store will likely span at least several classes and probably touch a database).

Thus, when deciding what should go into a single Statement, we have to consider both structure and functionality and make the following decisions:

- structure -- do we specify what a class should do, or what the whole component should do, or maybe a Statement should be about the whole system? I will refer to such structural decision as "level".
- functionality -- should a single Statement specify everything that structural element does, or maybe only a part of it? If only a part, then which part and how big should that part be? I will refer to such functional decision as "functional scope".

Our questions from the beginning of the chapter can be rephrased as:

1. On what level do we specify our software?
1. What should be the functional scope of a single Statement?

## On what level do we specify our software?

The answer to the first question is relatively simple -- we specify on multiple levels. How many levels there are and which ones we're interested in depends very much on the specific type of application that we write and programming paradigm (e.g. in pure functional programming, we don't have classes).

In this (and next) chapter, I focus mostly on class level (I will refer to it as unit level, since a class is a unit of behavior), i.e. every Statement is written against a public API of a specified class[^unclebobdisagrees].

Does that mean that we can only use a single class in our executable Statement? Let's look at an example of a well-written Statement and try to answer this question:

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

What exactly is a behavior? If you read this book from the beginning, you've probably seen a lot of Statements that specify behaviors. Let me show you another one, though.

Let's consider an example of a class representing a condition for deciding whether some kind of queue is full or not. A single bahvior we can specify is that the condition is met when it is notified three times of something being queued on a queue (so from a bigger-picture point of view, it's an observer of the queue):

```csharp
[Fact] public void 
ShouldBeMetWhenNotifiedThreeTimesOfItemQueued()
{
  //GIVEN
  var condition = new FullQueueCondition();
  condition.NotifyItemQueued();
  condition.NotifyItemQueued();
  condition.NotifyItemQueued();

  //WHEN
  var isMet = condition.IsMet();

  //THEN
  Assert.True(isMet);
}
```

The first thing to note is that two methods are called on the `condition` object: `NotifyItemQueued()` (three times) and `IsMet()` (once). I consider this example educative because I have seen people misunderstand unit level as "specifying a single method". Sure, there is usually a single method triggering the behavior (in this case it's `isMet()`, placed in the `//WHEN` section), but sometimes, more calls are necessary to set up a preconditions for a given behavior (hence the three `Queued()` calls placed in the `//GIVEN` section).

The second thing to note is that the Statement only says what happens when the `condition` object is notified three times -- this is the specified behavior. What about the scenario where the `condition` is only notified two times and when asked afterwards, should say it isn't met? This is a separate behavior and should be described by a separate Statement. The ideal to which we strive is characterized by three rules by Amir Kolsky and cited by Ken Pugh in his book *Lean-Agile Acceptance Test-Driven Development*:

1. A Statement should turn false for well-defined reason.
1. No other Statement should turn false for the same reason.
1. A Statement should not turn false for any other reason.

While it's impossible to achieve it in literal sense (e.g. all Statements specifying the `FullQueueCondition` behaviors must call a constructor, so when I put a `throw new Exception()` inside it, all Statements will turn false), however we want to keep as close to this goal as possible. This way, each Statement will introduce that "behavioral distinction" I mentioned before, i.e. it will show a new way the class can be valuable to its users.

Most of the time, I specify behaviors using the "GIVEN-WHEN-THEN" thinking framework. A behavior is triggered (`WHEN`) in some kind of context (`GIVEN`) and there are always some kind of results (`THEN`) of that behavior.

## Failing to adhere to the three rules

The three rules I mentioned are derived from experience. Let's see what happens if we don't follow one of them.

Our next example is about some kind of buffer size rule. This rule is asked whether the buffer can handle a string of specified length and answers "yes" if this string is at most three-elements long. The writer of a Statement for this class decided to violate the rules we talked about and wrote something like this:

```csharp
[Fact] public void 
ShouldReportItCanHandleStringWithLengthOf3ButNotOf4AndNotNullString()
{
  //GIVEN
  var bufferSizeRule = new BufferSizeRule();

  //WHEN
  var resultForLengthOf3 
    = bufferSizeRule.CanHandle(Any.StringOfLength(3));
  //THEN
  Assert.True(resultForLengthOf3);

  //WHEN - again?
  var resultForLengthOf4 
    = bufferSizeRule.CanHandle(Any.StringOfLength(4))
  //THEN - again?
  Assert.False(resultForLengthOf4);

  //WHEN - again??
  var resultForNull = bufferSizeRule.CanHandle(null);
  //THEN - again??
  Assert.False(resultForNull);
}
```

Note that it specifies three behaviors:

1. Acceptance of a string of allowed size.
1. Refusal of handling a string of size above the allowed limit.
1. Special case of null string.

As such, the Statement breaks rules: 1 (A Statement should turn false for well-defined reason) and 3 (A Statement should not turn false for any other reason). In fact, there are three reasons that can make our Statement false.

There are several reasons to avoid writing Statements like this. Some of them are:

1. Most xUnit frameworks stop executing a Statement on first assertion failure. If the first assertion fails in the above Statement, we won't know whether the rest of the behaviors work fine until we fix the first one. 
1. Readability tends to be worse as well as the documentation value of our Specification (the names of such Statements tend to be far from helpful). 
1. Failure isolation is worse -- when a Statement turns false, we'd prefer to know exactly which behavior was broken. Statements such as the one above don't give us this advantage.
1. Throughout a single Statement we usually work with the same object. When we trigger multiple behaviors on it, we can't be sure how triggering one behavior impacts subsequent behaviors. If we have e.g. four behaviors in a single Statement, we can't be sure how the three earlier ones impact the last one. In the example above, we could get away with this, since the specified object returned its result based only on the input of a specific method (i.e. it did not contain any mutable state). Imagine, however, what could happen if we triggered multiple behaviors on a single list. Would we be sure that it does not contain any leftover element after we added some items, then deleted some, then sorted the list and deleted even more?

## How many assertions do I need?

A single assertion by definition checks a single specified condition. If a single Statement is about a single behavior, then what about assertions? Does "single behavior" mean I can only have a single assertion per Statement? That was mostly the case for the Statements you have already seen throughout this book, but not for all.

To tell you the truth, there is a straightforward answer to this question -- a rule that says: "have a single assertion per test". What is important to remember is that it applies to "logical assertions", as Robert C. Martin indicated[^CleanCode]. 

Before we go further, I'd like to introduce a distinction. A "physical assertion" is a single `AssertXXXXX()` call. A "logical assertion" is one or more physical assertions that together specify one logical condition. To further illustrate this distinction, I'd like to give you two examples of logical assertions.

### Logical assertion -- example #1

A good example would be an assertion that specifies that all items in a list are unique (i.e. the list contains no duplicates). XUnit.net does not have such an assertion by default, but we can imagine we have written something like that and called it `AssertHasUniqueItems()`. Here's some code that uses this assertion:

```csharp
//some hypothetical code for getting the list:
var list = GetList();

//invoking the assertion:
AssertHasUniqueItems(list);
```

Note that it's a single logical assertion, specifying a well-defined condition. If we peek into the implementation however, we will find the following code:

```csharp
public static void AssertHasUniqueItems<T>(List<T> list)
{
  for(var i = 0 ; i < list.Count ; i++)
  {
    for(var j = 0 ; j < list.Count ; j++)
    {
      if(i != j)
      {
        Assert.NotEqual(list[i], list[j]);
      }
    }
  }
}
```

Which already executes several physical assertions. If we knew the exact number of elements in collection, we could even use three `Assert.NotEqual()` assertions instead of `AssertHasUniqueItems()`:

```csharp
//some hypothetical code for getting the collection:
var list = GetLastThreeElements();

//invoking the assertions:
Assert.NotEqual(list[0], list[1]);
Assert.NotEqual(list[0], list[2]);
Assert.NotEqual(list[1], list[2]);
```

Is it still a single assertion? Physically no, but logically -- yes. There is still one logical thing these assertions specify and that is the uniqueness of the items in the list.

### Logical assertion -- example #2

Another example of a logical assertion is one that specifies exceptions: `Assert.Throws()`. We already encountered one like this in this chapter. Here is the code again:

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

Note that in this case, there are two physical assertions (`Assert.Throws()` and `Assert.True()`), but one intent -- to specify the exception that should be thrown. We may as well extract these two physical assertions into a single one with a meaningful name:

```csharp
[Fact] public void
ShouldThrowValidationExceptionWithFatalErrorLevelWhenValidatedStringIsEmpty()
{
  //GIVEN
  var validation = new Validation();

  //WHEN - THEN
  AssertFatalErrorIsThrownWhen(
    () => validation.ApplyTo(string.Empty) 
  );
}
```

So every time we have several physical assertions that can be (or are) extracted into a single assertion method with a meaningful name, I consider them a single logical assertion. There is always a gray area in what can be considered a "meaningful name" (but let's agree that `AssertAllConditionsAreMet()` is not a meaningful name, ok?). The rule of thumb is that this name should express our intent better and clearer than the bunch of assertions it hides. If we look again at the example of `AssertHasUniqueItems()` this assertion does a better job of expressing our intent than a set of three `Assert.NotEqual()`.

## Summary

In this chapter, we tried to find out how much should go into a single Statement. We examined the notions of level and functional scope to end up with a conclusion that a Statement should cover a single behavior. We backed this statement by three rules by Amir Kolsky and looked at an example of what could happen when we don't follow one of them. Finally, we discussed how the notion of "single Statement per behavior" is related to "single assertion per Statement".

[^CleanCode]: Clean Code movies, don't remember which episode -- please help me find it and report issue on github.
[^unclebobdisagrees]: Some disagree, however, with writing Statements on the class level - see http://blog.cleancoder.com/uncle-bob/2017/03/03/TDD-Harms-Architecture.html
