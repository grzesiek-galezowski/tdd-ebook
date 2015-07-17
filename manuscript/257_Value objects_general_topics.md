# Aspects of value objects design

There are few aspects of design of value objects that I still need to talk about.

## Immutability

I already said that value objects are usually immutable. Some say immutability is the core part of something being a value (e.g. Kent Beck goes as far as to say that 1 is always 1 and will never become 2), while others don't consider it as hard constraint. One way or another, immutability makes an awful lot of sense for value objects. Allow me to outline just three reasons I think immutability is a key constraint for value objects.

### Accidental change of hash code

Many times, values are used as keys in hash maps (.e.g .NET's `Dictionary<K,V>` is essentially a hash map). Not that many people are aware of how hash maps work. the thing is that we act as if we were indexing something using an object, but the truth is, we are using hash codes in such cases. Let's imagine we have a dictionary indexed by instances of some elusive type, called `ValueObject`:

```csharp
Dictionary<ValueObject, AnObject> _objects; 
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

### If not mutability, then what?

There, I hope I convinced you that immutability is a great choice for value objects and nowadays, when we talk about values, we mean immutable ones. But one question remains unanswered: what about a situation when I really want to have:

* a number that is greater by three than another number?
* a date that is later by five days than another date?
* a path to a file in a directory that I already have?

If I cannot modify an existing value, how can I achieve such goals?

The answer is simple - value objects have operations that instead of modifying the existing object, return a new one, with state we are expecting. The old value remains unmodified.

Just to give you three examples, when I have an existing string and want to replace every occurence of letter `r` with letter `l`:

```csharp
string oldString = "rrrr";
string newString = oldString.Replace('r', 'l');
//oldString is still "rrrr", newString is "llll"
```

When I want to have a date later by five days than another date:

```csharp
string oldDate = DateTime.Now;
string newString = oldDate + TimeSpan.FromDays(5);
//oldDate is unchanged, newDate is later by 5 days
```

When I want to make a path to a file in a directory from a path to the directory[^atmafilesystem]:

```csharp
AbsoluteDirectoryPath oldPath 
  = AbsoluteDirectoryPath.Value(@"C:\Directory");
AbsoluteFilePath newPath = oldPath + FileName.Value("file.txt");
//oldPath is "C:\Directory", newPath is "C:\Directory\file.txt"
```

So, again, any time we want to have a value based on a previous value, instead of modifying the previous object, we create a new object with desired state.

## Implicit vs. explicit handling of variability (TODO check vs with or without a dot)

As in ordinary objects, there can be some variability in values. For example, we can have money, which includes dollars, pounds, zlotys (Polish money), euros etc. Another example of something that can be modelled as a value are paths (you know, `C:\Directory\file.txt` or `/usr/bin/sh`) - here, we can have absolute paths, relative paths, paths to files and paths pointing to directories.

Contrary to ordinary objects, however, where we solved variability by using interfaces and different implementations (e.g. we had `Alarm` interface with implementing classes like `LoudAlarm` or `SilentAlarm`), in values we do it differenly. This is because the variability of values is not behavioral. Whereas the different kinds of alarms varied in how they fulfilled the responsibility of signaling they were turned on (we said they responded to the same message with, sometimes entirely different, behaviors), the diffenrent kinds of currencies differ in what exchange rates are applied to them (e.g. "how many dollars do I get from 10 Euros and how many from 10 Punds?"), which is not a behavioral distinction. Likewise, paths differ in what kinds of operations can be applied to them (e.g. we can imagine that for paths pointing to files, we can have an operation called `GetFileName()`, which does not make sense for a path pointing to a directory).

So, assuming the differences are important, how do we handle them? There are two basic approaches that I like calling implicit and explicit. Both are useful in certain contexts, depending on what exactly we want to model, so both demand an explanation.

### Implicit variability

Let's imagine we want to model money using value objects[^tddbyexample]. Money can have different currencies, but we don't want to treat each currency in a special way. The only things that are impacted by currency are exhange rtates to other currencies. Other than this, we want every part of logic that works with money to work with each currency.

This leads us to making the differencies between currencies implicit, i.e. we will have a single type called `Money`, which will not expose its currency at all. We only have to tell the currency when we create an instance:

```csharp
Money tenPounds = Money.Pounds(10);
Money tenBucks = Money.Dollars(10);
Money tenYens = Money.Yens(10);
```

and when we want to know the concrete amount in a given currency:

```csharp
decimal amountOfDollarsOnMyAccount = mySavings.AmountOfDollars();
```

other than that, we are allowed to mix different currencies whenever and wherever we like[^wecoulduseextensionmethods]:

```csharp
Money mySavings = 
  Money.Dollars(100) +
  Money.Euros(200) +
  Money.Zlotys(1000);
``` 

And this is good, assuming all of our logic is common for all kinds of money and we do not have any special logic just for Pounds or just for Euros that we don't want to pass other currencies into by mistake.

Here, the variability of currency is implicit - most of the code is simply unaware of it and it is gracefully handled under the hood inside the `Money` class.

### Explicit variability

There are times, however, when we want the variability to be explicit, i.e. modeled usnig different types. Filesystem paths are a good example. Let's imagine the following method for creating a backup archives that accepts a destination path (for now as a string) as its input parameter:

```csharp
void Backup(string destinationPath);
```

This method has one obvious drawback - its signature does not tell anything about the characteristics of the destination path - is it an absolute path, or a relative path (and if relative, then relative to what?)? Should the path contain a file name for the backup file, or should it be just a directory path and file name is given according to some pattern (e.g. given on current date)? Or maybe file name in the path is optional and if none is given, then a default name is used? A lot of questions, isn't it?

We can try to work around it by changing the name of the parameter to hint the constraints, like this:

```csharp
void Backup(string absoluteFilePath);
```

but the effectiveness of that is based solely on someone reading the argument name and besides, before a path reaches this method, it is usually passed around several times and it's very hard to keep track of what actually is inside this string, so it's easy to mess things up and pass e.g. a relative path where an absolute one is expected. The compiler does not enforce any constraints. Besides that, one can pass an argument that's not even a path inside, because a string can contain any arbitrary content.

Looks like this is a good situation to introduce a value object, but what kind of type or types should we introduce? Surely, we could create a single type called `Path` that would have methods like `IsAbsolute()`, `IsRelative()`, `IsFilePath()` and `IsDirectoryPath()` (i.e. it would handle the variability implicitly), which would solve (only - we'll see that shortly) one part of the problem - the signature would be:

```csharp
void Backup(Path absoluteFilePath);
```

and we would not be able to pass an arbitrary string, only an instance of a `Path`, which may expose a factory method that checks whether the string passed is a proper path:

```csharp
//the following throws exception because string is not proper path
Path path = Path.Value(@"C:\C:\C:\C:\//\/\/");
``` 

and throws an exception in place of path creation. This is important - previously, when we did not have the value object, we could assign garbage to a string, pass it between several objects and get an exception from the `Backup()` method. Now, when we have a value object, there is a high probability thet it will be used as early as possible in the chain of calls, and if we try to create a path with wrong arguments, we will get an exception much closer to the place where the mistake was made, not at the end of the call chain.

So yeah, introducing a general `Path` value object might solve some problems, but not all of them. Still, the signature of the `Backup()` method does not signal that the path expected must be an absolute path to a file, so one may pass a relative path or a path to a directory.

In this case, the varying properties of paths are not just an obstacle, a problem to solve, like in case of money. They are they key differentiating factor in choosing whether a behavior is appropriate for a value or not. In such case, it makes a lot of sense to create several different value types for path, each representing a different set of constraints.

Thus, we may decide to introduce types like[^atmafilesystem2]:

* `AbsoluteFilePath` - representing an absolute path containing a file name, e.g. `C:\Dir\file.txt`
* `RelativeFilePath` - representing a relative path containing a file name, e.g. `Dir\file.txt`
* `AbsoluteDirPath` - representing an absolute path not containing a file name, e.g. `C:\Dir\`
* `RelativeDirPath` - representing a relative path not containing a file name, e.g. `Dir\`

Having all these types, we can now change the signature of the `Backup()` method to:

```csharp
void Backup(AbsoluteFilePath path);
```

Note that we do not have to explain the constraints in the argument name - we can just call it `path`, because the type already says what needs to be said. And by the way, no one will be able to pass e.g. a `RelativeDirPath` now by accident, not to mention a string.

Another property of making variability among values explicit is that some methods for conversions should be provided. For example, when all we've got is an `AbsoluteDirPath`, but we still want to invoke the `Backup()` method, we need to convert our path to an `AbsoluteFilePath` by adding a file name, that can be represented by a value objects itself (let's call it a `FileName`). The code that does the conversion then looks like this:

```csharp
//below dirPath is an instance of AbsoluteDirPath:
AbsoluteFilePath filePath = dirPath + FileName.Value("backup.zip");
```

Of course, we create conversion methods only where a conversion makes sense.

And that's it for the path example. 

### Summing up the implicit vs. explicit discussion

Note that while in the previous example (the one with money), making the variability (in currency) among values implicit helped us achieve our design goals, in this example it made more sense to do exactly the opposite - to make the variability (in both absolute/relative and to file/to directory axes) as explicit as to create a separate type for each combination of constraints. 

If we choose the implicit path, we can treat all variations the same, since they are all of the same type. If we decide on the explicit path, we end up with several types that are usually incompatible and we allow conversions between them where such conversions make sense.

## Special values

Some value types has values that are so specific asto have their own name. For example, a string value consisting of `""` is called an empty string. A XXXXXXXX (TODO put a maximum 32 bit integer here) is called "maximum 32 bit integer value". 

For example, in C#, we have `Int32.Max` and `Int32.Min` which are constants representing a maximum and minimum value of 32 bit integer. `string.Empty` representing an empty string.

In Java, we have things like `Duration.ZERO` to represent a zero duration or `DayOfWeek.MONDAY` to represent a specific day of week.

For such values, is makes a lot of sense to make them globally accessible from the value object classes, as is done in all the above examples from C# and Java library. This is because they are immutable, so the global accessibility does not cause any hurt. For example, we can imagine `string.Empty` implemented like this:

```csharp
public class string
{
  //...
  public const string Empty = "";
  //...
}
```

The additional `const` modifier ensures no one will assign any new value to the `Empty` field. By the way, we can use `const` only for types that have literal values, like a string. For many others, we will have to use a `static readonly` (or `final static` in case of Java) modifier. To demonstrate it, let's go back to the money example from this chapter and imagine we want to have a special value called `None` to symbolize no money in any currency. As our `Money` type has no literals, we cannot use the `const` modifier, so instead we have to do this:

```csharp
public class Money
{
  //...
  
  public static readonly 
    Money None = new Money(0, Currencies.Whatever);
  
  //...
}
```

This idiom is the only exception I know from the rule I gave you several chapters ago about not using static fields at all. Anyway, now that we have this `None` value, we can use it like this:

```csharp
if(accountBalance == Money.None)
{
  //...
}
```

## Value types and Tell Don't Ask

When talking about the web of objects metaphor, I stressed that objects should be told what to do, not asked for information. I also said that if a responsibility is too big for a single object to handle, it does not try to achieve it alone, but rather distribute the work further to other objects by sending messages to them. I said that preferrably (TODO check spelling) we would like to have mostly `void` methods that accept their context as arguments.

What about values? Does that metaphor apply to them? And if so, then how? And what about Tell Don't Ask?

First of all, values do not belong to the web of objects metaphor, alhough in almost all object oriented languages, values are implemented using the same mechanism as objects - a class[^csharpstructs]. Values can be passed between objects in messages, but we don't talk about values sending messages.

A conclusion from this is that values cannot be composed of objects. Values can be composed of values (as our `Path` type had a `string` inside), which ensures their immutability. Also, they can occasionally can objects as parameters of their methods (remember the `ProductName` class from previous chapters? I had a method `ToString()` accepting a `Format` interface), but this is more of an exception than a rule.

If the above statements about values are true, then it means values simply cannot be expected to conform to Tell Don't Ask. Sure, we want them to be encapsulate domain concepts, to provide higher-level interface etc., so we do **not** want values to become plain data structures like the ones we know from C, but the nature of values is to transfer pieces of data. 

As such, we expect values to contain a lot of query methods (although, as I said, we strive for something more abstract and more useful than mere "getter" methods most of the time). For example, you might like the idea of having a set of path-related classes (like `AbsoluteFilePath`), but in the end, you will have to somehow interact with a host of third party APIs that don't know anything about those classes. Then, a `ToString()` method that just returns internally held value will come in handy.




## Summary




[^wecoulduseextensionmethods]: I could use extension methods to make the example even more idiomatic, e.g. to be able to write `5.Dollars()`, but I don't want to go to far in the land of idioms specific to any language, because my goal is an audience wider than just C# programmers.  

[^atmafilesystem]: this example uses a library called Atma Filesystem: TODO hyperlink to nuget

[^atmafilesystem2]: for reference, please take a look at TODO hyperlink

[^tddbyexample]: This example is loosely based on Kent Beck's book Test Driven Development By Example. based on  TODO add reference to Kent's book

[^csharpstructs] C# has structs, which can sometimes come in handy when implementing values, especially starting from C# 5.0 where they got a bit more powerful.

TODO check whether the currencies are written uppercase in Kent's book



