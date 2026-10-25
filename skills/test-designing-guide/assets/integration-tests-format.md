### Integration tests

#### <ClassName, or scene/prefab/screen name>Test

| Test Method                                | Verification                                |
|--------------------------------------------|---------------------------------------------|
| `<Condition>_<Expected>`                   | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (acceptance test) | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (existing)        | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (test fix)        | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (spec change)     | `<property>` is `<expected value or state>` |
| `<Condition>_UNDEFINED`                    | **undefined**                               |
| `<Condition>_AMBIGUOUS`                    | **ambiguous** `<reason>`                    |

**Notes:**

- No test code is generated from the test cases marked undefined or ambiguous.
- Conditions `<condition>` and `<condition>` are explicitly undefined in the specification, so they are not tested.

### Visual verification tests

#### <ClassName, or scene/prefab/screen name>Test

| Test Method              | Image analysis by saved screenshot                                                                                      |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `<Condition>_<Expected>` | <visual aspects per `test-designing-guide` (Visual aspects to verify) — e.g. text/background contrast, font size/style> |

### Manual tests

| Test Case                 | Test perspectives / Verification method           |
|---------------------------|---------------------------------------------------|
| Brief description of item | <behavioral aspects to verify and how to confirm> |
