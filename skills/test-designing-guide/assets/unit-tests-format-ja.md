### Unit tests

#### <ClassName>Test

| Test Method                                           | Verification                                                          |
|-------------------------------------------------------|-----------------------------------------------------------------------|
| `<MethodName>_<条件>_<期待結果>`                      | `<プロパティ>` が `<期待値または状態>` である                         |
| `<MethodName>_<条件>_<期待結果>` (acceptance test)    | `<プロパティ>` が `<期待値または状態>` である                         |
| `<MethodName>_<条件>_<期待結果>` (reproduction test)  | `<プロパティ>` が `<期待値または状態>` である                         |
| `<MethodName>_<条件>_<期待結果>` (existing)           | `<プロパティ>` が `<期待値または状態>` である                         |
| `<MethodName>_<条件>_<期待結果>` (test fix)           | `<プロパティ>` が `<期待値または状態>` である                         |
| `<MethodName>_<条件>_<期待結果>` (spec change)        | `<プロパティ>` が `<期待値または状態>` である                         |
| `<MethodName>_<条件>_<期待結果>` (level: {1, 50, 99}) | `<プロパティ>` が `<期待値または状態>` である                         |
| `<MethodName>_<条件>_<期待結果>`                      | `<プロパティ>` が `<期待値または状態>` である (uses spy: IDependency) |
| `<MethodName>_<条件>_<期待結果>`                      | **unverifiable** `<プロパティ>` が `<期待値または状態>` である        |
| `<MethodName>_<条件>_UNDEFINED`                       | **undefined**                                                         |
| `<MethodName>_<条件>_AMBIGUOUS`                       | **ambiguous** `<理由>`                                                |
