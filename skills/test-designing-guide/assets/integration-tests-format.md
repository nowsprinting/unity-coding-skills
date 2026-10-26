### <ClassName, or scene/prefab/screen name>Test

#### Assertion-based tests

| Test Method                                | Verification                                                             |
|--------------------------------------------|--------------------------------------------------------------------------|
| `<Condition>_<Expected>`                   | `<property>` is `<expected value or state>`                              |
| `<Condition>_<Expected>` (acceptance test) | `<property>` is `<expected value or state>`                              |
| `<Condition>_<Expected>` (existing)        | `<property>` is `<expected value or state>`                              |
| `<Condition>_<Expected>` (test fix)        | `<property>` is `<expected value or state>`                              |
| `<Condition>_<Expected>` (spec change)     | `<property>` is `<expected value or state>`                              |
| `<Condition>_<Expected>`                   | When `<input>` is `<value>`, `<property>` is `<expected value or state>` |
| `<Condition>_UNDEFINED`                    | **undefined**                                                            |
| `<Condition>_AMBIGUOUS`                    | **ambiguous** `<reason>`                                                 |

**Notes:**

- The specification explicitly states the behavior under conditions `<condition>` and `<condition>` as "undefined", so they are not included in the test cases.
- No test code is generated from the test cases marked undefined or ambiguous.

#### Visual verification tests

| Test Method              | Image analysis by saved screenshot                                                                                      |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `<Condition>_<Expected>` | <visual aspects per `test-designing-guide` (Visual aspects to verify) — e.g. text/background contrast, font size/style> |

#### Manual tests

| Test Case                 | Test perspectives / Verification method           |
|---------------------------|---------------------------------------------------|
| Brief description of item | <behavioral aspects to verify and how to confirm> |
