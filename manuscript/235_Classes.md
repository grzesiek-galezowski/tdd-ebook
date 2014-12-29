# Classes

We already covered interfaces and protocols. In our quest for composability, We need to look at classes as well.

Classes implement and use interfaces, and communicate using protocols, so it may seem we are already done with them. The truth is that classes are still interesting on their own and there are few concepts related to them that need explanation.

## Single Responsibility

I already said that we want our system to be a web of composable objects. Obviously, an object is a granule of composability - we cannot e.g. unplug a half of an object and plug in another half. Thus, a valid question to ask is this: how big should an object be to make the composability comfortable - to let us unplug as much logic as we want, leaving the rest untouched.

The answer comes with a Single Responsibility Principle for classes[^SRPMethods], that basically says[^SRP]:

A> A code of a Class should have only one reason to change.

There has been a lot written about the principle on the web, so I am not going to be wiser than google. Still, I believe it is useful to explain this principle in terms of composability.

Usually, the hard part about this principle is the what is "a reason to change". Robert C. Martin explains[^srponstackoverflow] that this is about a single source of entropy that generates changes to the class. And we will study it on an example we already know.

### Separating responsibilities

Remember the code Johnny and Benjamin used to apply incentine plans to employees? In case not, here it is (it's just a single method, but it will suffice):

```csharp
public void ApplyYearlyIncentivePlan()
{
  var employees = _repository.CurrentEmployees();

  foreach(var employee in employees)
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
    employee.Save();
  }
}
```

So... how many reasons to change does this piece of code have? If "reason to change" was defined as a "way to change", there would be multiple such ways. For example, someone may decide that we are not giving raises anymore and the `employee.EvaluateRaise()` line would be gone. Likewise, a decision could be made that we are not giving bonuses, then the `employee.EvaluateBonus()` line would have to be removed. So, there are undoubtedly many ways this method could change. But would it be for different reasons? Actually, no. The reason in both cases would be that the CEO approved a new incentive plan. So, there is one reason to change, although there are many ways the code can change.

Now happens the more interesting discussion: what about saving the employees - is the reason for changing the way we save employees the same as for the bonuses and pays? For example, we may decide that we are not saving each employee separately, because it would cause a huge load on our data store, but instead, we will save them together in a single batch. This causes the code to change, e.g. like this:

```csharp
public void ApplyYearlyIncentivePlan()
{
  var employees = _repository.CurrentEmployees();

  foreach(var employee in employees)
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
  }
  
  _repository.SaveAll(employees);
}
```

So, as you might've already guessed, the reason for this change is different, thus, it is a separate responsibility and the logic for reading and storing employees should be separated from this class. The method would look something like this:

```csharp
public void ApplyYearlyIncentivePlanTo(IEnumerable<Employee> employees)
{
  foreach(var employee in employees)
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
  }
}
```

Reading and writing would be handled by different code - thus, the responsibilities are separated. Do we now have a code that adheres to Single Reponsibility Principle? We may, but consider this situation: the evaluation of the raises and bonuses begins getting slow and, instead of doing this for all employees in a `for` loop, we would rather parallelize it. After this change, the code could look like this (this will the the C# parallel looping):

```csharp
public void ApplyYearlyIncentivePlanTo(IEnumerable<Employee> employees)
{
  Parallel.ForEach(employees, employee =>
  {
    employee.EvaluateRaise();
    employee.EvaluateBonus();
  });
}
```

Is this a new reason to change? Of course it is! So, we may say we have encountered another responsibility and separate it. The code looks like this now:

```csharp
public void ApplyYearlyIncentivePlanTo(Employee employee)
{
  employee.EvaluateRaise();
  employee.EvaluateBonus();
}
```

The looping, which is a separate responsibility, is handled by a different class.
 
### How far do we go?

The above example begs three questions:

1.  Is there a point where we are sure we have separated all responsibilities?
2.  If there is, how can we be sure we have reached it?

The answer to the first question is: probably no. While some reasons to change are common sense, others can be drawn from our experience as developers, there are always some that are unexpected and until they surface, we cannot foresee them. Thus, the answer for the second question is: "there is no way". Which does not mean we should not try to separate the different reasons we see - quite the contrary.

I like the comparison to our usage of time in real life. Brewing time of black tea is usually around three to five minutes. This is what is printed on the package we buy: "3 --- 5 minutes". Nobody gives the time in seconds, because such granularity is not needed. If seconds made a difference in the process of brewing tea, we would probably be given time in seconds. But they don't. When we estimate tasks in software engineering, we also use different time granularity depending on the need.

A simplest software program that prints "hello world" on the screen may fit into a single "main" method we will probably not see it as several responsibilities. But as soon as we get a requirement to write "hello world" in a native language of the currently running operating system, obtaining the text becomes a separate responsibility from putting it on the screen. It all depends on what granularity we need at the moment (which, as I said, may be spotted from code or known up-front from our experience as developers).

### The mutual relationship between Single Responsibility Principle and composability

The reason I am writing all this is that responsibilities are the real granules of composability. The composability of objects that I talked about a lot already is actually a mean to achieve composability of responsibilities, which is our real goal. If we have two collaborating objects, each having a single responsibility, we can easily replace the way our application achieves one of these responsibilities without touching the other. Thus, objects conforming to SRP are the most comfortably composable. As the real reason for change in application is the change of responsibilities and the real reuse is reuse of responsibilities, this is a concept that determines the size of our objects[^notrdd].

## No work in constructors

A conclusion from 

TODO give open connection instead of opening it in constructor
TODO validation - put in factories, except nulls - an object requires valid peers.
http://misko.hevery.com/code-reviewers-guide/flaw-constructor-does-real-work/


TODO independent deployability

TODO principle at different level of abstraction - single level of abstraction principle

TODO small amount of private methods

TODO how are we to determine responsibility? From experience: we know to count something in hours, not minutes. Second way: composition becomes awkward. Third way: tests (Statements) will tell us.


[^SRPMethods]: This principle can be applied to methods as well, but we are not going to cover this part, because it is not directly tied to the notion of composability and this is not a design book ;-).

[^SRP]: http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod. 

[^srponstackoverflow]: https://stackoverflow.fogbugz.com/default.asp?W29030

[^notrdd]: note that I am talking about responsibilities the way SRP talks about them, not the way they are understood by e.g. Responsibility Driven Design. Thus, I am talking about responsibilities of a class, not responsibilities of its API.
