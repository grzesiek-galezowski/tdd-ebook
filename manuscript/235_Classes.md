# Classes

We already covered interfaces and protocols. In our quest for composability, We need to look at classes as well.

Classes implement and use interfaces, and communicate using protocols, so it may seem we are already done with them. The truth is that classes are still interesting on their own and there are few concepts related to them that need explanation.


## Single Responsibility

I already said that we want our system to be a web of composable objects. Obviously, an object is a granule of composability - we cannot e.g. unplug a half of an object and plug in another half. Thus, a valid question to ask is this: how big should an object be to make the composability comfortable - to let's unplug as much logic as we want, leaving the rest untouched.

The answer comes with a Single Responsibility Principle for classes[^SRPMethods], that basically says[^SRP]:



TODO the notion of unit (hour, second, microsecond) - responsibility is granular - parallelism may also be a responsibility

TODO independent deployability

TODO principle at different level of abstraction - single level of abstraction principle

TODO small amount of private methods

This leads to a question: what is the granule of composability? How much should a class do to be composable?

TODO how are we to determine responsibility? From experience: we know to count something in hours, not minutes. Second way: composition becomes awkward. Third way: tests (Statements) will tell us.


## Static fields and methods
## Work in constructors
## How to name a class

[^SRPMethods]: This principle can be applied to methods as well, but we are not going to cover this part, because it is not directly tied to the notion of composability and this is not a design book ;-).

[^SRP]: http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod. 