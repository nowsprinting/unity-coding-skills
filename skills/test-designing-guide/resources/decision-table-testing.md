# Decision Table Testing

Apply when a combination of multiple conditions produces different outcomes according to rules the specification defines — e.g., the damage multiplier determined by attribute affinity and a critical hit.
Unlike [combinatorial testing](combinatorial-testing.md), where every combination expects the same behavior, the expected result here changes with the combination.

## Conditions

Partition each condition per [equivalence partitioning](equivalence-partitioning.md); its equivalence partitions are the values the condition takes in the table.

## Rules

Each rule (column) is a combination of the conditions' equivalence partitions and its outcome.
When a condition does not affect a rule's outcome, mark it as "don't care" and merge the rules that differ only in it.

## Test Selection Criteria

Choose one criterion from each of the following, independently of each other:

- **Rules** — the default is every rule:
  - **Every condition** — each equivalence partition of every condition appears as a stated value, not "don't care", in at least one selected rule
  - **Every action** — each action, i.e., the outcome of a rule, appears in at least one selected rule
  - **Every rule** — every rule is selected

  For every condition and every action, select the fewest rules that meet the criterion.
- **Values of each condition** — the [test selection criterion of equivalence partitioning](equivalence-partitioning.md#test-selection-criterion), applied to the equivalence partitions of every condition, with the same default as equivalence partitioning; boundary value coverage adds the boundary values of an equivalence partition to the parameterized test of each selected rule that states it.
  An instruction that chooses the test selection criterion of equivalence partitioning chooses this one too.

## Test Methods

Design a test case for each rule the test selection criterion of the rules selects.
Rules with different outcomes become separate test methods (one method = one outcome, per [Deriving test methods from equivalence partitions](equivalence-partitioning.md#deriving-test-methods-from-equivalence-partitions)); rules sharing an outcome may be consolidated into one [parameterized test](test-design.md#parameterized-tests).

## Acceptance Tests

Mark as an acceptance test (see [Output Format](test-design.md#output-format)) the test case of each rule whose action is a normal outcome, not an error, and is one that an external specification, or a specification that realizes a stated requirement, explicitly states.

## Gaps and Contradictions

A combination no rule covers is a gap, and two rules giving different outcomes for the same combination are a contradiction; design the test case of a gap as undefined whatever the test selection criterion, no test case for a contradiction, and include the table as the modeling result (see [Test Techniques](test-design.md#test-techniques)).
A combination the specification explicitly states as undefined is not a gap: design no test case for it (see [Unverifiable, Undefined, and Ambiguous Test Cases](test-design.md#unverifiable-undefined-and-ambiguous-test-cases)).
