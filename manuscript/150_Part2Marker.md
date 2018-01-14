-# Part 2: Object-Oriented World

A> ## Status: pretty stable
A>
A> This chapter will probably get one big review in the far future. While I am pleased with the content, I will be looking for a better structure and wording, making little changes here and there. I may also add a number of sections explaining things to existing chapters on things I find were not sufficiently explained. Still, if you read it as it is now, you're not going to miss anything significant.

Most of the examples in the previous part were about a single object that did not have dependencies on other objects (with an exception of some values -- strings, integers, enums etc.). This is not how most OO systems are built. In this part, we are finally going to look at scenarios where multiple objects work together as a system.

This brings about some issues that need to be discussed. One of them is the approach to object oriented design and how it influences the tools we use to test-drive our code. You probably heard something about a tool called mock objects (at least from one of the introductory chapters of this book) or, in a broader sense, test doubles. If you open your web browser and type "mock objects break encapsulation", you will find a lot of different opinions -- some saying that mocks are great, others blaming them for all the evil in the world, and a lot of opinions that fall inbetween. The discussions are still heated, even though mocks were introduced more than ten years ago. My goal in this chapter is to outline the context and forces that lead to adoption of mocks and how to use them for your benefit, not failure.

Steve Freeman, one of the godfathers of using mock objects with TDD, [wrote](https://groups.google.com/d/msg/growing-object-oriented-software/rwxCURI_3kM/2UcNAlF_Jh4J): "mocks arise naturally from doing responsibility-driven OO. All these mock/not-mock arguments are completely missing the point. If you're not writing that kind of code, people, please don't give me a hard time". I am going to introduce mocks in a way that will not give Steve a hard time, I hope.

To do this, I need to cover some topics of object-oriented design. In fact, I decided to dedicate the entire part 2 solely for that purpose. Thus, this chapter will be about object oriented techniques, practices and qualities you need to know to use TDD effectively in the object-oriented world. The key quality that we'll focus on is objects composability.

W> ## Teaching one thing at a time
W>
W> During this part of the book, you will see me do a lot of code and design examples without writing any test. This may make you wonder whether you are still reading a TDD book.
W>
W> I want to make it very clear that by omitting tests in these chapters I am not advocating writing code or refactoring without tests. The only reason I am doing this is that teaching and learning several things at the same time may make everything harder, both for the teacher and for the student. So, while explaining the necessary object oriented design topics, I want you to focus only on them.
W>
W> Don't worry. After I've layed the groundwork for mock objects, I'll re-introduce TDD in part 3 and write lots of tests. Please trust me and be patient.

After reading part 2, you will understand an opinionated approach to object-oriented design that is based on the idea of object-oriented system being a web of nodes (objects) that pass messages to each other. This will give us a good starting point for introducing mock objects and mock-based TDD in part 3.

