# Test Helper — Quick Reference

Package: `com.nowsprinting.test-helper`

Add `TestHelper` to Assembly Definition References to use attributes and constraints.  
Add `TestHelper.RuntimeInternals` to also use `SceneManagerHelper`, `ScreenshotHelper`, and `PathHelper`.

---

## Attributes

### Scene setup

| Goal                                                    | Solution                                                        |
|---------------------------------------------------------|-----------------------------------------------------------------|
| Load an existing scene before the test                  | `[LoadScene("Assets/path/to/Scene.unity")]` on the test method  |
| Create a new empty scene before the test                | `[CreateScene]` on the test method                              |
| Include a scene not in Build Settings for player builds | `[BuildScene("Assets/path/to/Scene.unity")]` on the test method |

- Paths can be relative to the test class file: `"../../Scenes/MyScene.unity"`
- `[LoadScene]` and `[CreateScene]` run after `OneTimeSetUp` and before `SetUp`
- If you need to load a scene programmatically during the test, use `SceneManagerHelper.LoadSceneAsync(path)` combined with `[BuildScene]`
- Any test that creates a `GameObject` or instantiates a prefab (`new GameObject()`, `Object.Instantiate`) needs `[CreateScene]` or `[LoadScene]` — without one, the objects are created in whatever scene the editor currently has open and leak across tests. This is not specific to visual verification tests.

### Asset loading

| Goal                                       | Solution                                 |
|--------------------------------------------|------------------------------------------|
| Load an asset into a field before the test | `[LoadAsset("path")]` on a private field |

Must call `LoadAssetAttribute.LoadAssets(this)` from `[OneTimeSetUp]`.

```csharp
[LoadAsset("Assets/Tests/Prefabs/Cube.prefab")]
private GameObject _prefab;

[OneTimeSetUp]
public void OneTimeSetUp() => LoadAssetAttribute.LoadAssets(this);
```

### Game View

| Goal                                | Solution                                                                                                       |
|-------------------------------------|----------------------------------------------------------------------------------------------------------------|
| Focus the Game View before the test | `[FocusGameView]`                                                                                              |
| Set a custom resolution             | `[GameViewResolution(400, 200, "WQVGA")]` — wait one frame to apply if not using `[CreateScene]`/`[LoadScene]` |
| Show or hide Gizmos                 | `[GizmosShowOnGameView(true)]` on the test method only                                                         |

**When to add `[FocusGameView]`**: Add it at method scope on any test that includes UI-operation tests (using `GameObjectFinder`, click/drag operators, etc.). This avoids unintended GameView focus loss. Do not add it assembly-wide or on classes that test pure logic without UI interaction.

```csharp
[TestFixture]
[FocusGameView]
public class MySceneTest { ... }
```

**CI resolution**: To fix the GameView resolution in CI, pass test-helper CLI arguments in Unity's startup parameters rather than hardcoding it in test code:

```
-testHelperGameViewResolution "WQVGA"                       # matched against the resolution's display name (case-insensitive), not the enum identifier — e.g. FullHD needs "Full HD", FourK_UHD needs "4K UHD"
-testHelperGameViewWidth 400 -testHelperGameViewHeight 200  # or explicit pixels
```

### Skip conditions

| Goal                          | Solution                                   |
|-------------------------------|--------------------------------------------|
| Skip in `-batchmode`          | `[IgnoreBatchMode("reason")]`              |
| Skip in Editor window mode    | `[IgnoreWindowMode("reason")]`             |
| Skip for older Unity versions | `[UnityVersion(newerThanOrEqual: "2022")]` |
| Skip for newer Unity versions | `[UnityVersion(olderThan: "2019.4.0f1")]`  |

### Timing

| Goal                                    | Solution                                    |
|-----------------------------------------|---------------------------------------------|
| Change `Time.timeScale` during the test | `[TimeScale(2.0f)]` on the test method only |

### Screenshots and video (Play Mode only — do NOT use in Edit Mode)

| Goal                                              | Solution                                          |
|---------------------------------------------------|---------------------------------------------------|
| Take a screenshot after the test completes        | `[TakeScreenshot]` on the test method             |
| Take a screenshot at a specific point in the test | `await ScreenshotHelper.TakeScreenshotAsync()`    |
| Record video while the test runs                  | `[RecordVideo]` (requires Instant Replay package) |

