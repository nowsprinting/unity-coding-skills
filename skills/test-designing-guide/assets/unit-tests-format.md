### Unit tests

#### <ClassName>Test

| Test Method                                               | Verification                                                        |
|-----------------------------------------------------------|---------------------------------------------------------------------|
| `<MethodName>_<Condition>_<Expected>`                     | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (reproduction test) | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>` (n: {3, 6, 9})      | `<property>` is `<expected value or state>`                         |
| `<MethodName>_<Condition>_<Expected>`                     | `<property>` is `<expected value or state>` (uses spy: IDependency) |
