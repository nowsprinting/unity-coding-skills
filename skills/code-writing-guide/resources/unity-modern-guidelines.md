# Unity Modern Guidelines

## How to Use This Guidelines

Based on the detected Unity version, apply all features up to that version when writing Unity C# code.

**When writing Unity code**, use ALL features from this document up to the target version:
- Prefer modern Unity APIs over deprecated or legacy alternatives
- Never use features from newer Unity versions than the target
- Never use outdated patterns when a modern alternative is available

## Detected Unity Version

Project Unity version:
!`grep "m_EditorVersion:" ProjectSettings/ProjectVersion.txt 2>/dev/null | sed 's/m_EditorVersion: //' | grep . || echo unknown`

**If version detected (not "unknown"):**
- Say: "This project is using Unity X.Y, so I'll use modern Unity APIs and C# features up to this version."
- Do NOT list features, do NOT ask for confirmation

**If version is "unknown":**
- Say: "Could not detect Unity version in this repository"
- Use AskUserQuestion: "Which Unity version should I target?" with common version options

## Features by Unity Version

### Unity 2020.2+

**C# 8.0:**
- Switch expressions: `state switch { State.Active => true, _ => false }` instead of switch statements
    ```csharp
    // Instead of:
    string Describe(State state)
    {
        switch (state)
        {
            case State.Active: return "Active";
            case State.Dead:   return "Dead";
            default:           return "Unknown";
        }
    }
  
    // Use:
    string Describe(State state) => state switch
    {
        State.Active => "Active",
        State.Dead   => "Dead",
        _            => "Unknown",
    };
    ```
- Property patterns: `obj is Enemy { IsDead: true }` instead of casting and field checks
- Tuple patterns: `(a, b) switch { (0, 0) => "origin", _ => "other" }`
- Nullable reference types (to catch null dereferences at compile time): Add `-nullable:enable` to the csc.rsp file located directly under the `Assets/` or in the same directory as the assembly definition file.

**Unity APIs:**
- Add `[NonReorderable]` to serialized `List<T>` or array fields when Inspector reordering should be disabled
- Use `ProfilerRecorder` to sample performance counters (draw calls, SetPass) from runtime code

### Unity 2021.1+

**Object Pooling:**
- Use `ObjectPool<T>`, `ListPool<T>`, `HashSetPool<T>`, `DictionaryPool<TKey, TValue>` from `UnityEngine.Pool` instead of custom pool implementations
    ```csharp
    // Instead of:
    private readonly Queue<Bullet> _pool = new();
    private Bullet Get()            => _pool.Count > 0 ? _pool.Dequeue() : Instantiate(_prefab);
    private void   Return(Bullet b) => _pool.Enqueue(b);
    
    // Use:
    private readonly ObjectPool<Bullet> _pool = new(
        createFunc:      () => Instantiate(_prefab),
        actionOnGet:     b  => b.gameObject.SetActive(true),
        actionOnRelease: b  => b.gameObject.SetActive(false)
    );
    ```

### Unity 2021.2+

**.NET Standard 2.1:**
- Use `Span<T>` for zero-allocation temporary buffers instead of `new T[]`
- Use index-from-end `array[^1]` instead of `array[array.Length - 1]`
    ```csharp
    // Instead of:
    var last  = items[items.Length - 1];
    // Use:
    var last  = items[^1];
    ```
- Use range slices `array[1..4]` instead of `Array.Copy` or LINQ `Skip`/`Take`
    ```csharp
    // Instead of:
    var slice = items.Skip(1).Take(3).ToArray();
    // Use:
    var slice = items[1..4];
    ```

**C# 9.0:**
- Target-typed `new()`: `List<Enemy> enemies = new();` instead of `new List<Enemy>()`
- `init`-only setters for read-only-after-construction properties
- Record types for immutable value objects

**Unity APIs:**
- UI Toolkit (`UnityEngine.UIElements`) is now available for runtime UI — whether to adopt it depends on the project's UI system choice; follow the existing convention if the project already uses uGUI

### Unity 2022.3+

**Object Find APIs:**
- `UnityEngine.Object.FindObjectOfType`, `Object.FindObjectOfType<T>`, `Object.FindObjectsOfType`, `Object.FindObjectsOfType<T>`, `Object.FindObjectsOfTypeAll`, `Object.FindObjectsOfTypeIncludingAssets`, `Object.FindSceneObjectsOfType` are obsolete
- Use `Object.FindObjectsByType` / `Object.FindObjectsByType<T>` instead of `FindObjectsOfType`
- Use `Object.FindAnyObjectByType` / `Object.FindAnyObjectByType<T>` when a single matching instance is needed (faster than `FindFirst`; unlike `FindFirst`, not deprecated in 6000.4+)
- `Object.FindFirstObjectByType` / `Object.FindFirstObjectByType<T>` is available but deprecated in Unity 6000.4+ — prefer `FindAnyObjectByType` (see **Object Find APIs** under Unity 6000.4+)
- For code under `Packages/` whose minimum supported version is below 2022.3, guard with `UNITY_2022_3_OR_NEWER`
    ```csharp
    #if UNITY_2022_3_OR_NEWER
    return Object.FindObjectsByType<Button>(FindObjectsSortMode.None);
    #else
    return Object.FindObjectsOfType<Button>();
    #endif
    ```
