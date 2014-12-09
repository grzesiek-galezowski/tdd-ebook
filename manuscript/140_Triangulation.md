
Triangulation
=============

### A disclaimer

The first occurence of the term triangulation I know about is in Kent
Beck’s book [Test Driven Development: By Example](http://www.pearsonhighered.com/educator/product/Test-Driven-Development-By-Example/9780321146533.page)).


As one of the last topics of the core TDD techniques that do not require
us to delve into the object oriented world, I’d like to show you
triangulation.

Triangulation is often described as the most conservative of three
approaches of test-driving implementation. These approaches are:

1.  Type the obvious implementation
2.  Fake it (‘til you make it)
3.  Triangulate

All of these techniques are simple (triangulaion being a little more
complex), so I’ll show you all of them one by one, putting more emphasis
on triangulation:

Type The Obvious Implementation 
-------------------------------

The first of the three techniques is just writing an obvious
implementation in response to a Statetement. If the implementation is
simple, this approach makes a lot of sense. Let’s take a trivial example
of adding two numbers:

```csharp
[Fact] public void
ShouldAddTwoNumbersTogether()
{
  //GIVEN
  var sum = new Sum();

  //WHEN
  var result = sum.Of(3,5);

  //THEN
  Assert.Equal(8, result);
}
```

You may remember I told you that usually we write the simplest
production code that would make the Statement true. This rule would
encourage us to just return 8 from the `Of` method, because it would be
sufficient to make the Statement true. Instead, we can decide that the
logic is so obvious, that we can just write it based on this one
Statement:

```csharp
public class Sum
{
  public int Of(int a, int b)
  {
    return a+b;
  }
}
```

and this is it.

Note that I didn’t use Constrained Non-Determinism here, because its use
enforces using “Just write obvious implementation" technique. In fact,
most (if not all) Statements we wrote so far in previous chapters, uses
this approach because of this fact. Let’s take a look at how the above
Statement would look if we used Constrained Non-Determinism:

```csharp
[Fact] public void
ShouldAddTwoNumbersTogether()
{
  //GIVEN
  var a = Any.Integer();
  var b = Any.Integer();
  var sum = new Sum();

  //WHEN
  var result = sum.Of(a,b);

  //THEN
  Assert.Equal(a + b, result);
}
```

Here, we don’t have any choice. The most obvious implementation that
would make this Statement true is the correct implementation. We are
unable to return some constant value as we previously could (but we did
not), because we just don’t know what the expected result is and it is
strictly dependent on the input values which we don’t know as well.

Fake It (‘Til You Make It)
--------------------------

This technique is kind of funny. I do not recall myself ever using it,
but it is so interesting I want to show it to you anyway. It is so
simple you will not regret these few minutes even if just for broadening
your horizons.

There are two core things that we need to pay attention when using these
technique:

1.  Start with the simplest implementation possible (i.e. fake it),
    which usually is returning a literal constant. Then gradually
    transform the code of both Statement and implementation using
    variables
2.  When doing it, rely on your sense of duplication between Statement
    and (fake) implementation

let's apply Fake It to the same addition example as before (I promise,
for triangulation, I will give you better one). The Statement looks the
same as before:

```csharp
[Fact] public void
ShouldAddTwoNumbersTogether()
{
  //GIVEN
  var sum = new Sum();

  //WHEN
  var result = sum.Of(3,5);

  //THEN
  Assert.Equal(8, result);
}
```

Only this time, we are going to use the simplest implementation
possible. As I wrote, this simplest implementation is almost always to
return a constant:

```csharp
public class Sum
{
  public int Of(int a, int b)
  {
    return 8;
  }
}
```

The Statement evaluates to true (green) now, though the implementation
is obviously wrong. BUT, the TDD cycle is not over yet. Remember that as
soon as the Statement is true, refactoring phase kicks in. This is
something we were ignoring silently for now (and here we will only
slightly lick it). We can use the refactoring phase to remove
duplication between the Statement and it's implementing code.

First, let's note that the number 8 is duplicated between Statement and
implementation -- the implementation returns it and the Statement asserts
on it. To reduce this duplication, let's break the 8 in the
implementation into a sum:

```csharp
public class Sum
{
  public int Of(int a, int b)
  {
    return 3 + 5;
  }
}
```

Note the smart trick I did. I changed duplication between implementation
and expected result to duplication between implementation and input
values of the Statement. After all, 3 and 5 are the exact values I used
in the Statement, right? This kind of duplication is different in that
it can be removed using variables (this applies not only to input
variables, but basically anything we have access to prior to triggering
specified behavior -- constructor parameters, fields etc. in contrast to
result which we normally do not know until we invoke the behavior). The
duplication of number 3 can be eliminated this way:

