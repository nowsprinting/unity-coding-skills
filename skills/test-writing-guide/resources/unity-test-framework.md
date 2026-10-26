# Unity Test Framework Guidelines

Covers the conventions for writing tests with the Unity Test Framework.

Out of scope:

- Performance tests — see `unity-test-framework-performance.md`
- Test double patterns and dependency injection — see `test-doubles.md`

## Structure

- Tests targeting `Editor/` code, and tests validating assets → `Tests/Editor/` (Edit Mode tests)
- Validators → `Tests/Editor/`
- Tests targeting `Runtime/` code → `Tests/Runtime/` (Play Mode tests) — never Edit Mode tests: Edit Mode and Play Mode test runners cannot execute simultaneously, so splitting coverage for a single SUT between the two modes prevents running all tests at once, and only Play Mode tests can run on actual devices (player builds)
- Mirror the production code's directory structure within the test directory
- Test doubles (stub, spy, mock, fake, and dummy) → `Tests/Runtime/TestDoubles/` (also usable from Edit Mode tests)
- Test assistance utilities (creation method, custom assertion, etc.) → `Tests/Runtime/TestUtils/` (also usable from Edit Mode tests)
- Test scenes → `Tests/Scenes/`

### Creating a Test Assembly

When `Tests/Runtime/` or `Tests/Editor/` does not exist yet, run `scripts/create-test-asmdef.sh <ProductionAsmdefPath>` to generate `<ProductionAssembly>.Tests.asmdef`.

Examples:
- `${CLAUDE_SKILL_DIR}/scripts/create-test-asmdef.sh Assets/MyGame/Scripts/Runtime/MyGame.asmdef` → `Assets/MyGame/Tests/Runtime/MyGame.Tests.asmdef`
- `${CLAUDE_SKILL_DIR}/scripts/create-test-asmdef.sh Assets/MyGame/Scripts/Editor/MyGame.Editor.asmdef` → `Assets/MyGame/Tests/Editor/MyGame.Editor.Tests.asmdef`

## Naming

| Target               | Convention                                                                                                                     |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------|
| Test assembly        | `<ProductionAssembly>.Tests`                                                                                                   |
| Test namespace       | Same as the production class under test; `<RootNamespace>.Scenes` for a Scene file, `<RootNamespace>.Prefabs` for a Prefab     |
| Test class           | `<ClassName>Test` — e.g., `CharacterControllerTest`; `<ClassName>Validator` for a validator — e.g., `CardValidator`            |
| Test method          | `<MethodName>_<Condition>_<Expected>` — e.g., `TakeDamage_WhenHealthIsZero_ReturnsZero` or `TakeDamage_HPが0のとき_ゼロを返す` |
| System under test    | `sut`                                                                                                                          |
| Measured value       | `actual`                                                                                                                       |
| Expected value       | `expected`                                                                                                                     |
| Test double variable | Prefix with role: `stub`, `spy`, `mock`, `fake`, `dummy`                                                                       |

