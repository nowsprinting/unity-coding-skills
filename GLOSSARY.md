# Unity Coding Skills

Skills that drive test-first development of Unity games. The terms below fix the vocabulary that the skills share.

## Language

### From need to code

**Specification**:
The observable behavior at the boundary of a unit (system, module, or class). Unqualified "specification" or "spec" covers both kinds: the external specification and the design docs. It is the content wherever it is stated: a file, an issue, or what the user says in the conversation.
_Avoid_: Requirement, product spec, intent

**External specification**:
The specification at the outermost boundary of the product, as the player or the API user observes it. What users need to hold true is an external specification too.
_Avoid_: Requirement, product spec, functional specification, system specification

**Design docs**:
The specification inside the product, at any level: the smaller units a unit divides into (modules, scenes, prefabs, classes), how they depend on one another, method signatures, and the behavior at each unit's boundary. It covers the production code and assets, not the test design. Unqualified "design" means design docs.
_Avoid_: Software design, internal specification, implementation design, product design, architecture (only its high-level part)

**Game design**:
The rules and parameters of play decided by game designers; in the software sense, a specification.
_Avoid_: Design (unqualified)

**Visual design**:
The intended appearance of UI: layout, typography, contrast.
_Avoid_: Design (unqualified)

### Keywords in a specification

**TBD**:
The text a specification puts on an item not decided yet. The skills treat the item as non-existent: they design no test case for it, and neither test nor implement it.
_Avoid_: TBA, TODO, pending (the skills recognize only "TBD")

**Undefined**:
The text a specification states for the behavior under a condition it deliberately leaves open, e.g., "the result is undefined when HP is negative". A statement that the condition need not be considered, e.g., "a negative width need not be considered", counts as undefined too. It leaves no gap: the test design has no test case for the condition and lists it in the Notes. An undefined test case, marked `_UNDEFINED`, is the opposite: a gap where the specification states no expected result.
_Avoid_: Unspecified, out of scope

### Tests

**Test analysis**:
The analysis of the specification under test that identifies what to test: the test targets (testable features), each with its assigned specifications, and the specifications that get no test case. Narrower than the ISTQB sense, which also covers what this plugin leaves to test design.
_Avoid_: Preprocessing

**Specification under test**:
The specification that test analysis and test design design tests for: the specification the user gives, or the part of it an instruction selects. Test targets and test cases derive from it alone. Toward the user, just "specification".
_Avoid_: Target specification, input specification

**Reference**:
What the user gives test analysis and test design to read besides the specification under test. It only settles what the specification under test leaves open; no test target or test case derives from it.
_Avoid_: Reference material, test basis

**Assigned specification**:
A specification under test that test analysis assigned to a test target; the test target's test cases derive from it.
_Avoid_: Test condition (the ISTQB term also covers what no specification states), spec of test target

**Test design**:
The test cases derived from a specification, each assigned to a test layer.
_Avoid_: Design (unqualified)

**Test design document**:
The document that records a test design and the assessment of each test target.
_Avoid_: Test specification

**Expected result**:
The observable behavior a test case predicts from the specification, compared with the actual result the test target produces; an assertion, image analysis, or a human checks it.
_Avoid_: Expected outcome, expected behavior; expected value (the value an assertion compares, in test code)

**Acceptance test**:
A test that verifies a normal outcome, not an error, that an external specification explicitly states, selected per test technique: e.g., a valid equivalence partition, or a state-to-state reachability.
_Avoid_: Same-layer witness

**Integration test**:
A test whose subject is a scene or a prefab, verifying the behavior that emerges from its components and referenced assets. External specifications of a game usually land here.

**Unit test**:
A test whose subject is a class or an asset, verified through its API or content. An external specification given as an API is tested at this layer.

**Test target**:
The unit a test design is made for, designed as a whole: e.g., the screen transitions, a screen, a prefab, or a class. It names a subject in the product, not a passage of the specification, and a method is no test target of its own. The test target of a `ScriptableObject` class spans two subjects: the class's API (unit tests) and its assets' data (a validator).

**Contained test target**:
A test target whose subject lies within another test target's subject, e.g., a class placed on a screen, or a screen within the screen transitions. The container's tests cover only the behavior that combines its contained test targets.
_Avoid_: Component (a Unity component), child target

**Validator**:
A test whose subject is the project's assets of a `ScriptableObject` class, verifying that the data each holds satisfies the class's specification.
_Avoid_: Unit test (for the data of a `ScriptableObject` class)

**Test basis**:
A file or an issue that states the specification under test, or is a reference given with it, that test code or a test design document was written from, listed on it to find it by. It may be outdated or incomplete, so nothing trusts it beyond searching. Text written directly or taken from the conversation is no test basis. A test design document is no test basis, but test code lists it with them for searching.
_Avoid_: Source, reference (a document only consulted), origin, trace link

**Coverage item**:
In the ISTQB CT-MBT sense, one item that modeling the specifications with a test technique yields and a test case exercises: an equivalence partition, a decision table rule, or a state transition.
_Avoid_: Element

**Test selection criterion**:
The rule that selects which items of a test technique's model become test cases, e.g., boundary value coverage, every rule, or 0-switch coverage. Each technique has a default one, which an instruction may replace.

**Specification coverage**:
The ratio of the coverage items of the specifications that the tests verify. The coverage items come from modeling the specifications with equivalence partitioning, decision table testing, and state transition testing.
_Avoid_: Requirement coverage, test coverage (code coverage)

### Code

**Implementation**:
The code that realizes design docs or a test design, and the act of writing it.
_Avoid_: Product code (use production code for the code under test)

**Implementation target**:
The unit a phase of `implement` implements, e.g., the screen transitions, a screen, a prefab, or a class; test analysis takes it as a test target.
