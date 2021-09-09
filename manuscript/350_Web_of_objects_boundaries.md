# Reaching the web of objects boundaries

When doing the outside-in interface discovery and implementing collaborator after collaborator, there's often a point when we reach the boundaries of our application, which means we must execute some kind of I/O operation (like calling external API via HTTP) or use a class that is part of some kind of third-party package (e.g. provided by our framework of choice). In these places, the freedom with which we could shape our object-oriented reality is hugely constrained by these dependencies. Even though we still drive the behaviors using our intention, we need to be increasingly aware that the direction we take has to match the technology with which we communicate with the outside world at the end.

There are multiple examples of resources that lay on the boundaries of our web of objects. Files, threads, clock, database, communication channels (e.g. http, service bus, websockets), graphical user interfaces... these resources are used to implement mechanisms for things that play roles in our design. We need to somehow reach a consensus between what these implementation mechanisms require to do their job and what is the domain role they need to fit.

In this chapter, I describe several examples of reaching this consensus with some guidance of how to approach them. The gist of this guidance is to hide such dependencies below interfaces that model the roles we need.

## What time is it?

Consider getting the current time.

Imagine our application manages sessions that expire at one point. We model the concept of a session by creating a class called `Session` and allow querying it whether it's expired or not. To answer that question, the session needs to know its expiry time and the current time, and calculate their difference. In such a case, we can model the source of current time as some kind of "clock" abstraction. Here are several examples of how to do that.

### A query for the current time with a mock framework

We can model the clock as merely a service that delivers current time (e.g. via some kind of `.CurrentTime()` method) The `Session` class is thus responsible for doing the calculation. An example Statement describing this behavior could look like this:

```csharp
[Fact] public void
ShouldSayItIsExpiredWhenItsPastItsExpiryDate()
{
 //GIVEN
 var expiryDate = Any.DateTime();
 var clock = Substitute.For<Clock>();
 var session = new Session(expiryDate, clock);

 clock.CurrentTime().Returns(expiryDate + TimeSpan.FromTicks(1));
 
 //WHEN
 var isExpired = session.IsExpired();

 //THEN
 Assert.True(isExpired);
}
```

I stubbed my clock to return a specific point in time to make executing the Statement deterministic and to describe a specific behavior, which is indication of session expiry.

### More responsibility allocation in the clock abstraction

Our previous attempt at the clock abstraction was just to abstract away the services granted by a real time source ("what's the current time?"). We can make this abstraction fit our specific use case better by giving it a `IsPast()` method that will accept an expiry time and just tell us whether it's past that time or not. One of the Statements using the `IsPast()` method could look like this:

```csharp
[Fact] public void
ShouldSayItIsExpiredWhenItsPastItsExpiryDate()
{
 //GIVEN
 var expiryDate = Any.DateTime();
 var clock = Substitute.For<Clock>();
 var session = new Session(expiryDate, clock);

 clock.IsPast(expiryDate).Returns(true);
 
 //WHEN
 var isExpired = session.IsExpired();

 //THEN
 Assert.True(isExpired);
}
```

This time, I am also using a mock to stand in for a `Clock` implementation.

The upside of this is that the abstraction is more tuned to our specific need. The downside is that the calculation of the time difference between current and expiry time is done in a class that will be at least very difficult to describe with a deterministic Statement as it will rely on the system clock.

### A fake clock

If the services provided by an interface such as `Clock` are simple enough, we can create our own implementation for use in Statements. Such implementation would take away all the pain of working with a real external resource and instead give us a simplified or more controllable version. For example, a fake implementation of the `Clock` interface might look like this:

```csharp
class SettableClock : Clock
{
 public DateTime _currentTime = DateTime.MinValue;

 public void SetCurrentTime(DateTime currentTime)
 {
  _currentTime = currentTime;
 }

 public DateTime CurrentTime()
 {
  return _currentTime;
 }
}
```

This implementation of `Clock` has not only a getter for the current time (which is inherited from the `Clock` interface), but it also has a setter. The "current time" as returned by the `SettableClock` instance does not come from system clock, but can instead be set to a specific, deterministic value. Here's how the use of `SettableClock` looks like in a Statement:

