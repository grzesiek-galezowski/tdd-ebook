-# Part 3: TDD in Object-Oriented World

A> ## Status: under development
A>
A> I am in progress of writing this part. Still, there are several chapters that are already available for reading and pretty stable. I look forward to receiving your feedback!

So far, we've talked a lot about the object-oriented world, consisting of objects that exhibit the following properties:

1. Objects send messages to each other using interfaces and according to protocols. As long as these interfaces and protocols are adhered to by the recipients of the messages, the sender objects don't need to know who exactly is on the other side to handle the message. In other words, interfaces and protocols allow decoupling senders from the identity of their recipients.
1. Objects are built with Tell Don't Ask heuristic in mind, so that each object has its own responsibility and fulfills it when it's told to do something, without revealing the details of how it handles this responsibility,
1. Objects, their interfaces and protocols, are designed with composability in mind, which allows us to compose them as we would compose parts of sentences, creating small higher-level languages, so that we can reuse the objects we already have as our "vocabulary" and add more functionality by combining them into new "sentences".
1. Objects are created in places well separated from the places that use those objects. The place of object creation depends on the object lifecycle - it may be e.g. a factory or a composition root.

The world of objects is complemented by the world of values that exhibit the following characteristics:

1. Values represent quantities, measurements and other discrete pieces of data that we want to name, combine with each other, transform and pass along. Examples are: dates, strings, money, time durations, path values, numbers, etc.
1. Values are compared based on their data, not their references. Two values containing the same data are considered equal.
1. Values are immutable - when we want to have a value like another one, but with one aspect changed, we create a new value containing this change based on the previous value and the previous value remains unchanged.
1. Values do not (typically) rely on polymorphism - if we have several value types that need to be used interchangeably, the usual strategy is to provide explicit conversion methods between those types.

There are times when choosing whether something should be an object or a value poses a problem (I ran into situations when I modelled the same concept as a value in one application and as an object in another), so there is no strict rule on how to choose and, additionally, different people have different preferences.

This joint world is the world we are going to fit mock objects and other TDD practices into in the next part.

I know we have put TDD aside for such a long time. Believe me that this is because I consider understanding the concepts from part 2 crucial to getting mocks right.

Mock objects are not a new tool, however, there is still a lot of misunderstanding of what their nature is and where and how they fit best into the TDD approach. Some opinions went as far as to say that there are two styles of TDD: one that uses mocks (called "mockist TDD" or "London style TDD") and another without them (called "cassic TDD" or "Chicago style TDD"). Personally, I don't support this division. I like very much what [Nat Pryce said about it](https://groups.google.com/d/msg/growing-object-oriented-software/GNS8bQ93yOo/GViu-YvWCEoJ):

> (...) I argue that there are not different kinds of TDD. There are different design conventions, and you pick the testing techniques and tools most appropriate for the conventions you're working in.

The explanation of the "design conventions" that mocks were born from required putting you through so many pages about a specific view on object-oriented design. This is the view that mock objects as a tool and as a technique were chosen to support. Talking about mock objects out of the context of this view would make me feel like I'm painting a false picture.

After reading part 3, you will understand how mocks fit into test-driving object-oriented code, how to make Statements using mocks maintainable and how some of the practices I introduced in the chapters of part 1 apply to mocks. You will also be able to test-drive simple object-oriented systems.
