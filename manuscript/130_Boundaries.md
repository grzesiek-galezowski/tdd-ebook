# Specifying Functional Boundaries and Conditions

I> ### A Disclaimer
I> 
I> Before I begin, I have to disclaim that this chapter draws from a series of posts by Scott Bain and Amir Kolsky from the blog Sustainable Test-Driven Development and their upcoming book by the same title. I like how they adapt the idea of [boundary testing](https://en.wikipedia.org/wiki/Boundary_testing) so much that I learned to follow their guidelines. This chapter is going to be a rephrase of these guidelines. I encourage you to read the original blog posts on this subject on http://www.sustainabletdd.com/ (and buy the upcoming book by Scott, Amir and Max Guernsey).

## Sometimes, an anonymous value is not enough

In the last chapter, I described how anonymous values are useful when we specify a behavior that should be the same no matter what arguments we pass to the constructor or invoked methods. An example would be pushing an integer onto a stack and popping it back to see whether it's the same item we pushed -- the behavior is consistent for whatever number we push and pop:

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

In this case, the integer numbers can really be "any" -- the described relationship between input and output is independent of the actual values we use. As we saw in the last chapter, this is the typical case where we would apply Constrained Non-Determinism.

Sometimes, however, specified objects exhibit different behaviors based on what is passed to their constructors or methods or what they get by calling other objects. For example:

- in our application we may have a licensing policy where a feature is allowed to be used only when the license is valid, and denied after it has expired. In such case, the behavior before the expiry date is different than after -- the expiry date is the functional behavior boundary.
- Some shops are open from 10 AM to 6 PM, so if we had a query in our application whether the shop is currently open, we would expect it to be answered differently based on what the current time is. Again, the open and closed dates are functional behavior boundaries.
- An algorithm calculating the absolute value of an integer number returns the same number for inputs greater than or equal to `0` but negated input for negative numbers. Thus, `0` marks the functional boundary in this case.

In such cases, we need to carefully choose our input values to gain a sufficient confidence level while avoiding overspecifying the behaviors with too many Statements (which usually introduces penalties in both Specification run time and maintenance). Scott and Amir build on the proven practices from the testing community[^istqb] and give us some advice on how to pick the values. I'll describe these guidelines (slightly modified in several places) in three parts:

1. specifying exceptions to the rules -- where behavior is the same for every input values except one or more explicitly specified values,
2. specifying boundaries
3. specifying ranges -- where there are more boundaries than one.

## Exceptions to the rule

There are times when a Statement is true for every value except one (or several) explicitly specified. My approach varies a bit depending on the set of possible values and the number of exceptions. I'm ging to give you three examples to help you understand these variations better.

### Example 1: a single exception from a large set of values

In some countries, some digits are avoided e.g. in floor numbers in some hospitals and hotels due to some local superstitions or just sounding similar to another word that has very negative meaning. One example of this is /tetraphobia/[^tetraphobia], which leads to skipping the digit `4`, as in some languages, it sounds similar to the word "death". In other words, any number containing `4` is avoided and when you enter the building, you might not find a fourth floor (or fourteenth). Let's imagine we have several such rules for our hotels in different parts of the world and we want the software to tell us if a certain digit is allowed by local superstitions. One of these rules is to be implemented by a class called `Tetraphobia`:

```csharp
public class Tetraphobia : LocalSuperstition
{
  public bool Allows(char number)
  {
    throw new NotImplementedException("not implemented yet");
  }
}
```

It implements the `LocalSuperstition` interface which has an `Allows()` method, so for the sake of compile-correctness we had to create the class and the method. Now that we have it, we want to test-drive the implementation. What Statements do we write?

Obviously we need a Statement that says what happens when we pass a disallowed digit:

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

Note that we use the specific value for which the exceptional behavior takes place. Still, it may be a very good idea to extract `4` into a constant. In one of the previous chapters, I described a technique called **Constant Specification**, where we write an explicit Statement about the value of the named constant and use the named constant itself everywhere else instead of its literal value. So why did I not use this technique this time? The only reason is that this might have looked a little bit silly with such extremely trivial example. In reality, I should have used the named constant. Let's do this exercise now and see what happens.

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

Time for a Statement that describes the behavior for all non-exceptional values. This time, we are going to use a method of the `Any` class named `Any.OtherThan()`, that generates any value other than the one specified (and produces nice, readable code as a side effect):

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

and that's it -- I don't usually write more Statements in such cases. There are so many possible input values that it would not be rational to specify all of them. Drawing from Kent Beck's famouns comment from Stack Overflow[^kentconfidence], I think that our job is not to write as many Statements as we can, but as little as possible to truly document the system and give us a desired level of confidence.

### Example 2: a single exception from a small set of values

The situation is different, however, in when the exceptional value is chosen from a small set -- this is often the case where the input value type is an enumeration. Let's go back to an example from one of our previous chapters, where we specified that there is some kind of reporting feature and it can be accessed by either an administrator role or by an auditor role. Let's modify this example for now and say that only administrators are allowed to access reporting:

```csharp
[Fact] public void
ShouldGrantAdministratorsAccessToReporting()
{
 //GIVEN
 var access = new Access();

 //WHEN
 var accessGranted 
     = access.ToReportingIsGrantedTo(Roles.Admin);

 //THEN
 Assert.True(accessGranted);
}
```

The approach to this part is no different than what I did in the first example -- I wrote a Statement for the single exceptional value. Time to think about the other Statement -- the one that specifies what should happen for the rest of the roles. I'd like to describe two ways this task can be tackled.

The first way is to do it like in the previous example -- pick a value different than the exceptional one. This time we will use `Any.Besides()` method, which is best suited for enums:

```csharp
[Fact] public void
ShouldDenyAnyRoleOtherThanAdministratorAccessToReporting()
{
 //GIVEN
 var access = new Access();

 //WHEN
 var accessGranted 
     = access.ToReportingIsGrantedTo(Any.Besides(Roles.Admin));

 //THEN
 Assert.False(accessGranted);
}
```

This approach has two advantages:

1. Only one Statement is executed for the "access denied" case, so there is no significant run time penalty.
2. In case we expand our enum in the future, we don't have to modify this Statement -- the added enum member will get a chance to be picked up.

However, there is also one disadvantage -- we can't be sure the newly added enum member is used in this Statement. In the previous example, we didn't really care that much about the values that were used, because:

* `char` range was quite large so specifying the behaviors for all the values could prove troublesome and inefficient given our desired confidence level,
* `char` is a fixed set of values -- we can't expand `char` as we expand enums, so there is no need to worry about the future.

So what if there are only two more roles except `Roles.Admin`, e.g. `Auditor` and `CasualUser`? In such cases, I sometimes write a Statement that's executed against all the non-exceptional values, using XUnit.NET's `[Theory]` attribute that allows me to execute the same Statement code with different sets of arguments. An example here would be:

```csharp
[Theory]
[InlineData(Roles.Auditor)]
[InlineData(Roles.CasualUser)]
public void
ShouldDenyAnyRoleOtherThanAdministratorAccessToReporting(Roles role)
{
 //GIVEN
 var access = new Access();

 //WHEN
 var accessGranted 
     = access.ToReportingIsGrantedTo(role);

 //THEN
 Assert.False(accessGranted);
}
```

The Statement above is executed for both `Roles.Auditor` and `Roles.CasualUser`. The downside of this approach is that each time we expand an enumeration, we need to go back here and update the Statement. As I tend to forget such things, I try to keep at most one Statement in the system depending on the enum -- if I find more than one place where I vary my behavior based on values of a particular enumeration, I change the design to replace enum with polymorphism. Statements in TDD can be used as a tool to detect design issues and I'll provide a longer discussion on this in a later chapter.

### Example 3: More than one exception

The previous two examples assume there is only one exception to the rule. However, this concept can be extended to more values, as long as it is a finished, discrete set. If there are multiple exceptional values that produce the same behavior, I usually try to cover them all by using the mentioned `[Theory]` feature of Xunit.net. I'll demonstrate it by taking the previous example of granting access and assuming that this time, both administrator and auditor are allowed to use the feature. A Statement for behavior would look like this:

```csharp
[Theory]
[InlineData(Roles.Admin)]
[InlineData(Roles.Auditor)]
public void
ShouldAllowAccessToReportingBy(Roles role)
{
 //GIVEN
 var access = new Access();

 //WHEN
 var accessGranted 
     = access.ToReportingIsGrantedTo(role);

 //THEN
 Assert.False(accessGranted);
}
```

In the last example I used this approach for the non-exceptional values, saying that this is what I sometimes do. However, when specifying multiple exceptions to the rule, this is my default approach -- the nature of the exceptional values is that they are strictly specified, so I want them all to be included in my Specification.

This time, I'm not showing you the Statement for non-exceptional values as it follows the approach I outlined in the previous example.

## Rules valid within boundaries

Sometimes, a behavior varies around a boundary. The simplest example would be a set of rules on how to calculate an absolute value of a number:

1.  for any X less than `0`, the result is -X (e.g. absolute value of `-1.5` is `1.5`)
2.  for any X greater or equal to `0`, the result is X (e.g. absolute value of `3` is `3`).

As you can see, there is a boundary between the two behaviors. The right edge of this boundary is 0. Why do I say "right edge"? That is because the boundary always has two edges, which, by the way, also means it has a length. If we assume we are talking about the mentioned absolute value calculation and that our numerical domain is that of integer numbers, we can as well use `-1` instead of `0` as edge value and say that:

1.  for any X less or equal to `-1`, the result is -X (e.g. absolute value of `-1.5` is `1.5`)
2.  for any X greater than `-1`, the result is X (e.g. absolute value of `3` is `3`).

So a boundary is not a single number -- it always has a length -- the length between last value of the previous behavior and the first value of the next behavior. In case of our example, the length between `-1` (left edge -- last negated number) and `0` (right edge -- first non-negated) is `1`.

Now, imagine that we are not talking about integer values anymore, but about floating point values. Then the right edge value would still be `0`. But what about the left edge? It would not be possible for it to stay `-1`, because the rule would apply to e.g. `-0.9` as well. So what is the correct right edge value and the correct length of the boundary? Would the length be `0.1`? Or `0.001`? Or maybe `0.00000001`? This is harder to answer and depends heavily on the context, but it is something that must be answered for each particular case -- this way we know what kind of precision is expected of us. In our Specification, we have to document the boundary length somehow.

This brings an interesting question: how to describe the boundary length with Statements? To illustrate this, I want to show you two Statements describing the mentioned absolute value calculation for integers. The first Statement is for values smaller than 0 and we want to use the left edge value as our reference.

```csharp
[Fact] public void
ShouldNegateTheNumberWhenItIsLessThan0()
{
  //GIVEN
  var function = new AbsoluteValueCalculation();
  var lessThan0 = 0 - 1; //more on this later

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

There are two things to note about these examples. The first one is that I din’t use any kind of `Any` methods. I use `Any` in cases where I don't have a boundary or when I consider no value from an equivalence class better than others in any particular way. When I specify boundaries, however, instead of using methods like `Any.IntegerGreaterOrEqualTo(0)`, I use the edge values as I find that they more strictly define the boundary and drive the right implementation. Also, explicitly specifying the behaviors for the edge values allows me to document the boundary length.

The second thing to note is the usage of literal constant `0` in the example above. In one of the previous chapter, I described a technique called **Constant Specification** that is about writing an explicit Statement about the value of the named constant and use the named constant everywhere else instead of its literal. So why didn't I use this technique this time?

The only reason is that this might have looked a little bit silly with such extremely trivial example as calculating absolute value. In reality, I should have used the named constant in both Statements and it would show the boundary length even more clearly. Let's perform this exercise now and see what happens.

First, let's document the named constant with the following Statement:

```csharp
[Fact] public void
ShouldIncludeSmallestValueNotToNegateSetToZero()
{
  Assert.Equal(0, Constants.SmallestValueNotToNegate);
}
```

Now we've got everything we need to rewrite the two Statements we wrote earlier. The first would look like this:

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

As you can see, the first Statement contains the following expression: 

```csharp
Constants.SmallestValueNotToNegate - 1
```

where `1` is the exact length of the boundary. Like I said, the example is so trivial that it may look silly and funny, however, in real life scenarios, this is a technique I apply anytime, anywhere.

Boundaries may look like they apply only to numeric input, but they occur at many other places. There are boundaries associated with date/time (e.g. an action is performed again when time from last action is at least 30 seconds -- the decision would need to be made whether we need precision in seconds or maybe in ticks), to strings (e.g. validation of user name where it must be at least 2 characters, or password that must contain at least 2 special characters). They also apply to regular expressions. For example, for a simple regex `\d+`, we would surely specify for at least three values: an empty string, a single digit and a single non-digit.

## Combination of boundaries -- ranges

The previous examples focused on a single boundary. So, what about a situation when there are more, i.e. a behavior is valid within a range?

### Example -- driving license

Let's consider the following example: we live in a country where a citizen can get a driving license only after their 17th birthday, but before 65th (the government decided that people after 65 may have worse sight and that it's safer not to give them new driving licenses). Let's assume that are trying to develop a class that answers the question whether we can apply for driving license and the values returned by this query are as follows:

1. Age \< 17 -- returns enum value `QueryResults.TooYoung`
2. 17 \<= age \>= 65 -- returns enum value `QueryResults.AllowedToApply`
3. Age \> 65 -- returns enum value `QueryResults.TooOld`

Now, remember I wrote that I specify the behaviors with boundaries by using the edge values? This approach, when applied to the situation I just described, would give me the following Statements:

1. Age = 17, should yield result `QueryResults.TooYoung`
2. Age = 18, should yield result `QueryResults.AllowedToApply`
3. Age = 65, should yield result `QueryResults.AllowedToApply`
4. Age = 66, should yield result `QueryResults.TooOld`

thus, I would describe the behavior where the query should return `AllowedToApply` value twice, which effectively means that I would need to copy-paste the Statement and change just one value. How do we deal with this? Again, by using a parameterized Statement, i.e. the Xunit.net's `[Theory]` attribute. Thanks to it, we can write the code of the Statement once, but make the xUnit framework invoke it twice with different sets of input values. The code looks like this:

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

This way, thereI only need to werite a single method and by decorating it with `[InlineData]`, I make it executed four times with different values. The case of `AllowedToApply` is still evaluated twice for both edge cases (so there is more time spent on executing it, which for small cases is not an issue), but the code maintenance is easier -- we don’t have to copy-paste the code to specify both edges of the behavior in two separate Statements.

### Example -- setting an alarm

In the previous example, we were quite lucky because the specified logic was purely functional (i.e. it returned different results based on different inputs). Thanks to this, we could parameterize input values together with expected results. This is not always the case. For example, let's imagine that we have a `Clock` class that allows us to schedule an alarm. The class allows us to set the hour safely between 0 and 24, otherwise it throws an exception.

This time, I have to write two parameterized Statements -- one where a value is returned (for valid cases) and one where exception is thrown (for invalid cases). The first would look like this:

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

Other than that, I used exactly the same approach as the last time.

## Summary

In this chapter, I described specifying functional boundaries with a minimum amount of code and Statements, so that the Specification is more maintainable and runs faster. There is one more kind of situation left: when we have compound conditions (e.g. a password must be at least 10 characters and contain at least 2 special characters) -- we’ll get back to those when we introduce mock objects.


[^tetraphobia]: https://en.wikipedia.org/wiki/Tetraphobia
[^istqb]: see e.g. chapter 4.3 of ISQTB Foundation Level Syllabus at http://www.istqb.org/downloads/send/2-foundation-level-documents/3-foundation-level-syllabus-2011.html4
[^kentconfidence]: http://stackoverflow.com/a/153565
