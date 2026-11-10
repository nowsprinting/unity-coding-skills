# Test Analysis

Analyzes the specification under test to identify what to test: extract the test targets from the specifications, assign each specification to one of them, and leave out the specifications that get no test case.
In ISTQB terms, a test target is a testable feature, and its assigned specifications are test conditions.

## Input

- **Specification under test** — the specification to design tests for: the specification the user gives, or the part of it an instruction selects; test targets and test cases derive from it alone.
  "The specification" below means the specification under test.
- **References** (optional) — what the user gives to read besides the specification under test.
- **Instructions** (optional) — which part of the specification to design tests for, and the test techniques or test selection criteria to use.

Read a reference, or a document the specification under test links to, only to settle what the specification under test leaves open, e.g., the definition of a term it uses; extract no test target from it.

## Test Targets

Extract the test targets the specifications describe, e.g.:

- The screen transitions
- A screen
- A character (actor)
- A component (class)
- A `ScriptableObject` class (its methods implemented as unit tests, the constraints on its data as a validator)

Extract only targets the specification describes; do NOT derive targets at a level no specification describes — e.g., internal classes guessed from the external specification of a screen — because such tests couple to an implementation no specification fixes.
When the input includes design docs, the classes and signatures they fix are specifications, and are valid targets.

Assign each specification to exactly one test target, so that no test case or coverage item derives from it twice.

### Screen Transitions

Extract all the screen transitions as a single test target, whatever form the specification gives them in — a screen transition diagram, a sequence, a use case, or button operations written per screen: test design models them as one FSM (see [State transition testing](state-transition-testing.md#screen-transitions)), and splitting them across the screens leaves each target a fragment of it.

### ScriptableObject Classes

Extract a `ScriptableObject` class as one test target holding both the specifications of its methods (unit tests) and the constraints the specification states on its data (a validator); each constraint is a property of one asset (see [Validators](validators.md#properties)).
The unit tests and the validator then share the equivalence partitions of the fields both refer to, and a gap in a field reaches the user as one issue.

## Contained Test Targets

A test target may contain other test targets, each designed from its own specification: e.g., a screen contains the classes placed on it, and the screen transitions contain the screens.
Assign the behavior within a contained target to that target, and leave the container only the behavior that combines them — e.g., the wiring between a screen and its classes, or the transitions between screens.
A part of the subject without a specification of its own, e.g., a class no specification describes, is not a contained target; assign its behavior to the container.
Record the test targets each target contains.

## TBD Items

Treat an item the specification explicitly marks "TBD" as non-existent: assign it to no test target, since it is not decided yet.
Unlike the specifications below, the implementation does not fulfill it either.

## Specifications Without Test Cases

Assign the following specifications to no test target: they get no test case and count toward no coverage.
The implementation still fulfills them; only the tests leave them out.

- **A specification a declaration alone fulfills**, e.g., "the character's hit points can be changed in the Inspector", fulfilled by a `public` field or a property with `[field: SerializeField]` — Unity's serialization guarantees the behavior once the declaration exists, so a test only transcribes the declaration a second time.
- **A table listing each asset's concrete values** (e.g., a master data table) — the source the assets are authored from, not a property: a test comparing an asset or the list of assets with it only transcribes the table a second time.
- **A specification on the set of assets of a `ScriptableObject` class**, e.g., the number of assets or the presence of a specific asset — not a property of one asset; design a test case for it only when the user explicitly asks.

## Output

- The test targets, each with its assigned specifications and the test targets it contains
- The specifications left out per [TBD Items](#tbd-items) and [Specifications Without Test Cases](#specifications-without-test-cases), each with its reason
