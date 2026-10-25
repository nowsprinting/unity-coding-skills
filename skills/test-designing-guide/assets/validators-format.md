### Validators

#### <ClassName>Validator

| Test Method                            | Verification                                |
|----------------------------------------|---------------------------------------------|
| `<Condition>_<Expected>`               | `<property>` is `<expected value or state>` |
| `<Expected>`                           | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (existing)    | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (test fix)    | `<property>` is `<expected value or state>` |
| `<Condition>_<Expected>` (spec change) | `<property>` is `<expected value or state>` |

All tests are parameterized tests that take each `<ClassName>` ScriptableObject asset under `<data folder>` as an argument.
