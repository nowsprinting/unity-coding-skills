### <ClassName>Test

| Test Method                                                                                  | Verification                                                             | Tags                    |
|----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|-------------------------|
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>`                              |                         |
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>`                              | acceptance              |
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>`                              | reproduction            |
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>`                              | existing                |
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>`                              | test fix                |
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>`                              | spec change             |
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>`                              | acceptance, spec change |
| `<MethodName>_<Condition>_<Expected>` (level: {1, 50, 99})                                   | `<property>` is `<expected value or state>`                              |                         |
| `<MethodName>_<Condition>_<Expected>`                                                        | `<property>` is `<expected value or state>` (uses spy: IDependency)      |                         |
| `<MethodName>_<Condition>_<Expected>` ({a: 2, b: 1, expected: 1}, {a: 7, b: 3, expected: 4}) | `<property>` is `expected`                                               |                         |
| `<MethodName>_<Condition>_<Expected>`                                                        | When `<input>` is `<value>`, `<property>` is `<expected value or state>` |                         |
| `<MethodName>_<Condition>_<Expected>`                                                        | **unverifiable** `<property>` is `<expected value or state>`             |                         |
| `<MethodName>_<Condition>_UNDEFINED`                                                         | **undefined**                                                            |                         |
| `<MethodName>_<Condition>_AMBIGUOUS`                                                         | **ambiguous** `<reason>`                                                 |                         |

**Notes:**

- `<MethodName>`: The specification explicitly states the behavior under conditions `<condition>` and `<condition>` as "undefined", so they are not included in the test cases.
- No test code is generated from the test cases marked unverifiable, undefined, or ambiguous.
