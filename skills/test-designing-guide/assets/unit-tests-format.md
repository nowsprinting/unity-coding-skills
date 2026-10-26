### <ClassName>Test

| Test Method                                                | Verification                                                        |
|------------------------------------------------------------|---------------------------------------------------------------------|
| `<MethodName>_<Condition>_<Expected>`                      | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (acceptance test)    | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (reproduction test)  | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (existing)           | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (test fix)           | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (spec change)        | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (level: {1, 50, 99}) | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>`                      | `<property>` is `<expected value or state>` (uses spy: IDependency) |
| `<MethodName>_<Condition>_<Expected>`                      | **unverifiable** `<property>` is `<expected value or state>`        |
| `<MethodName>_<Condition>_UNDEFINED`                       | **undefined**                                                       |
| `<MethodName>_<Condition>_AMBIGUOUS`                       | **ambiguous** `<reason>`                                            |

**Notes:**

- No test code is generated from the test cases marked unverifiable, undefined, or ambiguous.
- `<MethodName>`: Conditions `<condition>` and `<condition>` are explicitly undefined in the specification, so they are not tested.
