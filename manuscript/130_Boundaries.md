# Specifying Functional Boundaries and Conditions

I> ### A Disclaimer
I> 
I> Before I begin, I have to disclaim that this chapter draws from a series of posts by Scott Bain and Amir Kolsky from the blog Sustainable Test-Driven Development and their upcoming book by the same title. I like how they adapt the idea of [boundary testing](https://en.wikipedia.org/wiki/Boundary_testing) so much that I learned to follow the guidelines they outlined. This chapter is going to be a rephrase of these guidelines. I encourage you to read the original blog posts on this subject on http://www.sustainabletdd.com/ (and buy the upcoming book by Scott, Amir and Max Guernsey).

## Sometimes, an anonymous value is not enough

Anonymous values are useful when we specify a behavior, that should be the same no matter what arguments we pass to the constructor or invoked methods. An example would be pushing an integer onto a stack and popping it back to see whether it's the same item we pushed -- the behavior is consistent for whatever number we push and pop:

```csharp
[Fact] public void
ShouldPopLastPushedItem()
{
  //GIVEN
  var lastPushedItem = Any.Integer();
  var stack = new Stack<int>();
  stack.Push(Any.Integer());
  stack.Push(Any.Integer());
  stack.Push(lastPushedItem);

  //WHEN
  var poppedItem = stack.Pop();

  //THEN
  Assert.Equal(lastPushedItem, poppedItem);
}
```

In this case, the integer numbers can really be "any" -- the described relationship between input and output is independent of the actual values we use. As indicated in one of the previous chapters, this is the typical case where Constrained Non-Determinism applies.

Sometimes, however, specified objects exhibit different behaviors based on what is passed to their constructors or methods or what they get by calling other objects. For example:

- in our application we may have a licensing policy where a feature is allowed to be used only when the license is valid, and denied after it has expired. In such case, the behavior for dates before expiry date is different than after - the expiry date is the functional behavior boundary.
- Some shops are open from 10:00 to 18:00, so if we had a query in our application whether the shop is currently open, we would expect it to be answered differently based on what the current time is.
- An algorithm calculating the absolute value of an integer number returns the same number for inputs greater than or equal to `0` but negated input for negative numbers.

In such cases, Scott and Amir offer us other guidelines for choosing input values. I'll divide the explanation into three parts: 

1. specifying exceptions to the rules - where behavior is the same for every input values except one or more explicitly specified values,
2. specifying boundaries
3. specifying ranges - where there are more boundaries than one.

## Exceptions to the rule

There are times, when a Statement is true for every value except one (or more) explicitly specified. 

### Example 1: a single exception from a large set of values

Let's examine the following example: in some countries, some digits are skipped e.g. as floor numbers in some hospitals and hotels due to some local superstitions or just sounding similar to another word that has very negative meaning. One example of this is tetraphobia[^tetraphobia], which leads to skipping the digit `4`, as in some languages, it sounds similar to the word "death". In other words, anu number containing `4` is skipped. Let's imagine we have several such rules for our hotels in different parts of the world and we want the software to tell us if a certain number is allowed by local superstitions. One of our classes is called `Tetraphobia`:

```csharp
public class Tetraphobia : LocalSuperstition
{
  public bool Allows(char number)
  {
    throw new NotImplementedException("not implemented yet");
  }
}
```

It implements the `LocalSuperstition` interface which as the `AllowsInFloorNumber()`, so for the sake of compile-correctness we had to create the class and the method. Now that we have it, we want to test-drive the implementation. What Statements do we write?

Obviously we need a Statement that says what happens when we pass a disallowed number:

```csharp
[Fact] public void
ShouldReject4()
{
  //GIVEN
  var tetraphobia = new Tetraphobia();

  //WHEN
  var isFourAccepted = tetraphobia.Allows('4');

  //THEN
  Assert.False(isFourAccepted);
}
```

Note that we use the specific value for which the exceptional behavior takes place. It may be a very good idea to extract `4` into a constant. In one of the previous chapters, I described a technique called **Constant Specification**, where we write an explicit Statement about the value of the named constant and use the named constant everywhere else instead of its literal. So why did i not use this technique this time? The only reason is that this might have looked a little bit silly with such extremely trivial example. In reality, I should have used the named constant. Let's do this exercise now and see what happens.

```csharp
[Fact] public void
ShouldRejectSuperstitiousValue()
{
  //GIVEN
  var tetraphobia = new Tetraphobia();

  //WHEN
  var isSuperstitiousValueAccepted = 
    tetraphobia.Allows(Tetraphobia.SuperstitiousValue);

  //THEN
  Assert.False(isSuperstitiousValueAccepted);
}
```

When we do that, we have to document the named constant with the following Statement:

```csharp
[Fact] public void
ShouldReturn4AsSuperstitiousValue()
{
  Assert.Equal('4', Tetraphobia.SuperstitiousValue);
}
```

The next Statement is for all the other cases. Here, we are going to use a method of the `Any` class named `Any.OtherThan()`, that generates any value other than the one specified (and produces nice, readable code as a side effect):

```csharp
[Fact] public void
ShouldRejectSuperstitiousValue()
{
  //GIVEN
  var tetraphobia = new Tetraphobia();

  //WHEN
  var isNonSuperstitiousValueAccepted =
    tetraphobia.Allows(Any.OtherThan(Tetraphobia.SuperstitiousValue);

  //THEN
  Assert.True(isNonSuperstitiousValueAccepted);
}
```

and this is it - I don't usually write more Statements in such cases. There are so many possible input values that it would not be rational to specify all of them.

### Example 2: a single exception from a small set of values

The situation is different, however, in case where the exceptional value is chosen from a small set - this is often the case where the input value type is an enumeration. Let's go back to an example from one of our previous chapters, where we specified that there is some kind of reporting feature and it can be accessed by either an administrator role or by an auditor role. Let's modify this example for now and say that only administrators:

```csharp
[Fact] public void
ShouldAllowAccessToReportingWhenAskedForEitherAdministratorOrAuditor()
{
 //GIVEN
 var roleAllowedToUseReporting = Any.Of(Roles.Admin, Roles.Auditor);
 var access = new Access();

 //WHEN
 var accessGranted 
     = access.ToReportingIsGrantedTo(roleAllowedToUseReporting);

 //THEN
 Assert.True(accessGranted);
}
```

The example shown above assumes there is only one exception to the rule (the mediocre grade). However, this concept can be scaled up to more values, as long as it is a finished, discrete set.

TODO TODO TODO TODO TODO 

The example shown above assumes there is only one exception to the rule (the mediocre grade). However, this concept can be scaled up to more values, as long as it is a finished, discrete set. If there are multiple exceptional values that produce the same behavior, I usually try to cover them all with a single Statement using a parameterized Statement. In XUnit.Net this is achieved using `[Theory]` attribute with data specified as `[InlineData()]`:

```csharp
[Theory]
[InlineData(17, QueryResults.TooYoung)]
[InlineData(18, QueryResults.AllowedToApply)]
[InlineData(65, QueryResults.AllowedToApply)]
[InlineData(66, QueryResults.TooOld)]
public void ShouldYieldResultForAge(int age, QueryResults expectedResult)

```

a single Statement is sufficient to cover them all (using `Any` class and making the following call for exception Statement: `Any.Of(value1, value2)` and the following for the rest: `Any.OtherThan(value1, value2)`). However, when there are multiple exceptions to the rule and each one triggers a different behavior, each one deserves its own Statement.

Rules valid within boundaries
-----------------------------

Sometimes, a behavior varies around a numerical boundary. The simplest example would be a set of rules on how to calculate an absolute value of a number:

1.  for any X less than 0, the result is -X (e.g. absolute value of -1.5 is 1.5)
2.  for any X greater or equal to 0, the result is X (e.g. absolute value of 3 is 3).

As you can see, there is a boundary between the two behaviors and the right edge of the boundary is 0. Why do I say "right edge"? That is because the boundary always has two edges and there’s a length between them. If we assume we are talking about the mentioned absolute value calculation and that our numerical domain is that of integer numbers, we can as well use -1 as edge value and say that:

1.  for any X less or equal to -1, the result is -X (e.g. absolute value of -1.5 is 1.5)
2.  for any X greater than -1, the result is X (e.g. absolute value of 3 is 3).

So a boundary is not a single number -- it always has a length -- the length between last value of the previous behavior and the first value of the next behavior. In case of our example, the length between -1 (left edge -- last negated number) and 0 (right edge -- first non-negated) is 1.

Now, imagine that we are not talking about integer values anymore, but about floating point values. Then the right edge value would still be 0. But what about left edge? It would not be possible for it to stay -1, because the rule applies to e.g. -0.9 as well. So what is the correct right edge value and the correct length of the boundary? Would the length be 0.1? Or 0.001? Or maybe 0.00000001? This is harder to answer and depends heavily on the context, but it is something that must be answered for each particular case -- this way we know what kind of precision is expected of us. In our Specification, we have to document the boundary length somehow.

So the next topic is: how to describe the boundary length with Statements? To illustrate this, I want to show you two Statements assuming we’re implementing the mentioned absolute value calculation for integers. The first Statement is for values smaller than 0 and we want to use the left edge value here like this:

```csharp
[Fact] public void
ShouldNegateTheNumberWhenItIsLessThan0()
{
  //GIVEN
  var function = new AbsoluteValueCalculation();
  var lessThan0 = 0 - 1;

  //WHEN
  var result = function.PerformFor(lessThan0);

  //THEN
  Assert.Equal(-lessThan0, result);
}
```

And the next Statement for values at least 0 and we want to use the right edge value:

```csharp
[Fact] public void
ShouldNotNegateTheNumberWhenItIsGreaterOrEqualTo0()
{
  //GIVEN
  var function = new AbsoluteValueCalculation();
  var moreOrEqualTo0 = 0;

  //WHEN
  var result = function.PerformFor(moreOrEqualTo0);

  //THEN
  Assert.Equal(moreOrEqualTo0, result);
}
```

There are two things to note about these examples. The first one is that we don’t use any kind of `Any` methods. We explicitly take the edges, because they’re the numbers that most strictly define the boundary. This way we document the boundary length.

It is important to understand why we are not using methods like `Any.IntegerGreaterOrEqualTo(0)`, even though we do use `Any` in case when we have no boundary. This is because in the latter case, no value is better than the other in any particular way. In case of boundaries, however, the edge values are better in that they more strictly define the boundary and drive the right implementation.

The second thing to note is the usage of literal constant 0 in the above example. In one of the previous chapter, I showed you a technique called **Constant Specification**, where we write an explicit Statement about the value of the named constant and use the named constant everywhere else instead of its literal. So why did i not use this technique?

The only reason is that this might have looked a little bit silly with such extremely trivial example as calculating absolute value. In reality, I should have used the named constant in both Statements and it would show the boundary length even more clearly. Let's perform this exercise now and see what happens.

First, let's document the named constant with the following Statement:

```csharp
[Fact] public void
ShouldIncludeSmallestValueNotToNegateSetToZero()
{
  Assert.Equal(0, Constants.SmallestValueNotToNegate);
}
```

Now we have got everything we need to rewrite the two Statements we wrote earlier. The first would look like this:

```csharp
[Fact] public void
ShouldNegateTheNumberWhenItIsLessThanSmallestValueNotToNegate()
{
  //GIVEN
  var function = new AbsoluteValueCalculation();
  var lastNumberToNegate 
    = Constants.SmallestValueNotToNegate - 1;

  //WHEN
  var result = function.PerformFor(lastNumberToNegate);

  //THEN
  Assert.Equal(-lastNumberToNegate, result);
}
```

And the second Statement for values at least 0:

```csharp
[Fact] public void
ShouldNotNegateNumberWhenItIsGreaterOrEqualToSmallestValueNotToNegate()
{
  //GIVEN
  var function = new AbsoluteValueCalculation();

  //WHEN
  var result = function.PerformFor(
    Constants.SmallestValueNotToNegate
  );

  //THEN
  Assert.Equal(
    Constants.SmallestValueNotToNegate, result);
}
```

As you can see, the first Statement contains the following expression: `Constants.SmallestValueNotToNegate - 1`, where 1 is the exact length of the boundary. Like I said, the situation is so trivial that it may look silly and funny, however, in real life scenarios, this is a great technique to apply anytime, anywhere.

Boundaries may look like they apply only to integer input, but they occur at many other places. There are boundaries associated with date/time (e.g. an action is performed again when time from last action is at least 30 seconds -- the decision would need to be made whether we need precision in seconds or maybe in ticks), to strings (e.g. validation of user name where it must be at least 2 characters, or password that must contain at least 2 special characters) etc.

Combination of boundaries -- ranges
----------------------------------

So, what about a behavior that is valid in a range? Let's assume that we live in a country where a citizen can get a driving license only after their 17th birthday, but before 65th (the government decided that people after 65 have worse sight and it’s safer not to give them new driving licenses). Let's also assume that we try to develop a class that answers the question whether we can apply for driving license and the return values of this query are as follows:

1.  Age \< 17 -- returns enum value `QueryResults.TooYoung`
2.  17 \<= age \>= 65 -- returns enum value `QueryResults.AllowedToApply`
3.  Age \> 65 -- returns enum value `QueryResults.TooOld`

Now, remember I wrote that we specify the behaviors near boundaries? Such approach, however, when applied to the situation I just described, would give us the following Statements:

1.  Age = 17, should yield result `QueryResults.TooYoung`
2.  Age = 18, should yield result `QueryResults.AllowedToApply`
3.  Age = 65, should yield result `QueryResults.AllowedToApply`
4.  Age = 66, should yield result `QueryResults.TooOld`

thus, we would describe the behavior where the query should return `AllowedToApply` value twice, which effectively means that we would copy-paste the Statement and change just one value. How do we deal with this? Thankfully, we have a solution available:

Most xUnit frameworks provide some kind of data-driven test functionality, which we can use to write parameterized Statements. The functionality basically means that we can write the code of the Statement once, but make the xUnit framework invoke it twice with different sets of input values. Let’s see an example in XUnit.net:

```csharp
[Theory]
[InlineData(17, QueryResults.TooYoung)]
[InlineData(18, QueryResults.AllowedToApply)]
[InlineData(65, QueryResults.AllowedToApply)]
[InlineData(66, QueryResults.TooOld)]
public void ShouldYieldResultForAge(int age, QueryResults expectedResult)
{
  //GIVEN
  var query = new DrivingLicenseQuery();

  //WHEN
  var result = query.ExecuteFor(age);

  //THEN
  Assert.Equal(expectedResult, result);
}
```

This way, there is only one Statement executed four times. The case of `AllowedToApply` is still evaluated twice for both edge cases (so there is more time spent on executing it, which for small cases is not an issue), but the code maintenance issue is gone -- we don’t have to copy-paste the code to specify both edges of the behavior.

Note that we’re quite lucky because the specified logic is strictly functional (i.e. returns different results based on different inputs). Thanks to this, we could parameterize input values together with expected results. This is not always the case. For example, let's imagine that we have a clock class where we can set alarm time. The class allows us to set hour between 0 and 24, but otherwise throws an exception.

While some xUnit frameworks, like NUnit, allow us to handle both cases with one Statement by writing something like this:

```csharp
//NOTE: this is an example in NUnit framework!
[TestCase(Hours.Min, Result=Hours.Min)]
[TestCase(Hours.Max, Result=Hours.Max)]
[TestCase(Hours.Min-1, ExpectedException = typeof(OutOfRangeException))]
[TestCase(Hours.Max+1, ExpectedException = typeof(OutOfRangeException))]
public int 
ShouldBeAbleToSetHourBetweenMinAndMaxButNotOutsideThatRange(
  int inputHour)
{
  //GIVEN
  var clock = new Clock();
  clock.SetAlarmHour(inputHour);

  //WHEN
  var setHour = clock.GetAlarmHour();

  //THEN
  return setHour;
}
```

Others, like XUnit.NET, don’t (not that it’s a defect of the framework, it’s just that the philosophy behind those two is a little bit different and that some features have hidden price attached to their usage which some frameworks are willing to pay, while others aren’t). Thus, we have to solve it by writing two parameterized Statements -- one where a value is returned (for valid cases) and one where exception is thrown (for invalid cases). The first would look like this:

```csharp
[Theory]
[InlineData(Hours.Min)]
[InlineData(Hours.Max)]
public void 
ShouldBeAbleToSetHourBetweenMinAndMax(int inputHour)
{
  //GIVEN
  var clock = new Clock();
  clock.SetAlarmHour(inputHour);

  //WHEN
  var setHour = clock.GetAlarmHour();

  //THEN
  Assert.Equal(inputHour, setHour);
}
```

and the second:

```csharp
[Theory]
[InlineData(Hours.Min-1)]
[InlineData(Hours.Max+1)]
public void 
ShouldThrowOutOfRangeExceptionWhenTryingToSetAlarmHourOutsideValidRange(
  int inputHour)
{
  //GIVEN
  var clock = new Clock();

  //WHEN - THEN
  Assert.Throws<OutOfRangeException>( 
    ()=> clock.SetAlarmHour(inputHour)
  );
}
```

Summary
-------

In this chapter, we covered specifying numerical boundaries with a minimal amount of code, so that the Specification is more maintainable and runs fast. There is one more kind of situation left: when we have compound conditions (e.g. a password must be at least 10 characters and contain at least 2 special characters) -- we’ll get back to those when we introduce mocks.


[^tetraphobia]: TODO link to wikipedia