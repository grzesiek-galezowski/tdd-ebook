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

### The mutual relationship between Single Responsibility Principle and composability

Why am I writing about all this? It is because there is a symbiosis between SRP and composability. As I said, there's no way to compose half of an object with half of another one. When we pick an object, that's it - we get everything that's "in stock". I also said that object is a granule of composability. The truth is, responsibility is a granule of composability as well. On one hand, it doesn't make sense to e.g. compose half of responsibility with another half. If we have a situation like that, these "halves" are in reality separate responsibilities.

We need composability between objects to achieve composability between responsibilities - this is our real goal.

Separating things that change for the same reason makes it easier to replace things changing for different reasons than our class.


In order to have composable objects, we somehow need to divide responsibilities between them

3.  If there isn't, where do we stop in separating responsibilities?

This makes the third question interesting.

TODO composability reinforces SRP, SRP reinforces composability

TODO: answer no, never 

  
  

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

[^srponstackoverflow]: https://stackoverflow.fogbugz.com/default.asp?W29030