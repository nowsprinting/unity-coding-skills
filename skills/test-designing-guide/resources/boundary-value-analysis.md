# Boundary Value Analysis

Apply when the specification differentiates behavior at the edges of [equivalence partitions](equivalence-partitioning.md): test the values on both sides of each place where two equivalence partitions meet.
For a field valid in `1–99`: equivalence partitions `<1` / `1–99` / `>99`; boundaries `0, 1` and `99, 100`.

## Equivalence Partitions Beyond the Limits

Equivalence partitioning adds an equivalence partition beyond every upper and lower limit; test the boundaries between them and the range within the limits too (e.g., `HP` at `0` and `-1`).

## Test Methods

Boundary values follow the derivation rules of equivalence partitioning (one method per equivalence partition): fold each equivalence partition's boundary values into that equivalence partition's [parameterized test](../SKILL.md#parameterized-tests) (e.g., the valid equivalence partition over `{1, 99}`) — never one method per boundary.

## When to Skip

Over-testing boundaries inflates the number of test cases and increases maintenance cost on every spec change.
When the specification does not differentiate behavior near an edge (e.g., display color mapping), one representative per equivalence partition suffices and boundary values can be skipped entirely.
