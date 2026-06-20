### Editor tests

#### <ClassName>

| Test Method                                     | Verification                                                        |
|-------------------------------------------------|---------------------------------------------------------------------|
| `Method_Condition_Expected`                     | `<property>` is `<expected value or state>`                         |
| `Method_Condition_Expected` (reproduction test) | `<property>` is `<expected value or state>`                         |
| `Method_Condition_Expected` (n: {3, 6, 9})      | `<property>` is `<expected value or state>`                         |

### Unit tests

#### <ClassName>

| Test Method                                      | Verification                                                        |
|--------------------------------------------------|---------------------------------------------------------------------|
| `Method_Condition_Expected`                      | `<property>` is `<expected value or state>`                         |
| `Method_Condition_Expected`                      | `<property>` is `<expected value or state>` (uses spy: IDependency) |

### Integration tests

#### <ClassName>

| Test Method                                      | Verification                                                        |
|--------------------------------------------------|---------------------------------------------------------------------|
| `Condition_Expected`                             | `<property>` is `<expected value or state>`                         |

### Visual verification tests

#### <ClassName>

| Test Method           | Image analysis by saved screenshot                                                             |
|-----------------------|------------------------------------------------------------------------------------------------|
| `Condition_Expected`  | <element positions, no overlap, text/background contrast>                                      |

### Manual tests

| Test Case                   | Test perspectives / Verification method           |
|-----------------------------|---------------------------------------------------|
| Brief description of item   | <behavioral aspects to verify and how to confirm> |
