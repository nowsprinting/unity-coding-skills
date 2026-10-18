# Combinatorial Testing

Apply when multiple data-driven parameters (factors) combine and the expected behavior itself stays the same — e.g., the selected character and equipment.
Unlike [decision table testing](decision-table-testing.md), where rules map each combination of conditions to a different outcome, every combination here expects the same behavior; the test cases look for combinations whose interaction breaks it.

- **Levels** — the values of each parameter. For a numeric parameter, partition its values per [equivalence partitioning](equivalence-partitioning.md) and take one representative per equivalence partition as its levels.
- **Integration tests** — as a principle, cover every combination of the levels of any two parameters with the pairwise (all-pairs) method; write `(use pairwise)` in the [parameterized test](equivalence-partitioning.md#parameterized-tests) notation.
- **Unit tests** — as a principle, cover all combinations; write the levels of each parameter in the parameterized test notation, e.g., `(character: (Character), weapon: {Sword, Bow})`.
- **Combinatorial explosion** — with many parameters or levels, even pairwise combinations explode. Judge the testability low: assess it as `ASSESSMENT: FAIL` (combinatorial explosion), and propose in the Issues to break the test down into tests at a more detailed level.
- **Classification tree** — to choose the combinations, draw each parameter as a classification and its levels as classes under it; each test case then picks one class from every classification.
