# Decision Table Testing

Apply when a combination of multiple conditions produces different outcomes according to rules the specification defines — e.g., the damage multiplier determined by attribute affinity and a critical hit.
Unlike [combinatorial testing](combinatorial-testing.md), where every combination expects the same behavior, the expected result here changes with the combination.

- **Conditions** — partition each condition per [equivalence partitioning](equivalence-partitioning.md); its equivalence partitions are the values the condition takes in the table.
- **Rules** — each rule (column) is a combination of the conditions' equivalence partitions and its outcome.
  When a condition does not affect a rule's outcome, mark it as "don't care" and merge the rules that differ only in it.
- **Test methods** — cover every rule.
  Rules with different outcomes become separate test methods (one method = one outcome, per [Deriving test methods from equivalence partitions](equivalence-partitioning.md#deriving-test-methods-from-equivalence-partitions)); rules sharing an outcome may be consolidated into one [parameterized test](equivalence-partitioning.md#parameterized-tests).
- **Gaps and contradictions** — a combination no rule covers is a gap, and two rules giving different outcomes for the same combination are a contradiction; design the test case of a gap as undefined and no test case for a contradiction, and include the table as the modeling result (see [Test Techniques](../SKILL.md#test-techniques)).
