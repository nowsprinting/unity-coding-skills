## <ClassName>Validator

### Validator test cases

| Test Method              | Verification                                | Tags       |
|--------------------------|---------------------------------------------|------------|
| `<Condition>_<Expected>` | `<property>` is `<expected value or state>` | acceptance |
| `<Expected>`             | `<property>` is `<expected value or state>` |            |

**Notes:**

- All tests are parameterized tests that take each master data record of `<ClassName>` under `<data folder>` as an argument.
- No test code is generated from the test cases marked unverifiable, undefined, or ambiguous.
