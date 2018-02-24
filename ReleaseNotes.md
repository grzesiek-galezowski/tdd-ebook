# 31-01-2018

A new version of the book is available! Notable changes are:

1. **An entirely new chapter** on mock objects applied in a test-first manner. I did three or four passes through the content to ensure it reads smoothly. Of course, any sugggestions, bug fixes etc. are welcome. You can always use the github page for these.
1. **New supporting chapter**: *About code examples* is added. As some of the readers are more familiar with Java than C# and I want them to get the most out of this book, I made some rough notes at the beginning of the book that point towards some of the differences between the two languages. A small piece of this chapter is also dedicated to C# users. If you use a different language and still enjoy the book, I encourage you to contribute notes that allow the users of your language of choice to access the book more easily.
1. **Part statuses**. Many times I have been asked whether a particular part of the book is stable enough. Some readers didn't want to read something that was about to change soon in a big way. Likewise, many would rather read a nearly finished thing than an "alpha chapter". This is why I decided to be more open about the status and each part begins with a status note that says what I currently think about the content maturity.

Happy reading and, as usual, I'm looking forward to your opinions and suggestions.

# 18-11-2017

Hi, today's update brings to you a cosmetically revised version of factories chapter (the most changes were made to "Factories are themselves polymorphic (encapsulation of rule)" section, where the existing example was changed to one I consider better) as well as a new chapter on mock objects. You may also note that I changed the numbering of parts. Part 2 is entirely devoted to object oriented design primer and object-oriented TDD was moved to newsly created chapter 3. There are also some placeholders as I have lots of ideas for new chapters. Everything will come, in time. Looking at all the hype around functional programming, I can only hope that OO doesn't become obsolete before I finish the book :-D.

Enjoy, and, as always, I welcome any feedback!

# 22-07-2017

Hi, a new version is available and it contains polished and reviewed version of a new chapter that up to this moment was in a "preview" state. Namely - Aspects of value objects design. This concludes the set of chapters devoted to value objects. Enjoy!

# 03-07-2017

Hi,

The main dish of this release is a fix for bug "Is BroadcastingObserver really more flexible? #93". I took this opportunity to do a slight face-lift of the impacted chapter as well as split the object composition chapter into three (it was a really long one) along with style corrections. The bulk of the content is unchanged, so if you already read these chapters and didn't have issues with them, there's probably not a great need to re-read it. 

My next step will be going back to the value objects chapters that I left half-finished and bring them into a production-ready stage. 

As usual, happy reading and thanks for your support.

# 05-05-2017

After a long work, the triangulation chapter - the last chapter of part 1 is now refactored and partly rewritten.

For starters, I renamed the chapter from Triangulation to "Driving the implementation from Specification", because all three techniques shown there are classic and equally important, even though I have my favourites.

The second big change is a complete rewrite of the triangulation part of this chapter. I replaced the summing elements throughout a list example with two other examples - one very basic and the other a bit more advanced. The basic example is about calculating the sum of two integers, which is exactly the same example that was used to describe two other techniques. This way, readers can compare how all three techniques apply to the same coding problem to examine the differences in the mechanics. The advanced example is based on a a LED display kata from Corey Haines, although with modified rules and goal. Of course, I'll be more than happy to know your thoughts and suggestions.

As for my next steps - now that I finished Part 1, I think I will not review Part 2 as thoroughly yet. I will probably fix several outstanding issues that were raised for some parts of Part 2 and then finish the chapters on value objects that I started before the big review of Part 1.

Happy reading and thank you to all those who support me!!

# 15-03-2017

This version includes some fixes to the boundary chapter - the one that was most recently reviewed. Thanks to Łukasz Maternia for spotting some bugs and an area for improvement. This led me to change two examples in the boundaries and ranges sections.

# 13-02-2017

One day before the Valentine's day, I'd like to present you with another version of the tutorial. This time, I did an overhaul of the chapter about specifying boundaries and functional conditions. Since I last wrote it, my approach changed a bit to a more nuanced one and I tried to convey a bit about the different situations in which I make different choices. Also, I incorporated one or two small but useful fixes by others (thanks!!). Where I knew there are still open issues (this is true for two chapters), I decided to add a note at the beginning of each chapter do that you can find it. These issues are very minor, so they should not get in the way when reading.

Hope you like the changes and, as always, I welcome comments, opinions and suggestions.