- `[TakeScreenshot]` works with sync `[Test]`, async `[Test]`, and `[UnityTest]` — no need to make the method async just to use it.
- Saved to `<Application.persistentDataPath>/TestHelper/Screenshots/<TestName>.png` by default. The absolute path is recorded in the NUnit test result as the `Screenshot` property — read it from there instead of composing the path by hand (the file name is sanitized, and gets a `_1`, `_2` … suffix when one test saves several).

> [!WARNING]\
> When combining `[TakeScreenshot]` with `[CreateScene]`:
>
> - Declare `[TakeScreenshot]` **above** `[CreateScene]`. Both implement `IOuterUnityTestAction`, and NUnit runs `AfterTest` in source declaration order — `[CreateScene]`'s `AfterTest` unloads the scene it created, so a `[TakeScreenshot]` declared below it captures an already-unloaded scene. (`[LoadScene]` does not unload in `AfterTest`, so order doesn't matter there.)
> - Pass `[CreateScene(camera: true)]`. The default `camera: false` leaves no camera to clear the GameView, and a Screen Space Overlay `Canvas` doesn't clear the background itself, so the previous test's rendered frame stays visible in the new screenshot.

```csharp
[Test]
[TakeScreenshot]              // before [CreateScene] — its AfterTest unloads the scene
[CreateScene(camera: true)]   // camera clears the GameView; without it the previous test's frame remains
public async Task MyScene_SomeState_Screenshot() { ... }
```

> [!WARNING]\
> `[TakeScreenshot]` captures **after `TearDown` has run**, not at the end of the test method body. If `TearDown` destroys GameObjects or unloads the scene, the screenshot will be empty — call `await ScreenshotHelper.TakeScreenshotAsync()` inside the test method instead.

> [!IMPORTANT]\
> When the resolution itself is part of the test condition (e.g., verifying element positions at a specific viewport size), apply `[GameViewResolution]` on the test method. CI runs at a constrained screen resolution and a standalone Player cannot change its resolution at run time, so a resolution-pinned test should also carry `[Category("IgnoreCI")]` and `[UnityPlatform]` restricted to the desktop editors (see `unity-test-framework.md`):

```csharp
[Test]
[LoadScene(ScenePath)]
[GameViewResolution(400, 200, "WQVGA")]
[Category("IgnoreCI")]
[UnityPlatform(RuntimePlatform.OSXEditor, RuntimePlatform.WindowsEditor, RuntimePlatform.LinuxEditor)]
public async Task MyScene_SomeLayout_At400x200_Screenshot() { ... }
```

> [!NOTE]\
> Do not override the resolution or the output directory — let the test run at whatever the environment provides, and read the actual path back from the `Screenshot` property (see `run-tests` skill → Visual Verification).

---

## Constraints

Add `using Is = TestHelper.Constraints.Is;` to use these alongside NUnit's `Is`.

| Goal                                        | Constraint                              |
|---------------------------------------------|-----------------------------------------|
| Assert a `UnityEngine.Object` was destroyed | `Assert.That(actual, Is.Destroyed)`     |
| Assert it was NOT destroyed                 | `Assert.That(actual, Is.Not.Destroyed)` |

### Layout constraints

Requires test-helper **v1.6.1 or later**. These implement the recipes referenced by `test-writing-guide` → **Layout assertion tests**.

| Goal                                                  | Constraint                                        |
|-------------------------------------------------------|---------------------------------------------------|
| A dialog/popup/root panel is within the screen bounds | `Assert.That(rootPanel, Is.WithinScreen)`         |
| An element is fully within its parent container       | `Assert.That(element, Is.FullyWithin(container))` |
| No pair in a collection overlaps                      | `Assert.That(elements, Is.Not.Overlapping)`       |
| Text does not overflow its own `RectTransform`        | `Assert.That(element, Is.Not.TextOverflowing)`    |

`Overlapping` and `TextOverflowing` match when the defect is present, so the form you actually write is the negated one (`Is.Not.Overlapping`, `Is.Not.TextOverflowing`) — don't write `Is.Overlapping` meaning "no overlap".

`WithinScreen` targets a screen's top-level, dynamically-positioned container (dialog, popup, context menu) — the one actually at risk of clipping past the screen edge. Elements nested inside it are checked against their **parent container** with `FullyWithin`, not against the screen again — see `test-designing-guide` → Integration test perspectives → UI layout.

**Modifiers**

