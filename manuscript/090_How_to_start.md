How to start?
=============

Whenever I sat down with someone who was about to write code in a Statement-first manner for the first time, the person would stare at the screen, then at me, then would say: “what now?". It is easy to say: “You know how to write code, you know how to write a unit test for it, just this time start with the latter rather than the first", but for many people, this is something that blocks them completely. If you are one of them, do not worry -- you are not alone. I decided to dedicate this chapter solely to techniques for kicking off a Statement when there is no code.

Start with a good name
----------------------

It may sound obvious, but some people are having serious trouble describing the behavior they expect from their code. If you can name the behavior, it is a great starting point.

I know not everybody pays attention to naming their Statements, mainly because the Statements are considered second-level citizens -- as long as they run and “prove the code does not contain defects", they are considered sufficient. We will take a look at some examples of bad names and then I'll go into some rules of good naming.

### Consequences of bad naming

Many people do not really care about how their Statements are named. This is a symptom of treating the Specification as garbage or leftovers -- this approach is dangerous, because it leads to bad, unmaintainable Specifications that look more like lumps of code put together accidentally in a haste than that they resemble living documentation. Imagine that your Specification consists of names like this:

-   `TrySendPacket()`
-   `TrySendPacket2()`
-   `testSendingManyPackets()`
-   `testWrongPacketOrder1()`
-   `testWrongPacketOrder2()`

and try for yourself how difficult it is to answer the following questions:

1.  How do you know what situation each Statement describes?
2.  How do you know whether the Statement describes a single situation, or several at the same time?
3.  How do you know whether the assertions inside those Statements are really the right ones assuming each Statement was written by someone else or a long time ago?
4.  How do you know whether the Statement should stay or be removed when you modify the functionality it specifies?
5.  If your changes in production code make a Statement evaluate to false, how do you know whether the Statement is no longer correct or the production code is wrong?
6.  How do you know whether you will not introduce a duplicate Statement for a behavior when adding to a Specification that was originally created by another team member?
7.  How do you estimate, by looking at the runner tool report, whether the fix for a failing Statement will be easy or not?
8.  What do you answer new developers in your team when they ask you “what is this Statement for?"
9.  How can you keep track of the Statements already made about the specified class and those still to make?

### What does a good name contain? 

To be of any use, the name of a Statement has to describe its expected behavior. At the minimum, it should describe what happens under what circumstances. Let's take a look at one of the names Steve Freeman and Nat Pryce came up with in their great book Growing Object-Oriented Software Guided By Tests: 

```java
notifiesListenersThatServerIsUnavailableWhenCannotConnectToItsMonitoringPort()
```

Note a few things about the name of the Statement:

1.  It describes a behavior of an instance of a specific class. Note that it does not contain the name of the method that triggers the behavior, because what is specified is not a single method, but the behavior itself. The Statement name simply tells what an instance does (“notifies listeners that server is unavailable") under certain circumstances (“when cannot connect to its monitoring port"). It is important because you can derive such a description from thinking about the responsibilities of a class without the need to know any of its method signature or the code that is inside the class. Hence, this is something you can come up with before implementing -- you just need to know why you created this class and build on this knowledge.
2.  The name is relatively long. Really, really, **really** do not worry about it. As long as you are describing a single behavior, it's fine. I know people usually are hesitant to give long names to Statements, because they try to apply the same rules to those names as to method names in production code (and in production code a long method name can be a sign that the method has too many responsibilities). Let me make it clear -- these two cases are different. In case of Statements, the methods are not invoked by anyone besides the automatic test runner, so they will not obfuscate any code that would need to call them with their long names. Sure, we could put all the information in a comment instead of the Statement name and leave the name short, like this:

    ```csharp
    [Fact]
    //Notifies listeners that server 
    //is unavailable when cannot connect
    //to its monitoring port
    public void Statement_002()
    {
      //...
    }
    ```
    
    There are two downsides to this. We now have to add extra information (`Statement_002`) specifically for the compiler, because every method needs to have a name -- there is usually no value a human could derive from such a name. The second downside is that when the Statement evaluates to false, the test runner shows the following line: `Statement_002: FAILED` -- note that all the information included in the comment is missing from the failure report. It is really better to receive a report like:

    `notifiesListenersThatServerIsUnavailableWhenCannotConnectToItsMonitoringPort: FAILED`

    because then a lot of information about the Statement that fails is available from the test runner window.