# 30-12-2016

Hi, along with my wishes for a Happy New Year, I'd like to give you a new version of the book with almost completely rewritten chapter "What is the scope of a unit-level Statement in TDD?". The previous version of this chapter was an almost copy-pasted blog post and it lacked in many ways. I hope you like the new version of the chapter and if you have any suggestions, bug reports, topics you'd like to discuss, you know how to contact me, don't you?

So, again, happy reading and a happy 2017!

# 08-10-2016

Hi,

This release marks several small improvements by contributors (thanks!) and an overhaul to constrained non-determinism chapter. I fixed a lot of misconceptions, added more explanation, links to external sources etc. Hope you like it better!

# 16-07-2016

Hi,

This time, the "Is TDD about analysis..." chapter underwent an overhaul. I corrected a lot of phrases, expanded some explanations and I hope the readability of the chapter is much better now.

As a bonus, I fixed chapter markers for about half of the chapters. They were broken since several releases and I didn't even notice, lol :-).

Anyway, I'm currently planning to prepare a talk about how test-first is not as counter-intuitive as many think. I found interesting comparisons of TDD to scientific method and the other think I'd like to do is present TDD as an agile process. I'm really curious about your experiences - do you view test-first approach as counter-intuitive? If so, why? If not, what view or metaphor of TDD appealed to you the most? If you'd like to share your point of view and experience, you can reach me through the leanpub's "contact the author" feature.

Happy reading!

# 29-06-2016

Hi!

Quality Excites 2016 is over, so time for another release of your favourite book :-) err... never mind. In this release, I did an overhaul to "How to start?" chapter - corrected some explanations, fixed some mistakes in examples etc. From my point of view, the chapter is more "complete" now. Have fun!

# 09-05-2016

Hi!

It's been some time since I last published. This version contains an overhaul of chapter "Practicing what we have already learned" - the one where Johnny and Benjamin try to take on a simple problem using TDD. By the way, I noticed that the title of this chapter is misleading, since it not only repeats some of the already covered elements, but also introduces several new ones. I'm still searching for a better name - if you have some ideas, please let me know!

Anyway, as for this chapter, I corrected a lot of typos and misleading sentences, I also found some small errors in the code. I also managed to include several fixes by contributors (see pull requests on github page). Overall, I feel the chapter is in much better shape now than it was earlier.

