### <ClassName, or scene/prefab/screen name>Test

#### Assertion-based tests

Equivalence Partitioning (Boundary value coverage)

| Test Method         | Verification                                  | Tags       |
|---------------------|-----------------------------------------------|------------|
| `<条件>_<期待結果>` | `<プロパティ>` が `<期待値または状態>` である | acceptance |
| `<条件>_<期待結果>` | `<プロパティ>` が `<期待値または状態>` である |            |

State Transition Testing (0-switch coverage)

| Test Method         | Verification                                  | Tags       |
|---------------------|-----------------------------------------------|------------|
| `<条件>_<期待結果>` | `<プロパティ>` が `<期待値または状態>` である |            |

**Notes:**

- 条件 `<条件>`、`<条件>` は、振る舞いが「未定義」と仕様に明示されているため、テストケースに含まれません
- unverifiable, undefined, ambiguous と書かれたテストケースからは、テストコードは生成されません

#### Visual verification tests

| Test Method         | Image analysis by saved screenshot                                                                                   | Tags |
|---------------------|----------------------------------------------------------------------------------------------------------------------|------|
| `<条件>_<期待結果>` | <`test-designing-guide` の Visual aspects to verify に従う — 例: 文字と背景のコントラスト、フォントサイズ・スタイル> |      |

#### Manual tests

| Test Case                | Test perspectives / Verification method |
|--------------------------|-----------------------------------------|
| テストケースの簡潔な説明 | <検証する挙動と確認方法>                |
