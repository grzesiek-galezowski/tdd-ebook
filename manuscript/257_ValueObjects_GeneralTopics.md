# Aspects of value objects design

There are few aspects of design of value objects that I still need to talk about.

## Immutability

I already said that value objects are usually immutable. This is not a hard constraint, although it is based on years of engineering practice. Allow me to outline just three reasons I think immutability is key constraint for value objects.

### Accidental change of hash code

Many times, values are used as keys in hash maps (.e.g .NET's `Dictionary<K,V>` is essentially a hash map). Not that many people are aware of how hash maps work. the thing is that we act as if we were indexing something using an object, but the truth is, we are using hash codes in such cases. Let's imagine we have a dictionary indexed by instances of some elusive type, called `ValueObject`:

```csharp
Dictionary<ValueObject, SomeObject> _objects; 
```

 and that we are allowed to change the state of its object, e.g. by using a method `SetName()`. Now, it is a shame to admit, but there was a time when I thought that doing this:

```csharp
ValueObject val = ValueObject.With("name");
_objects[val] = new SomeObject();

// we are mutating the state:
val.SetName("name2");

var objectIAddedTwoLinesAgo = _objects[val];
```

would give me access to the original object I put into the dictionary with `val` as a key. The impression was caused by the code `_objects[val] = new SomeObject();` looking as if I indexed the dictionary with an object, where in reality, the dictionary was merely taking the `val` to calculate its hash code and use this as a real key. 

This is the reason why the above code would throw an exception, because by changing the state of the `val` with the statement: `val.SetName("name2");`, I also changed its calculated hash code, so the second time I did `_objects[val]`, I was accessing an entirely different index of the dictionary than when I did it the first time.

As it is quite common situation that value objects end up as keys inside dictionaries, it is better to leave them immutable to avoid nasty surprises.

### Accidental modification by foreign code

If you have ever programmed in Java, you have to remember its `Date` class, that did behave like a value, but was mutable (with methods like `setMonth()`, `setTime()`, `setHours()` etc.). 

Now, value objects are different from normal objects in that they tend to be passed a lot to many subroutines or accessed from getters. Many Java programmers did this kind of error when allowing access to a `Date` field:

```java
public class ObjectWithDate {

  private final Date _date = new Date();
  
  //...
  
  public Date getDate() {
    //oops...
    return _date;
  }
}
```

It was so funny, because every user of such objects could modify the internal data like this:

```java
ObjectWithDate o = new ObjectWithDate();

o.getDate().setTime(10000);

```

The reason this was happening was that the method `getDate()` returned a reference to a mutable object, so by calling the getter, we would get access to internal field. 

As it was most of the time against the intention of the developers, it forced them to manually creating a copy each time they were returning a date:

```java
public Date getDate() {
  return (Date)_date.clone();
}
```

which was easy to forget and may have introduced a performance penalty on cloning objects each time, even when the code that was calling the getter had no intention of modifying the date.

And that's not all, folks - after all, I said to avoid getters, so we should not have this problem, right? Well, no, because the same applies when our class passes the date somewhere like this:

```java
public void dumpInto(Destination destination) {
  return destination.write(_date);
}
```

In case of this `dumpInto()` method, the `Destination` is allowed to modify the date it receives anyway it likes, which, again, was usually against developers' intention.

I saw many, many issues in production code caused by the mutability of Java `Date` type alone. That's one of the reasons the new time library in Java 8 (`java.time`) contains immutable types for time and date. When a type is immutable, you can safely return its instance or pass it somewhere without having to worry that someone will overwrite your local state against your intention.

### Thread safety

Mutable values cause issues when they are shared by threads, because such objects can be changed by few threads at the same time, which can cause data corruption. I stressed a few times already that value objects tend to be created many times in many places and passed along inside methods or returned as results a lot. Thus, this is a real danger. Sure, we could lock each method such a mutable value object, but then, the performance penalty could be severe.

On the other hand, when an object is immutable, there are no multithreading concerns. After all, no one is able to modify the state of an object, so there is no possibility for concurrent modifications causing data corruption. This is one of the reasons why functional languages, where data is immutable by default, gain a lot of attention in domains where running many threads is necessary.

There, I hope I convinced you that immutability is a great choice for value objects and nowadays, when we talk about values, we mean immutable ones.

## Implicit vs. explicit handling of variability (TODO check vs with or without a dot)

As in ordinary objects, there can be some variability in values. For example, we can have money, which includes dollars, pounds, zlotys (Polish money), euros etc. Another example of something that can be modelled as a value are paths (you know, `C:\Directory\file.txt` or `/usr/bin/sh`) - here, we can have absolute paths, relative paths, paths to files and paths pointing to directories.

Contrary to ordinary objects, however, where we solved variability by using interfaces and different implementations (e.g. we had `Alarm` interface with implementing classes like `LoudAlarm` or `SilentAlarm`), in values we do it differenly. This is because the variability of values is not behavioral. Whereas the different kinds of alarms varied in how they fulfilled the responsibility of signaling they were turned on (we said they responded to the same message with, sometimes entirely different, behaviors), the diffenrent kinds of currencies differ in what conversion rates are applied to them (e.g. "how many dollars do I get from 10 Euros and how many from 10 Punds?"), which is not a behavioral distinction. Likewise, paths differ in what kinds of operations can be applied to them (e.g. we can imagine that for paths pointing to files, we can have an operation called `GetFileName()`, which does not make sense for a path pointing to a directory).

So, assuming the differences are important, how do we handle them? There are two basic approaches that I like calling implicit and explicit. Both are useful in certain contexts, depending on what exactly we want to model, so both demand an explanation.

### Implicit variability

This kind of variability is what can be seen in an example by Kent Beck from his famous book Test Driven Development By Example. This example was about money, where we always have a single type called `Money`, which internally can be pounds, dollars, yens etc. His example was in Java, but it will be more comfortably for me to translate it to C#[^wecoulduseextensionmethods]. Anyway, this is how we could create different amounts of money in different currencies:

```csharp
Money tenPounds = Money.Punds(10);
Money tenBucks = Money.Dollars(10);
Money tenYens = Money.Yens(10);
```

In reality, it actually was a single type, which differed in how it was created - which was hidden by the factory methods. Thanks to the different between e.g. yens and dollars being implicit, we could safely mix them, e.g. we could write:

```csharp
Money allMySavings = 
    Money.Pounds(10) 
  + Money.Euros(24)
  + Money.Dollars(13);
```

and this was a good thing, since all that Kent cared about in the end in regard to money was "do I have enough?".

TODO


show you how using a value object helps us with the changes  


TODO continue from here
TODO tell don't ask - wasn't it written about earlier?

TODO what about type incompatibility?
TODO special values like none or blank
TODO explicit vs implicit
TODO why immutability
TODO  It looks like the effort on creating such a wrapper around just one value is huge, however, most of the methods are straightforward and others can be auto-generated by an IDE (like Equals(), GetHashCode() and equality operators).



Note few things about this implementation:



4.  Product names are immutable. There is no operation that can overwrite its state once the object is created. This is on purpose and is a design constraint that we want to maintain. For example, we may want to sell sets of products in the future ("2 in 1" etc.) and treat it as a separate product with a name being a merger of the component names. In such case, we could write:

    ```csharp
    var productSetName = productName1.MergeWith(productName2);
    ```
and this operation would create a new product name instead of modifying any of the component product names. Note that this is also the same as in case of strings, which, in C#, are immutable (every operation like `Trim()`, `Replace()` etc. creates a new object).

Ok, now for the first change:


### TODO implementing value objects

factory methods, equals, why immutable, gethashcode, implicit values or explicit values, narrowing down the interface, passing multiple strings can cause the order of the arguments to be confused, treating time as integer, treating strings as paths, Title type instead of strings or utils.


### Summary

By examining the above example, we can see the following principle emerging:

I> When you give a value a name that belongs to the problem domain, it means that its type should be a separate domain-specific class which is under your control instead of a general-purpose library class that's out of your control.

And it's a nice one to remember, especially because we often tend to model such values as a library types and wake up when it's already too late to make the transition to value object effectively. I'm an example of this and that's why I re-learned this principle by hard many times.

And that's it for today. I'll be happy to hear your thoughts. Until then, see ya!


TODO talk about static const value objects. const can be used only for types that have literals. Thus static readonly is used. Todo: interfaces let us treat related objects the same, and values let us separate unrelated objects.

[^wecoulduseextensionmethods]: The difference between Jva dn C# here is that C# supports operator overloading whereas Java does not. By the way, I could use extension methods to make the example even more idiomatic, but I don't want to go to far in the land of specific language idioms to leave the code readable for the wider audience.  