- `<RootNamespace>` is the `rootNamespace` of the assembly that defines the component classes used in the Scene or Prefab; the Scene or Prefab itself belongs to no assembly.
  When those classes span several assemblies (excluding Unity's and third-party ones), use the one that none of the others references.
  If a test class for the same Scene or Prefab already exists, add tests to it.
  If more than one assembly remains, pick the one whose `rootNamespace` existing Scene or Prefab tests already use; ask the user only when none do.
- A validator's namespace is the namespace of the `ScriptableObject` class it validates.
- Use the test method name the test design gives.
  When writing a test without a test design, load the `test-designing-guide` skill and follow its Test Case Naming.

## Modernize Test Code

Old Unity Test Framework patterns are common in training data.
The table below maps outdated patterns to their modern equivalents.
**Do not use the old forms.**

| Old (outdated)                          | Modern                                      |
|-----------------------------------------|---------------------------------------------|
| `[UnityTest] IEnumerator` for async     | `[Test] async Task`                         |
| `Assert.AreEqual(expected, actual)`     | `Assert.That(actual, Is.EqualTo(expected))` |
| `Assert.IsTrue(condition)`              | `Assert.That(condition, Is.True)`           |
| `Assert.IsNull(obj)`                    | `Assert.That(obj, Is.Null)`                 |

### Play Mode is determined by path, not by attributes

`[UnityTest]` is **not** Play Mode exclusive — it runs in both Edit Mode and Play Mode.
Mode is determined by the **test file's path**, not by test attributes:

- `Tests/Editor/` → **Edit Mode**
- `Tests/Runtime/` → **Play Mode**

`[Test]`, `[UnityTest]`, `[CreateScene]`, and `[LoadScene]` do **not** affect which mode the test runs in.

### Async tests: use `[Test]` + `async Task`

```csharp
// Do NOT write this
[UnityTest]
public IEnumerator MyTest()
{
    yield return null;
    Assert.AreEqual(42, sut.Value);
}

// Write this instead
[Test]
public async Task MyTest()
{
    await Awaitable.NextFrameAsync();
    Assert.That(sut.Value, Is.EqualTo(42));
}
```

`[TestCase]` and `[TestCaseSource]` work with `async Task`.

### Assertions: use the constraint model

```csharp
// Do NOT use the classic model
Assert.AreEqual(expected, actual);
Assert.IsTrue(condition);
Assert.IsNull(obj);

// Use the constraint model
Assert.That(actual, Is.EqualTo(expected));
Assert.That(condition, Is.True);
Assert.That(obj, Is.Null);
```

---

## Writing Tests

- `[TestFixture]` is required on every test class
- Separate Arrange / Act / Assert sections with blank lines; no AAA comments
- Prefer one `Assert.That` per test method.
  **Exception**: when the Verification column of the test case lists multiple properties (the multi-property exception in the test design, e.g., the state resulting from a transition), multiple `Assert.That` calls are permitted in a single test.
  In that case, pass a short `message` string as the third argument to **each** `Assert.That` to identify which property is being verified.
- Use the **constraint model only**: `Assert.That(actual, constraint)` — never use the classic model (`Assert.AreEqual`, etc.)
- Do NOT pass the `message` argument to `Assert.That` in single-assertion tests; the test name and constraint must be self-explanatory.
  When a test contains multiple `Assert.That` calls (see exception above), a `message` argument is **required** on every call.

```csharp
// Single assertion — no message needed
Assert.That(sut.IsActive, Is.True);

// Multiple assertions — verifying several properties of the state resulting from a transition
sut.SetDefeat();
await Awaitable.NextFrameAsync();
Assert.That(battleScene.DefeatScoreText.text, Is.EqualTo("0"), "score text");
Assert.That(battleScene.DefeatScoreText.alignment, Is.EqualTo(TextAnchor.MiddleCenter), "score alignment");
Assert.That(battleScene.DefeatScoreText.color, Is.EqualTo(Color.white), "score color");
```

### Constraint Tips

- For predicate assertions over a collection, prefer NUnit's strongly typed predicate constraint over LINQ:
  - Good: `Assert.That(items, Has.Some.Matches<Tool>(t => t.Name == "expected"))`
  - Avoid: `Assert.That(items.Any(t => t.Name == "expected"), Is.True)`
- Negation uses `Has.None.Matches<T>(...)`.

### Constraint Reference

**Numeric**

| Goal                          | Constraint                                            |
|-------------------------------|-------------------------------------------------------|
| Exact equality with tolerance | `Is.EqualTo(44.0f).Within(2)` or `.Within(5).Percent` |
| Greater than                  | `Is.GreaterThan(n)`                                   |
| Greater than or equal         | `Is.GreaterThanOrEqualTo(n)`                          |
| Less than                     | `Is.LessThan(n)`                                      |
| Less than or equal            | `Is.LessThanOrEqualTo(n)`                             |
| Within range                  | `Is.InRange(low, high)`                               |

`Within` also works on `DateTime`: `Is.EqualTo(expected).Within(2).Days`.

**String**

| Goal                           | Constraint                                    |
|--------------------------------|-----------------------------------------------|
| Starts with                    | `Does.StartWith("Se")`                        |
| Ends with                      | `Does.EndWith("!")`                           |
| Contains substring             | `Does.Contain("foo")`                         |
| Matches regex                  | `Does.Match(@"\d+")`                          |
| Case-insensitive               | Append `.IgnoreCase` to any string constraint |
| No clipping in failure message | Append `.NoClip` to `Is.EqualTo`              |

**Collection**

| Goal                           | Constraint                                                |
|--------------------------------|-----------------------------------------------------------|
| Contains element               | `Does.Contain(4)` / `Has.Member(4)`                       |
| Order-independent equality     | `Is.EquivalentTo(expected)`                               |
| Sorted                         | `Is.Ordered`                                              |
| Subset                         | `Is.SubsetOf(superset)`                                   |
| Superset                       | `Is.SupersetOf(subset)`                                   |
| All elements match predicate   | `Has.All.Matches<T>(t => ...)`                            |
| Some element matches predicate | `Has.Some.Matches<T>(t => ...)` (prefer over LINQ `.Any`) |
| No element matches predicate   | `Has.None.Matches<T>(t => ...)`                           |
| Dictionary key exists          | `Contains.Key("k")`                                       |
| Dictionary value exists        | `Contains.Value(42)`                                      |

**Type**

| Goal                                                           | Constraint                           |
|----------------------------------------------------------------|--------------------------------------|
| Is instance of T or subclass                                   | `Is.InstanceOf<T>()`                 |
| Is exactly T                                                   | `Is.TypeOf<T>()`                     |
| actual is T or a superclass of T (T can be assigned to actual) | `Is.AssignableFrom<T>()`             |
| Has attribute                                                  | `Has.Attribute<T>()`                 |
| Has property with value                                        | `Has.Property("Foo").EqualTo("Bar")` |

**File / Path**

| Goal                           | Constraint                        |
|--------------------------------|-----------------------------------|
| File or directory exists       | `Does.Exist`                      |
| File only (ignore directories) | `Does.Exist.IgnoreDirectories`    |
| Normalized path equality       | `Is.SamePath("/folder1/folder2")` |

**Operators**

```csharp
Assert.That(actual, Is.GreaterThan(40).Or.LessThan(30));
Assert.That(actual, Is.GreaterThan(0).And.LessThan(100));
Assert.That(actual, Is.Not.Null);
```

**Exceptions**

```csharp
Assert.That(() => Foo.Bar(-1), Throws.TypeOf<ArgumentException>());
Assert.That(() => Foo.Bar(-1), Throws.TypeOf<ArgumentException>()
    .And.Message.EqualTo("Expected message"));
```

For `async` methods, use the try-catch pattern — see [Async Tests](#async-tests).

## GC Allocation Constraint

Assert that no GC heap allocation occurs during a delegate:

```csharp
using Is = UnityEngine.TestTools.Constraints.Is;

Assert.That(() => sut.Foo(), Is.Not.AllocatingGCMemory());
```

- **Must alias `UnityEngine.TestTools.Constraints.Is`** — it conflicts with `NUnit.Framework.Is`, so add the `using` alias.
- No async alternative exists.
  Do not work around this by blocking on an async call inside the delegate (e.g., `.Wait()` / `.GetAwaiter().GetResult()`); measure allocations only in a synchronous path, or not at all.
- `Debug.Log` inside the delegate triggers a GC allocation and causes the assertion to fail.

## Comparers

Use `Is.EqualTo(...).Using(comparer)` for tolerance-based or custom equality:

```csharp
Assert.That(actual, Is.EqualTo(expected).Using(new FloatEqualityComparer(0.1f)));
```

Unity Test Framework built-in comparers (all use relative error):

| Type         | Comparer                     |
|--------------|------------------------------|
| `float`      | `FloatEqualityComparer`      |
| `Vector2`    | `Vector2EqualityComparer`    |
| `Vector3`    | `Vector3EqualityComparer`    |
| `Vector4`    | `Vector4EqualityComparer`    |
| `Quaternion` | `QuaternionEqualityComparer` |
| `Color`      | `ColorEqualityComparer`      |

For project-specific comparers (`FlipTexture2dEqualityComparer`, `XmlComparer`), see `test-helper.md`.

## No Control Flow in Tests

Never use `if`, `switch`, `for`, `foreach`, `while`, or the ternary operator in test code.
Tests must be straight-line single-pass code — control flow makes the expected result ambiguous and reduces trust in the test itself; a bug in a branch can hide behind a path that was never taken.

Exceptions:

- A `while` loop that waits for a state transition is allowed.
  Even then, prefer extracting the loop into an async helper method and waiting on it from the test method with `await` (or `yield return`).
- When the test design asks for a structural property that needs an algorithm to check, e.g., "the exit is reachable from the entrance" of a generated maze, write the solver (path-finding, etc.) as test code with the control flow it needs.
  Put it in a helper method so that the test method itself stays straight-line.

## Parameterized Tests

Use `[TestCase]`, `[TestCaseSource]`, `[Values]`, `[ValueSource]` when Arrange differs but Act and Assert are the same.

Choose the attributes by where the test cases come from:

- Rules derived by equivalence partitioning or a decision table → `[TestCase]` / `[TestCaseSource]`: each rule is one explicit case.
- Data derived by combinatorial testing → `[Values]` / `[ValueSource]`: NUnit generates the combinations from the values of each parameter.

### TestCase / TestCaseSource

Use `[TestCase]` when the design specifies `({defence: Fire, attack: Water}, {defence: Water, attack: Wood})` — limited to specific combinations.
Each tuple becomes one `[TestCase]` attribute:

```csharp
[TestCase(Element.Fire, Element.Water)]
[TestCase(Element.Water, Element.Wood)]
public void GetDamageFactor_WeaknessAttribute_Returns2x(Element defence, Element attack) { ... }
```

Use `TestCaseData` with `.SetName(...)` to give test cases readable names when using `[TestCaseSource]`.
Start the name with `{m}`, the placeholder for the method name: a name set with `SetName` replaces the method name in the test's full name, so test methods sharing a source would otherwise report the same full name for a case.

```csharp
private static TestCaseData[] s_cases =
{
    new TestCaseData(Element.Fire, Element.Water).SetName("{m}(water to fire)"),
    new TestCaseData(Element.Water, Element.Wood).SetName("{m}(wood to water)"),
};

[TestCaseSource(nameof(s_cases))]
public void Damage_WeaknessAttribute_Returns2x(Element defence, Element attack) { ... }
```

### Values / ValueSource

The following maps the test-designing-guide notation to NUnit attributes:

| Design notation                                                       | NUnit                                                      |
|-----------------------------------------------------------------------|------------------------------------------------------------|
| `(flag: (bool))` — bool param, all values                             | `[Values] bool flag`                                       |
| `(direction: (Direction))` — enum param, all values                   | `[Values] Direction direction`                             |
| `(n: {3, 6, 9})` — explicit values, single param                      | `[Values(3, 6, 9)] int n`                                  |
| `(flag: (bool), count: {0, 1, 5})` — mixed                            | `[Values] bool flag, [Values(0, 1, 5)] int count`          |
| `(a: {0, 1, -1}, b: {0, 1})` — multiple params, exhaustive            | `[Values(0, 1, -1)] int a, [Values(0, 1)] int b`           |
| `(a: {0, 1, -1}, b: {0, 1}, by pairwise)` — multiple params, pairwise | `[Pairwise]` on the method + `[Values(...)]` on each param |

- `[Values]` with no argument on a `bool` parameter generates `true` and `false`; on an enum parameter, it generates all defined values
- Multiple `[Values]` parameters produce the **full Cartesian product** by default
- `[ParametrizedIgnore]` on the method → exclude specific combinations
- `[Pairwise]` on the method → pairwise coverage instead of full Cartesian; use when the test cases specify `by pairwise`
- `[Sequential]` on the method → match parameters by index (not combinatorial); do NOT use in principle — use `[TestCase]` / `[TestCaseSource]` instead to make each combination explicit

### Validators

A `### <ClassName>Validator` section in the test design runs each test method on the project's assets of that `ScriptableObject` class.
Implement validators as Edit Mode tests under `Tests/Editor/`: `AssetDatabase`, which finds and loads the assets, is Editor-only.
The test design gives no parameter notation: read the assets to select from the method name's `<Condition>` segment — e.g., `AttackCard_AttackIsGreaterThanZero` selects the attack cards, i.e., the `Card` assets whose `Type` is `Attack` — and a method name without `<Condition>` covers every asset of the class.
Supply the assets with `[TestCaseSource]`, naming each `TestCaseData` after its asset file, and load each asset in the test:

```csharp
private static IEnumerable<TestCaseData> AttackCards => AssetDatabase
    .FindAssets("t:Card", new[] { "Assets/MyGame/Data" })
    .Select(AssetDatabase.GUIDToAssetPath)
    .Where(path => AssetDatabase.LoadAssetAtPath<Card>(path).Type == CardType.Attack)
    .Select(path => new TestCaseData(path).SetName($"{{m}}({Path.GetFileName(path)})"));

[TestCaseSource(nameof(AttackCards))]
public void AttackCard_AttackIsGreaterThanZero(string path)
{
    var sut = AssetDatabase.LoadAssetAtPath<Card>(path);
    Assert.That(sut.Attack, Is.GreaterThan(0));
}
```

- Prefer `[TestCaseSource]` with `SetName` over `[ValueSource]`: a `[ValueSource]` case is named after the whole path argument, which buries the asset name in the test results.
- In an interpolated string, escape the `{m}` placeholder as `{{m}}` (see [TestCase / TestCaseSource](#testcase--testcasesource)).
- Select the assets in the source (`.Where(...)`), not with `if` in the test (see [No Control Flow in Tests](#no-control-flow-in-tests)).
- Limit `FindAssets` to the selection scope the test design names, so test assets under `Tests/` are not validated.

## Setup test fixture

When multiple test methods in a class share the same scene setup, create a test scene file and load it with `[LoadScene]` instead of repeating the setup in each test.
Scene files are typically 1:1 with the test class, so name the file after the test class (e.g., `CharacterControllerTest.unity`).
Place it under `Tests/Scenes/`.
Use the `edit-scene` skill to create the scene file.

## Lifecycle Hooks

| Attribute                                        | Timing                               | Notes                                                   |
|--------------------------------------------------|--------------------------------------|---------------------------------------------------------|
| `[SetUp]` / `[TearDown]`                         | Before / after each test method      | `async Task` supported (UTF v1.3+)                      |
| `[UnitySetUp]` / `[UnityTearDown]`               | Before / after each test (coroutine) | Runs before `[SetUp]` / after `[TearDown]` respectively |
| `[OneTimeSetUp]` / `[OneTimeTearDown]`           | Once per class                       |                                                         |
| `[UnityOneTimeSetUp]` / `[UnityOneTimeTearDown]` | Once per class (coroutine)           | UTF v1.5+                                               |

Guidelines:
- `[SetUp]` owns initialization; cleanup of leftover state belongs in `[SetUp]`, not `[TearDown]`.
- `[TearDown]` owns resource release (e.g., `Object.DontDestroyOnLoad` objects that can't be cleaned by scene reload).
- In nested classes, only the `[SetUp]` / `[TearDown]` defined in the **same class** as the test method runs — the outer class's hooks do not run.
- Avoid over-centralizing setup; values that affect assertion validity should stay visible inside the test method itself — a reader must understand the test without scrolling to `[SetUp]`; burying assertion-relevant values there makes correctness harder to judge.
- `[SetUp]` and `[TearDown]` also work with `async Task`; `[OneTimeSetUp]` and `[OneTimeTearDown]` do not, so use `[UnityOneTimeSetUp]` and `[UnityOneTimeTearDown]` instead
- `[LoadScene]` and `[CreateScene]` (Test Helper) run after `[OneTimeSetUp]` and before `[SetUp]`.

## Test Selection Attributes

| Attribute                                                          | Purpose                                                                       |
|--------------------------------------------------------------------|-------------------------------------------------------------------------------|
| `[Category("IgnoreCI")]`                                           | Tag for filtering at run time; CI uses `-testCategory "!IgnoreCI"` to exclude |
| `[UnityPlatform(RuntimePlatform.WindowsPlayer)]`                   | Run only on specified platforms                                               |
| `[UnityPlatform(exclude = new[] { RuntimePlatform.WebGLPlayer })]` | Exclude specific platforms                                                    |
| `[Ignore("reason")]`                                               | Temporarily skip; reason shown in runner UI                                   |
| `[Explicit("reason")]`                                             | Run only when explicitly selected in the runner                               |

Attributes can be applied to assembly (`[assembly: Category("...")]`), class, or method.

Assembly-level attributes go in an `AssemblyInfo.cs` file placed at the root directory of the assembly (the same directory as the `.asmdef` file):

```csharp
using NUnit.Framework;

[assembly: UnityPlatform(exclude = new[] { RuntimePlatform.WebGLPlayer })]
```

## Timing, Repeat, Retry

| Attribute       | Purpose                               | Notes                                                                                     |
|-----------------|---------------------------------------|-------------------------------------------------------------------------------------------|
| `[Timeout(ms)]` | Override default 3-minute timeout     | Covers **total** time including repeats / retries                                         |
| `[MaxTime(ms)]` | Fail if execution exceeded the limit  | Does not interrupt mid-test                                                               |
| `[Repeat(n)]`   | Run n times; stop on first failure    | `[SetUp]`/`[TearDown]` run each iteration; `[UnitySetUp]`/`[UnityTearDown]` run only once |
| `[Retry(n)]`    | Re-run on failure up to n times total | Exception-caused failures are **not** retried; overuse is an anti-pattern                 |

## Async Tests

- Use `[Test]` attribute with `async` keyword instead of `[UnityTest]` attribute
- `[TestCase]` and `[TestCaseSource]` work with async test methods
- Do not use `Task.Delay` or arbitrary wait; use `await Awaitable.NextFrameAsync()` when only one frame is needed
- To assert that an async method throws, use try-catch.
  Blocking on the `Task` (`.Wait()` / `.GetAwaiter().GetResult()`) is not a substitute:

```csharp
try
{
    await Foo.Bar(-1);
    Assert.Fail("Expected exception was not thrown");
}
catch (ArgumentException expectedException)
{
    Assert.That(expectedException.Message, Is.EqualTo("Expected message"));
}
```

`try`/`catch` is the one sanctioned exception to [No Control Flow in Tests](#no-control-flow-in-tests) — it is not in that section's prohibited list, and this is the only place this guide requires it.

### Anti-pattern: Fixed-time Waits

Async tests often need to wait a little — e.g., after `SceneManager.LoadScene` to let `Start` / `Update` run, or one frame after placing a `GameObject` before using a `Raycaster`.

`Task.Delay` (or any other fixed-duration sleep) is the wrong tool.
No fixed duration is "just right" — too short produces flaky tests, too long inflates total test run time, and OS timer resolution makes precise tuning impossible regardless.

Pick the wait that matches the situation:

- **Known frame count** — `await Awaitable.NextFrameAsync()` on Unity 2023+.
  On older Unity, use `UniTask.NextFrame` / `UniTask.DelayFrame`, or write the test with `[UnityTest]` and `yield return null`.
- **Waiting for a state transition** (e.g., "next turn") — Drive the wait off the game's state machine with `UniTask.WaitUntil` or `UnityEngine.WaitUntil` instead of guessing a duration.
  Extract the wait into a named helper method (e.g., `async Awaitable WaitForPlayerTurn()`) to make intent clear and allow reuse across tests.
- **Unknown duration** (UI interactions, asset loads, backend calls) — Poll state at a short interval through a helper.
  The UI Test Helper package (`test-helper.ui`) ships `GameObjectFinder`, which already does this.

## Preconditions: Assume

When a test depends on external state (scene hierarchy, assets), use `Assume.That(...)` to verify preconditions instead of `Assert.That(...)`:

```csharp
var cube = GameObject.Find("Cube");
Assume.That(cube, Is.Not.Null);     // inconclusive (orange) if missing, not failed (red)
sut.AttackTo(cube);
Assert.That((bool)cube, Is.False);
```

A failed `Assume` marks the test **inconclusive** in the runner, making it easy to distinguish environment problems from real failures.

## Destroyed GameObject

In the editor, `Destroy()` does not immediately null the reference.
`UnityEngine.Object` overrides `==` and `bool` cast to expose destroyed state:

```csharp
Assert.That((bool)cube, Is.False);   // passes when destroyed
```

**Prefer `Is.Destroyed` from Test Helper** — it expresses intent more clearly.
See `test-helper.md`.

## Log Handling

By default, `Debug.LogError`, `LogException`, and `LogAssertion` cause a test failure.
When production code is expected to emit these, use the following APIs to prevent unintended test failures:

```csharp
// Allow specific log output (string or Regex)
LogAssert.Expect(LogType.Error, "error message");
LogAssert.Expect(LogType.Error, new Regex(@"Se.+? Paratus"));

// Assert no unexpected logs occurred — place at the very end of the test
LogAssert.NoUnexpectedReceived();

// Suppress all failing logs for a single test (resets automatically per test, cannot be set in [SetUp])
LogAssert.ignoreFailingMessages = true;
```

`[TestMustExpectAllLogs]` on a class or method is equivalent to calling `LogAssert.NoUnexpectedReceived()` at the end of each test.

**Async caveat**: in async tests, log failure is evaluated at each `yield` point — call `LogAssert.Expect` before yielding.

- Do NOT use `LogAssert` to verify log messages emitted by the production code under test; create a Spy logger that the production code writes through.
  This keeps tests independent of Unity's global log handler.
- `LogAssert` is acceptable only when a Spy cannot be injected — i.e., the log is emitted by `UnityEngine` itself or a third-party library outside our control.
  Typical uses: asserting an expected `Debug.LogError` / `LogException` from such a source, or `LogAssert.NoUnexpectedReceived()` to ensure no unexpected engine/library errors during a test.

## Spy MonoBehaviour Conventions

When creating a Spy `MonoBehaviour` (placed under `Tests/Runtime/TestDoubles/`) to capture events such as `IPointerClickHandler.OnPointerClick`:

- Apply `[AddComponentMenu("/")]` (Unity 2021+) or `[AddComponentMenu("")]` (older Unity) so it does not appear in the editor's **Add Component** picker.
- Record invocations into public properties (call count, last arguments, etc.) and let the test read them directly.
  Do NOT log to `Debug.Log` and assert with `LogAssert` — that couples the test to Unity's global log handler and is harder to inspect than typed state.

```csharp
[AddComponentMenu("/")]
public class SpyOnPointerClickHandler : MonoBehaviour, IPointerClickHandler
{
    public int ClickCount { get; private set; }
    public PointerEventData LastEventData { get; private set; }

    public void OnPointerClick(PointerEventData eventData)
    {
        ClickCount++;
        LastEventData = eventData;
    }
}
```

- Assert against the public properties in the test:

```csharp
Assert.That(spy.ClickCount, Is.EqualTo(1));
Assert.That(spy.LastEventData.button, Is.EqualTo(PointerEventData.InputButton.Left));
```

## MonoBehaviour Lifecycle Testing

**Avoid this pattern whenever possible.**
First try to extract testable logic out of the `MonoBehaviour` using the Humble Object pattern and test it directly.
Only use `MonoBehaviourTest<T>` when the lifecycle progression itself (`Awake` → `Start` → `Update`) must be observed from inside.

When necessary, create a Spy subclass implementing `IMonoBehaviourTest` and yield from a `[UnityTest]`:

```csharp
private class SpyMyMonoBehaviour : MyMonoBehaviour, IMonoBehaviourTest
{
    public bool WasStart => base._wasStart;
    public bool IsTestFinished => WasStart;   // runner polls this until true
}

[UnityTest]
public IEnumerator Start_SomeCondition_SetsWasStart()
{
    yield return new MonoBehaviourTest<SpyMyMonoBehaviour>();
    var spy = GameObject.FindObjectOfType<SpyMyMonoBehaviour>();
    Assert.That(spy.WasStart, Is.True);
    GameObject.DestroyImmediate(spy.gameObject);
}
```

Follow the Spy naming convention from [Spy MonoBehaviour Conventions](#spy-monobehaviour-conventions).

## Testing Non-Public Members

- **Do not test `private` members** — doing so tests implementation, not specification.
  Private members have no guaranteed contract and tests break on valid refactors.
- To test `internal` members, add to the production assembly side:

```csharp
[assembly: InternalsVisibleTo("MyAssembly.Tests")]
```

- Do not use reflection to access `private` members — reflection-based access tests implementation structure, not observable behaviour; any internal rename or refactor breaks the test without changing the contract (fragile test).

## Comments

Do NOT write XML documentation comments in test code.

## Troubleshooting

### `[Test]` on an `async` method fails to compile or run

If a test written as `[Test]` + `async` method (per the Async Tests section above) errors out — compile error, `async void` rejection, or the runner refusing to execute the test — the `com.unity.test-framework` package is too old.
Upgrade to **v1.4.6** in `Packages/manifest.json`.

### `[ParametrizedIgnore]` is not recognized

If `[ParametrizedIgnore]` on a parameterized test errors as an unknown attribute, the `com.unity.test-framework` package is too old.
Upgrade to **v1.4.6** in `Packages/manifest.json`.

### `[Repeat]` or `[Retry]` test times out unexpectedly

`[Timeout(ms)]` covers the **total** execution time across all iterations, not per iteration.
When using `[Repeat(n)]`, set `[Timeout]` to at least `n × per-iteration-budget`.

### `LogAssert.ignoreFailingMessages` set in `[SetUp]` has no effect

`LogAssert.ignoreFailingMessages` resets to `false` before each test.
Set it explicitly inside the test method where it is needed — it cannot be applied globally via `[SetUp]`.