| Modifier                            | Applies to         | Effect                                                                                                                                                        |
|-------------------------------------|--------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.Within(px)`                       | all four           | Tolerance in pixels, default `0.5f`, negative values clamp to 0                                                                                               |
| `.Horizontally()` / `.Vertically()` | `FullyWithin` only | Narrow the check to one axis; calling both is equivalent to neither (both axes checked)                                                                       |
| `.Ignoring(group)`                  | `Overlapping` only | Exclude pairs where both members belong to `group`; a member is still checked against elements outside the group; call repeatedly to register multiple groups |

```csharp
Assert.That(card, Is.FullyWithin(viewport).Horizontally().Within(2f));
Assert.That(cards, Is.Not.Overlapping.Ignoring(ignoredGroup).Within(2f));
Assert.That(flavorText, Is.Not.TextOverflowing.Within(1f));
```

**Accepted `actual` types**: `RectTransform`, `GameObject`, or `Component` (resolved via its `GameObject`). A value that can't be resolved throws `ArgumentNullException`/`ArgumentException` rather than reporting a non-match — otherwise a negated constraint (`Is.Not.WithinScreen`) would vacuously pass on `null`.

**Usage notes**

- `Is.Not.Overlapping` takes a **collection**; a single `RectTransform`/`GameObject`/`Component`, or a collection with fewer than 2 elements, throws `ArgumentException`. Pass even a two-element comparison as an array: `new[] { a, b }`.
- `Is.TextOverflowing` only looks at a `Text`/`TMP_Text` on the resolved `RectTransform`'s **own** `GameObject` — passing a parent throws `ArgumentException`. When applying it over a collection, filter down to elements that actually carry a text component first.
- `Is.All.<constraint>` applies a constraint to every item of a collection, e.g. `Is.All.WithinScreen`.
- Call `Canvas.ForceUpdateCanvases()` before `Is.Not.TextOverflowing` — without it, the assertion fails with "has not been laid out; call `Canvas.ForceUpdateCanvases()` before asserting". (The general layout-settling rule — `Canvas.ForceUpdateCanvases()` then `await Awaitable.NextFrameAsync()` — is already covered in `test-writing-guide` → Layout assertion tests; this note only calls out `TextOverflowing`'s specific failure mode.)

**What these constraints do NOT see**: they compare axis-aligned bounding boxes of the four world corners only — `RectMask2D` clipping, `Canvas.enabled`, `CanvasGroup.alpha`, and `activeInHierarchy` are ignored (geometry only). A rotated element is over-approximated by its AABB. All three Canvas render modes (Overlay / Camera / World Space) are supported.

To verify an element is not clipped by a `RectMask2D`, pass the mask's `RectTransform` as the `FullyWithin` container, guarded by `Assume.That` — the constraint itself doesn't know whether masking is even in effect, so a passing `FullyWithin` on an unmasked container proves nothing about clipping:

```csharp
Assume.That(containerGo.GetComponent<RectMask2D>(), Is.Not.Null); // Without RectMask2D, a failing FullyWithin does not mean clipping — elements outside the bounds are still rendered
Assert.That(image, Is.FullyWithin(containerRectTransform));
```

---

## Comparers

| Goal                                                                                       | Comparer                                                       |
|--------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| Compare two `Texture2D` perceptually using FLIP                                            | `new FlipTexture2dEqualityComparer(meanErrorTolerance: 0.01f)` |
| Compare two strings as equivalent XML (order-insensitive, ignores comments and whitespace) | `new XmlComparer()`                                            |

```csharp
Assert.That(actual, Is.EqualTo(expected).Using(new XmlComparer()));
```

`FlipTexture2dEqualityComparer` requires the `FlipBinding.CSharp` NuGet package and `ENABLE_FLIP_BINDING` scripting symbol.

---

## Runtime Utilities

### SceneManagerHelper

Load a scene by path (supports relative paths, works in Edit Mode, Play Mode, and on Player):

```csharp
await SceneManagerHelper.LoadSceneAsync("../../Scenes/SampleScene.unity");
```

Use with `[BuildScene]` if the scene is not in Build Settings.

### PathHelper

Create a unique temporary file path named after the running test:

```csharp
var path = PathHelper.CreateTemporaryFilePath(extension: "txt");
// → {Application.temporaryCachePath}/MyTestMethod.txt
```

Pass `namespaceToDirectory: true` to include namespace and class name in the path.
