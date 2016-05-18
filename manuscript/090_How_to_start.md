How to start?
=============

Whenever I sat down with someone who was about to write code in a Statement-first manner for the first time, the person would stare at the screen, then at me, then would say: "what now?". It's easy to say: "You know how to write code, you know how to write a test for it, just this time start with the latter rather than the first", but for many people, this is something that blocks them completely. If you are one of them, don't worry -- you're not alone. I decided to dedicate this chapter solely to techniques for kicking off a Statement when there is no code.

Start with a good name
----------------------

I already said that a Statement is a description of a behavior expressed in code. A thought process leading to creation of such an executable Statement might look like the following sequence of questions:

1.  What is the scope of the behavior I'm trying to specify? Example answer: I'm trying to specify a behavior of a `Calculator` class.
1.  What is the behavior of a `Calculator` class I'm trying to specify? Example answer: it should display all entered digits that are not leading zeroes.
1.  How to specify this behavior through code? Example answer: `[Fact] public void ShouldDisplayAllEnteredDigitsThatAreNotLeadingZeroes() ...` (i.e. a piece of code).

Note that before writing any code, there are at least two questions that can be answered in human language. Many times answering these questions first before starting to write the code of the Statement makes things easier. Even though, this can still be a challenging process. To apply this advice successfully, some knowledge on how to properly name Statements is required. I know not everybody pays attention to naming their Statements, mainly because the Statements are often considered second-level citizens -- as long as they run and "prove the code doesn't contain defects", they are considered sufficient. We will take a look at some examples of bad names and then I'll go into some rules of good naming.

### Consequences of bad naming

I have seen many people not really caring about how their Statements are named. This is a symptom of treating the Specification as garbage or leftovers -- I consider this approach dangerous, because I have seen it lead to Specifications that are hard to maintain and that look more like lumps of code put together accidentally in a haste than a kind of "living documentation". Imagine that your Specification consists of Statements named like this:

-   `TrySendPacket()`
-   `TrySendPacket2()`
-   `testSendingManyPackets()`
-   `testWrongPacketOrder1()`
-   `testWrongPacketOrder2()`

and try for yourself how difficult it is to answer the following questions:

1.  How do you know what situation each Statement describes?
2.  How do you know whether the Statement describes a single situation, or several at the same time?
3.  How do you know whether the assertions inside those Statements are really the right ones assuming each Statement was written by someone else or a long time ago?
4.  How do you know whether the Statement should stay or be removed from the Specification when you modify the functionality described by this Statement?
5.  If your changes in production code make a Statement turn false, how do you know whether the Statement is no longer correct or the production code is wrong?
6.  How do you know whether you will not introduce a duplicate Statement for a behavior when adding to a Specification that was originally created by another team member?
7.  How do you estimate, by looking at the runner tool report, whether the fix for a failing Statement will be easy or not?
8.  What do you answer new developers in your team when they ask you "what is this Statement for?"
9.  How do you know when your Specification is complete if you can't tell from the Statement names what behaviors you already have covered and what not?

### What does a good name contain? 

To be of any use, the name of a Statement has to describe its expected behavior. At the minimum, it should describe what happens under what circumstances. Let's take a look at one of the names Steve Freeman and Nat Pryce came up with in their great book [Growing Object-Oriented Software Guided By Tests](http://www.growing-object-oriented-software.com/): 

```java
notifiesListenersThatServerIsUnavailableWhenCannotConnectToItsMonitoringPort()
```

Note a few things about the name of the Statement:

1.  It describes a behavior of an instance of a specific class. Note that it doesn't contain the name of the method that triggers the behavior, because what is specified is not a single method, but the behavior itself (this will be covered in more detail in the coming chapters). The Statement name simply tells what an instance does ("notifies listeners that server is unavailable") under certain circumstances ("when cannot connect to its monitoring port"). It is important for me because I can derive such a description from thinking about the responsibilities of a class without the need to know any of its method signatures or the code that's inside the class. Hence, this is something I can come up with before implementing -- I just need to know why I created this class and build on this knowledge.
2.  The name is relatively long. Really, really, **really** don't worry about it. As long as you are describing a single behavior, I'd say it's fine. I've seen people hesitate to give long names to Statements, because they tried to apply the same rules to those names as to the names of methods in production code. In production code, a long method name can be a sign that the method has too many responsibilities or that insufficient abstraction level is used to describe a functionality and that the name may needlessly reveal implementation details. My opinion is that these two reasons don't apply as much to Statements. In case of Statements, the methods are not invoked by anyone besides the automatic test runner, so they will not obfuscate any code that would need to call them with their long names. In addition, the Statements names need not be as abstract as production code method names - they can reveal more. 

    Alternatively, we could put all the information in a comment instead of the Statement name and leave the name short, like this:

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
    
    however, there are two downsides to this. First, we now have to add an extra piece of information (`Statement_002`) only to satisfy the compiler, because every method needs to have a name anyway -- and there is usually no value a human could derive from a name such as `Statement_002`. The second downside is that when the Statement turns false, the test runner shows the following line: `Statement_002: FAILED` -- note that all the information included in the comment is missing from the failure report. I consider it much more valuable to receive a report like:

    `notifiesListenersThatServerIsUnavailableWhenCannotConnectToItsMonitoringPort: FAILED`

    because in such case, a lot of information about the Statement that fails is available from the test runner report.

