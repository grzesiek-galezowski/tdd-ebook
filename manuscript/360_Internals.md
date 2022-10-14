# What not to mock?

Design follows RDD process (lol). This way we discover a lot of peers of the current class. But not every class is part of the web. We already know about value objects. Another example are simple data structures, or DTOs. They might be part of the public API of a class but are not mocks. Another category is internals - stuff that is hidden inside a class and adds to its behavior.

## Internals

What is internal is a choice (new A(new B) vs new A()). Internal is a building block of a single web node.

Steve Freeman: small clusters of objects.

What internals do we have?

1. Value objects, ints etc.
2. Collections
3. Utils (e.g. I wrote my util for generating hash code or my own class for joining strings or calculations)
4. library classes (if communication with library class is important, maybe wrap it with another class where it becomes an internal)
5. synchronization primitives?