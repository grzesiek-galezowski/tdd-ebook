How is TDD about analysis and what does "GIVEN-WHEN-THEN" mean?
===============================================================

During their work on the calculator code, Johnny mentioned that TDD is, among other things, about analysis. This chapter examines this concept further. Let's start by answering the following question:

Is there really a commonality between analysis and TDD?
-------------------------------------------------------

From Wikipedia:

> Analysis is the process of breaking a complex topic or substance into smaller parts to gain a better understanding of it.

Thus, for TDD to be about analysis, it has to fulfill two conditions:

1.  It has to be a process of breaking a complex topic into smaller parts
2.  It has to allow gaining a better understanding of such smaller parts

In the story about Johnny, Benjamin and Jane, I included a part where they analyze requirements using concrete examples. Johnny explained that this is a part of a technique called Acceptance Test-Driven Development. The process followed by the three characters fulfilled both mentioned conditions for a process to be analytical. But what about TDD itself?

Although I used parts of the ATDD process in the story to make the analysis part more obvious, similar things happen at pure technical levels. For example, when starting development with a failing application-wide Statement (i.e. one that covers a behavior of an application as a whole. We will talk about levels of granularity of Statements later. For now the only thing you need to know is that the so called "unit tests level" is not the only level of granularity we write Statements on), we may encounter a situation where we need to call a web method and make an assertion on its result. This makes us think: what should this method be called? What are the scenarios supported? What do I need to get out of it? How should its user be notified about errors? Many times, this leads us to either a conversation (if there is another stakeholder that needs to be involved in the decision) or rethinking our assumptions. The same applies on "unit level" - if a class implements a domain rule, there might be some good domain-related questions resulting from trying to write a Statement for it. If a class implements a technical rule, there might be some good technical questions to discuss with other developers etc. This is how we gain a better understanding of the topic we are analyzing, which makes TDD fulfill the second of the two requirements for it to be an analysis method.

But what about the first requirement? What about breaking a complex logic into smaller parts?

If you go back to Johnny and Benjamin's story, you will note that when talking to a customer and when writing code, they used a TODO list. This list was first filled with whatever scenarios they came up with, but later, they would add smaller units of work. When doing TDD, we do the same, essentially decomposed complex topics into smaller items and putting them on the TODO list (this is one of the practices that serve decomposition. The other one is mocking, but let's not get into that yet). Thanks to this, we can focus on one thing at a time, crossing off item after item from the list after it's done. If we learn something new or encounter a new issue that needs our attention, we can add it to the TODO list and get back to it later, for now continuing our work on the current point of focus.

I> An example TODO list from the middle of an implementation task may look like this (don't read through it, I put it here just to give you a glimpse - you're not supposed to understand what the list items are about):
I>
I>  1.  --- Create an entry point to the module (top-level abstraction)
I>  2.  --- Implement main workflow of the module
I>  3.  --- Implement `Message` interface
I>  4.  --- Implement `MessageFactory` interface
I>  5.  Implement `ValidationRules` interface
I>  6.  --- Implement behavior required from Wrap method in `LocationMessageFactory` class
I>  7.  Implement behavior required from ValidateWith method in `LocationMessage` class for Speed field
I>  8.  Implement behavior required from ValidateWith method in `LocationMessage` class for Age field
I>  9.  Implement behavior required from ValidateWith method in `LocationMessage` class for Sender field

Note that some items are already crossed out as done, while others remain pending and waiting to be addressed. All these items are what the article on Wikipedia calls "smaller parts" - a result of breaking a bigger topic.

Ok, that's it for the discussion. Now that we are sure that TDD is about analysis, let's focus on the tools we can use to aid and inform it. You already saw both of them in this book, now we're going to have a closer look.

Gherkin
-------

Hungry? Too bad, because the Gkerkin I am gonna talk about is not edible. It is a notation and a way of thinking about behaviors of the specified piece of code. It can be applied on different levels of granularity -- any behavior, whether of a whole system or a single class, may be described using Gherkin.

In fact we already used this notation, we just didn't name it so. Gherkin is the GIVEN-WHEN-THEN structure that you can see everywhere, even as comments in the code samples. This time, we are stamping a name on it and analyzing it further.

In Gherkin, a behavior description consists mostly of three parts:

1.  Given -- a context
2.  When -- a cause
3.  Then -- a effect

