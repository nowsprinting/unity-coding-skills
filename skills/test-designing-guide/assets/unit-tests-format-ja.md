### <ClassName>Test

Equivalence Partitioning (Boundary value coverage)

| Test Method                      | Verification                                  | Tags       |
|----------------------------------|-----------------------------------------------|------------|
| `<MethodName>_<条件>_<期待結果>` | `<プロパティ>` が `<期待値または状態>` である | acceptance |
| `<MethodName>_<条件>_<期待結果>` | `<プロパティ>` が `<期待値または状態>` である |            |

Decision Table Testing (Every rule, Boundary value coverage)

| Test Method                      | Verification                                  | Tags       |
|----------------------------------|-----------------------------------------------|------------|
| `<MethodName>_<条件>_<期待結果>` | `<プロパティ>` が `<期待値または状態>` である |            |

**Notes:**

- `<MethodName>` の条件 `<条件>`、`<条件>` は、振る舞いが「未定義」と仕様に明示されているため、テストケースに含まれません
- unverifiable, undefined, ambiguous と書かれたテストケースからは、テストコードは生成されません
