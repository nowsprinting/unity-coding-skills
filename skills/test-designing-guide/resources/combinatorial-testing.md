# Combinatorial Testing

Apply only when an instruction enables it (see [Test Techniques](../SKILL.md#test-techniques)), to test the combinations of multiple parameters (factors) whose expected result stays the same — e.g., the selected character and equipment.
The other techniques leave the inputs the expected result does not depend on out of the test cases, and the test-writing phase gives them neutral values; testing their combinations is a risk judgment the specification does not make, so the user makes it.
Unlike [decision table testing](decision-table-testing.md), where rules map each combination of conditions to a different outcome, every combination here expects the same behavior; the test cases look for combinations whose interaction breaks it.

## One Expected Result

Every combination shares one expected result, even when it is a number.
When the expected result depends on the combination, e.g., damage computed from the character and the weapon, the asserting test would have to compute or branch on its parameters; model it with [decision table testing](decision-table-testing.md) instead.

## Levels

The levels are the values of each parameter.
Since the output has one equivalence partition, partition the input by its own kinds, and take one representative per input equivalence partition as its levels: positive, zero, and negative at most for a number; every member for an enum; every type the parameter can take for a type, e.g., the classes implementing an interface.
Choose the levels so that no combination falls in a condition the specification explicitly states as undefined; when no choice of levels avoids it, write the combinations with the limited-combinations notation.

## Classification Tree

To choose the combinations, draw each parameter as a classification and its levels as classes under it; each test case then picks one class from every classification.

## Test Selection Criterion

Choose one of the following; the default is pairwise in integration tests and all combinations in unit tests:

- **All combinations** — every combination of the levels of all parameters
- **Pairwise** — every combination of the levels of any two parameters (2-wise)

Unity Test Framework generates no other combination set, so decline an instruction for any other criterion, e.g., 3-wise: take the default instead, and state in the Notes that Unity Test Framework supports only all combinations and pairwise.

The unit test framework generates the combinations from the levels, so the test case lists each parameter with its levels in the [parameterized test](../SKILL.md#parameterized-tests) notation, not the combinations, e.g., `(character: (Character), weapon: {Sword, Bow})`; for pairwise, append `by pairwise` to it, e.g., `(character: (Character), weapon: {Sword, Bow}, by pairwise)`.

Validators get no combinatorial testing: their input is the assets authored in the project, which the test cannot choose.

## Combinatorial Explosion

In integration tests, with many parameters or levels, even pairwise combinations explode.
Judge the testability low: assess it as `⚠️WARN` (combinatorial explosion), and propose in the Issues to break the test down into tests at a more detailed level.
Unit tests are not judged for combinatorial explosion.
