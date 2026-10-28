# Error Guessing

Experience-based; derive cases from failure patterns common in game development.
Use this to surface implementation concerns that specification-based techniques don't reach.
Apply it only when an instruction enables it (see [Test Techniques](../SKILL.md#test-techniques)), or to find the trigger of a reported bug (see [Reproduction tests](reproduction-tests.md)): a guessed failure pattern comes from no specification, so whether it is worth a test case is a risk judgment the user makes.

Examples to consider:

- Rapid button mashing
- Simultaneous button press
- Input during scene transition / loading
- Collision tunneling
- Random distribution bias or pseudo-random number generator (PRNG) sequence looping
- Numeric overflow
- Network failure
