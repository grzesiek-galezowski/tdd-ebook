# An object-oriented approach summary

## Where are we now?

So far, we talked a lot about the object-oriented world, consisting of objects, that: 

* send messages to each other using interfaces and according to protocols. Thanks to this, objects could send messages, without knowing who exactly is on the other side to handle the message
* are built around the Tell Don't Ask heuristic, so that each object has its own responsibility and handles it when its told, without conveying to anyone how it is handling the responsibility
* are built around the quality of composaibility, which lets us compose them as we would compose parts of sentences, creating higher-level languages, so that we can reuse the objects we already have as our "vocabulary" and add new functionality by combining them into new "sentences".
* are created in places well separated from the places that use those objects, depending on their lifecycle, e.g. factories and composition root. 

and of values that:

* represent quantities, measurements and other discrete pieces of data that we want to name, combine with each other, transform and pass along. Examples are: dates, strings, money, time durations, path values, numbers, etc.
* are compared based on their data, not their references. Two values containing the same data are considered equal.
* are immutable - when we want to have a value like another one, but with one aspect changed, we create another value based on the previous value and the previous value remains unchanged.
* do not rely on polymorphism - if we have several value types that need to be used interchangeably, the usual strategy is to provide explicit conversion methods between those types.

There are times when choosing whether something should be an object or a value poses a problem, so there is no strict rule on how to choose and different people have different preferences.

This is the world we are going to fit mock objects and other TDD practices into.

## So, tell me again, why are we here?

I hope you're not mad at me because we put aside TDD for such a long time. Believe me that understanding the concepts from all the chapters from part 2 up to now is crucial to getting mocks right.

Mock objects are not a new tool, however, there is still a lot of misunderstanding of what their nature is and where and how they fit best into the TDD approach. Some opinions went as far as to say that there are two styles of TDD: one that uses mocks (called "mockist TDD" or "London style TDD") and another without them (called "cassic TDD" or "Chicago style TDD"). Me personally, I don't support this division. I like very much what Nat Pryce said about it[^differenttddtools]:

> (...) I argue that there are not different kinds of TDD. There are different design conventions, and you pick the testing techniques and tools most appropriate for the conventions you’re working in.

I hope now you understand why i put you through so many pages talking about a specific view on object-oriented design. This is the view that mock objects as a tool and as a technique were chosen to support. Talking about mock objects out of the context of this view would not make too much sense.


[^differenttddtools]: TODO add reference and change it into a url instead of footnote. 