3.  Using a name that describes a single behavior allows me to find out quickly why the Statement turned false. Let's say a Statement is true when I start refactoring, but at one point it turns false and the report in the runner looks like this: `TrySendingHttpRequest: FAILED` -- it only tells me that an attempt was made to send a HTTP request, but, for instance, doesn't tell me whether the object I specified in that Statement is some kind of sender that should try to send this request under some circumstances, or if it is a receiver that should handle such a request properly. To learn what went wrong, I have to go open the source code of the Statement. On the other hand, when I have a Statement named `ShouldRespondWithAnAckWheneverItReceivesAnHttpRequest`, then if it turns false, I know what's broken -- the object no longer responds with an ACK to an HTTP request. This may be enough to identify which part of the code is at fault and which of my changes made the Statement false.

### My favourite convention

There are many conventions for naming Statements appropriately. My favorite is the one [developed by Dan North](http://dannorth.net/introducing-bdd/), where each Statement name begins with the word `Should`. So for example, I would name a Statement:

`ShouldReportAllErrorsSortedAlphabeticallyWhenErrorsOccurDuringSearch()`

The name of the Specification (i.e. class name) answers the question "who should do it?", i.e. when I have a class named `SortingOperation` and want to say that it "should sort all items in ascending order when performed", I say it like this:

```csharp
public class SortingOperationSpecification
{
 [Fact] public void
 ShouldSortAllItemsInAscendingOrderWhenPerformed()
 {
 }
}
```

By writing the above, I say that "Sorting operation *(this is derived from the Specification class name)* should sort all items in ascending order when performed *(this is derived from the name of the Statement)*". 

The word "should" was introduced by Dan to weaken the statement following it and thus to allow questioning what you are stating and ask yourself the question: "should it really?". If this causes uncertainty, then it is high time to talk to a domain expert and make sure you understand well what you need to accomplish. If you are not a native English speaker, the "should" prefix will probably have a weaker influence on you -- this is one of the reasons why I don't insist on you using it. I like it though[^argumentsagainstshould].

When devising a name, it's important to put the main focus on what result or action is expected from an object, not e.g. from one of its methods. If you don't do that, it may quickly become troublesome. As an example, one of my colleagues was specifying a class `UserId` (which consisted of user name and some other information) and wrote the following name for the Statement about the comparison of two identifiers:

`EqualOperationShouldFailForTwoInstancesWithTheSameUserName()`.

Note that this name is not written from the perspective of a single object, but rather from the perspective of an operation that is executed on it. We stopped thinking in terms of object responsibilities and started thinking in terms of operation correctness. To reflect an object perspective, this name should be something more like:

`ShouldNotBeEqualToAnotherIdThatHasDifferentUserName()`.

When I find myself having trouble with naming like this, I suspect one of the following may be the case:

1.  I am not specifying a behavior of a class, but rather the outcome of a method.
2.  I am specifying more than one behavior.
3.  The behavior is too complicated and hence I need to change my design (more on this later).
4.  I am naming the behavior of an abstraction that is too low-level, putting too many details in the name. I usually only come to this conclusion when all the previous points fail me.

### Can't the name really become too long?

A few paragraphs ago, I mentioned you shouldn't worry about the length of Statement names, but I have to admit that the name can become too long occasionally. A rule I try to follow is that the name of a Statement should be easier to read than its content. Thus, if it takes me less time to understand the point of a Statement by reading its body than by reading its name, then I consider the name too long. If this is the case, I try to apply the heuristics described above to find and fix the root cause of the problem.

Start by filling the GIVEN-WHEN-THEN structure with the obvious
----------------------------------------------------------------

This technique can be used as an extension to the previous one (i.e. starting with a good name), by inserting one more question to the question sequence we followed the last time:

1.  What is the scope of the behavior I'm trying to specify? Example answer: I'm trying to specify a behavior of a `Calculator` class.
1.  What is the behavior of a `Calculator` class I'm trying to specify? Example answer: it should display all entered digits that are not leading zeroes.
1.  **What is the context ("GIVEN") of the behavior, the action ("WHEN") that triggers it and expected reaction ("THEN") of the specified object? Example answer: Given I turn on the calculator, when I enter any digit that's not a 0 followed by any digits, then they should be visible on the display**. 
1.  How to specify this behavior through code? Example answer: `[Fact] public void ShouldDisplayAllEnteredDigitsThatAreNotLeadingZeroes() ...` (i.e. a piece of code).

Alternatively, it can be used without the naming step, when it's harder to come up with a name than with a GIVEN-WHEN-THEN structure. In other words, a GIVEN-WHEN-THEN structure can be easily derived from a good name and vice versa.

This technique is about taking the GIVEN, WHEN and THEN parts and translating them into code in an almost literal, brute-force way (without paying attention to missing classes, methods or variables), and then adding all the missing pieces that are required for the code to compile and run.

### Example

Let's try it out on a simple problem of comparing two users for equality. We assume that two users should be equal to each other if they have the same name:

```gherkin
Given a user with any name
When I compare it to another user with the same name
Then it should appear equal to this other user
```

Let's start with the translation part. Again, remember we're trying to make the translation as literal as possible without paying attention to all the missing pieces for now.

The first line:

```gherkin
Given a user with any name
```

can be translated literally to the following piece of code:

```csharp
var user = new User(anyName);
```

Note that we don't have the `User` class yet and we don't bother for now with what `anyName` really is. It's OK. 

Then the second line:

```gherkin
When I compare it to another user with the same name
```

can be written as:

```csharp
user.Equals(anotherUserWithTheSameName);
```

Great! Again, we don't care what `anotherUserWithTheSameName` is yet. We treat it as a placeholder. Now the last line:

```gherkin
Then it should appear equal to this other user
```

and its translation into the code:

```csharp 
Assert.True(usersAreEqual);
```

Ok, so now that the literal translation is complete, let's put all the parts together and see what's missing to make this code compile:

```csharp
[Fact] public void 
ShouldAppearEqualToAnotherUserWithTheSameName()
{
  //GIVEN
  var user = new User(anyName);

  //WHEN
  user.Equals(anotherUserWithTheSameName);

  //THEN
  Assert.True(usersAreEqual);
}
```

As we expected, this doesn't compile. Notably, our compiler might point us towards the following gaps:

1.  Variable `anyName` is not declared.
1.  Object `anotherUserWithTheSameName` is not declared.
1.  Variable `usersAreEqual` is both not declared and it does not hold the comparison result.
1.  If this is our first Statement, we might not even have the `User` class defined at all.

The compiler created a kind of a small TODO list for us, which is nice. Note that while we don't have compiling code, filling the gaps to make it compile boils down to making a few trivial declarations and assignments:

1.  `anyName` can be defined as:

    `var anyName = Any.String();`

2.  `anotherUserWithTheSameName` can be defined as:

    `var anotherUserWithTheSameName = new User(anyName);`

3.  `usersAreEqual` can be defined as variable which we assign the comparison result to:

    `var usersAreEqual = user.Equals(anotherUserWithTheSameName);`

4.  If class `User` does not yet exist, we can add it by simply stating:

    ```csharp
    public class User 
    {
      public User(string name) {}
    }
    ```

Putting it all together again, after filling the gaps, gives us:

```csharp
[Fact] public void 
ShouldAppearEqualToAnotherUserWithTheSameName()
{
  //GIVEN
  var anyName = Any.String();
  var user = new User(anyName);
  var anotherUserWithTheSameName = new User(anyName);

  //WHEN
  var usersAreEqual = user.Equals(anotherUserWithTheSameName);

  //THEN
  Assert.True(usersAreEqual);
}
```

And that's it -- the Statement is complete!

TODO TODO TODO TODO

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
 = authorization.AccessToReportingIsGrantedTo(
  roleAllowedToUseReporting);
```

Resist the urge to define a class or variable as soon as it seems needed, as that will only throw you off the track and steal your focus from what is important. The key to doing TDD successfully is to learn to use something that does not exist yet as if it existed.

Note that we do not know what `roleAllowedToUseReporting` is, neither do we know what `authorization` is, but that did not stop us from writing this line. Also, the `AccessToReportingIsGrantedTo()` method is just taken off the top of our head. It is not defined anywhere, it just made sense to write it like this, because it is the most direct translation of what we had in mind.

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
  .AccessToReportingIsGrantedTo(roleAllowedToUseReporting);

 //THEN
 Assert.True(accessGranted);
}
```

Using what we learned by formulating the Statement, it was easy to give it a name.

Start by invoking a method if you have one
------------------------------------------

Sometimes, we have to add a new class that must implement an existing interface. The interface imposes what methods the new class must support. If this point is already decided, we can start our Statement by first calling the method and then discovering what we need to supply.

### Example

Suppose we have an application that, among other things, handles importing an existing database from another instance of the application. Given that the database is large and importing it can be a lengthy process, a message box is displayed each time a user performs the import. Assuming the user's name is Johnny, the message box displays the message "Johnny, please sit down and enjoy your coffee for a few minutes as we take time to import your database." The class that implements this looks like:

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
   return null;
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


[^argumentsagainstshould]: There are also some arguments against using the word "should", e.g. by Kevlin Henney (see http://www.infoq.com/presentations/testing-communication).