- Note: These APIs are also backported to Unity 2020.3.4, 2021.3.18, and 2022.2.5
- Note: On Unity 6000.4+ the `FindObjectsSortMode` argument shown above is obsolete — drop it (see **Object Find APIs** under Unity 6000.4+)

### Unity 2023.1+

**MonoBehaviour initialization state properties:**
- `didAwake` (bool) — `true` after `Awake()` has been called on this instance
- `didStart` (bool) — `true` after `Start()` has been called on this instance

**Awaitable — ALWAYS prefer over coroutines:**
- Use `async Awaitable` methods instead of `IEnumerator` coroutines
- `Awaitable.NextFrameAsync(ct)` instead of `yield return null`
- `Awaitable.EndOfFrameAsync(ct)` instead of `yield return new WaitForEndOfFrame()`
- `Awaitable.FixedUpdateAsync(ct)` instead of `yield return new WaitForFixedUpdate()`
- `Awaitable.WaitForSecondsAsync(t, ct)` instead of `yield return new WaitForSeconds(t)`
- Pass `destroyCancellationToken` (on `MonoBehaviour`) to tie async lifetime to object destruction

```csharp
// Instead of:
private IEnumerator SpawnRoutine()
{
    yield return new WaitForSeconds(2f);
    SpawnEnemy();
    yield return null;
    ShowEffect();
}
StartCoroutine(SpawnRoutine());

// Use:
private async Awaitable SpawnAsync(CancellationToken ct = default)
{
    await Awaitable.WaitForSecondsAsync(2f, ct);
    SpawnEnemy();
    await Awaitable.NextFrameAsync(ct);
    ShowEffect();
}
_ = SpawnAsync(destroyCancellationToken);
```

### Unity 2023.2+

**TextMesh Pro:**
- TMP is merged into uGUI (`com.unity.ugui` **v2.0**); do NOT add the separate `com.unity.textmeshpro` package
- Import and usage are unchanged: use `TMPro.TextMeshProUGUI`, `TMPro.TMP_Text`, etc.

**Mobile Screen Reader (Accessibility):**
- `UnityEngine.Accessibility` module added; supports iOS VoiceOver and Android TalkBack
- Build an `AccessibilityHierarchy` of `AccessibilityNode` instances to expose UI elements to the OS screen reader
- Reference: https://unity.com/blog/engine-platform/mobile-screen-reader-support-in-unity

### Unity 6000.0+

**Unity Test Framework:**                                                                                                                                                                                        
- `com.unity.test-framework` is bundled as a **core package** from 6000.0.44f1; no separate package installation required

### Unity 6000.3+

**Testing:**
- Use UI Test Framework (`com.unity.test-framework.ui`) v1.0 for UI Toolkit (UIElements) interaction tests

### Unity 6000.4+

**ECS Core Packages:**
- `com.unity.entities`, `com.unity.collections`, `com.unity.mathematics`, `com.unity.entities.graphics` are bundled as **core packages** (shipped with the editor); no separate package installation required

**InstanceID → EntityId migration:**
- `InstanceID` (int) is deprecated in favour of the new `EntityId` type
- Do NOT cast `EntityId` to/from `int`
- Do NOT rely on hash codes, string serialisation, or creation-order sorting of `EntityId`
- `GetInstanceID()` and related methods are deprecated; prefer `EntityId`-based APIs
- `InstanceID` will be removed in a future release
- For code under `Packages/` whose minimum supported version is below 6000.4, guard with `UNITY_6000_4_OR_NEWER`
    ```csharp
    #if UNITY_6000_4_OR_NEWER
    EntityId id = gameObject.GetEntityId();
    #else
    int id = gameObject.GetInstanceID();
    #endif
    ```

**Object Find APIs:**
- `UnityEngine.Object.FindObjectsByType<T>(FindObjectsInactive, FindObjectsSortMode)` and `Object.FindObjectsByType<T>(FindObjectsSortMode)` are obsolete (`FindObjectsSortMode` parameter is dropped)
- Use `Object.FindObjectsByType<T>(FindObjectsInactive)` instead of `FindObjectsByType<T>(FindObjectsInactive, FindObjectsSortMode)`
- Use `Object.FindObjectsByType<T>()` instead of `FindObjectsByType<T>(FindObjectsSortMode)`
- `FindObjectsSortMode` is dropped because `InstanceID`-order sorting can no longer be guaranteed after the `InstanceID` → `EntityId` migration above
- For code under `Packages/` whose minimum supported version is below 6000.4, guard with `UNITY_6000_4_OR_NEWER`
    ```csharp
    #if UNITY_6000_4_OR_NEWER
    return Object.FindObjectsByType<Button>();
    #elif UNITY_2022_3_OR_NEWER
    return Object.FindObjectsByType<Button>(FindObjectsSortMode.None);
    #else
    return Object.FindObjectsOfType<Button>();
    #endif
    ```

**Singular Object Find APIs:**
- `Object.FindFirstObjectByType<T>` is obsolete — it relied on InstanceID ordering, which can no longer be guaranteed after the InstanceID → EntityId migration
- Use `Object.FindAnyObjectByType<T>` instead; it is already available since Unity 2022.3+ so no additional 6000.4 version gate is needed
- For code under `Packages/` whose minimum supported version is below 2022.3, use a two-branch guard:
    ```csharp
    #if UNITY_2022_3_OR_NEWER
    var obj = Object.FindAnyObjectByType<MyComponent>();
    #else
    var obj = Object.FindObjectOfType<MyComponent>();
    #endif
    ```