I received some comments about these chapters that include Johnny and Benjamin. Some said they're not needed and that they repeat the somewhat naive narrative of Uncle Bob's Craftsman articles (e.g. http://thecleancoder.blogspot.com/2010/10/craftsman-62-dark-path.html, btw, I myself liked this series and I think Robert is better writer than me when it comes to building a story) or his even more naive and tendentious dialog-blog posts (e.g. https://blog.8thlight.com/uncle-bob/2014/05/14/TheLittleMocker.html, btw, I like them as well, although I agree with the tendentiousness charge). On the other hand, I received some thumbs up, saying that these chapters reveal a lot about the questions one rises when they encounter certain patterns and techniques and that they do a fine job showing the dynamics of TDD and object oriented design process. Based on this, these chapters will stay in the book and I may add some more when necessity arises. Still, if you have an opinion, please let me know!

Best regards and happy reading!

# 20-03-2016

Hi,

It's been a long time since I last released a new version. The good news is that this time, an overhaul touched two chapters instead of one. I made two passed through chapters "It's not (only) a test" and "Statement-first programming". Now they more accurately reflect my current point of view and hopefully the examples are better explained. So, if you didn't like these chapters previously, please try to give them another go. I wrote these chapters a long time ago and in their first versions, they were just some text pulled from my blog. Now they should feel more as a part of a book and their quality should feel improved. I'm always looking forward to hear/read your suggestions and impressions, either via e-mail (leanpub has a button called "contact the author" or sth.), twitter, github...

A big Thank You to all the contributors that pointed typos, style problems etc. I'm (and the rest of the readers probably are as well) very grateful for your contributions!

# 08-12-2015

Hello, dear readers and TDD practitioners!

This is my second attempt to write to you. The first time, book release stopped due to an error and I lost what I wrote to you back then. I'm pretty sure you didn't get the previous message. If you did, then sorry for spamming you.

Anyway, last time I released a new version, I promised that next chapters would not take as long to process. I was wrong. A lot of things happened since then - I passed an ISTQB exam, I started guest lectures on three universities in Cracow and did some other things, so the review of "The essential tools" chapter slipped. 

As I said, this release contains a reviewed version of "the essential tools" - I read that chapter again and I noticed there was a lot of room for improvements, especially that this chapter was aimed at novice readers. So I added a lot of clarifications, expanded some of the descriptions, made several corrections to examples and replaced an old XUnit.net GUI runner screenshot with one from Resharper runner (this is because the new XUnit version does not have a GUI runner anymore).

My next step is to review the "It's not a test" chapter. Some time ago, I was forced to re-read that chapter as a lot of fixes were submitted by Martin Moene (thanks again!). I noticed then that while this chapter does reflect my views, it does not do so as accurately as I would like to. Also, the language that I used for this chapter is not the same as I use today when discussing TDD. This is a good moment for you to send me any comments and suggestions you may have about this chapter - I will try to take as much of them as possible into account.

The last news is that I added dead link detection to build scripts, so it will be easier to fix any links that go out of service. I also deleted the old HTML version of the book on github.io as it was out of date and not maintained anymore. It is replaced by leanpub's online version, so please use that.

I don't expect next release to be this year. So, those of you that celebrate Christmas, please accept my wishes of Merry Christmas! And a Happy New Year to everyone!

Best regards and happy reading!

# 30-10-2015

Hi,

As promised, I started reviewing the book chapter by chapter, updating the content to better reflect my current point of view and what I have learned since I started this book.

This release contains reviewed version of the first chapter: Motivation. Reading through the chapter again I noticed that the thing it lacked the most was respect for the reader. Some might say I got "soft", however, I really think you deserve this respect, whether you agree with my point of view or not. I also tried to use more e-prime language, not to impose my views on the reader. I don't want to treat my readers as students who should learn from "the master - me" :-), instead, I'd like to encourage you to engage in a discussion so that I can learn from you. I found that this works much better preaching. As much as I am a catholic dogmatic theology enthusiast, I believe software engineering shouldn't be treated as undisputable dogma, since it's not based on revelation.

This chapter took long, since I was busy with other things like preparing three topics for internal conference and training for a driver's license exam. Now that these things are over, I will hopefully have more time to review further chapter. I am still open to any feedback you might have.

Cheers and happy reading!

# 17-09-2015

Hi!

The new version of TDD: Extensive Tutorial is available. It includes a new chapter on value object anatomy. The chapter continues a discussion on value objects. There will be one more (which you can read in a very draft form by going past the "warning" sign) and we'll get back to TDD and introduce mock objects properly.

This version includes a lot of style corrections and changes to earlier chapters by Martin Moene (which you can look up in the committ history: https://github.com/grzesiek-galezowski/tdd-ebook/commits/master) and some corrections by Spyros Maniatopoulos and Reuven Yagel. Thanks, guys!

Looking through the corrections, it occured to me that my style of writing and building argumentation has matured since I wrote the first chapters. I also noticed some parts of the text that are not as clear as I would like them to be. Thus, I'm thinking of revisiting the earlier chapters and making them clearer, maybe change some examples, maybe clarify existing ones. My dillema has always been between making the older material better and writing new. This time, however, I think there will be more value in reviewing older chapters as this is what most of you stumble upon when you open the book. Please let me know what you think, especially when you think otherwise. Maybe some of you are waiting on the mock introduction and would like to get it part faster?

Anyway, best regards and happy reading! As always, please let me know on any opinions, issues, corrections etc. either through leanpub's contact facilities or through github.

# 22-08-2015

Hi!

it has been a long time since I last wrote to you. Since then, there were few minor releases of the book, but I decided to write another message when I have a new chapter ready. So now you know ;-). The chapter is called Value Objects and is a first of three chapters on value objects that the book will include.

Apart from that, I got a lot of help from Martin Moene, author of lest, a modern, C++11-native, header-only, tiny framework for unit-tests, TDD and BDD (https://github.com/martinmoene/lest). Martin did a titanic work fixing style and typos as well as proposing some changes to the structure and content of a several chapters. I am really happy I decided to make the book open source as I am beginning to see the power of collaboration with community members that bring a lot of good things to the content of the book. Our community is still pretty small, but I value every feedback, be it an opinion, a typo fix, a request for clarification or content change suggestion.

I started thinking about maybe creating a small low-traffic google discussion group, so that some feedback can be shared with all of the community. Please let me know what you think (for now, you can use the feedback icon on the book's leanpub page).

Enjoy!

# 11-06-2015

Hello!

It's been a while since I last published. Just to let you know - this is not in any way a sign of me losing my motivation for writing this book. 

The real reason is that I got to present on two great conferences: Academic Festival in Kraków and Quality Excites in Gliwice. I needed a lot of time to prepare slides and, additionally I made a lot of trainings inside my company, so I was busy. Which isn't bad at all, since it allowed some of my ideas to mature and for me to gain a little distance. What a nice surprise it was when I got back to the last chapter in progress that I paused writing for several months and discovered that what I have written still makes a lot of sense to me!

So, I am back on track and I will be writing more. As a proof of this, the new version of the book contains a new, fresh chapter on viewing object composition as a language. This is heavy influenced by what Nat Pryce and Steve Freeman are researching nowadays, do I gave them a lot of credit in the chapter and am doing so here. 

The chapter was very difficult for me to write (wait, didn't I say that about some previous chapters?), so I would be very, very grateful for any feedback, both big (like very valuable e-mails I have received from some of you) and very small (like a mention on twitter). Of course, another way of providing feedback is through pull requests, because the source markdown of the book is hosted on github (just look: https://github.com/grzesiek-galezowski/tdd-ebook/tree/master/manuscript).

Hope you like it! One or two chapters more and we're back to core TDD and introducing mocks (wait, didn't I say that about some previous chapters? :-)).

Happy reading!

# 10-01-2015

Hello!

After Christmas, new year, some Ultra Street Fighter 4 + Path of Exile, learning for driving license and conducting some technical training, the new chapter is ready.

This chapter is about two topics related to classes - Single Responsibility Principle and static fields usage. I planned to include the guildeline to avoid real work in constructors, but I could not come up with a flluent and clear argumentation yet, so I decided to postpone it. You can expect me to update this chapter in the future.

The next thing is integrating a bunch of corrections constributed by Reuven Yagel (thanks!). If you'd like to view the changes, github has all the commits history.

The third thing I did was to make a downloadable pdf sample (placed on the book page) which in reality is (and will be) the full book. Anybody can download it without creating an account on leanpub (but only you who registered will get these lovely e-mails :-) plus mobi and epub versions). This is my Christmas gift to the world.

Happy reading!


# 30-11-2014

Hello!

Yes, I know I e-mailed you about a week ago. Still, I have important message to share: the hardest and trickiest for me to write chapter is ready! 

This chapter (Protocols) deals with the idea of creating a stable communication patterns between object and its collaborators. Understanding this idea is crucial for working effectively mock objects.

If you like, please let me know what you think about this new chapter. It was difficult to write, I made three passes through it making corrections and I still feel it can be improved. Even one sentence or a small suggestion is valuable to me!

Oh, and by the way, this is an open source e-book, with sources on github, so if you find a typo or something that is not proper English (I am not a native speaker), you are welcome to fork the repo (it's all in leanpub-flavored markdown, which is easy to understand) and send me a pull request or open an issue on github (or just let me know via leanpub).

Have a great week and happy reading!

# 14-11-2014

Hello!

Long time no hear from me! Looking at the publish dates, seems like I have not published anything since 2 months ago.

Today I added a new chapter on interfaces. I planned this chapter to be on both interfaces and protocols between objects, but there was too much to grasp and the nesting level for sections was suffering as well, so I figured I'd split the chapter to fix all these things. The protocol part will be published soon (well, actually it's already part of the book, just in draft state and after a warning sign ;-). 

After that I am planning to do maybe one more chapter on value objects and then get back to TDD and mocks.

Happy reading!

# 08-09-2014

Hi, haven't written for quite a long time, main purposes being:
1. The release of Ultra Street Fighter 4 :-)
2. Polishing new chapter on how to compose objects

Yeah, the new chapter is ready! I struggled a lot with it and it is quite long, but I hope it proves useful since it touches on both ways of composing objects and *a lot* on benefits of factories.

Happy reading!

# 05-08-2014

In this version:
- definitely finished "Why do we need composability" chapter to make it cleaner
- fixed a lot of small errors, typos and misformattings throughout the book

Happy reading and I am eager to hear your opinions and suggestions through twitter, leanpub or github!

# 29-07-2014

- First version published on leanpub.
- Contains full part 1
- Part 2 is in progress