3.  Using a name that describes a single behavior allows you to track quickly why the Statement is false when it is. Suppose a Statement is true when you start refactoring, but at one point it starts being evaluated as false and the report in the runner looks like this: `TrySendingHttpRequest: FAILED` -- it tells you that an attempt is made to send a HTTP request, but, for instance, does not tell you whether the object you specified is the sender that should try to send this request under some circumstances, or if it is the receiver that should handle such a request properly. To learn what went wrong, you have to go to the Statement body and scan its source code. Now compare the Statement name to the following one: `ShouldRespondWithAnAckWheneverItReceivesAHttpRequest`. Now when it evaluates to false, you can tell what is broken -- the object no longer responds with an ACK to an HTTP request. This may be enough to identify which part of the code is at fault.

### My favourite convention

There are many conventions for naming Statements appropriately. My favorite is the one [developed by Dan North](http://dannorth.net/introducing-bdd/), where each Statement name begin with the word `Should`. So for example, I would name a Statement:

`ShouldReportAllErrorsSortedAlphabeticallyWhenErrorsOccurDuringSearch()`

The name of the Specification (i.e. class name) answers the question “who should do it?", i.e. when I have a class named `SortingOperation` and want to say that it “should sort all items in ascending order when performed", I say it like this:

```csharp
public class SortingOperationSpecification
{
 [Fact] public void
 ShouldSortAllItemsInAscendingOrderWhenPerformed()
 {
 }
}
```

The word "should" was introduced by Dan to weaken the statement following it and thus to allow questioning what you are stating and ask yourself the question: "should it really?". If this causes uncertainty, then it is high time to talk to a domain expert and make sure you understand well what you need to accomplish. If you are not a native English speaker, the “should" prefix will probably have a weaker influence on you -- this is one of the reasons why I don't insist on you using it. I like it though[^argumentsagainstshould].

When devising a name, it is important to put the main focus on what result or action is expected from an object. If you do not do that, it'll quickly become troublesome. As an example, one of my colleagues was specifying a class `UserId` and wrote the following name for the Statement about the comparison of two identifiers:

`EqualOperationShouldPassForTwoInstancesWithTheSameUserName()`.

Note that this is not from the perspective of a single object, but rather from the perspective of an operation that is executed on it. We stopped thinking in terms of object responsibilities and started thinking in terms of operation correctness. To reflect a Statement, this name should be something more like:

`ShouldReportThatItIsEqualToAnotherIdThatHasTheSameUserName()`.

When I find myself having trouble with naming like this, I suspect one of the following may be the case:

1.  I am not specifying a behavior of a class, but rather the outcome of a method.
2.  I am specifying more than one behavior.
3.  The behavior is too complicated and hence I need to change my design (more on this later).
4.  I am naming the behavior of an abstraction that is too low-level, putting too many details in the name. I usually only come to this conclusion when all the previous points fail me.

### But can't the name become too long?

A few paragraphs ago, I mentioned you shouldn't worry about the length of Statement names, but I have to admit that the name does become too long occasionally. A rule I try to follow is that the name of a Statement should be easier to read than its content. Thus, if it takes me less time to understand the point of a Statement by reading its body than by reading its name, then the name is too long. If this is the case, I try to apply the heuristics described above to find and fix the root cause of the problem. 

Start by filling the GIVEN-WHEN-THEN structure with the obvious
----------------------------------------------------------------

This is a technique that is applicable when you come up with a GIVEN-WHEN-THEN structure for the Statement or a good name for it (a GIVEN-WHEN-THEN structure can be easily derived from a good name and vice versa). Anyway, this technique is about taking the GIVEN, WHEN and THEN parts and translating them into code in an almost literal, brute-force way, and then adding all the missing pieces that are required for the code to compile and run.

### Example

Let's try this on a simple problem of comparing two users. We assume that two users should be equal to each other if they have the same name:

```gherkin
Given a user with any name
When I compare it to another user with the same name
Then it should appear equal to this other user
```

Let's start with the translation

The first line:

```gherkin
Given a user with any name
```

can be translated literally to code like this:

```csharp
var user = new User(anyName);
```

Then the second line:

```gherkin
When I compare it to another user with the same name
```

can be written as:

```csharp
user.Equals(anotherUserWithTheSameName);
```

Great! Now the last line:

```gherkin
Then it should appear equal to this other user
```

and its translation into the code:

```csharp 
Assert.True(areUsersEqual);
```

Ok, so now we have made the translation, let's summarize it and see what is missing to make this code compile:

```csharp
[Fact] public void 
ShouldAppearEqualToAnotherUserWithTheSameName()
{
  //GIVEN
  var user = new User(anyName);

  //WHEN
  user.Equals(anotherUserWithTheSameName);

  //THEN
  Assert.True(areUsersEqual);
}
```

As we expected, this will not compile. Notably, our compiler might point us towards the following gaps:

1.  Variable `anyName` is not declared.
2.  Object `anotherUserWithTheSameName` is not declared.
3.  Variable `areUsersEqual` is both not declared and it does not hold the comparison result.
4.  If this is our first Statement, we might not even have the `User` class defined at all.

The compiler created a kind of a small TODO list for us, which is nice. Note that while we do not have compiling code, filling the gaps boils down to making a few trivial declarations and assignments:

1.  `anyName` can be defined as:

    `var anyName = Any.String();`

2.  `anotherUserWithTheSameName` can be defined as:

    `var anotherUserWithTheSameName = new User(anyName);`

3.  `areUsersEqual` can be defined as follows:

    `var areUsersEqual = user.Equals(anotherUserWithTheSameName);`

4.  If class `User` does not yet exist, we can add it by simply stating:

    `public class User {}`

Putting it all together:

```csharp
[Fact] public void 
ShouldAppearEqualToAnotherUserWithTheSameName()
{
  //GIVEN
  var anyName = Any.String();
  var user = new User(anyName);
  var anotherUserWithTheSameName = new User(anyName);

  //WHEN
  var areUsersEqual = user.Equals(anotherUserWithTheSameName);

  //THEN
  Assert.True(areUsersEqual);
}
```

And that's it -- the Statement is complete!

Start from the end
------------------

This is a technique that I suggest to people that seem to have absolutely no idea how to start. I got it from Kent Beck’s book Test Driven Development by Example. It seems funny initially, but it is quite powerful. The trick is to write the Statement ‘backwards’, i.e. starting with what the Statement asserts to be true (in terms of the GIVEN-WHEN-THEN structure, we would say that we start with our THEN).

This works, because many times we are quite sure of what the outcome of the behavior should be, but are unsure of how to get there.

### Example

Imagine we are writing a class for granting access to a reporting functionality that is based on roles. We have no idea what the API should look like and how to write our Statement, but we do know one thing: in our domain the access can be either granted or denied. Let's take the first case we can think of and, starting backwards, begin with the following assertion:

```csharp
//THEN
Assert.True(accessGranted);
```

Ok, that part was easy, but did we make any progress with that? Of course we did -- we now have code that does not compile, with the error caused by the variable `accessGranted`. Now, in contrast to the previous approach where we translated a GIVEN-WHEN-THEN structure into a Statement, our goal is not to make this compile as soon as possible. Instead we are to answer the question: how do I know whether the access is granted or not? The answer: it is the result of authorization of the allowed role. Ok, so let's just write it down, ignoring everything that stands in our way:

```csharp
//WHEN
var accessGranted 
 = authorization.IsAccessToReportingGrantedTo(
  roleAllowedToUseReporting);
```

Resist the urge to define a class or variable as soon as it seems needed, as that will only throw you off the track and steal your focus from what is important. The key to doing TDD successfully is to learn to use something that does not exist yet as if it existed.

Note that we do not know what `roleAllowedToUseReporting` is, neither do we know what `authorization` is, but that did not stop us from writing this line. Also, the `IsAccessToReportingGrantedTo()` method is just taken off the top of our head. It is not defined anywhere, it just made sense to write it like this, because it is the most direct translation of what we had in mind.

Anyway, this new line answers the question about where we take the `accessGranted` from, but it also makes us ask further questions:

1.  Where does the `authorization` variable come from?
2.  Where does the `roleAllowedToUseReporting` variable come from?

As for `authorization`, we do not have anything specific to say about it other than that it is an object of a class that we do not yet have. To proceed, let's pretend that we have such a class. How do we call it? The instance name is `authorization`, so it is quite straightforward to name the class `Authorization` and instantiate it in the simplest way we can think of:

```csharp
//GIVEN
var authorization = new Authorization();
```

Now for the `roleAllowedToUseReporting`. The first question that comes to mind when looking at this is: which roles are allowed to use reporting? Let's assume that in our domain, this is either an Administrator or an Auditor. Thus, we know what is going to be the value of this variable. As for the type, there are various ways we can model a role, but the most obvious one for a type that has few possible values is an enum. So:

```csharp
//GIVEN
var roleAllowedToUseReporting = Any.Of(Roles.Admin, Roles.Auditor);
```

And so, working our way backwards, we have arrived at the final solution:

```csharp
[Fact] public void
ShouldAllowAccessToReportingWhenAskedForEitherAdministratorOrAuditor()
{
 //GIVEN
 var roleAllowedToUseReporting = Any.Of(Roles.Admin, Roles.Auditor);
 var authorization = new Authorization();

 //WHEN
 var accessGranted = authorization
  .IsAccessToReportingGrantedTo(roleAllowedToUseReporting);

 //THEN
 Assert.True(accessGranted);
}
```

We still need to give this Statement a name, but given what we already know this is an easy task.

Start by invoking a method if you have one
------------------------------------------

Sometimes, we have to add a new class that must implement an existing interface. The interface imposes what methods the new class must support. If this point is already decided, we can start our Statement by first calling the method and then discovering what we need to supply.

### Example

Suppose we have an application that, among other things, handles importing an existing database from another instance of the application. Given that the database is large and importing it can be a lengthy process, a message box is displayed each time a user performs the import. Assuming the user's name is Johnny, the message box displays the message “Johnny, please sit down and enjoy your coffee for a few minutes as we take time to import your database." The class that implements this looks like:

```csharp
public class FriendlyMessages
{
  public string 
  HoldOnASecondWhileWeImportYourDatabase(string userName)
  {
    return string.Format("{0}, "
      + "please sit down and enjoy your coffee "
      + "for a few minutes as we take time "
      + "to import your database",
      userName);
  }
}
```

Now, imagine that we want to ship a trial version of the application with some features disabled, one of which is importing a database. One of the things we need to do is to display a message saying that this is a trial version and that the import feature is locked. We can do this by extracting an interface from class `FriendlyMessages` and implement this interface in a new class that is used when the application is run as the trial version. The extracted interface looks like this:

```csharp
public interface Messages
{
  string HoldOnASecondWhileWeImportYourDatabase(string userName);
}
```

So our new implementation is forced to support the `HoldOnASecondWhileWeImportYourDatabase` method. When we implement the class, we start with the following:

```csharp
public class TrialVersionMessages : Messages
{
 public string HoldOnASecondWhileWeImportYourDatabase(string userName)
 {
   throw new NotImplementedException();
 }
}
```

Now, we are ready to start writing a Statement. Assuming we do not know where to start, we just start with creating an object and invoking the method that needs to be implemented:

```csharp
[Fact] 
public void TODO()
{
 //GIVEN
 var trialMessages = new TrialVersionMessages();
 
 //WHEN
 trialMessages.HoldOnASecondWhileWeImportYourDatabase();

 //THEN
 Assert.True(false); //to remember about it
}
```

As you can see, we added an assertion that always fails at the end to remind ourselves that the Statement is not finished yet. As we don't have any relevant assertions yet, the Statement would otherwise be evaluated as true and we might not notice that it's incomplete. However, as it stands the Statement does not compile anyway, because the method `HoldOnASecondWhileWeImportYourDatabase` takes a string argument and we didn't pass any. This makes us ask the question what this argument is and what its role is in the behavior triggered by method `HoldOnASecondWhileWeImportYourDatabase`. It looks like it is a user name and we want it to be somewhere in the result of the method. Thus, we can add it to the Statement like this:

```csharp
[Fact] 
public void TODO()
{
 //GIVEN
 var trialMessages = new TrialVersionMessages();
 var userName = Any.String();
 
 //WHEN
 trialMessages.
  HoldOnASecondWhileWeImportYourDatabase(userName);

 //THEN
 Assert.True(false); //to remember about it
}
```

Now, this compiles but is evaluated as false because of the guard assertion that we put at the end. Our goal is to substitute it with a proper assertion for the expected result. The return value of the call to `HoldOnASecondWhileWeImportYourDatabase` is a string message, so all we need to do is to come up with the message that we expect in case of the trial version:

```csharp
[Fact] 
public void TODO()
{
 //GIVEN
 var trialMessages = new TrialVersionMessages();
 var userName = Any.String();
 
 //WHEN
 var message = trialMessages.
  HoldOnASecondWhileWeImportYourDatabase(userName);

 //THEN
 var expectedMessage = 
  string.Format("{0}, better get some pocket money!", userName);

 Assert.Equal(expectedMessage, message);
}
```

All what is left is to find a good name for the Statement. This isn’t an issue since we already specified the desired behavior in the code, so we can just summarize it as something like `ShouldYieldAMessageSayingThatFeatureIsLockedWhenAskedForImportDatabaseMessage`.

Summary
-------

When you are stuck and do not know how to start, the techniques from this chapter may help to get you on your way. Note that the examples given are simplistic and assume that there is only one object that takes some kind of input parameter and returns a well defined result. However, this is not how most of the object-oriented world is built. There we have many objects that communicate with other objects, send messages, invoke methods on each other and that often do not return a value. Don't worry, all of these techniques also work there and we’ll revisit them as soon as we learn how to do TDD in the larger object-oriented world (after the introduction of the concept of mock objects). Here, I’ve tried to keep it simple.


[^argumentsagainstshould]: There are also some arguments against using the word "should", e.g. by Kevlin Henney (see https://vimeo.com/108007508).

