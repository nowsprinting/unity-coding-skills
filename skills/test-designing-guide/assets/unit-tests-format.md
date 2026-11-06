### <ClassName>Test

Equivalence Partitioning (Boundary value coverage)

| Test Method                           | Verification                                | Tags       |
|---------------------------------------|---------------------------------------------|------------|
| `<MethodName>_<Condition>_<Expected>` | `<property>` is `<expected value or state>` | acceptance |
| `<MethodName>_<Condition>_<Expected>` | `<property>` is `<expected value or state>` |            |

Decision Table Testing (Every rule, Boundary value coverage)

| Test Method                           | Verification                                | Tags       |
|---------------------------------------|---------------------------------------------|------------|
| `<MethodName>_<Condition>_<Expected>` | `<property>` is `<expected value or state>` |            |

**Notes:**

- `<MethodName>`: The specification explicitly states the behavior under conditions `<condition>` and `<condition>` as "undefined", so they are not included in the test cases.
- No test code is generated from the test cases marked unverifiable, undefined, or ambiguous.
