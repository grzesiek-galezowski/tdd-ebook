# Developing a TDD style and Constrained Non-Determinism

In [one of the first chapters](#chapter-essential-tools), I introduced to you the idea of anonymous values generator. I showed you the `Any` class which I use for generating such values. Throughout the chapters that followed, I have used it quite extensively in many of the Statements I wrote.

The time has come to explain a little bit more about the underlying principles of using anonymous values in Statements. Along the way, we'll also examine developing a style of TDD.

## A style?

Yep. Why am I wasting your time writing about style instead of giving you the hardcore technical details? Here's my answer: before I started writing this tutorial, I read four or five books solely on TDD and maybe two others that contained chapters on TDD. All of this added up to about two or three thousands of paper pages, plus numerous posts on many blogs. And you know what I noticed? No two authors use exactly the same set of techniques for test-driving their code! I mean, sometimes, when you look at the techniques they suggest, two authorities contradict each other. As each authority has their followers, it isn't uncommon to observe and take part in discussions about whether this or that technique is better than a competing one or which technique is "a smell"[^mocks-are-not-stubs] and leads to trouble in the long run.

I've done a lot of this, too. I also tried to understand how come people praise techniques I (thought I) KNEW were wrong and led to disaster. Over time, I came to understand that this is not a "technique A vs. technique B" debate. There are certain sets of techniques that work together and symbiotically enhance each other. Choosing one technique leaves us with issues we have to resolve by adopting other techniques. This is how a style is developed.

Developing a style starts with a set of problems to solve and an underlying set of principles we consider important. These principles lead us to adopt our first technique, which makes us adopt another one and, ultimately, a coherent style emerges. Using Constrained Non-Determinism as an example, I will try to show you how part of a style gets derived from a technique that is derived from a principle.

## Principle: Tests As Specification

As I already stressed, I strongly believe that tests should constitute an executable specification. Thus, they should not only pass input values to an object and assert on the output, they should also convey to their reader the rules according to which objects and functions work. The following toy example shows a Statement where it isn't explicitly explained what the relationship between input and output is:

```csharp
[Fact] public void 
ShouldCreateBackupFileNameContainingPassedHostName()
{
  //GIVEN
  var fileNamePattern = new BackupFileNamePattern();
  
  //WHEN
  var name = fileNamePattern.ApplyTo("MY_HOST_NAME");
  
  //THEN
  Assert.Equal("backup_MY_HOST_NAME.zip", name);
}
```

Although in this case the relationship can be guessed quite easily, it still isn't explicitly stated, so in more complex scenarios it might not be as trivial to spot. Also, seeing code like that makes me ask questions like: 

* Is the `"backup_"` prefix always applied? What if I pass the prefix itself instead of `"MY_HOST_NAME"`? Will the name be `"backup_backup_.zip"`, or just `"backup_.zip"`? 
* Is this object responsible for any validation of passed string? If I pass `"MY HOST NAME"` (with spaces) will this throw an exception or just apply the formatting pattern as usual?
* Last but not least, what about letter casing? Why is `"MY_HOST_NAME"` written as an upper-case string? If I pass `"my_host_name"`, will it be rejected or accepted? Or maybe it will be automatically converted to upper case? 

This makes me adopt a first technique to provide my Statements with better support for the principle I follow.

## First technique: Anonymous Input

I can wrap the actual value `"MY_HOST_NAME"` with a method and give it a name that better documents the constraints imposed on it by the specified functionality. In this case, the `BackupFileNamePattern()` method should accept whatever string I feed it (the object is not responsible for input validation), so I will name the wrapping method `AnyString()`:

```csharp
[Fact] public void 
ShouldCreateBackupFileNameContainingPassedHostName()
{
  //GIVEN
  var hostName = AnyString();
  var fileNamePattern = new BackupFileNamePattern();
  
  //WHEN
  var name = fileNamePattern.ApplyTo(hostName);
  
  //THEN
  Assert.Equal("backup_MY_HOST_NAME.zip", name);
}

public string AnyString()
{
  return "MY_HOST_NAME";
}
```

By using **anonymous input**, I provided a better documentation of the input value. Here, I wrote `AnyString()`, but of course, there can be a situation where I use more constrained data, e.g. I would invent a method called `AnyAlphaNumericString()` if I was in need of a string that doesn't contain any characters other than letters and digits. 

I> ### Anonymous input and equivalence classes
I>
I> Note that this technique is useful only when we specify a behavior that should occur for all members of some kind of equivalence class. An example of equivalence class is "a string starting with a number" or "a positive integer" or "any legal URI". When a behavior should occur only for a single specific input value, there is no room for making it anonymous. Taking authorization as an example, when a certain behavior occurs only when the input value is `Users.Admin`, we have no useful equivalence class and we should just use the literal value of `Users.Admin`. On the other hand, for a behavior that occurs for all values other than `Users.Admin`, it makes sense to use a method like `AnyUserOtherThan(Users.Admin)` or even `AnyNonAdminUser()`, because this is a useful equivalence class.

Now that the Statement itself is freed from the knowledge of the concrete value of `hostName` variable, the concrete value of `"backup_MY_HOST_NAME.zip"` in the assertion looks kind of weird. That's because, there is still no clear indication of the kind of relationship between input and output and whether there is any at all (as it currently is, the Statement suggests that the result of the `ApplyTo()` is the same for any `hostName` value). This leads us to another technique.

## Second technique: Derived Values

To better document the relationship between input and output, we have to simply derive the expected value we assert on from the input value. Here is the same Statement with the assertion changed:

```csharp
[Fact] public void 
ShouldCreateBackupFileNameContainingPassedHostName()
{
  //GIVEN
  var hostName = AnyString();
  var fileNamePattern = new BackupFileNamePattern();
  
  //WHEN
  var name = fileNamePattern.ApplyTo(hostName);
  
  //THEN
  Assert.Equal($"backup_{hostName}.zip", name);
}
public string AnyString()
{
  return "MY_HOST_NAME";
}
```

This looks more like a part of specification, because we are documenting the format of the backup file name and show which part of the format is variable and which part is fixed. This is something you would probably find documented in a paper specification for the application you are writing -- it would probably contain a sentence saying: "The format of a backup file should be **backup\_H.zip**, where **H** is the current local host name". What we used here was a **derived value**.

**Derived values** are about defining expected output in terms of the input that was passed to provide a clear indication on what kind of "transformation" the production code is required to perform on its input.

## Third technique: Distinct Generated Values

Let's assume that some time after our initial version is shipped, we are asked to change the backup feature so that it stores backed up data separately for each user that invokes this functionality. As the customer does not want to have any name conflicts between files created by different users, we are asked to add name of the user doing backup to the backup file name. Thus, the new format is **backup\_H\_U.zip**, where H is still the host name and U is the user name. Our Statement for the pattern must change as well to include this information. Of course, we are trying to use the anonymous input again as a proven technique and we end up with:

```csharp
[Fact] public void 
ShouldCreateBackupFileNameContainingPassedHostNameAndUserName()
{
  //GIVEN
  var hostName = AnyString();
  var userName = AnyString();
  var fileNamePattern = new BackupFileNamePattern();
  
  //WHEN
  var name = fileNamePattern.ApplyTo(hostName, userName);
  
  //THEN
  Assert.Equal($"backup_{hostName}_{userName}.zip", name);
}

public string AnyString()
{
  return "MY_HOST_NAME";
}
```

Now, we can clearly see that there is something wrong with this Statement. `AnyString()` is used twice and each time it returns the same value, which means that evaluating the Statement does not give us any guarantee, that both arguments of the `ApplyTo()` method are used and that they are used in the correct places. For example, the Statement will be considered true when user name value is used in place of a host name by the `ApplyTo()` method. This means that if we still want to use the anonymous input effectively without running into false positives[^false-positive], we have to make the two values distinct, e.g. like this:

```csharp
[Fact] public void 
ShouldCreateBackupFileNameContainingPassedHostNameAndUserName()
{
  //GIVEN
  var hostName = AnyString1();
  var userName = AnyString2(); //different value
  var fileNamePattern = new BackupFileNamePattern();
  
  //WHEN
  var name = fileNamePattern.ApplyTo(hostName, userName);
  
  //THEN
  Assert.Equal($"backup_{hostName}_{userName}.zip", name);
}

public string AnyString1()
{
  return "MY_HOST_NAME";
}

public string AnyString2()
{
  return "MY_USER_NAME";
}
```

We solved the problem (for now) by introducing another helper method. However, as you can see, this is not a very scalable solution. Thus, let's try to reduce the amount of helper methods for string generation to one and make it return a different value each time:

```csharp
[Fact] public void 
ShouldCreateBackupFileNameContainingPassedHostNameAndUserName()
{
  //GIVEN
  var hostName = AnyString();
  var userName = AnyString();
  var fileNamePattern = new BackupFileNamePattern();
  
  //WHEN
  var name = fileNamePattern.ApplyTo(hostName, userName);
  
  //THEN
  Assert.Equal($"backup_{hostName}_{userName}.zip", name);
}

public string AnyString()
{
  return Guid.NewGuid().ToString();
}
```

This time, the `AnyString()` method returns a guid instead of a human-readable text. Generating a new guid each time gives us a fairly strong guarantee that each value would be distinct. The string not being human-readable (contrary to something like `"MY_HOST_NAME"`) may leave you worried that maybe we are losing something, but hey, didn't we say **Any**String()?

**Distinct generated values** means that each time we generate an anonymous value, it's different (if possible) than the previous one and each such value is generated automatically using some kind of heuristics.

## Fourth technique: Constant Specification

Let's consider another modification that we are requested to make -- this time, the backup file name needs to contain version number of our application as well. Remembering that we want to use the derived values technique, we will not hardcode the version number into our Statement. Instead, we will use a constant that's already defined somewhere else in the application's production code (this way we also avoid duplication of this version number across the application). Let's imagine this version number is stored as a constant called `Number` in `Version` class. The Statement updated for the new requirements looks like this:

```csharp
[Fact] public void 
ShouldCreateBackupFileNameContainingPassedHostNameAndUserNameAndVersion()
{
  //GIVEN
  var hostName = AnyString();
  var userName = AnyString();
  var fileNamePattern = new BackupFileNamePattern();
  
  //WHEN
  var name = fileNamePattern.ApplyTo(hostName, userName);
  
  //THEN
  Assert.Equal(
    $"backup_{hostName}_{userName}_{Version.Number}.zip", name);
}

public string AnyString()
{
  return Guid.NewGuid().ToString();
}
```

Again, rather than a literal value of something like `5.0`, I used the `Version.Number` constant which holds the value. This allowed me to use a derived value in the assertion, but left me a little worried about whether the `Version.Number` itself is correct -- after all, I used the production code constant for creation of expected value. If I accidentally modified this constant in my code to an invalid value, the Statement would still be considered true, even though the behavior itself would be wrong.

To keep everyone happy, I usually solve this dillemma by writing a single Statement just for the constant to specify what the value should be:

```csharp
public class VersionSpecification
{
 [Fact] public void 
 ShouldContainNumberEqualTo1_0()
 {
   Assert.Equal("1.0", Version.Number);
 }
}
```

By doing so, I made sure that there is a Statement that will turn false whenever I accidentally change the value of `Version.Number`. This way, I don't have to worry about it in the rest of the Specification. As long as this Statement holds, the rest can use the constant from the production code without worries.

## Summary of the example 

By showing you this example, I tried to demonstrate how a style can evolve from the principles we believe in and constraints we encounter when applying those principles. I did so for two reasons:

1.  To introduce to you a set of techniques (although it would be more accurate to use the word "patterns") I personally use and recommend. Giving an example was the best way of describing them in a fluent and logical way that I could think of.
2.  To help you better communicate with people that are using different styles. Instead of just throwing "you are doing it wrong" at them, consider understanding their principles and how their techniques of choice support those principles.

Now, let's take a quick summary of all the techniques introduced in the backup file name example:

Derived Values
:   I define my expected output in terms of the input to document the relationship between input and output.

Anonymous Input
:   When I want to document the fact that a particular value is not relevant for the current Statement, I use a special method that produces the value for me. I name this method after the equivalence class that I need it to belong to (e.g. `Any.AlphaNumericString()`) and this way, I make my Statement agnostic of what particular value is used.     
    
Distinct Generated Values
:   When using anonymous input, I generate a distinct value each time (in case of types that have very few values, like boolean, try at least not to generate the same value twice in a row) to make the Statement more reliable. 
    
Constant Specification
:   I write a separate Statement for a constant to specify what its value should be. This way, I can use the constant instead of its literal value in all the other Statements to create a Derived Value without the risk that changing the value of the constant would not be detected by my executable Specification.

## Constrained non-determinism

When we combine anonymous input together with distinct generated values, we get something that is called **Constrained Non-Determinism**. This is a term [coined by Mark Seemann](http://blog.ploeh.dk/2009/03/05/ConstrainedNon-Determinism/) and basically means three things:

1.  Values are anonymous i.e. we don't know the actual value we are using.
2.  The values are generated in as distinct as possible sequence (which means that, whenever possible, no two values generated one after another hold the same value)
3.  The non-determinism in generation of the values is constrained, which means that the algorithms for generating values are carefully picked in order to provide values that belong to a specific equivalence class and that are not "evil" (e.g. when generating "any integer", we'd rather not allow generating ‘0' as it is usually a special-case-value that often deserves its own Statement).

There are multiple ways to implement constrained non-determinism. Mark Seemann himself has invented the AutoFixture library for C\# that is [freely available to download](https://github.com/AutoFixture/AutoFixture). Here is a shortest possible snippet to generate an anonymous integer using AutoFixture:

```csharp
Fixture fixture = new Fixture();
var anonymousInteger = fixture.Create<int>();
```

I, on the other hand, follow Amir Kolsky and Scott Bain, who recommend using `Any` class as seen in the previous chapters of this book. `Any` takes a slightly different approach than AutoFixture (although it uses AutoFixture internally). My implementation of `Any` class is [available to download as well](https://github.com/grzesiek-galezowski/tdd-toolkit).

## Summary

I hope that this chapter gave you some understanding of how different TDD styles came into existence and why I use some of the techniques I do (and how these techniques are not just a series of random choices). In the next chapters, I will try to introduce some more techniques to help you grow a bag of neat tricks -- a coherent style[^xunitpatterns].

[^mocks-are-not-stubs]: One of such articles can be found at https://martinfowler.com/articles/mocksArentStubs.html 
[^xunitpatterns]: For the biggest collection of such techniques, or more precisely, patterns, see XUnit Test Patterns by Gerard Meszaros.
[^false-positive]: A "false positive" is a test that should be failing but is passing.
