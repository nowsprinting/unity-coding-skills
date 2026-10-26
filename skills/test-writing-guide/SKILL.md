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

- Before modifying any test file, check if the editor is in Play Mode.
  If it is, stop it using the `unity_play_control` tool first.
- Never create `.meta` files.
  Unity editor creates them automatically.
- When a test creates a `GameObject` or instantiates a prefab, apply `[CreateScene]` to the test method (not required if `[LoadScene]` is already present).
- When adding a test seam to production code (e.g., an `internal` accessor or a virtual override point to support injection), always wrap it with `#if UNITY_INCLUDE_TESTS` … `#endif` so it is excluded from non-test builds:
    ```csharp
    #if UNITY_INCLUDE_TESTS
    internal void SetStateForTest(State state) => _state = state;
    #endif
    ```

### Test Design Markers

- Do not touch the test of a test case marked `(existing)`.
- For a test case marked `(test fix)` or `(spec change)`, change the existing test to match the test case instead of adding a new one.
- Do not implement a test case whose Verification column starts with `**unverifiable**`, `**undefined**`, or `**ambiguous**`: it has no API to observe the actual result through, or no single expected result to assert.

### Categories

- For a test case marked `(acceptance test)` in the test design, apply `[Category("Acceptance")]` to the test method.
- When implementing tests designed as integration tests, apply `[Category("Integration")]` to the test method.
- When implementing tests designed as visual verification tests, apply `[Category("VisualVerification")]` to the test method.
- For test methods that test the `internal` visibility method, apply `[Category("Internal")]`.
- For test methods that depend on animation timing or other timing-sensitive conditions that may cause instability on slow CPUs, apply `[Category("IgnoreCI")]`.
- For test methods that specify the `GameViewResolution` attribute, apply `[Category("IgnoreCI")]`.

### Neutral Values

Arrange the input values the test design states — the parameters of a parameterized test and the input values in the Verification column — as given: the expected result depends on them.
Give every other value — the values the test's outcome does not depend on, e.g., an argument of the SUT, a field of an object passed to the SUT, the default of a creation-method parameter — a value that declares "this value does not matter here":

- Use a **neutral** value: `0`, `null`, `false`, empty string/collection.
  A domain-plausible value (e.g. `hp = 79`) reads as a deliberate Arrange choice, and no reader can tell it apart from a value the outcome depends on.
- If no neutral value works — `0`/`null` breaks the object graph or crashes something downstream — then nothing can mean "does not matter", so the test states the value it needs.
  Substituting a different "safe" value just hides the same problem behind a less obvious number.

A value no assertion can depend on (e.g. a display name used only for logging) genuinely does not matter, so a descriptive placeholder such as `"TestEnemy"` is fine in place of `null` — but default to neutral, and deviate only when you can state why the value is provably inert.

### Object Creation Pattern

Use a creation method for objects needed in tests:

```csharp
private SomeClass CreateSystemUnderTest() { ... }
```