```csharp
[Fact] public void
ShouldSayItIsExpiredWhenItsPastItsExpiryDate()
{
 //GIVEN
 var expiryDate = Any.DateTime();
 var clock = new SettableClock();
 var session = new Session(expiryDate, clock);

 clock.SetCurrentTime(expiryDate + TimeSpan.FromSeconds(1));
 
 //WHEN
 var isExpired = session.IsExpired();

 //THEN
 Assert.True(isExpired);
}
```

I could also do the second version of the clock - the one with `IsPast()` method - in a very similar way. I would just need to put some extra intelligence into the `SettableClock`, duplicating tiny bits of real `Clock` implementation. In this case, it's not a big issue, but there can be cases when this can be an overkill. For a fake to be warranted, the fake implementation must be much, much simpler than the real implementation that we intend to use.

An advantage of a fake is that it can be reused (e.g. a reusable settable clock abstraction can be found in Noda Time and Joda Time libraries). A disadvantage is that the more sophisticated code sits inside the fake, the more probable it is that it will contain bugs. If a very intelligent fake is still worth it despite the complexity (and I've seen several cases when it was), I'd consider writing some Specification around the fake implementation.

### Other usages of this approach

The same approach as we used with a system clock can be taken with other sources of non-deterministic values, e.g. random value generators.

## Timers

Timers are objects that allow deferred or periodic code execution, usually in an asynchronous manner.

I> In C# these days, almost everything asynchronous is done using `Task` class, and `async`-`await` keywords. Despite that, I decided to leave them out of this chapter to make it better understandable to non-C# users. So forgive me for a little less realistic example and I hope you can map that to your modern code.

Typically, a timer usage is composed of three stages:

1. Scheduling the timer expiry for a specific point in time, passing it a callback to execute on expiry. Usually a timer can be told whether to continue the next cycle after the current one is finished, or stop.
1. When the timer expiry is scheduled, it runs asynchronously in some kind of background thread.
1. When the timer expires, the callback that was passed during scheduling is executed and the timer either begins another cycle, or stops.

From the point of view of our collaboration design, the important parts are point 1 and 3. Let's tackle them one by one.

### Scheduling a periodic task

First let's imagine we create a new session, add it to some kind of cache and set a timer expiring every 10 seconds to check whether privileges of the session owner are still valid. A Statement for that might look like this:

```csharp
[Fact] public void
ShouldAddCreatedSessionToCacheAndScheduleItsPeriodicPrivilegesRefreshWhenExecuted()
{
 //GIVEN
 var sessionData = Any.Instance<SessionData>();
 var id = Any.Instance<SessionId>();
 var session = Any.Instance<Session>();
 var sessionFactory = Substitute.For<SessionFactory>();
 var cache = Substitute.For<SessionCache>();
 var periodicTasks = Substitute.For<PeriodicTasks>();
 var command = new CreateSessionCommand(id, sessionFactory, cache, sessionData);
 
 sessionFactory.CreateNewSessionFrom(sessionData).Returns(session);

 //WHEN
 command.Execute();

 //THEN
 Received.InOrder(() =>
 {
  cache.Add(id, session);
  periodicTasks.RunEvery(TimeSpan.FromSeconds(10), session.RefreshPrivileges);
 });
}
```

Note that I created a `PeriodicTasks` interface to model an abstraction for running... well... periodic tasks. This seems like a generic abstraction and might be made a bit more domain-oriented if needed. For our toy example, it should do. The `PeriodicTask` interface looks like this:

```csharp
interface PeriodicTasks
{
 void RunEvery(TimeSpan period, Action actionRanOnExpiry);
}
```

In the Statement above, I only specified that a periodic operation should be scheduled. Specifying how the `PeriodicTasks` implementation carries out its job is out of scope.

The `PeriodicTasks` interface is designed so that I can pass a method group instead of a lambda, because requiring lambdas would make it harder to compare arguments between expected and actual invocations in the Statement. So if I wanted to schedule a periodic invocation of a method that has an argument (say, a single `int`), I would add a `RunEvery` method that would look like this:

```csharp
interface PeriodicTasks
{
 void RunEvery(TimeSpan period, Action<int> actionRanOnExpiry, int argument);
}
```

or I could make the method generic:

```csharp
interface PeriodicTasks
{
 void RunEvery<TArg>(TimeSpan period, Action<TArg> actionRanOnExpiry, TArg argument);
}
```

If I needed different sets of arguments, I could just add more methods to the `PeriodicTasks` interface, provided I don't couple it to any specific domain-related class (if I needed that, I'd rather split `PeriodicTasks` into several more domain-specific interfaces).

