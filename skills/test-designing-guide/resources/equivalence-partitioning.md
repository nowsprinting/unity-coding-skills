# Equivalence Partitioning

Group the values of each input into equivalence partitions the specification says produce the same outcome.
A **valid equivalence partition** produces a normal outcome; an **invalid equivalence partition** results in an error — e.g., `0` and negative numbers in FizzBuzz.

Test each equivalence partition with one representative, chosen in this order:

1. A value the specification states for the equivalence partition (when it states several, e.g., as examples, take all of them into the equivalence partition's parameterized test)
2. The middle value of its range, when the range has both bounds
3. A prime number within it, when its range lacks a bound
4. Any one value within it, e.g., for a non-numeric equivalence partition, or a range without a prime number

When the specification defines no behavior for an equivalence partition, valid or invalid, it is a gap in the specification: do not guess or invent the behavior, but design its test case as undefined and include the equivalence partition table as the modeling result (see [Test Techniques](../SKILL.md#test-techniques)).
An equivalence partition the specification explicitly states as undefined is not a gap: design no test case for it (see [Unverifiable, Undefined, and Ambiguous Test Cases](../SKILL.md#unverifiable-undefined-and-ambiguous-test-cases)).

Add an equivalence partition beyond every upper and lower limit, even when the specification states only the range within them — e.g., `HP < 0`, `HP > MaxHP`, `EXP > Next` (the experience needed for the next level).
Such a value often arises from a calculation rather than a direct input: damage exceeding the remaining HP, experience gained beyond the next level.
Whether it is a valid or an invalid equivalence partition depends on the specification — `EXP > Next` is a valid equivalence partition, since it produces a level up.

## Deriving test methods from equivalence partitions

The most common derivation error is merging equivalence partitions with **different** expected results into one (parameterized) method, encoding the difference as a condition in the name/Verification (e.g. `..._InteractableMatchesNonEmpty`, "interactable is true *only when* non-empty").
One rule prevents it:

**One test method = one equivalence partition = one definite expected result.**
Never parameterize the expected result.
If the expected result changes with the input, the inputs belong to **different** equivalence partitions → **separate** test methods, each named after its own outcome.

For each input variable:
1. Partition the input domain into equivalence partitions the specification says produce the **same** outcome.
2. Emit **one method per equivalence partition**, named `..._<Partition>_<ThatPartitionsOutcome>`.
   The `<Expected>` segment is a concrete state/value (`IsInteractable`, `IsNotInteractable`), never a condition word (`Matches…`, `…WhenNonEmpty`, `DependingOn…`).
3. Within one equivalence partition, consolidate its representative and its boundary values into **one parameterized** method — they share the outcome (see [Parameterized tests](#parameterized-tests)).

**Worked example** — `drawPileButton.interactable` driven by the draw pile count:

| Equivalence partition   | Representative values | Expected result           |
|-------------------------|-----------------------|---------------------------|
| Empty (`count == 0`)    | `0`                   | `interactable` is `false` |
| Non-empty (`count ≥ 1`) | `1` (boundary), `5`   | `interactable` is `true`  |

Two equivalence partitions, two outcomes → **two** methods (NOT one parameterized method over `{0, 1, 5}`):

| Test Method                                                            | Verification                             |
|------------------------------------------------------------------------|------------------------------------------|
| `Sync_DrawPileIsEmpty_DrawPileButtonIsNotInteractable`                 | the draw pile button is not interactable |
| `Sync_DrawPileIsNotEmpty_DrawPileButtonIsInteractable` (count: {1, 5}) | the draw pile button is interactable     |

The non-empty method keeps both `1` and `5` because they share the outcome `true`; `1` is the equivalence partition's boundary value, `5` its representative — a prime number, since the equivalence partition has no upper bound.

## Parameterized tests

When multiple test cases share the same expected result — such as the representative and the boundary values of the same equivalence partition, decision table rules sharing an outcome, or [combinations of parameters](combinatorial-testing.md) — consolidate them into a single parameterized test.

**Specifying parameter name and values in the Test Method column** — write values after the method name:

- **Bool parameter, all values**: `(flag: (bool))`
- **Enum parameter, all values**: `(direction: (Direction))`
- **Multiple parameters, all combinations (exhaustive)**: `(param1: {0, 1, 2}, param2: {3, 4, 5})` — when a parameter is `bool` or enum covering all its values, use the shorthand in place of the braces: `(flag: (bool), count: {0, 1, 5})`
- **Multiple parameters, limited to specific combinations**: `({param1: 0, param2: 3}, {param1: 1, param2: 4})`

Do NOT over-consolidate: keep separate rows for tests that belong to **different** equivalence partitions or produce **different** expected results.

## Invalid equivalence partition

The expected result of an invalid equivalence partition is the error the specification defines — e.g., an exception thrown, an error message shown, or the input rejected.

- **UI input validation** — test invalid inputs that a user can enter through the UI (e.g., out-of-range values in a numeric text field).
  These represent real failure paths at the system boundary and must be tested.
- **Dependency error returns** — when the specification defines a dependency's error/failure path, whether to test it depends on the dependency's origin:
  - **Library or framework** (external, not owned by this project) → test it; use a stub to inject the error condition.
  - **Game's own code** (another component in this project) → skip; trust internal code correctness.
  - **Uncertain** → record it as an issue (an unclear specification) in the [Assessment](../SKILL.md#assessment) instead of designing test cases.
