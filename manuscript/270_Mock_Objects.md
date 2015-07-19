# Mock Objects

it makes sense to test protocols as we want to reuse them

objects are independent of context - which context should we use for testing?

TODO many say that testing with mocks is testing "isolated from dependencies". I disagree. Each object is designed to be independent of context and mocks are just another context. We can have more context not for production - trace context, demo context etc.