### Expiry

Specifying a case when the timer expires and the scheduled task needs to be executed is even easier. We just need to do what the timer code would do - invoke the scheduled code from our Statement. For my session example, assuming that an implementation of the `Session` interface is a class called `UserSession`, I could the following Statement to describe a behavior where losing privileges to access session content leads to event being generated:

```csharp
[Fact] public void 
ShouldNotifyObserverThatSessionIsClosedOnPrivilegesRefreshWhenUserLosesAccessToSessionContent()
{
 //GIVEN
 var user = Substitute.For<User>();
 var sessionContent = Any.Instance<SessionContent>();
 var sessionEventObserver = Substitute.For<SessionEventObserver>();
 var id = Any.Instance<SessionId>();
 var session = new UserSession(id, sessionContent, user, sessionEventObserver);
 
 user.HasAccessTo(sessionContent).Returns(false);

 //WHEN
 session.RefreshPrivileges();

 //THEN
 sessionEventObserver.Received(1).OnSessionClosed(id);
}
```

For the purpose of this example, I am skipping other Statements (for example you might want to specify a behavior when the `RefreshPrivileges` is called multiple times as that's what the timer is ultimately going to do) and multithreaded access (timer callbacks are typically executed from other threads, so if they access mutable state, this state must be protected from concurrent modification).

## Threads

I usually see threads used in two situations:

1. To run several tasks in parallel. For example, we have several independent, heavy calculations and we want to do them at the same time (not one after another) to make the execution of the code finish earlier.
1. To defer execution of some logic to an asynchronous background job. This job can still be running even after the method that started it finishes execution.

### Parallel execution

In the first case -- one of parallel execution -- multithreading is an implementation detail of the method being called by the Statement. The Statement itself doesn't have to know anything about it. Sometimes, though, it needs to know that certain operations might not execute in the same order every time.

Consider the an example, where we evaluate payment for multiple employees. Each evaluation is a costly operation, so implementation-wise, we want to do them in parallel. A Statement describing such operation could look like this:

```csharp
public void [Fact]
ShouldEvaluatePaymentForAllEmployees()
{
 //GIVEN
 var employee1 = Substitute.For<Employee>();
 var employee2 = Substitute.For<Employee>();
 var employee3 = Substitute.For<Employee>();
 var employees = new Employees(employee1, employee2, employee3);

 //WHEN
 employees.EvaluatePayment();

 //THEN
 employee1.Received(1).EvaluatePayment();
 employee2.Received(1).EvaluatePayment();
 employee3.Received(1).EvaluatePayment();
}
```

Note that the Statement doesn't mention multithreading at all, because that's the implementation detail of the `EvaluatePayment` method on `Employees`. However, note also that the Statement doesn't specify the order in which the payment is evaluated for each employee. Part of that is because the order doesn't matter and the Statement accurately describes that. If, however, the Statement specified the order, it would not only be overspecified, but also could be evaluated as true or false non-deterministically. That's because in the case of parallel execution, the order in which the methods would be called on each employee could be different.

### Background task

Using threads to run background tasks is like using timers that run only once. Just use a similar approach to timers.

## Others

There are other dependencies like I/O devices, random value generators or third-party SDKs (e.g. an SDK for connecting to a message bus), but I won't go into them as the strategy for them is the same - don't use them directly in your domain-related code. Instead, think about what role they play domain-wise and model that role as an interface. Then use the problematic resource inside a class implementing this interface. Such class will be covered by another kind of Specification which I will cover further in the book.