### Integration tests

#### <ClassName, or scene/prefab/screen name>Test

| Test Method                           | Verification                                  |
|---------------------------------------|-----------------------------------------------|
| `<条件>_<期待結果>`                   | `<プロパティ>` が `<期待値または状態>` である |
| `<条件>_<期待結果>` (acceptance test) | `<プロパティ>` が `<期待値または状態>` である |
| `<条件>_<期待結果>` (existing)        | `<プロパティ>` が `<期待値または状態>` である |
| `<条件>_<期待結果>` (test fix)        | `<プロパティ>` が `<期待値または状態>` である |
| `<条件>_<期待結果>` (spec change)     | `<プロパティ>` が `<期待値または状態>` である |
| `<条件>_UNDEFINED`                    | **undefined**                                 |
| `<条件>_AMBIGUOUS`                    | **ambiguous** `<理由>`                        |

**Notes:**

- unverifiable, undefined, ambiguous と書かれたテストケースからはテストコードを生成しません
- 条件 `<条件>`、`<条件>` は明示的に未定義のためテストしない

### Visual verification tests

#### <ClassName, or scene/prefab/screen name>Test

| Test Method         | Image analysis by saved screenshot                                                                                   |
|---------------------|----------------------------------------------------------------------------------------------------------------------|
| `<条件>_<期待結果>` | <`test-designing-guide` の Visual aspects to verify に従う — 例: 文字と背景のコントラスト、フォントサイズ・スタイル> |

### Manual tests

| Test Case                | Test perspectives / Verification method |
|--------------------------|-----------------------------------------|
| テストケースの簡潔な説明 | <検証する挙動と確認方法>                |
