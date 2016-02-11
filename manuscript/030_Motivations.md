Motivation -- the first step to learning TDD
===========================================

I'm writing this book because I'm a TDD enthusiast. I believe TDD is a huge improvement over other software development methodologies I have used to deliver quality software. I believe this is true not only for me, but for many other software developers. Which makes me question, why don't more people learn and use TDD as their software delivery methodology of choice? In my professional life, I haven't seen the adoption rate to be big enough to justify the claim that TDD is currently in the mainstream.

You already have my respect for deciding to pick up a book, rather than building your understanding of TDD on the foundation of urban legends and your own imagination. I am honored and happy you chose this one, no matter if this is your first book on TDD or one of many you have opened up in your learning endeavors.  As much as I really hope you will read this book from cover to cover, I am aware it doesn't always happen. That makes me want to ask you an important question that may help you determine whether you really want to read on: why do you want to learn TDD?

By questioning your motivation, I'm not trying to discourage you from reading this book. Rather, I'd like you to reconsider the goal you want to achieve by reading it. A few years ago, I had an apprentice who wanted to learn TDD. Together we started working on a small project to let him grasp the necessary skills through practice, with me sitting next to him, providing guidance. He showed up three or four times, then he resigned, having "more urgent things to do" and "no time". Since then, he has not progressed in his understanding or utilization of TDD at all. Even today, I sometimes wonder what was his motivation and why it somehow burned out.

Over time, I have noticed that some of us (myself included) may think we need to learn something (as opposed to wanting to learn something) for whatever reasons, e.g. getting a promotion at work, gaining a certificate, adding something to CV, or just "staying up to date" with recent hypes. Unfortunately, Test-Driven Development tends to fall into this category for many people. Such motivation may be difficult to sustain over the long term.

Another source of motivation may be imagining TDD as something it really is not. Some of us may only have a vague knowledge of what the real costs and benefits of TDD are. Knowing that TDD is valued and praised by others, we may draw conclusions that it has to be good for us as well. We may have a vague understanding of the reasons, such as "the code will be more tested" for example. As we don't know the real "why" of TDD, we may make up some reasons to practice test-first development, like "to ensure tests are written for everything". Don't get me wrong, these statements might be partially true, however, they miss a lot of the essence of TDD. If TDD does not bring the benefits we imagine it might bring, dissapointment may creep in. I heard such disappointed practitioners saying "I don’t really need TDD, because I need tests that give me confidence on a broader scope" or "Why do I need unit tests[^notonlyunittests] when I already have integration tests, smoke tests, sanity tests, exploration tests, etc...?". Many times, I saw TDD getting abandoned before even being understood.

Is learning TDD a high priority for you? Are you determined to try it out and really learn it? If you're not, hey, I heard the new series of Game Of Thrones is on TV, why don’t you check it out instead? Ok, I’m just teasing, however, as some say, TDD is "easy to learn, hard to master"[^easytolearn], so without some guts to move on, it will be hard. Especially since my plan is to introduce the content slowly and gradually, so that you can get better explanation of some of the practices and techniques.

How TDD feels like
------------------

My brother and I liked to play video games in our childhood -- one of the most memorable being Tekken 3 -- a Japanese tournament beat’em up for Sony Playstation. Beating the game with all the warriors and unlocking all hidden bonuses, mini-games etc. took about a day. Some could say the game had nothing to offer since then. Why is it then that we spent more than a year on it?

![Tekken3](images/Tekken3-gray.png)

It is because each fighter in the game had a lot of combos, kicks and punches that could be mixed in a variety of ways. Some of them were only usable in certain situations, others were something I could throw at my opponent almost anytime without a big risk of being exposed to counterattacks. I could side-step to evade enemy’s attacks and, most of all, I could kick another fighter up in the air where they could not block my attacks and I was able to land some nice attacks on them before they fell down. These in-the-air techniques were called "juggles". There were magazines that published lists of new juggles each month and the hype has stayed in the gaming community for well over a year.

Yes, Tekken was easy to learn -- I could put one hour into training the core moves of a character and then be able to "use" this character, but I knew that what would make me a great fighter was the experience and knowledge on which techniques were risky and which were not, which ones could be used in which situations, which ones, if used one after another, gave the opponent little chance to counterattack etc. No wonder that soon many tournaments sprang, where players could clash for glory, fame and rewards. Even today, you can watch some of those old matches on youtube.

TDD is like Tekken. You probably heard the mantra "red-green-refactor" or the general advice "write your test first, then the code", maybe you even did some experiments on your own where you were trying to implement a bubble-sort algorithm or other simple stuff by starting with a test. But that is all like practicing Tekken by trying out each move on its own on a dummy opponent, without the context of real-world issues that make the fight really challenging. And while I think such exercises are very useful (in fact, I do a lot of them), I find an immense benefit in understand the bigger picture of real-world TDD usage as well.

Some people I talk to about TDD sum up what I say to them as, "This is really demotivating -- there are so many things I have to watch out for, that it makes me never want to start!". Easy, don’t panic -- remember the first time you tried to ride a bike -- you might have been really far back then from knowing traffic regulations and following road signs, but that didn't really keep you away, did it?  

I find TDD very exciting and it makes me excited about writing code as well. Some guys of my age already think they know all about coding, are bored with it and cannot wait until they move to management or requirements or business analysis, but hey! I have a new set of techniques that makes my coding career challenging again! And it is a skill that I can apply to many different technologies and languages, making me a better developer overall! Isn't that something worth aiming for?

## Let's get it started!

In this chapter, I tried to provoke you to rethink your attitude and motivation. If you are still determined to learn TDD with me by reading this book, which I hope you are, then let's get to work! 

[^easytolearn]: I don’t know who said it first, I searched the web and found it in few places where none of the writers gave credit to anyone else for it, so I decided just to mention that I’m not the one that coined this phrase.

[^notonlyunittests]: By the way, TDD is not only about unit tests, which we will get to eventually.

