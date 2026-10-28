### <ClassName>Validator

| Test Method                                     | Verification                                                 | Tags                    |
|-------------------------------------------------|--------------------------------------------------------------|-------------------------|
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>`                  |                         |
| `<Expected>`                                    | `<property>` is `<expected value or state>`                  |                         |
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>`                  | acceptance              |
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>`                  | reproduction            |
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>`                  | existing                |
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>`                  | test fix                |
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>`                  | spec change             |
| `<Condition>_<Expected>`                        | `<property>` is `<expected value or state>`                  | acceptance, spec change |
| `<Condition>_<Expected>` (stats: {Base, Bonus}) | `<property>` is `<expected value or state>`                  |                         |
| `<Condition>_<Expected>`                        | **unverifiable** `<property>` is `<expected value or state>` |                         |
| `<Condition>_UNDEFINED`                         | **undefined**                                                |                         |
| `<Condition>_AMBIGUOUS`                         | **ambiguous** `<reason>`                                     |                         |

**Notes:**

- All tests are parameterized tests that take each `<ClassName>` ScriptableObject asset under `<data folder>` as an argument.
- The specification explicitly states the behavior under conditions `<condition>` and `<condition>` as "undefined", so they are not included in the test cases.
- No test code is generated from the test cases marked unverifiable, undefined, or ambiguous.
