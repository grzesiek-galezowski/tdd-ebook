# On Object Composability

In this chapter, I will try to outline briefly why object composability is a goal worth achieving and how it can be achieved. I am going to start with an example of an unmaintainable code and will gradually fix its flaws in the next chapters. For now, we are going to fix just one of the flaws, so the code we will end up will not be perfect by any means, still, it will be better by one quality.

In the coming chapters, we will learn more valuable lessons resulting from changing this little piece of code.

## Another task for Johnny and Benjamin

Remember Johnny and Benjamin? Looks like they managed their previous task and are up to something else. Let's listen to their conversation as they are working on another project...

**Benjamin:** So, what's this assignment about?

**Johnny:** Actually, it's nothing exciting -- we'll have to add two features to a legacy application that's not prepared for the changes.

**Benjamin:** What is the code for?

**Johnny:** It is a C# class that implements company policies. As the company has just started using this automated system and it was started recently, there is only one policy implemented: yearly incentive plan. Many corporations have what they call incentive plans. These plans are used to promote good behaviors and exceeding expectations by employees of a company.

**Benjamin:** You mean, the project has just started and is already in a bad shape?

**Johnny:** Yep. The guys writing it wanted to "keep it simple", whatever that means, and now it looks pretty bad.

**Benjamin:** I see...

**Johnny:** By the way, do you like riddles?

**Benjamin:** Always!

**Johnny:** So here's one: how do you call a development phase when you ensure high code quality?

**Benjamin:** ... ... No clue... So what is it called?

**Johnny:** It's called "now".

**Benjamin:** Oh!

**Johnny:** Getting back to the topic, here's the company incentive plan.

Every employee has a pay grade. An employee can be promoted to a higher pay grade, but the mechanics of how that works is something we will not need to deal with.

Normally, every year, everyone gets a raise of 10%. But to encourage behaviors that give an employee a higher pay grade, such an employee cannot get raises indefinitely on a given pay grade. Each grade has its associated maximum pay. If this amount of money is reached, an employee does not get a raise anymore until they reach a higher pay grade.

Additionally, every employee on their 5th anniversary of working for the company gets a special, one-time bonus which is twice their current payment.

**Benjamin:** Looks like the source code repository just finished synchronizing. Let's take a bite at the code!

**Johnny:** Sure, here you go:

```csharp
public class CompanyPolicies : IDisposable
{
  readonly SqlRepository _repository
    = new SqlRepository();
  
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
  
  public void Dispose()
  {
    _repository.Dispose();
  }
}
```

**Benjamin:** Wow, there is a lot of literal constants all around and functional decomposition is barely done!

**Johnny:** Yeah. We won't be fixing all of that today. Still, we will follow the boy scout rule and "leave the campground cleaner than we found it".

**Benjamin:** What's our assignment?

**Johnny:** First of all, we need to provide our users with a choice between an SQL database and a NoSQL one. To achieve our goal, we need to be somehow able to make the `CompanyPolicies` class database type-agnostic. For now, as you can see, the implementation is coupled to the specific `SqlRepository`, because it creates a specific instance itself:

```csharp
public class CompanyPolicies : IDisposable
{
  readonly SqlRepository _repository
    = new SqlRepository();
```

Now, we need to evaluate the options we have to pick the best one. What
options do you see, Benjamin?

**Benjamin:** Well, we could certainly extract an interface from `SqlRepository` and introduce an if statement to the constructor like this:

```csharp
public class CompanyPolicies : IDisposable
{
  readonly Repository _repository;

  public CompanyPolicies()
  {
    if(...)
    {
      _repository = new SqlRepository();
    }
    else
    {
      _repository = new NoSqlRepository();
    }
  }
```

**Johnny:** True, but this option has few deficiencies. First of all, remember we're trying to follow the boy scout rule and by using this option we introduce more complexity to the `CommonPolicies` class. Also, let's say tomorrow someone writes another class for, say, reporting and this class will also need to access the repository -- they will need to make the same decision on repositories in their code as we do in ours. This effectively means duplicating code. Thus, I'd rather evaluate further options and check if we can come up with something better. What's our next option?

**Benjamin:** Another option would be to change the `SqlRepository` itself to be just a wrapper around the actual database access, like this:

```csharp
public class SqlRepository : IDisposable
{
  readonly Repository _repository;

  public SqlRepository()
  {
    if(...)
    {
      _repository = new RealSqlRepository();
    }
    else
    {
      _repository = new RealNoSqlRepository();
    }
  }

  IList<Employee> CurrentEmployees()
  {
    return _repository.CurrentEmployees();
  }
```

**Johnny:** Sure, this is an approach that could work and would be worth considering for very serious legacy code, as it does not force us to change the `CompanyPolicies` class at all. However, there are some issues with it. First of all, the `SqlRepository` name would be misleading. Second, look at the `CurrentEmployees()` method -- all it does is delegating a call to the implementation chosen in the constructor. With every new method required of the repository, we'll need to add new delegating methods. In reality, it isn't such a big deal, but maybe we can do better than that?

**Benjamin:** Let me think, let me think... I evaluated the option where `CompanyPolicies` class chooses between repositories. I also evaluated the option where we hack the `SqlRepository` to makes this choice. The last option I can think of is leaving this choice to another, "3rd party" code, that would choose the repository to use and pass it to the `CompanyPolicies` via its constructor, like this:

