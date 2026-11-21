# Unity Coding Skills

Skills that drive test-first development of Unity games. The terms below fix the vocabulary that the skills share.

## Language

### From need to code

**Specification**:
The observable behavior at the boundary of a part (system, module, scene, prefab, class, or asset). Unqualified "specification" or "spec" covers both kinds: the external specification and the design docs. It is the content wherever it is stated: a file, an issue, or what the user says in the conversation.
_Avoid_: Requirement, product spec, intent

**External specification**:
The specification at the outermost boundary of the product, as the player or the API user observes it. What users need to hold true is an external specification too.
_Avoid_: Requirement, product spec, functional specification, system specification

**Design docs**:
The specification inside the product, at any level: the smaller parts a part divides into (modules, scenes, prefabs, classes), how they depend on one another, method signatures, and the behavior at each part's boundary. It covers the production code and assets, not the test design. Unqualified "design" means design docs.
_Avoid_: Software design, internal specification, implementation design, product design, architecture (only its high-level part)

**Game design**:
The rules and parameters of play decided by game designers; in the software sense, a specification.
_Avoid_: Design (unqualified)

**Visual design**:
The intended appearance of UI: layout, typography, contrast.
_Avoid_: Design (unqualified)

### Master data

**Master data class**:
A class that holds master data, e.g., a subclass of `ScriptableObject`, whether or not the specification constrains the data.
_Avoid_: `ScriptableObject` class (one way to implement it), data class

**Master data record**:
One instance of a master data class authored in the project, e.g., one asset.
_Avoid_: Record (unqualified), asset (one way to store it), instance, row

### Keywords in a specification

**TBD**:
The text a specification puts on an item not decided yet. The skills treat the item as non-existent: they design no test case for it, and neither test nor implement it.
_Avoid_: TBA, TODO, pending (the skills recognize only "TBD")

**Undefined**:
The text a specification states for the behavior under a condition it deliberately leaves open, e.g., "the result is undefined when HP is negative". A statement that the condition need not be considered, e.g., "a negative width need not be considered", counts as undefined too. It leaves no gap: the test design has no test case for the condition. An undefined test case, marked `_UNDEFINED`, is the opposite: a gap where the specification states no expected result.
_Avoid_: Unspecified, out of scope

### Tests

**Test analysis**:
The analysis of the specification under test that identifies what to test: the test targets (testable features), each with its assigned specifications, and the specifications that get no test case. Narrower than the ISTQB sense, which also covers what this plugin leaves to test design.
_Avoid_: Preprocessing

**Specification under test**:
The specification that test analysis and test design design tests for: what the user gives as the specification, or the part of it an instruction selects. Test targets and test cases derive from it alone; any other document read only settles what it leaves open. Toward the user, just "specification".
_Avoid_: Target specification, input specification

**Assigned specification**:
A specification under test that test analysis assigned to a test target; the test target's test cases derive from it.
_Avoid_: Test condition (the ISTQB term also covers what no specification states), spec of test target

**Test design**:
The test cases derived from a specification, each a unit test, an integration test, or a validator.
_Avoid_: Design (unqualified)

**Test design document**:
The document that records a test design and the assessment of each test target.
_Avoid_: Test specification

**Expected result**:
The observable behavior a test case predicts from the specification, compared with the actual result the test target produces; an assertion, image analysis, or a human checks it.
_Avoid_: Expected outcome, expected behavior; expected value (the value an assertion compares, in test code)

**Test level**:
The group of tests a specification's subject decides, in the ISTQB sense narrowed to two: unit tests for a class or an asset, and integration tests for a scene or a prefab. The means of verification splits no test level: visual verification tests and manual tests are integration tests, not system tests. A validator belongs to no test level, and an acceptance test is no test level either: it is a test case selected within one.
_Avoid_: Test layer, level (unqualified), system test, acceptance testing (as a test level)

**Acceptance test**:
A test that verifies a normal outcome, not an error, that an external specification explicitly states, selected per test technique: e.g., a valid equivalence partition, or a state-to-state reachability.
_Avoid_: Same-test-level witness

**Integration test**:
A test whose subject is a scene or a prefab, verifying the behavior that emerges from its components and referenced assets. External specifications of a game usually land here.

**Unit test**:
A test whose subject is a class or an asset, verified through its API or content, including the behavior Unity's lifecycle or UI events drive in a component.

**Test target**:
The part a test design is made for, designed as a whole: e.g., the screen transitions, a screen, a prefab, or a class. It names a subject in the product, not a passage of the specification, and a method is no test target of its own. A master data class and its master data records are two test targets: the class's API (unit tests) and the data of its master data records (a validator).

**Contained test target**:
A test target whose subject lies within another test target's subject, e.g., a class placed on a screen, or a screen within the screen transitions. The container's tests cover only the behavior that combines its contained test targets.
_Avoid_: Component (a Unity component), child target

**Validator**:
A test whose subject is the master data records of a master data class, verifying that the data each holds satisfies the specification.
_Avoid_: Unit test (for the data of master data records)

**Test basis**:
A file or an issue that test code or a test design was written from, listed on the test code or in the test design document to find it by: one that states the specification under test, or one read that settled what it leaves open. It may be outdated or incomplete, so nothing trusts it beyond searching. Text written directly or taken from the conversation is no test basis. A test design document is no test basis, but test code lists it with them for searching.
_Avoid_: Source, reference, origin, trace link

**Coverage item**:
In the ISTQB CT-MBT sense, one item that modeling the specifications with a test technique yields and a test case exercises: an equivalence partition, a decision table rule, or a state transition.
_Avoid_: Element

**Test selection criterion**:
The rule that selects which items of a test technique's model become test cases, e.g., boundary value coverage, every rule, or 0-switch coverage. Each technique has a default one, which an instruction may replace.

**Combinatorial testing**:
The test technique that tests that the inputs a test case's expected result does not depend on (factors) leave that expected result unchanged in combination; every combination shares it. Narrower than the ISTQB sense (CTAL-TA v4.0, 3.1.2): of its two approaches, it takes the one that tests every combination with the same test case, applied to input data instead of configuration parameters, and leaves out the one that gives each combination its own expected result. A combination whose expected result changes by the specification's rules belongs to decision table testing.
_Avoid_: Combinatorial testing for combinations with different expected results (use decision table testing)

**Specification coverage**:
The ratio of the coverage items of the specifications that the tests verify. The coverage items come from modeling the specifications with equivalence partitioning, decision table testing, and state transition testing.
_Avoid_: Requirement coverage, test coverage (code coverage)

### Code

**Implementation**:
The code that realizes design docs or a test design, and the act of writing it.
_Avoid_: Product code (use production code for the code under test)

**Implementation target**:
The part a phase of `implement` implements, e.g., the screen transitions, a screen, a prefab, a class, or the master data records of a master data class; test analysis takes it as a test target.