Give a creation-method parameter a default so that tests state only the values their outcome depends on, and pick it per [Neutral Values](#neutral-values).
If no neutral value works, **give no default at all**: make the parameter required so every call site states its own value.

```csharp
// Do NOT do this — 79/80 reads as an intentional Arrange choice; 2 silently hides that 0 throws
private RunState CreateRunState(int hp = 79, int maxHp = 80) { ... }
private static Catalog CreateCatalog(int midCount = 2) { ... }

// Do this — neutral where a "does not matter" value exists; required where none does
private RunState CreateRunState(int hp = 0, int maxHp = 0) { ... }
private static Catalog CreateCatalog(int midCount) { ... }
```

### Multi-frame tests

When a game mechanic across frames (e.g., playing a card and waiting for its resolution), wait for the step to finish before asserting — not at a fixed frame count.

```csharp
await DragCard(Cards[1], Enemies[0]);
while (battleDirector.IsPlaying) // wait until the played action fully resolves
    await Awaitable.NextFrameAsync();
Assert.That(battleState.Enemies[0].Hp, Is.LessThan(hpBefore));
```

- To confirm step completion, use a production-side state machine or a "busy" signal (`IsPlaying`, coroutine flag, etc.).
  Do not use a fixed number of frames or `WaitForSeconds`.
- When UniTask is available, `UniTask.WaitUntil` and `UniTask.WaitUntilValueChanged` are alternatives to the `while` loop:
  ```csharp
  await UniTask.WaitUntil(() => isActive == false);
  await UniTask.WaitUntilValueChanged(this, x => x.isActive);
  ```
- When an operation triggers a deferred `Destroy` or UI rebuild, advance one extra `await Awaitable.NextFrameAsync()` before asserting on the new hierarchy.

### UI Tests

#### Layout assertion tests: verify UI layout with deterministic assertions

Implement a test case the test design gives as a layout assertion test — the element is within the screen, elements do not overlap, text does not overflow its container — with deterministic assertions, as designed.
Reasons:

- **Deterministic pass/fail**: boolean assertions run unattended in CI without a human reading screenshots.
- **Pins the specific bug**: an overlap assertion names the two elements; a screenshot cannot.

Choose the implementation means by what the condition is about:

- **Rect comparison** — `Is.WithinScreen` (within-screen bounds), `Is.WithinContainer(container)` (containment in a parent), `Is.Not.Overlapping` (overlap between elements)
- **Text overflow** — `Is.Not.TextOverflowing` (preferred/rendered size exceeds the rect, or characters are truncated)
- **Raycast reachability** — `GameObjectFinder` with `reachable: true` (optionally with a paginator) proves the element is on screen and not covered by another element; use it when the condition is "the user can actually reach this element"

Before asserting, settle layout with `Canvas.ForceUpdateCanvases()` then `await Awaitable.NextFrameAsync()` — the former rebuilds pending layout/graphic geometry (rect sizes, text metrics); the latter waits for a real render pass, which is what a raycast reachability check needs, since a newly activated/deactivated `Graphic`'s `CanvasRenderer.depth` stays unset until then and `GraphicRaycaster` silently skips any candidate whose `depth == -1` — `ForceUpdateCanvases()` alone does not assign it.

See `test-helper.md` → **Layout constraints** for the constraint API (`Is.WithinScreen` / `Is.WithinContainer` / `Is.Not.Overlapping` / `Is.Not.TextOverflowing`).

#### Use GameObjectFinder instead of GameObject.Find

When finding a GameObject that the user interacts with, always use `TestHelper.UI.GameObjectFinder` instead of `UnityEngine.GameObject.Find`, `Object.FindFirstObjectByType`, `Object.FindAnyObjectByType`, and `Object.FindObjectOfType`.
Reasons:

- **Timing safety**: polls until the object appears, so tests pass even when GameObjects are instantiated asynchronously or on the next frame
- **Reachability and interactability**: verifies the object is actually reachable by the user and (optionally) interactable — matching real user experience
- **Blocking check**: `reachable: true` (default) naturally catches elements hidden behind a modal or overlay — which is often the bug being caught
- **Actionable failures**: throws `TimeoutException` with a clear message; `GameObject.Find` silently returns `null` and causes a confusing `NullReferenceException` later

See: `test-helper-ui.md`.

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

See: `test-helper-ui.md`.

#### Verify modal/overlay blocking

A modal or overlay must block interaction with elements behind it.
Test from two angles:

- **Behavioural (preferred)**: attempt to reach a background element via `GameObjectFinder` with `reachable: true` (default) while the overlay is open — the finder throws `TimeoutException`, confirming blockage.
  Repeat with the overlay dismissed to confirm reachability restores.
- **Structural**: assert the backdrop intercepts raycasts: `Assert.That(background.GetComponent<Image>().raycastTarget, Is.True)` (or `canvasGroup.blocksRaycasts`).

When a decorative full-screen element should not block (e.g., a background image), annotate it with `NonBlockingAnnotation` so `GameObjectFinder` skips it.
See: `test-helper-ui.md`.

### Visual verification tests

When implementing a visual verification test (a test designed to verify on-screen rendering via screenshot and image analysis):

1. Take a screenshot using `[TakeScreenshot]` or `ScreenshotHelper.TakeScreenshotAsync()` (see `test-helper.md`).
2. Apply `[Description("After running this test, verify the screenshots from the following perspectives: <verification aspects>")]` to the test method.
   The verification aspects are taken directly from the **Image analysis by saved screenshot** column in the test case design.
3. Apply `[Category("VisualVerification")]` to the test method.
4. You can omit writing `Assert` statements.

When a designed visual verification test shares its test condition with a designed layout assertion test, you may implement both as a single test method: take the screenshot in the layout assertion test, apply steps 2–3 to it, and keep the layout assertions (step 4 does not apply).

## Resources

Read the appropriate resource file based on the situation:

- Before writing or modifying any test code file: Read `${CLAUDE_SKILL_DIR}/resources/unity-test-framework.md`
- Before writing or modifying any test code file: Read `${CLAUDE_SKILL_DIR}/resources/test-helper.md`
- Before writing or modifying UI tests with `TestHelper.UI` namespace API (e.g., `GameObjectFinder`, `Monkey`): Read `${CLAUDE_SKILL_DIR}/resources/test-helper-ui.md`
- Before writing or modifying tests that use test doubles (stub, spy, mock, fake, dummy): Read `${CLAUDE_SKILL_DIR}/resources/test-doubles.md`
- Before writing or modifying tests that verify statistical properties of samples (e.g., a drop rate, a damage distribution) with the `TestHelper.Statistics` namespace API: Read `${CLAUDE_SKILL_DIR}/resources/test-helper-statistics.md`
- Before writing or modifying performance tests (`com.unity.test-framework.performance`, `[Performance]`, `Measure.*`): Read `${CLAUDE_SKILL_DIR}/resources/unity-test-framework-performance.md`
