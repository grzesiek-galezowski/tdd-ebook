# Aspects of value objects design

In the last chapter, we examined the anatomy of a value object. Still, there are several more aspects of value objects design that I still need to mention to give you a full picture.

## Immutability

I mentioned before that value objects are usually immutable. Some say immutability is the core part of something being a value (e.g. Kent Beck goes as far as to say that 1 is always 1 and will never become 2), while others don't consider it as a hard constraint. One way or another, designing value objects as immutable has served me exceptionally well to the point that I don't even consider writing value object classes that are mutable. Allow me to describe three of the reasons I consider immutability a key constraint for value objects.

### Accidental change of hash code

Many times, values are used as keys in hash maps (.e.g .NET's `Dictionary<K,V>` is essentially a hash map). Let's imagine we have a dictionary indexed with instances of a type called `KeyObject`:

```csharp
Dictionary<KeyObject, AnObject> _objects;
```

When we use a `KeyObject` to insert a value into a dictionary:

```csharp
KeyObject key = ...
_objects[key] = anObject;
```

then its hash code is calculated and stored separately from the original key.

When we read from the dictionary using the same key:

```csharp
AnObject anObject = _objects[key];
```

then its hash code is calculated again and only when the hash codes match are the key objects compared for equality. 

Thus, in order to successfully retrieve an object from a dictionary with a key, this key object must meet the following conditions in regard to the key we previously used to put the object in:

1. The `GetHashCode()` method of the key used to retrieve the object must return the same hash code as that of the key used to insert the object did during the insertion,
1. The `Equals()` method must indicate that both the key used to insert the object and the key used to retrieve it are equal.

The bottom line is: if any of the two conditions is not met, we cannot expect to get the item we inserted.

I mentioned in the previous chapter that hash code of a value object is calculated based on its state. A conclusion from this is that each time we change the state of a value object, its hash code changes as well. So, let's assume our `KeyObject` allows changing its state, e.g. by using a method `SetName()`. Thus, we can do the following:

```csharp
KeyObject key = KeyObject.With("name");
_objects[key] = new AnObject();

// we mutate the state:
key.SetName("name2");

//do we get the inserted object or not?
var objectIInsertedTwoLinesAgo = _objects[key];
```

This will throw a `KeyNotFoundException` (this is the dictionary's behavior when it is indexed with a key it does not contain), as the hash code when retrieving the item is different than it was when inserting it. By changing the state of the `key` with the statement: `key.SetName("name2");`, I also changed its calculated hash code, so when I asked for the previously inserted object with `_objects[val]`, I tried to access an entirely different place in the dictionary than the one where my object is stored.

As I find it a quite common situation that value objects end up as keys inside dictionaries, I'd rather leave them immutable to avoid nasty surprises. 

### Accidental modification by foreign code

I bet many who code or coded in Java know its `Date` class. `Date` behaves like a value (it has overloaded equality and hash code generation), but is mutable (with methods like `setMonth()`, `setTime()`, `setHours()` etc.). 

Typically, value objects tend to be passed a lot throughout an application and used in calculations. Many Java programmers at least once exposed a `Date` value using a getter:

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

The `getDate()` method allows users of the `ObjectWithDate` class to access the date. But remember, a date object is mutable and a getter returns a reference! Everyone who calls the getter gains access to the internally stored instance of `Date` and can modify it like this:

```java
ObjectWithDate o = new ObjectWithDate();

o.getDate().setTime(date.getTime() + 10000); //oops!

return date;
```

Of course, no one would do it in the same line like on the snippet above, but usually, this date was accessed, assigned to a variable and passed through several methods, one of which did something like this:

```java
public void doSomething(Date date) {
  date.setTime(date.getTime() + 10000); //oops!
  this.nextUpdateTime = date;
}
```

This led to unpredicted situations as the date objects were accidentally modified far, far away from the place they were retrieved[^aliasingbug].

As most of the time it wasn't the intention, the problem of date mutability forced us to manually create a copy each time their code returned a date:

```java
public Date getDate() {
  return (Date)_date.clone();
}
```

which many of us tended to forget. This cloning approach, by the way, may have introduced a performance penalty because the objects were cloned every time, even when the code that was calling the `getDate()` had no intention of modifying the date[^dateoptimization].

Even when we follow the suggestion of avoiding getters, the same applies when our class passes the date somewhere. Look at the body of a method, called `dumptInto()`:

```java
public void dumpInto(Destination destination) {
  destination.write(this.date); //passing reference to mutable object
}
```

Here, the `destination` is allowed to modify the date it receives anyway it likes, which, again, is usually against developers' intentions.

I saw many, many issues in production code caused by the mutability of Java `Date` type alone. That's one of the reasons the new time library in Java 8 (`java.time`) contains immutable types for time and date. When a type is immutable, you can safely return its instance or pass it somewhere without having to worry that someone will overwrite your local state against your will.

### Thread safety

When mutable values are shared between threads, there is a risk that they are changed by several threads at the same time or modified by one thread while being read by another. This can cause data corruption. Like I mentioned, value objects tend to be created many times in many places and passed inside methods or returned as results a lot - this seems to be their nature. Thus, this risk of data corruption or inconsistency raises.

Imagine our code took hold of a value object of type `Credentials`, containing username and password. In addition, let's assume `Credentials` objects are mutable. If so, one thread may accidentally modify the object while it is used by another thread, leading to data inconsistency. So, provided we need to pass login and password separately to a third-party security mechanism, we may run into the following:

```csharp
public void LogIn(Credentials credentials)
{
  thirdPartySecuritySystem.LogIn(
    credentials.GetLogin(),
    //imagine password is modified before the next line
    //from a different thread
    credentials.GetPassword())
}
```

On the other hand, when an object is immutable, there are no multithreading concerns. If a piece of data is read-only, it can be safely read by as many threads as we like. After all, no one is able to modify the state of an object, so there is no possibility of inconsistency[^functionallanguages].

### If not mutability, then what?

For the reasons I described, I consider immutability a crucial aspect of value object design and in this book, when I talk about value objects, I assume they are immutable.

Still there is one question that remains unanswered: what about a situation when I really want to:

* replace all occurences of letter 'r' in a string to letter 'l'?
* move a date forward by five days?
* add a file name to an absolute directory path to form an absolute file path (e.g. "C:\" + "myFile.txt" = "C:\myFile.txt")?

If I am not allowed to modify an existing value, how can I achieve such goals?

The answer is simple - value objects have operations that, instead of modifying the existing object, return a new one, with the state we are expecting. The old value remains unmodified. This is the way e.g. strings behave in Java and C#.

Just to address the three examples I mentioned

* when I have an existing `string` and want to replace every occurence of letter `r` with letter `l`:

```csharp
string oldString = "rrrr";
string newString = oldString.Replace('r', 'l');
//oldString is still "rrrr", newString is "llll"
```

* When I want to move a date forward by five days:

```csharp
DateTime oldDate = DateTime.Now;
DateTime newString = oldDate + TimeSpan.FromDays(5);
//oldDate is unchanged, newDate is later by 5 days
```

* When I want to add a file name to a directory path to form an absolute file path[^atmafilesystem]:

```csharp
AbsoluteDirectoryPath oldPath 
  = AbsoluteDirectoryPath.Value(@"C:\Directory");
AbsoluteFilePath newPath = oldPath + FileName.Value("file.txt");
//oldPath is "C:\Directory", newPath is "C:\Directory\file.txt"
```

So, again, anytime we want to have a value based on a previous value, instead of modifying the previous object, we create a new object with desired state.

## Handling of variability

As in ordinary objects, there can be some variability in the world of values. For example, money can be dollars, pounds, zlotys (Polish money), euros etc. Another example of something that can be modelled as a value are path values (you know, `C:\Directory\file.txt` or `/usr/bin/sh`) -  there can be absolute paths, relative paths, paths to files and paths pointing to directories, we can have unix paths and Windows paths.

Contrary to ordinary objects, however, where we solved variability by using interfaces and different implementations (e.g. we had an `Alarm` interface with implementing classes such as `LoudAlarm` or `SilentAlarm`), in the world values we do it differenly. Taking the alarms I just mentioned as an example, we can say that the different kinds of alarms varied in how they fulfilled the responsibility of signaling that they were turned on (we said they responded to the same message with -- sometimes entirely -- different behaviors). Variability in the world of values is typically not behavioral in the same way as in case of objects. Let's consider the following examples:

1. Money can be dollars, punds, zlotys etc., and the different kinds of currencies differ in what exchange rates are applied to them (e.g. "how many dollars do I get from 10 Euros and how many from 10 Punds?"), which is not a behavioral distinction. Thus, polymorphism does not fit this case.
1. Paths can be absolute and relative, poiting to files and directories. They differ in what operations can be applied to them. E.g. we can imagine that for paths pointing to files, we can have an operation called `GetFileName()`, which doesn't make sense for a path pointing to a directory. While this is a behavioral distinction, we cannot say that "directory path" and a "file path" are variants of the same abstraction - rather, that are two different abstractions. Thus, polymorphism does not seem to be the answer here either.
1. Sometimes, we may want to have a behavioral distinction, like in the following example. We have a value class representing product names and  we want to write in several different formats depending on situation.

How do we model this variability? I usually consider three basic approaches, each applicable in different contexts:

* implicit - which would apply to the money example,
* explicit - which would fit the paths case nicely,
* delegated - which would fit the case of product names.

Let me give you a longer description of each of these approaches.

### Implicit variability

Let's go back to the example of modeling money using value objects[^tddbyexample]. Money can have different currencies, but we don't want to treat each currency in any special way. The only things that are impacted by currency are rates by which we exchange them for other currencies. We want the rest of our program to be unaware of which currency it's dealing with at the moment (it may even work with several values, each of different currency, at the same time, during one calculation or another business operation).

This leads us to making the differencies between currencies implicit, i.e. we will have a single type called `Money`, which will not expose its currency at all. We only have to tell what the currency is when we create an instance:

```csharp
Money tenPounds = Money.Pounds(10);
Money tenBucks = Money.Dollars(10);
Money tenYens = Money.Yens(10);
```

and when we want to know the concrete amount in a given currency:

```csharp
//doesn't matter which currency it is, we want dollars.
decimal amountOfDollarsOnMyAccount = mySavings.AmmountOfDollars();
```

other than that, we are allowed to mix different currencies whenever and wherever we like[^wecoulduseextensionmethods]:

```csharp
Money mySavings =
  Money.Dollars(100) +
  Money.Euros(200) +
  Money.Zlotys(1000);
```

This appeoach works under the assumption that all of our logic is common for all kinds of money and we don't have any special piece of logic just for Pounds or just for Euros that we don't want to pass other currencies into by mistake[^naivemoneyexample].

To sum up, we designed the `Money` type so that the variability of currency is implicit - most of the code is simply unaware of it and it is gracefully handled under the hood inside the `Money` class.

### Explicit variability

There are times, however, when we want the variability to be explicit, i.e. modeled using different types. Filesystem paths are a good example.

For starters, let's imagine we have the following method for creating a backup archives that accepts a destination path (for now as a string - we'll get to path objects later) as its input parameter:

```csharp
void Backup(string destinationPath);
```

This method has one obvious drawback - its signature doesn't tell anything about the characteristics of the destination path, which begs some questions:

* Should it be an absolute path, or a relative path. If relative, then relative to what?
* Should the path contain a file name for the backup file, or should it be just a directory path and file name will be given according to some kind of pattern (e.g. a word "backup" + current timestamp)?
* Or maybe the file name in the path is optional and if none is given, then a default name is used?

These questions suggest that the current design doesn't convey the intention explicitly enough. We can try to work around it by changing the name of the parameter to hint the constraints, like this:

```csharp
void Backup(string absoluteFilePath);
```

but the effectiveness of that is based solely on someone reading the argument name and besides, before a path (passed as a string) reaches this method, it is usually passed around several times and it's very hard to keep track of what is inside this string, so it becomes easy to mess things up and pass e.g. a relative path where an absolute one is expected. The compiler does not enforce any constraints. More than that, one can pass an argument that's not even a path, because a `string` can contain any arbitrary content.

Looks to me like a good situation to introduce a value object, but what kind of type or types should we introduce? Surely, we could create a single type called `Path`[^javahaspath] that would have methods like `IsAbsolute()`, `IsRelative()`, `IsFilePath()` and `IsDirectoryPath()` (i.e. it would handle the variability implicitly), which would solve (only - we'll see that shortly) one part of the problem - the signature would be:

```csharp
void Backup(Path absoluteFilePath);
```

and we would not be able to pass an arbitrary string, only an instance of a `Path`, which may expose a factory method that checks whether the string passed is in a proper format:

```csharp
//the following could throw an exception
//because the argument is not in a proper format
Path path = Path.Value(@"C:\C:\C:\C:\//\/\/");
```

Such factory method could throw an exception at the time of path object creation. This is important - previously, when we did not have the value object, we could assign garbage to a string, pass it between several objects and get an exception from the `Backup()` method. Now, that we modeled paths as value objects, there is a high probability that the `Path` type will be used as early as possible in the chain of calls. Thanks to this and to the validation inside the factory method, we will get an exception much closer to the place where the mistake was made, not at the end of the call chain.

So yeah, introducing a general `Path` value object might solve some problems, but not all of them. Still, the signature of the `Backup()` method does not signal that the path expected must be an absolute path to a file, so one may pass a relative path or a path to a directory, even though only one kind of path is acceptable.

In this case, the varying properties of paths are not just an obstacle, a problem to solve, like in case of money. They are they key differentiating factor in choosing whether a behavior is appropriate for a value or not. In such case, it makes a lot of sense to create several different value types, each representing a different set of path constraints.

Thus, we may decide to introduce types like[^atmafilesystem2]:

* `AbsoluteFilePath` - representing an absolute path containing a file name, e.g. `C:\Dir\file.txt`
* `RelativeFilePath` - representing a relative path containing a file name, e.g. `Dir\file.txt`
* `AbsoluteDirPath` - representing an absolute path not containing a file name, e.g. `C:\Dir\`
* `RelativeDirPath` - representing a relative path not containing a file name, e.g. `Dir\`

Having all these types, we can now change the signature of the `Backup()` method to:

```csharp
void Backup(AbsoluteFilePath path);
```

Note that we don't have to explain the constraints with the name of the argument - we can just call it `path`, because the type already says what needs to be said. And by the way, no one will be able to pass e.g. a `RelativeDirPath` now by accident, not to mention an arbitrary string.

Making variability among values explicit by creating separate types usually leads us to introduce some conversion methods between these types where such conversion is legal. For example, when all we've got is an `AbsoluteDirPath`, but we still want to invoke the `Backup()` method, we need to convert our path to an `AbsoluteFilePath` by adding a file name, that can be represented by a value objects itself (let's call its class `FileName`). In C#, we can use operator overloading for some of the conversions, e.g. the `+` operator would do nicely for appending a file name to a directory path. The code that does the conversion would then look like this:

```csharp
AbsoluteDirPath dirPath = ...
...
FileName fileName = ...
...
//'+' operator is overloaded to handle the conversion:
AbsoluteFilePath filePath = dirPath + fileName;
```

Of course, we create conversion methods only where they makes sense from the point of view of the domain we are modelling. We wouldn't put a conversion method inside `AbsoluteDirectoryPath` that would combine it with another `AbsoluteDirectoryPath`[^pathscomplex].

### Delegated variability

Finally, we can achieve variability by delegating the varying behavior to an interface and have a value object accept that interface implementation as a method parameter. An example of this would be the `Product` class from the previous chapter that had the following method declared:

```csharp
public string ToString(Format format);
```

where `Format` was an interface and we passed different implementations of this interface to this method, e.g. `ScreenFormat` or `ReportingFormat`. Note that having the `Format` as a method parameter instead of e.g. a constructor parameter allows us to uphold the value semantics, because `Format` is not part of the object but rather a "guest helper". Thanks to this, we are free from dillemas such as "is the name 'laptop' formatted for screen equal to 'laptop' formatted for a report?"

### Summing up the implicit vs explicit vs delegated discussion

Note that while in the first example (the one with money), making the variability (in currency) among values implicit helped us achieve our design goals, in the path example it made more sense to do exactly the opposite - to make the variability (in both absolute/relative and to file/to directory axes) as explicit as to create a separate type for each combination of constraints.

If we choose the implicit approach, we can treat all variations the same, since they are all of the same type. If we decide on the explicit approach, we end up with several types that are usually incompatible and we allow conversions between them where such conversions make sense. This is useful when we want some pieces of our program to be explicitly compatible with only one of the variations.

I must say I find delegated variability a rare case (formatting the conversion to string is a typical example) and throughout my entire career I had maybe one or two situations where I had to resort to it. However, some libraries use this approach and in your particular domain or type of applications such cases may be much more typical.

## Special values

Some value types have values that are so specific that they have their own names. For example, a string value consisting of `""` is called "an empty string". `2,147,483,647` is called "a maximum 32 bit integer value". These special values make their way into value objects design. For example, in C#, we have `Int32.MaxValue` and `Int32.MinValue` which are constants representing a maximum and minimum value of 32 bit integer and `string.Empty` representing an empty string. In Java, we have things like `Duration.ZERO` to represent a zero duration or `DayOfWeek.MONDAY` to represent a specific day of week.

For such values, the common practice I've seen is making them globally accessible from the value object classes, as is done in all the above examples from C# and Java. This is because values are immutable, so the global accessibility doesn't hurt. For example, we can imagine `string.Empty` implemented like this:

```csharp
public class string
{
  //...
  public const string Empty = "";
  //...
}
```

The additional `const` modifier ensures no one will assign any new value to the `Empty` field. By the way, in C#, we can use `const` only for types that have literal values, like a string or an `int`. For our custom value objects, we will have to use a `static readonly` modifier (or `static final` in case of Java). To demonstrate it, let's go back to the money example from this chapter and imagine we want to have a special value called `None` to symbolize no money in any currency. As our `Money` type has no literals, we cannot use the `const` modifier, so instead we have to do something like this:

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

When talking about the "web of objects" metaphor, I stressed that objects should be told what to do, not asked for information. I also wrote that if a responsibility is too big for a single object to handle, it shouldn't try to achieve it alone, but rather delegate the work further to other objects by sending messages to them. I mentioned that preferably we would like to have mostly `void` methods that accept their context as arguments.

What about values? Does that metaphor apply to them? And if so, then how? And what about Tell Don't Ask?

First of all, values don't appear explicitly in the web of objects metaphor, at least they're not "nodes" in this web. Although in almost all object-oriented languages, values are implemented using the same mechanism as objects - classes[^csharpstructs], I treat them as somewhat different kind of construct with their own set of rules and constraints. Values can be passed between objects in messages, but we don't talk about values sending messages by themselves.

A conclusion from this may be that values should not be composed of objects (understood as nodes in the "web"). Values should be composed of other values (as our `Path` type had a `string` inside), which ensures their immutability. Also, they can occasionally can objects as parameters of their methods (like the `ProductName` class from previous chapter that had a method `ToString()` accepting a `Format` interface), but this is more of an exception than a rule. In rare cases, I need to use a collection inside a value object. Collections in Java and C# are not typically treated as values, so this is kind of an exception from the rule. Still, when I use collections inside value objects, I tend to use the immutable ones, like [ImmutableList](https://msdn.microsoft.com/en-us/library/dn467185(v=vs.111).aspx).

If the above statements about values are true, then it means values simply cannot be expected to conform to Tell Don't Ask. Sure, we want them to be encapsulate domain concepts, to provide higher-level interface etc., so we struggle very hard for the value objects not to become plain data structures like the ones we know from C, but the nature of values is rather as "intelligent pieces of data" rather than "abstract sets of behaviors".

As such, we expect values to contain query methods (although, as I said, we strive for something more abstract and more useful than mere "getter" methods most of the time). For example, you might like the idea of having a set of path-related classes (like `AbsoluteFilePath`), but in the end, you will have to somehow interact with a host of third party APIs that don't know anything about those classes. Then, a `ToString()` method that just returns internally held value will come in handy.

## Summary

This concludes my writing on value objects. I never thought there would be so much to discuss as to how I believe they should be designed. For readers interested in seeing a state-of-the-art case study of value objects, I recommend looking at [Noda Time](https://nodatime.org/) (for C#) and [Joda Time](http://www.joda.org/joda-time) (for Java) libraries (or [Java 8 new time and date API](http://www.oracle.com/technetwork/articles/java/jf14-date-time-2125367.html)).

[^functionallanguages]: This is one of the reasons why functional languages, where data is immutable by default, gain a lot of attention in domains where doing many things in parallel is necessary.

[^wecoulduseextensionmethods]: I could use extension methods to make the example even more idiomatic, e.g. to be able to write `5.Dollars()`, but I don't want to go to far in the land of idioms specific to any language, because my goal is an audience wider than just C# programmers.  

[^atmafilesystem]: this example uses a library called Atma Filesystem: https://www.nuget.org/packages/AtmaFilesystem/

[^atmafilesystem2]: for reference, please take a look at https://www.nuget.org/packages/AtmaFilesystem/

[^tddbyexample]: This example is loosely based on Kent Beck's book Test-Driven Development By Example.

[^csharpstructs]: C# has structs, which can sometimes come in handy when implementing values, even though they have some constraints (see https://stackoverflow.com/questions/333829/why-cant-i-define-a-default-constructor-for-a-struct-in-net).

[^naivemoneyexample]: I am aware that this example looks a bit naive - after all, adding money in several currencies would imply they need to be converted to a single currency and the exchange rates would then apply, which could make us lose money. Kent Beck acknowledged and solved this problem in his book Test-Driven Development By Example - be sure to take a look what he came up with if you're interested. 

[^javahaspath]: This is what Java did. I don't declare that Java designers made a bad decision - a single `Path` class is probably much more versatile. The only thing I'm saying is that this design is not optimal for our particular scenario. 

[^dateoptimization]: Unless Java optimizes it somehow, e.g. by using copy-on-write approach.

[^pathscomplex]: frankly, as in the case of money, the vision of paths I described here is a bit naive. Still, this naive view may be all what we need in our particular case.

[^aliasingbug]: This is sometimes called "aliasing bug": https://martinfowler.com/bliki/AliasingBug.html