In other words, the emphasis is on causality in a given context. There's also a fourth keyword: And -- we can use it to add more context, more causes or more effects. You'll have a chance to see an example in a few seconds

As I said, there are different levels you can apply this. Here is an example for such a behavior description from the perspective of its end user (this is called acceptance-level Statement):

```gherkin
Given a bag of tea costs $20
And there is a discount saying "pay half for a second bag"
When I buy two bags
Then I should be charged $30
```

And here is one for unit-level (note again the line starting with "And" that adds to the context):

```gherkin
Given a list with 2 items
When I add another item
And check items count
Then the count should be 3
```

While on acceptance level  we put such behavior descriptions together with code as a single whole (If this doesn't ring a bell, look at tools such as SpecFlow or Cucumber or FIT to get some examples), on the unit level the description is usually not written down in a literal way, but rather it is translated and written only in form of source code. Still, this structure is useful when thinking about behaviors required from an object or objects, as we saw when we talked about starting from Statement rather than code. I like to put the structure explicitly in my Statements -- I find that it helps make them more readable (TODO TODO TODO add article stating otherwise). So most of my unit-level Statements follow this template:

```csharp
[Fact]
public void Should__BEHAVIOR__()
{
  //GIVEN
  ...context...

  //WHEN
  ...trigger...

  //THEN
  ...assertions etc....
}
```

Sometimes the WHEN and THEN sections are not so easily separable -- then I join them, like in case of the following Statement specifying that an object throws an exception when asked to store null:

```csharp
[Fact]
public void ShouldThrowExceptionWhenAskedToStoreNull()
{
  //GIVEN
  var safeList = new SafeList();

  //WHEN - THEN
  Assert.Throws<Exception>(
    () => safeList.Store(null)
  );
}
```

By thinking in terms of these three parts of behavior, we may arrive at different circumstances (GIVEN) at which the behavior takes place, or additional ones that are needed. The same goes for triggers (WHEN) and effects (THEN). If anything like this comes to our mind, we add it to the TODO list.

TODO list... again!
-----------------

As I said earlier, a TODO list is a repository for our deferred work, including anything that comes to our mind when writing or thinking about a Statement, but is not a part o the current Statement we are writing. On one hand, we don't want to forget it, on the other - we don't want it to haunt us and distract us from our current task, so we write it down as soon as possible and continue with our current task. When we'are finished with it, we take another item from TODO list and start working on it.

Imagine we're writing a piece of logic that allows users access when they are employees of a zoo, but denies access if they are merely guests of the zoo. Then, after starting writing a Statement we realize that employees can be guests as well -- for example, they might choose to visit the zoo with their families during their vacation. Still, the two previous rules hold, so to not allow this case to distract us, we can quickly add an item to the TODO list (like "TODO: what if someone is an employee, but comes to the zoo as a guest?") and finish the current Statement. When we're finished, you can always come back to the list of deferred items and pick next item to work on.

There are two important questions related to TODO lists: "what exactly should we add as a TODO list item?" and "How to efficiently manage the TODO list?". We will take care of these two questions now.

### What to put on a TODO list?

Everything that we need addressed but is not part of the current Statement. Those items may be related to implementing unimplemented methods, to add whole functionalities (such items are usually followed my more fine-grained sub tasks as soon as we start implementing them), they might be reminders to take a better look at something (e.g. "investigate what is this component’s policy for logging errors") or questions about the domain that need to get answered. If we get carried away too much in coding and we tend to forget to eat, we can even add a reminder ("TODO: eat lunch!"). I never encountered a case where I needed to share this TODO list with anyone else, so I treat it as my personal sketchbook. I recommend the same to you - the list is yours!

### How to pick items from TODO list?

Which item to choose from the TODO list when we have several of them? I have no clear rule, although I tend to take into account the following factors:

1.  Risk -- if what I learn by implementing or discussing a particular item from the list can have a big impact on design or behavior of the system, I tend to pick such items first. An example of such item is when I start implementing validation of a request that arrives to my application and want to return different error depending on which part of the request is wrong. Then, during the development, I may discover that more than one part of the request can be wrong at a time and I have to answer a question: which error code should be returned in such case? Or maybe the return codes should be accumulated for all validations and then returned as a list?
2.  Difficulty -- depending on my mental condition (how tired I am, how much noise is currently around my desk etc.), I tend to pick items with difficulty that best matches this condition. For example, after finishing an item that requires a lot of thinking and figuring out things, I tend to take on some small and easy items to feel wind blowing in my sails and to rest a little bit. 
3.  Completeness -- in simplest words, when I finish test-driving an "if" case, I usually pick up the "else" next. For example, after I finish implementing a Statement saying that something should return true for values less than 50, then the next item to pick up is the "greater or equal to 50" case. Usually, when I start test-driving a class, I take items related to this class until I run out of them, then go on to another one.

### Where to put a TODO list?

I encountered two ways of maintaining a TODO list. The first one is on a sheet of paper, which is nice, but requires me to take my hands off the keyboard, grab a pen or pencil and then get back to coding every time I think of something. Also, the only way a TODO item written on a sheet of paper can tell me which place in code it is related to, is (obviously) by its text. The good thing about paper is that it is by far one of the best tools for sketching, so when my TODO item is best stored as a diagram or a drawing (which doesn't happen too often, but sometimes does) , I use pen and paper.

The second alternative is to use a TODO list functionality built-in into an IDE. Most IDEs, such as Visual Studio (and Resharper plugin has its own enhanced version), Xamarin Studio, IntelliJ or eclipse-based IDEs have such functionality. The rules are simple -- I put special comments (e.q. `//TODO do something`) in the code and a special view in my IDE aggregates them for me, allowing me to navigate to each item later. This is my primary way of maintaining a TODO list, because:

1.  They don't force me to take my hands off my keyboard to add an item to the list.
2.  I can put a TODO item in a certain place in the code where is makes sense and then navigate back to it later with a click of a mouse. This, apart from other advantages, allows writing shorter notes than if I had to do it on paper. For example, a TODO item saying "TODO: what if it throws an exception?" looks out of place on a sheet of paper, but when added as a comment to my code in the right place, it's sufficient.
3.  Many TODO lists automatically add items for certain things that happen in the code. E.g. in C\#, when I'm yet to implement a method that was automatically generated the IDE, its body usually consists of a line that throws a `NotImplementedException` exception. Guess what -- `NotImplementedException` occurences are added to the TODO list automatically, so I don't have to manually add items to the TODO list for implementing the methods where they occur.

The TODO list maintained in the source code has one minor drawback - we have to remember to clear the list or we may end up pushing the items to the source control repository along with the rest of the source code. Such leftover TODO items may accumulate in the code, effectively reducing the ability to navigate through the items that were added by me. There are several strategies of dealing with this:

//TODO//TODO//TODO//TODO//TODO//TODO//TODO//TODO//TODO//TODO//TODO//TODO

1. For greenfield projects, I found it relatively easy to set up a static analysis check that runs when the code is built and doesn't allow the build to finish unless all TODO items are removed.
2. removing all TODO items at start
3. Using a different marker 

### Expanded TDD process with a TODO list 

In one of the previous chapters, I introduced you to the basic TDD process that contained three steps: write unfulfilled Statement, fulfill it and refactor the code. TODO list adds new steps to this process leading to the following list of steps:

1.  Examine TODO list and pick an item that makes most sense to implement next
2.  Write unfulfilled Statement
3.  Make it unfulfilled for the right reason
4.  Fulfill the Statement and make sure all already fulfilled Statements are still fulfilled
5.  Cross out the item from TODO list
6.  Repeat until no item is left on the TODO list

Of course, we are free to add new items to the TODO list as we make progress with the existing ones and at the beginning of each cycle the list is re-evaluated to choose the most important item to implement next taking into account what was added during the previous cycle.

### Potential downsides

There are also some downsides. The biggest is that people often add TODO items for other means than to support TDD and they never go back to such items. Some people joke that a TODO left in the code means "Once, I wanted to...". Anyway, such items may pollute your TDD-related TODO list with so much cruft that your own items are barely findable. To work around it, I tend to use a different tag than TODO (many IDEs let you define your own tags, or support multiple tag types out of the box. E.g. with Resharper, I like to use "bug" tag, because this is something no one would leave in the code) and filter by it. Another options is, of course, getting rid of the leftover TODO items -- if no one addressed it for a year, then probably no one ever will.

Another downside is that when you work with multiple workspaces/solutions, your IDE will gather TODO items only from current solution/workspace, so you will have few TODO lists -- one per workspace or solution. Fortunately, this isn’t usually a big deal.
