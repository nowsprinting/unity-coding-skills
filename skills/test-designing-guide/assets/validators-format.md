### Validators

#### <ClassName>Validator

| Test Method                                     | Verification                                |
|-------------------------------------------------|---------------------------------------------|
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>` |
| `<Expected>`                                    | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (existing)             | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (test fix)             | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (spec change)          | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (stats: {Base, Bonus}) | `<property>` is `<expected value or state>` |
| `<Condition>_UNDEFINED`                         | **undefined**                               |
| `<Condition>_AMBIGUOUS`                         | **ambiguous** `<reason>`                    |

**Notes:**

- All tests are parameterized tests that take each `<ClassName>` ScriptableObject asset under `<data folder>` as an argument.
- No test code is generated from the test cases marked undefined or ambiguous.
- Conditions `<condition>` and `<condition>` are explicitly undefined in the specification, so they are not tested.
