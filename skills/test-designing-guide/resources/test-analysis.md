# Test Analysis

Analyzes the specification under test to identify what to test: extract the test targets from the specifications, assign each specification to one of them, and leave out the specifications that get no test case.
In ISTQB terms, a test target is a testable feature, and its assigned specifications are test conditions.

## Input

- **Specification under test** — the specification to design tests for: what the user gives as the specification, or the part of it an instruction selects; test targets and test cases derive from it alone.
  "The specification" below means the specification under test.
- **Instruction** (optional) — which part of the specification to design tests for, and the test techniques or test selection criteria to use.

Whatever else you read, e.g., a document the specification under test links to or another document of the project, only settles what the specification under test leaves open, e.g., the definition of a term it uses; extract no test target from it.

## Test Targets

Extract the test targets the specifications describe, e.g.:

- The screen transitions
- A screen
- A character (actor)
- A component (class)
- A master data class: a class that holds master data, e.g., a subclass of `ScriptableObject` (its methods, tested by unit tests)
- The master data records of a master data class: the instances of it authored in the project, e.g., its assets (the constraints on their data, tested by a validator)

Extract only targets the specification describes; do not derive targets at a level no specification describes — e.g., internal classes guessed from the external specification of a screen — because such tests couple to an implementation no specification fixes.
When the input includes design docs, the classes and signatures they fix are specifications, and are valid targets.

Assign each specification to exactly one test target, so that no test case or coverage item derives from it twice.

### Screen Transitions

Extract the screen transitions of each screen transition system — the screens that transitions connect to one another, e.g., all the screens of a game, or the screens of a feature with transitions of its own — as a single test target, whatever form the specification gives them in — a screen transition diagram, a sequence, a use case, or button operations written per screen: test design models them as one FSM (see [State transition testing](state-transition-testing.md#screen-transitions)), and splitting them across the screens leaves each target a fragment of it.

### Master Data Classes

Extract a master data class and its master data records as two test targets: the class holds the specifications of its methods (unit tests), and the master data records hold the constraints the specification states on their data (a validator); each constraint is a property of one master data record (see [Validators](validators.md#properties)).
Their subjects differ — the class's API, and the data authored in the project — so each is designed and assessed on its own, even where both refer to the same fields.
Extract the master data records only when the specification states such a constraint.
Record those constraints with the master data class too, without assigning them to it: they bound the values its fields hold, so test design leaves the values they exclude out of the class's unit tests.

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
- **A specification of a constructor with no branch**, e.g., "the constructor sets the maximum hit points to the given value" — such a constructor only sets the members of the instance, by assignments that run whenever an instance is created, so a test only transcribes the assignments a second time; the values it sets are inputs of the test cases of the methods that read them, not expected results. A specification that states a branch in a constructor, e.g., "the constructor throws an exception when the given value is negative", is assigned to its test target like any other.
- **A table listing each master data record's concrete values** (e.g., a master data table) — the source the master data records are authored from, not a property: a test comparing a master data record or the list of them with it only transcribes the table a second time.
- **A specification on the set of master data records of a master data class**, e.g., the number of them or the presence of a specific one — not a property of one master data record; only when the user explicitly asks, assign it to the test target of the master data records.

## Output

- The test targets, each with its assigned specifications and the test targets it contains; a master data class also with the constraints on its master data records
- The specifications left out per [TBD Items](#tbd-items) and [Specifications Without Test Cases](#specifications-without-test-cases), each with its reason
