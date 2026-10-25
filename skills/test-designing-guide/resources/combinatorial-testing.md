# Combinatorial Testing

Apply when multiple data-driven parameters (factors) combine and the expected result itself stays the same — e.g., the selected character and equipment.
Unlike [decision table testing](decision-table-testing.md), where rules map each combination of conditions to a different outcome, every combination here expects the same behavior; the test cases look for combinations whose interaction breaks it.

- **One expected result** — every combination shares one expected result, even when it is a number.
  When the expected result depends on the combination, e.g., damage computed from the character and the weapon, the asserting test would have to compute or branch on its parameters; model it with [decision table testing](decision-table-testing.md) instead.
- **Levels** — the values of each parameter.
  Since the output has one equivalence partition, partition the input by its own kinds, and take one representative per input equivalence partition as its levels: positive, zero, and negative at most for a number; every member for an enum; every type the parameter can take for a type, e.g., the classes implementing an interface.
- **Integration tests** — as a principle, cover every combination of the levels of any two parameters with the pairwise (all-pairs) method; append `by pairwise` to the [parameterized test](equivalence-partitioning.md#parameterized-tests) notation, e.g., `(character: (Character), weapon: {Sword, Bow}, by pairwise)`, and the test-writing phase selects a covering combination set.
- **Unit tests** — cover all combinations, never pairwise; write the levels of each parameter in the parameterized test notation, e.g., `(character: (Character), weapon: {Sword, Bow})`.
- **Combinatorial explosion** — in integration tests, with many parameters or levels, even pairwise combinations explode.
  Judge the testability low: assess it as `ASSESSMENT: WARN` (combinatorial explosion), and propose in the Issues to break the test down into tests at a more detailed level.
  Unit tests are not judged for combinatorial explosion.
- **Classification tree** — to choose the combinations, draw each parameter as a classification and its levels as classes under it; each test case then picks one class from every classification.