```csharp
public class Sum
{
  public int Of(int a, int b)
  {
    return a + 5;
  }
}
```

and we have just the number 5 duplicated, because we used variable to
transfer the value of 3 from Statement method to the `Of`
implementation, so we have it in one place now. let's do the same with
5:

```csharp
public class Sum
{
  public int Of(int a, int b)
  {
    return a + b;
  }
}
```

And that’s it. I used a trivial example, since I don’t want to spend too
much time on this, but you can find more advanced ones in Kent Beck’s
book if you like.

Triangulation
-------------

As I wrote, triangulation is the most conservative technique, because
following it involves the tiniest possible steps to arrive at the right
solution. The technique is called triangulation by analogy to [radar
triangulation](http://encyclopedia2.thefreedictionary.com/radar+triangulation)
where outputs from at least two radars must be used to determine the
position of a unit. Also, in radar triangulation, the position is
measured indirectly, by combining the following data: range (not
position!) between two radars, measurement done by each radar and the
positions of the radars (which we know, because we are the ones who put
the radars there). From this data, we can derive a triangle, so we can
use trigonometry to calculate the position of the third point of the
triangle, which is the desired position of the unit (two remaining
points are the positions of radars). Such measurement is indirect in
nature, because we do not measure the position directly, but calculate
it from other helper measurements.

These two characteristics: indirect measurement and using at least two
sources of information are at the core of TDD triangulation. Basically,
it says:

1.  **Indirect measurement**: derive the design from few known examples
    of its desired external behavior by looking at what varies in these
    examples and making this variability into something more general
2.  **Using at least two sources of information**: start with the
    simplest possible implementation and make it more general **only**
    when you have two or more different examples (i.e. Statements that
    describe the desired functionality for specific inputs). Then new
    examples can be added and generalization can be done again. This
    process is repeated until we reach the desired implementation.
    Robert C. Martin developed a maxim on this, saying that “As the
    tests get more specific, the code gets more generic.

Usually, when TDD is showcased on simple examples, triangulation is the
primary technique used, so many novices mistakenly believe TDD is all
about triangulation. This isn’t true, although triangulation is
important.

#### Example 

Suppose we want to write a logic that creates an aggregate sum of the
list. Let’s assume that we have no idea how to design the internals of
our custom list class so that it fulfills its responsibility. Thus, we
start with the simplest example of calculating a sum of 0 elements:

```csharp
[Fact] public void 
ShouldReturn0AsASumOfNoElements()
{
  //GIVEN
  var listWithAggregateOperations 
    = new ListWithAggregateOperations();

  //WHEN
  var result = listWithAggregateOperations.SumOfElements();

  //THEN
  Assert.Equal(0, result);
}
```

Remember we want to write just enough code to make the Statement true.
We can achieve it with just returning 0 from the `SumOfElements` method:

```csharp
public class ListWithAggregateOperations
{
  public int SumOfElements()
  {
    return 0;
  }
}
```

This is not yet the implementation we are happy with, which makes us add
another Statement -- this time for a single element:

```csharp
[Fact] public void 
ShouldReturnTheSameElementAsASumOfSingleElement()
{
  //GIVEN
  var singleElement = Any.Integer();
  var listWithAggregateOperations 
    = new ListWithAggregateOperations(singleElement);

  //WHEN
  var result = listWithAggregateOperations.SumOfElements();

  //THEN
  Assert.Equal(singleElement, result);
}
```

The naive implementation can be as follows:

```csharp
public class ListWithAggregateOperations
{
  int _element = 0;

  public ListWithAggregateOperations()
  {    
  }

  public ListWithAggregateOperations(int element)
  {
    _element = element;
  }

  public int SumOfElements()
  {
    return _element;
  }
}
```

We have two examples, so let's check whether we can generalize now. We
could try to get rid of the two constructors now, but let's wait just
a little bit longer and see if this is the right path to go (after all,
I told you that we need **at least** two examples).

Let’s add third example then. What would be the next more complex one?
Note that the choice of next example is not random. Triangulation is
about considering the axes of variability. If you carefully read the
last example, you probably noticed that we already skipped one axis of
variability -- the value of the element. We used `Any.Integer()` where we
could use a literal value and add a second example with another value to
make us turn it into variable. This time, however, I decided to **type
the obvious implementation**. The second axis of variability is the
number of elements. The third example will move us further along this
axis -- so it will use two elements instead of one or zero. This is how
it looks like:

```csharp
[Fact] public void 
ShouldReturnSumOfTwoElementsAsASumWhenTwoElementsAreSupplied()
{
  //GIVEN
  var firstElement = Any.Integer();
  var secondElement = Any.Integer();
  var listWithAggregateOperations 
    = new ListWithAggregateOperations(firstElement, secondElement);

  //WHEN
  var result = listWithAggregateOperations.SumOfElements();

  //THEN
  Assert.Equal(firstElement + secondElement, result);
}
```

And the naive implementation will look like this:

```csharp
public class ListWithAggregateOperations
{
  int _element1 = 0;
  int _element2 = 0;

  public ListWithAggregateOperations()
  {
  }

  public ListWithAggregateOperations(int element)
  {
    _element1 = element;
  }

  //added
  public ListWithAggregateOperations(int element1, int element2)
  {
    _element1 = element1;
    _element2 = element2;
  }

  public int SumOfElements()
  {
    return _element1 + _element2; //changed
  }
}
```

After adding and implementing the third example, the variability of
elements count becomes obvious. Now that we have three examples, we see
even more clearly that we have redundant constructors and redundant
fields for each element in the list and if we added a fourth example for
three elements, we’d have to add another constructor, another field and
another element of the sum computation. Time to generalize!

How do we encapsulate the variability of the element count so that we
can get rid of this redundancy? A collection! How do we generalize the
addition of multiple elements? A foreach loop through the collection!
Thankfully, C\# supports `params` keyword, that let's use it to remove
the redundant constructor like this:

```csharp
public class ListWithAggregateOperations
{
  int[] _elements;  

  public ListWithAggregateOperations(params int[] elements)
  {
    _elements = elements;
  }

  public int SumOfElements()
  {
    //changed
    int sum = 0;
    foreach(var element in _elements)
    {
      sum += element;
    }
    return sum;
  }
}
```

While the first Statement (“no elements") seems like a special case, the
remaining two -- for one and two elements -- seem to be just two
variations of the same behavior (“some elements"). Thus, it is a good
idea to make a more general Statement that describes this logic to
replace the two examples. After all, we don’t want more than one failure
for the same reason. So as the next step, I will write a Statement to
replace these examples (I leave them in though, until I get this one to
evaluate to true).

```csharp
[Fact]
public void 
ShouldReturnSumOfAllItsElementsWhenAskedForAggregateSum()
{
  //GIVEN
  var firstElement = Any.Integer();
  var secondElement = Any.Integer();
  var thirdElement = Any.Integer();
  var listWithAggregateOperations 
    = new ListWithAggregateOperations(
        firstElement, 
        secondElement, 
        thirdElement);

  //WHEN
  var result = listWithAggregateOperations.SumOfElements();

  //THEN
  Assert.Equal(
   firstElement + 
   secondElement + 
   thirdElement, result);
}
```

This Statement uses three values rather than zero, one or two as in the
examples we had. When I need to use collections with deterministic size
(and I do prefer to do it everywhere where using collection with
non-deterministic size would force me to use a `for` loop in my
Statement), I pick 3, which is the number I got from Mark Seemann and
the rationale is that 3 is the smallest number that has distinct head,
tail and middle element. One or two elements seem like a special case,
while three sounds generic enough.

One more thing we can do is to ensure that we didn’t write a **false
positive**, i.e. a Statement that is always true due to being badly
written. In other words, we need to ensure that the Statement we just
wrote will ever evaluate to false if the implementation is wrong. As we
wrote it after the implementation is in place, we do not have this
certainty.

What we will do is to modify the implementation slightly to make it
badly implemented and see how our Statement will react (we expect it to
evaluate to false):

```csharp
public int SumOfElements()
{
  //changed
  int sum = 0;
  foreach(var element in _elements)
  {
    sum += element;
  }
  return sum + 1; //modified with "+1"!
}
```

When we do this, we can see our last Statement evaluate to false with
a message like “expected 21, got 22". We can now undo this one little
change and go back to correct implementation.

The examples (“zero elements", “one element" and “two elements") still
evaluate to true, but it’s now safe to remove the last two, leaving only
the Statement about a behavior we expect when we calculate sum of no
elements and the Statement about N elements we just wrote.

And voilà! We have arrived at the final, generic solution. Note that the
steps we took were tiny -- so you might get the impression that the
effort was not worth it. Indeed, this example was only to show the
mechanics of triangulation -- in real life, if we encountered such simple
situation we’d know straight away what the design would be and we’d
start with the general Statement straight away and just type in the
obvious implementation. Triangulation shows its power in more complex
problems with multiple design axes and where taking tiny steps helps
avoid “analysis paralysis".

Summary
-------

As I stated before, triangulation is most useful when you have no idea how the internal design of a piece of functionality will look like (e.g. even if there are work-flows, they cannot be easily derived from your knowledge of the domain) and it’s not obvious along which axes your design must provide generality, but you are able to give some examples of the observable behavior of that functionality given certain inputs. These are usually situations where you need to slow down and take tiny steps that slowly bring you closer to the right design and functionality -- and that’s what triangulation is for!
