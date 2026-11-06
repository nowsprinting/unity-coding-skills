### <ClassName, or scene/prefab/screen name>Test

#### Assertion-based tests

Equivalence Partitioning (Boundary value coverage)

| Test Method              | Verification                                | Tags       |
|--------------------------|---------------------------------------------|------------|
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>` | acceptance |
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>` |            |

State Transition Testing (0-switch coverage)

| Test Method              | Verification                                | Tags       |
|--------------------------|---------------------------------------------|------------|
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>` |            |

**Notes:**

- The specification explicitly states the behavior under conditions `<condition>` and `<condition>` as "undefined", so they are not included in the test cases.
- No test code is generated from the test cases marked undefined or ambiguous.

#### Visual verification tests

| Test Method              | Image analysis by saved screenshot                                                                                      | Tags |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------|------|
| `<Condition>_<Expected>` | <visual aspects per `test-designing-guide` (Visual aspects to verify) — e.g. text/background contrast, font size/style> |      |

#### Manual tests

| Test Case                 | Test perspectives / Verification method           |
|---------------------------|---------------------------------------------------|
| Brief description of item | <behavioral aspects to verify and how to confirm> |
