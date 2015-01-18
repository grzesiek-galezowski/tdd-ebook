#Refactoring Object Composition

When describing object compositon and Composition Root in particular, I promised to get back to the topic of making the composition root cleaner and more readable.

Before I do this, however, we need to get one important question answered...

## Why bother?

Up to now you have to be sick and tired from reading me stressing how important composability is. Also, I said that in order to reach high composability of a class, it has to be context-independent. To reach this independence, I introduced the principle of separating object use from construction, pushing the construction part away into specialized places. I also said that a lot can be contributed to this quality by making the interfaces and protocols abstract and having as small amount of implementation details there as possible.

All of this has its cost, however. Striving for high context-independence takes away from us the ability to look at a single class and determine its context just by reading its code. Such class is "dumb" about the context it operates in.

On the other hand, I also said that it is important for the behavior of the application itself to be changeable by changing which object talks to which object. So, application behavior is still important.

if we are not able to read it from class, where it is? Answer: object composition. It is declarative definition of our system. But how can we read it if it looks like this:

TODO example 


## number of decisions in app is unchanged

we can push it to metadata, configuration, language dsl, anyway, we try to program on higher level


1.  Factory method & method composition
2.  variadic covering method -- creating collection using variadic parameter method or variadic constructors
3.  variable as terminator
4.  Explaining method (i.e. returns its argument. Use with care)