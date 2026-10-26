# Unity Coding Skills

Skills and agents that drive test-first development of Unity games. The terms below fix the vocabulary that the skills share.

## Language

### From need to code

**Requirement**:
What users or the environment need to hold true, stated outside the system's boundary.
_Avoid_: Spec, intent

**External specification**:
The specification at the outermost boundary of the product, as the player or the API user observes it. Specifications below it come from software design and are called just "specification".
_Avoid_: Product spec, functional specification, system specification

**Specification**:
The observable behavior at the boundary of a unit (system, module, or class) that satisfies its requirements. The boundary is relative: a design decision at one level is a specification for the level below.
_Avoid_: Requirement, product spec, intent; "spec" or "specification" as the name of a document

**Game design**:
The rules and parameters of play decided by game designers; in the software sense, a specification, while the intended player experience is a requirement.
_Avoid_: Design (unqualified)

**Visual design**:
The intended appearance of UI: layout, typography, contrast.
_Avoid_: Design (unqualified)

**Software design**:
The internal structure of a unit (classes, method signatures, dependencies) chosen to satisfy its specification. Unqualified "design" means software design.
_Avoid_: Implementation design, product design

### Tests

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
A test that verifies a normal outcome, not an error, of an external specification or of a specification that realizes an explicitly stated requirement.
_Avoid_: Same-layer witness

**Integration test**:
A test whose subject is a scene or a prefab, verifying the behavior that emerges from its components and referenced assets. External specifications of a game usually land here.

**Unit test**:
A test whose subject is a class or an asset, verified through its API or content. An external specification given as an API is tested at this layer.

**Test target**:
The unit a test design is made for, designed as a whole: e.g., the screen transitions, a screen, a prefab, or a class. The test target of a `ScriptableObject` class spans two subjects: the class's API (unit tests) and its assets' data (a validator).

**Contained test target**:
A test target whose subject lies within another test target's subject, e.g., a class placed on a screen, or a screen within the screen transitions. The container's tests cover only the behavior that combines its contained test targets.
_Avoid_: Component (a Unity component), child target

**Validator**:
A test whose subject is the project's assets of a `ScriptableObject` class, verifying that the data each holds satisfies the class's specification.
_Avoid_: Unit test (for the data of a `ScriptableObject` class)

### Code

**Implementation**:
The code that realizes a software design or a test design, and the act of writing it.
_Avoid_: Product code (use production code for the code under test)