```csharp
public class CompanyPolicies : IDisposable
{
  private readonly Repository _repository;

  public CompanyPolicies(Repository repository)
  {
    _repository = repository;
  }
```

This way, the `CompanyPolicies` won't know what exactly is passed to it via its constructor and we can pass whatever we like -- either an SQL repository or a NoSQL one!

**Johnny:** Great! This is the option we're looking for! For now, just believe me that this approach will lead us to many good things -- you'll see why later.

**Benjamin:** OK, so let me just pull the `SqlRepository` instance outside the `CompanyPolicies` class and make it an implementation of `Repository` interface, then create a constructor and pass the real instance through it...

**Johnny:** Sure, I'll go get some coffee.

... 10 minutes later

**Benjamin:** Haha! Look at this! I am SUPREME!

```csharp
public class CompanyPolicies : IDisposable
{
  //_repository is now an interface
  readonly Repository _repository; 

  // repository is passed from outside.
  // We don't know what exact implementation it is.
  public CompanyPolicies(Repository repository)
  {
    _repository = repository;
  }
  
  public void ApplyYearlyIncentivePlan()
  {
    //... body of the method. Unchanged.
  }
  
  public void Dispose()
  {
    _repository.Dispose();
  }
}
```

**Johnny:** Hey, hey, hold your horses! There is one thing wrong with this code.

**Benjamin:** Huh? I thought this is what we were aiming at.

**Johnny:** Yes, except the `Dispose()` method. Look closely at the `CompanyPolicies` class. it is changed so that it is not responsible for creating a repository for itself, but it still disposes of it. This is could cause problems because `CompanyPolicies` instance does not have any right to assume it is the only object that is using the repository. If so, then it cannot determine the moment when the repository becomes unnecessary and can be safely disposed of.

**Benjamin:** Ok, I get the theory, but why is this bad in practice? Can you give me an example?

**Johnny:** Sure, let me sketch a quick example. As soon as you have two instances of `CompanyPolicies` class, both sharing the same instance of `Repository`, you're cooked. This is because one instance of `CompanyPolicies` may dispose of the repository while the other one may still want to use it.

**Benjamin:** So who is going to dispose of the repository?

**Johnny:** The same part of the code that creates it, for example, the `Main` method. Let me show you an example of how this may look like:

```csharp
public static void Main(string[] args)
{
  using(var repo = new SqlRepository())
  {
    var policies = new CompanyPolicies(repo);

    //use above created policies 
    //for anything you like
  }
}
```

This way the repository is created at the start of the program and disposed of at the end. Thanks to this, the `CompanyPolicies` has no disposable fields and it does not have to be disposable itself -- we can just delete the `Dispose()` method:

```csharp
//not implementing IDisposable anymore:
public class CompanyPolicies 
{
  //_repository is now an interface
  readonly Repository _repository; 

  //New constructor
  public CompanyPolicies(Repository repository)
  {
    _repository = repository;
  }
  
  public void ApplyYearlyIncentivePlan()
  {
    //... body of the method. No changes
  }

  //no Dispose() method anymore
}
```

**Benjamin:** Cool. So, what now? Seems we have the `CompanyPolicies` class depending on a repository abstraction instead of an actual implementation, like SQL repository. I guess we will be able to make another class implementing the interface for NoSQL data access and just pass it through the constructor instead of the original one.

**Johnny:** Yes. For example, look at `CompanyPolicies` component. We can compose it with a repository like this:

```csharp
var policies 
  = new CompanyPolicies(new SqlRepository());
```

or like this:

```csharp
var policies 
  = new CompanyPolicies(new NoSqlRepository());
```

without changing the code of `CompanyPolicies`. This means that `CompanyPolicies` does not need to know what `Repository` exactly it is composed with, as long as this `Repository` follows the required interface and meets expectations of `CompanyPolicies` (e.g. does not throw exceptions when it is not supposed to do so). An implementation of `Repository` may be itself a very complex and composed of another set of classes, for example, something like this:

```csharp
new SqlRepository(
  new ConnectionString("..."), 
  new AccessPrivileges(
    new Role("Admin"), 
    new Role("Auditor")
  ),
  new InMemoryCache()
);
```

but the `CompanyPolicies` neither knows or cares about this, as long as it can use our new `Repository` implementation just like other repositories.

**Benjamin:** I see... So, getting back to our task, shall we proceed with making a NoSQL implementation of the `Repository` interface?

**Johnny:** First, show me the interface that you extracted while I was looking for the coffee.

**Benjamin:** Here:

```csharp
public interface Repository
{
  IList<Employee> CurrentEmployees();
}
```

**Johnny:** Ok, so what we need is to create just another implementation and pass it through the constructor depending on what data source is chosen and we're finished with this part of the task.

**Benjamin:** You mean there's more?

**Johnny:** Yeah, but that's something for tomorrow. I'm exhausted today.

## A Quick Retrospective

In this chapter, Benjamin learned to appreciate composability of an object, i.e. the ability to replace its dependencies, providing different behaviors, without the need to change the code of the object class itself. Thus, an object, given replaced dependencies, starts using the new behaviors without noticing that any change occurred at all.

The code mentioned has some serious flaws. For now, Johnny and Benjamin did not encounter a desperate need to address them.

Also, after we part again with Johnny and Benjamin, we are going to reiterate the ideas they stumble upon in a more disciplined manner.
