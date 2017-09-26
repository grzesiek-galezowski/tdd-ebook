# Mock objects as a design tool

## Outside-in development

## Programming by intention

## Responsibility-Driven Design

## Specifying factories

# What not to mock?

## Internals

## How to use value objects in Statements?

## How to specify value objects?

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


-# Part 4: Application architecture

# On stable boundaries

# Ports and adapters

## Physical splitting of layers

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

## Driver

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
