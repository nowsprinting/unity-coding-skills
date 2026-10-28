### <ClassName, or scene/prefab/screen name>Test

#### Assertion-based tests

| Test Method              | Verification                                                             | Tags                    |
|--------------------------|--------------------------------------------------------------------------|-------------------------|
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>`                              |                         |
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>`                              | acceptance              |
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>`                              | existing                |
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>`                              | test fix                |
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>`                              | spec change             |
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>`                              | acceptance, spec change |
| `<Condition>_<Expected>` | When `<input>` is `<value>`, `<property>` is `<expected value or state>` |                         |
| `<Condition>_UNDEFINED`  | **undefined**                                                            |                         |
| `<Condition>_AMBIGUOUS`  | **ambiguous** `<reason>`                                                 |                         |

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
