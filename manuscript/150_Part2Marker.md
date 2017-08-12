-# Part 2: Test-Driven Development in Object-Oriented World

Most of the examples in the previous part were about a single object that did not have dependencies on other objects (with an exception of some values -- strings, integers, enums etc.). This is not how a real OO systems are built. In this part, we are finally going to look at scenarios where multiple objects work together as a system.

This brings about some issues that need to be discussed. One of them is the approach to object oriented design and how it influences the tools we use to test-drive our code. You probably heard something about a tool called mock objects (at least from one of the introductory chapters of this book) or, in a broader sense, test doubles. If you open your web browser and type "mock objects break encapsulation", you will find a lot of different opinions -- some saying that mocks are great, others blaming them for everything bad in the world, and a lot of opinions in between those. The discussions are still heated, even though mocks were introduced more than ten years ago. My goal in this chapter is to outline the context and forces that lead to adoption of mocks and how to use them for your benefit, not failure.

Steve Freeman, one of the godfathers of using mock objects with TDD, [wrote](https://groups.google.com/d/msg/growing-object-oriented-software/rwxCURI_3kM/2UcNAlF_Jh4J): "mocks arise naturally from doing responsibility-driven OO. All these mock/not-mock arguments are completely missing the point. If you're not writing that kind of code, people, please don't give me a hard time". I am going to introduce mocks in a way that will not give Steve a hard time, I hope.

To do this, I need to cover some topics of object-oriented design. That is why not all chapters in this part are specifically about TDD, but some are about object oriented techniques, practices and qualities you need to know to use TDD effectively in the object-oriented world. The key quality that we will focus on is object composability.

W> ## Teaching one thing at a time
W>
W> For several next chapters, you will see me do a lot of code and design examples without writing any test. This may make you wonder whether you are still reading a TDD book.
W>
W> I want to make it very clear that by omitting tests in these chapters I am not advocating writing code or refactoring without tests. The only reason I am doing this is that teaching and learning several things at the same time makes everything harder, both for the teacher and for the student. So, while explaining the necessary object oriented design topics, I want you to focus only on them.
W>
W> Don't worry. After I've layed the groundwork for mock objects, I'll re-introduce TDD and write lots of tests. Please trust me and be patient.

After reading part 2, you will understand how mocks fit into test-driving object-oriented code, how to make Statements using mocks maintainable and how some of the practices I introduced in the chapters of part 1 apply to mocks. You will also be able to test-drive simple object-oriented systems.
