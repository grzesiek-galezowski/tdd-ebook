# Mock objects as a design tool

## Outside-in development

## Worked example

Johhny and Benjamin, creating subscription, subscription is validated (as few fields as possible) when a subscription is created, a notification is sent. Use command pattern, collecting parameter, maybe observer. Note that until we do something with this subscription, there is no need to store it. Second example - scheduled expiry.

## Programming by intention

## Responsibility-Driven Design

## Specifying factories

# What not to mock?

## Internals

## How to use value objects in Statements?

## How to specify value objects?

## Terminal nodes in object graph

# Guidance of test smells

## Long Statements

## Lots of stubbing

## Specifying private members

## Mocking third party

### Mocking time

### Mocking random

### Mocking long-running threads

### Mocking timers with callbacks

### Mocking asynchronous tasks

### Mocking databases

# Revisiting topics from chapter 1

## Constrained non-determinism in OO world

### Passive vs active roles

## Behavioral boundaries

## Triangulation

# Maintainable mock-based Statements

## Setup and teardown

# Refactoring mock code

until you pop it out through the constructor, it's object's private business.

mocks rely on the boundaries being stable. If wrong on this, tests need to be rewritten, but the feedbak from tests allows stabilizing the boundaries further. And there are not that many tests to change as we test small pieces of code.

-# Part 4: Application architecture

# On stable/architectural boundaries

# Ports and adapters

## Physical separation of layers

### "Screaming" architecture

# What goes into application?

## Application and other layers

Services, entities, interactors, domain etc. - how does it match?

# What goes into ports?

## Data transfer objects

## Ports are not a layer

-# Part 5: TDD on application architecture level

# Designing automation layer

## Adapting screenplay pattern

code in terms of intention (when knowing more about intention)
refactor the domain-specific API (when knowing more about underlying technology)

## Driver

reusing the composition root

### Separate start method

### Fake adapters

They include port-specific setup and assertions.

Create a new fake adapter per each call.

### Using fakes

For threads and e.g. databases - simpler objects with partially defined behavior

## Actors

Where do assertions go? into the actors or context?

How to manage per-actor context (e.g. each actor has its own sent & received messages stored)

These are not actors as in actor model

## Data builders

nesting builders, builders as immutable objects.
