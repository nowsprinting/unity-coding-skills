---
name: test-writing-guide
description: >-
  Provides guidelines for writing test code for Unity projects.
  Make sure to use this skill whenever writing, creating, editing, or modifying test code files (files under Tests/).
  This includes implementing new tests, fixing test failures, adding test cases, or any task that results in test code changes.
  Even for small edits or one-line fixes, load this skill to ensure test conventions are followed.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for writing test code for Unity projects.

## Rules

- Before modifying any test file, check if the editor is in Play Mode. If it is, stop it using the `mcp__jetbrains__unity_play_control` tool first.
- Never create `.meta` files. Unity editor creates them automatically.
- When implementing a test for an `internal` visibility method, add `[Category("Internal")]` to the test method.
- When implementing tests designed as integration tests, add `[Category("Integration")]` to the test method.
- When implementing tests designed as acceptance tests (marked `(acceptance test)` in the test case design), add `[Category("Acceptance")]` to the test method.
- When a test creates a `GameObject`, add `[CreateScene]` to the test method (not required if `[LoadScene]` is already present).
- When adding a test seam to production code (e.g., an `internal` accessor or a virtual override point to support injection), always wrap it with `#if UNITY_INCLUDE_TESTS` … `#endif` so it is excluded from non-test builds:
    ```csharp
    #if UNITY_INCLUDE_TESTS
    internal void SetStateForTest(State state) => _state = state;
    #endif
    ```

### UI Tests

#### Use GameObjectFinder instead of GameObject.Find

When finding a GameObject that the user interacts with, always use `TestHelper.UI.GameObjectFinder` instead of `UnityEngine.GameObject.Find`, `Object.FindFirstObjectByType`, `Object.FindAnyObjectByType`, and `Object.FindObjectOfType`.
Reasons:

- **Timing safety**: polls until the object appears, so tests pass even when GameObjects are instantiated asynchronously or on the next frame
- **Reachability and interactability**: verifies the object is actually reachable by the user and (optionally) interactable — matching real user experience
- **Blocking check**: `reachable: true` (default) naturally catches elements hidden behind a modal or overlay — which is often the bug being caught
- **Actionable failures**: throws `TimeoutException` with a clear message; `GameObject.Find` silently returns `null` and causes a confusing `NullReferenceException` later

#### Use Operators instead of direct event invocation

When reproducing user actions, always use uGUI operators (e.g., `UguiClickOperator`, `UguiTextInputOperator` in `TestHelper.UI.Operators` namespace) instead of directly calling button events or setting field values.
Reasons:

- **Correct event simulation**: operators go through Unity's `EventSystem` and input pipeline, exercising the same code path as a real user interaction
- **Reachability-gated**: test fails if a UI element is disabled or hidden
- **Simpler test code**: no need to look up components or call internal methods; just find the GameObject and operate it

```csharp
// NG — bypasses Unity's event pipeline
button.GetComponent<Button>().onClick.Invoke();
inputField.GetComponent<InputField>().text = "12345";
scene.OnConfirmClicked();

// OK — goes through the proper UI event path
await new UguiClickOperator().OperateAsync(button);
await new UguiTextInputOperator().OperateAsync(inputField, "12345");
```

### Visual verification tests

When implementing a visual verification test (a test designed to verify on-screen rendering via screenshot and image analysis):

1. Take a screenshot using `[TakeScreenshot]` or `ScreenshotHelper.TakeScreenshotAsync()` (see `test-helper.md`).
2. Add `[Description("Verify the screenshots from the following perspectives: <verification aspects>")]` to the test method. The verification aspects are taken directly from the `(saves screenshot for image analysis: ...)` note in the test case design.
3. Add `[Category("VisualVerification")]` to the test method.
4. You can omit writing `Assert` statements.

## Resources

Read the appropriate resource file based on the situation:

- Before writing or modifying any test code file: Read `${CLAUDE_SKILL_DIR}/resources/unity-test-framework.md`
- Before writing or modifying any test code file: Read `${CLAUDE_SKILL_DIR}/resources/test-helper.md`
- Before writing or modifying UI tests with `TestHelper.UI` namespace API (e.g., `GameObjectFinder`, `Monkey`): Read `${CLAUDE_SKILL_DIR}/resources/test-helper-ui.md`
