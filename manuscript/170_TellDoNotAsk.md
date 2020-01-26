# Telling, not asking {#170-TellDoNotAsk}

In this chapter, we'll get back to Johnny and Benjamin as they introduce another change in the code they are working on. In the process, they discover the impact that return values and getters have on the composability of objects.

## Contractors

**Johnny:** G'morning. Ready for another task?

**Benjamin:** Of course! What's next?

**Johnny:** Remember the code we worked on yesterday? It contains a policy for regular employees of the company. But the company wants to start hiring contractors as well and needs to include a policy for them in the application.

**Benjamin:** So this is what we will be doing today?

**Johnny:** That's right. The policy is going to be different for contractors. While, just as regular employees, they will be receiving raises and bonuses, the rules will be different. I made a small table to allow comparing what we have for regular employees and what we want to add for contractors:


| Employee Type       | Raise                 |     Bonus              |
|---------------------|-----------------------|------------------------|
| Regular Employee    | +10% of current salary if not reached a maximum on a given pay grade | +200% of current salary one time after five years     |
| Contractor          | +5% of average salary calculated for last 3 years of service (or all previous years of service if they have worked for less than 3 years | +10% of current salary when a contractor receives score more than 100 for the previous year             |

So while the workflow is going to be the same for both a regular employee and a contractor:

1. Load from repository
1. Evaluate raise
1. Evaluate bonus
1. Save

the implementation of some of the steps will be different for each type of employee.

**Benjamin:** Correct me if I am wrong, but these "load" and "save" steps do not look like they belong with the remaining two -- they describe something technical, while the other steps describe something strictly related to how the company operates...

**Johnny:** Good catch, however, this is something we'll deal with later. Remember the boy scout rule -- just don't make it worse. Still, we're going to fix some of the design flaws today.

**Benjamin:** Aww... I'd just fix all of it right away.

**Johnny:** Ha ha, patience, Luke. For now, let's look at the code we have now before we plan further steps.

**Benjamin:** Let me just open my IDE... OK, here it is:

```csharp
public class CompanyPolicies
{
  readonly Repository _repository;

  public CompanyPolicies(Repository repository)
  {
    _repository = repository;
  }
  
  public void ApplyYearlyIncentivePlan()
  {
    var employees = _repository.CurrentEmployees();

    foreach(var employee in employees)
    {
      var payGrade = employee.GetPayGrade();

      //evaluate raise
      if(employee.GetSalary() < payGrade.Maximum)
      {
        var newSalary 
          = employee.GetSalary() 
          + employee.GetSalary() 
          * 0.1;
        employee.SetSalary(newSalary);
      }
  
      //evaluate one-time bonus
      if(employee.GetYearsOfService() == 5)
      {
        var oneTimeBonus = employee.GetSalary() * 2;
        employee.SetBonusForYear(2014, oneTimeBonus);
      }
  
      employee.Save();
    }
  }
}
```

**Benjamin:** Look, Johnny, the class, in fact, contains all the four steps you mentioned, but they are not named explicitly -- instead, their internal implementation for regular employees is just inserted in here. How are we supposed to add the variation of the employee type?

**Johnny:** Time to consider our options. We have a few of them. Well?

**Benjamin:** For now, I can see two. The first one would be to create another class similar to `CompanyPolicies`, called something like `CompanyPoliciesForContractors` and implement the new logic there. This would let us leave the original class as is, but we would have to change the places that use `CompanyPolicies` to use both classes and choose which one to use somehow. Also, we would have to add a separate method to the repository for retrieving the contractors.

**Johnny:** Also, we would miss our chance to communicate through the code that the sequence of steps is intentionally similar in both cases. Others who read this code in the future will see that the implementation for regular employees follows the steps: load, evaluate raise, evaluate bonus, save. When they look at the implementation for contractors, they will see the same order of steps, but they will be unable to tell whether the similarity is intentional, or a pure accident.

**Benjamin:** So our second option is to put an `if` statement into the differing steps inside the `CompanyPolicies` class, to distinguish between regular employees and contractors. The `Employee` class would have an `isContractor()` method and depending on what it would return, we would either execute the logic for regular employees or contractors. Assuming that the current structure of the code looks like this:

```csharp
foreach(var employee in employees)
{
  //evaluate raise
  ...
  
  //evaluate one-time bonus
  ...
  
  //save employee
}
```

the new structure would look like this:

```csharp
foreach(var employee in employees)
{
  if(employee.IsContractor())
  {
    //evaluate raise for contractor
    ...
  }
  else
  {
    //evaluate raise for regular
    ...
  }

  if(employee.IsContractor())
  {
    //evaluate one-time bonus for contractor
    ...
  }
  else
  {
    //evaluate one-time bonus for regular
    ...
  }
  
  //save employee
  ...
}
```

this way we would show that the steps are the same, but the implementation is different. Also, this would mostly require us to add code and not move the existing code around.

**Johnny:** The downside is that we would make the class even uglier than it was when we started. So despite initial easiness, we'll be doing a huge disservice to future maintainers. We have at least one another option. What would that be?

**Benjamin:** Let's see... we could move all the details concerning the implementation of the steps from `CompanyPolicies` class into the `Employee` class itself, leaving only the names and the order of steps in `CompanyPolicies`:

```csharp
foreach(var employee in employees)
{
  employee.EvaluateRaise();
  employee.EvaluateOneTimeBonus();
  employee.Save();
}
```

Then, we could change the `Employee` into an interface, so that it could be either a `RegularEmployee` or `ContractorEmployee` -- both classes would have different implementations of the steps, but the `CompanyPolicies` would not notice, since it would not be coupled to the implementation of the steps anymore -- just the names and the order.

**Johnny:** This solution would have one downside -- we would need to significantly change the current code, but you know what? I'm willing to do it, especially that I was told today that the logic is covered by some tests which we can run to see if a regression was introduced.

**Benjamin:** Cool, what do we start with?

**Johnny:** The first thing that is between us and our goal are these getters on the `Employee` class:

```csharp
GetSalary();
GetGrade();
GetYearsOfService();
```

They just expose too much information specific to the regular employees. It would be impossible to use different implementations when these are around. These setters don't help much:

```csharp
SetSalary(newSalary);
SetBonusForYear(year, amount);
```

While these are not as bad, we'd better give ourselves more flexibility. Thus, let's hide all of it behind more abstract methods that only reveal our intention.

First, take a look at this code:

```csharp
//evaluate raise
if(employee.GetSalary() < payGrade.Maximum)
{
  var newSalary
    = employee.GetSalary()
    + employee.GetSalary()
    * 0.1;
  employee.SetSalary(newSalary);
}
```

Each time you see a block of code separated from the rest with blank lines and starting with a comment, you see something screaming "I want to be a separate method that contains this code and has a name after the comment!". Let's grant this wish and make it a separate method on the `Employee` class.

**Benjamin:** Ok, wait a minute... here:

```csharp
employee.EvaluateRaise();
```

**Johnny:** Great! Now, we've got another example of this species here:

```csharp
//evaluate one-time bonus
if(employee.GetYearsOfService() == 5)
{
  var oneTimeBonus = employee.GetSalary() * 2;
  employee.SetBonusForYear(2014, oneTimeBonus);
}
```

**Benjamin:** This one should be even easier... Ok, take a look:

```csharp
employee.EvaluateOneTimeBonus();
```

**Johnny:** Almost good. I'd only leave out the information that the bonus is one-time from the name.

**Benjamin:** Why? Don't we want to include what happens in the method name?

**Johnny:** Actually, no. What we want to include is our intention. The bonus being one-time is something specific to the regular employees and we want to abstract away the details about this or that kind of employee, so that we can plug in different implementations without making the method name lie. The names should reflect that we want to evaluate a bonus, whatever that means for a particular type of employee. Thus, let's make it:

```csharp
employee.EvaluateBonus();
```

**Benjamin:** Ok, I get it. No problem.

**Johnny:** Now let's take a look at the full code of the `EvaluateIncentivePlan` method to see whether it is still coupled to details specific to regular employees. Here's the code:

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

**Benjamin:** It seems that there is no coupling to the details about regular employees anymore. Thus, we can safely make the repository return a combination of regulars and contractors without this code noticing anything. Now I think I understand what you were trying to achieve. If we make interactions between objects happen on a more abstract level, then we can put in different implementations with less effort.

**Johnny:** True. Can you see another thing related to the lack of return values on all of the `Employee`'s methods in the current implementation?

**Benjamin:** Not really. Does it matter?

**Johnny:** Well, if `Employee` methods had return values and this code depended on them, all subclasses of `Employee` would be forced to supply return values as well and these return values would need to match the expectations of the code that calls these methods, whatever these expectations were. This would make introducing other kinds of employees harder. But now that there are no return values, we can, for example:

- introduce a `TemporaryEmployee` that has no raises, by leaving its `EvaluateRaise()` method empty, and the code that uses employees will not notice.
- introduce a `ProbationEmployee` that has no bonus policy, by leaving its `EvaluateBonus()` method empty, and the code that uses employees will not notice.
- introduce an `InMemoryEmployee` that has an empty `Save()` method, and the code that uses employees will not notice.

As you see, by asking the objects less, and telling it more, we get greater flexibility to create alternative implementations and the composability, which we talked about yesterday, increases!

**Benjamin:** I see... So telling objects what to do instead of asking them for their data makes the interactions between objects more abstract, and so, more stable, increasing composability of interacting objects. This is a valuable lesson -- it is the first time I hear this and it seems a pretty powerful concept.

## A Quick Retrospective

In this chapter, Benjamin learned that the composability of an object (not to mention clarity) is reinforced when interactions between it and its peers are: abstract, logical and stable. Also, he discovered, with Johnny's help, that it is further strengthened by following a design style where objects are told what to do instead of asked to give away information to somebody who then decides on their behalf. This is because if an API of an abstraction is built around answering specific questions, the clients of the abstraction tend to ask it a lot of questions and are coupled to both those questions and some aspects of the answers (i.e. what is in the return values). This makes creating another implementation of abstraction harder, because each new implementation of the abstraction needs to not only provide answers to all those questions, but the answers are constrained to what the client expects. When abstraction is merely told what its client wants it to achieve, the clients are decoupled from most of the details of how this happens. This makes introducing new implementations of abstraction easier -- it often even lets us define implementations with all methods empty without the client noticing at all.

These are all important conclusions that will lead us towards TDD with mock objects.

Time to leave Johnny and Benjamin for now. In the next chapter, I'm going to reiterate their discoveries and put them in a broader context.
