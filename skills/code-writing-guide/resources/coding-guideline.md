# Coding Guidelines

## Backward Compatibility

Do NOT maintain backward compatibility unless explicitly requested. Break things boldly — backward compatibility layers accumulate over time, increasing maintenance cost and making the codebase harder to evolve.

- Under `Assets/`: delete unused methods outright.
- Under `Packages/`: for `public` members, mark them with `[Obsolete]` first to announce deprecation before removal.

## Unity Version-Dependent Code

This section applies only to code under `Packages/`, where a UPM package must support a range of Unity versions
(take the minimum from the package's `package.json` `unity` / `unityRelease` fields). Code under `Assets/` is
built with a single Unity version — write it directly for that version, with no `#if` and no suppression comment.

When code is **needed on some Unity versions and not on others** — it is required on one side of a version boundary
and redundant or invalid on the other — wrap it in a `#if` directive. This includes `using` directives.

Do NOT leave such code unconditional with a diagnostic-suppression comment
(`// ReSharper disable once ...`, `[SuppressMessage]`, `#pragma warning disable`):
the IDE and analyzers only ever see one Unity version, so their verdict is correct on just one side of the boundary,
and suppressing it makes that misjudgement permanent.

- Use `UNITY_<version>_OR_NEWER` symbols. There is no `_OR_OLDER` form, so express "older only" as `#if !UNITY_<version>_OR_NEWER`.
- Place version-guarded `using` directives in a block at the end of the using list, so the rest stays sortable.
- Add a "why not" comment naming what changed at that version (see the "Why Not" Comments section below).
  The boundary version alone does not explain itself.

    ```csharp
    using System.Threading.Tasks;
    using NUnit.Framework;
    #if !UNITY_2023_1_OR_NEWER
    // Unity 2023.1 or newer provides the awaiter for AsyncOperation;
    // on older versions it comes from UniTask.
    using Cysharp.Threading.Tasks;
    #endif
    ```

**This does not apply when the code works on every supported version and a newer version merely deprecates it.**
Such code is version-independent, so it needs no `#if`; suppress the deprecation warning
(`#pragma warning disable CS0618`) with a "why not" comment instead.
Only switch to a `#if` branch once the API is actually removed, or once you want the newer API on newer versions.

**This is for Unity version differences only, in `Assets/` or `Packages/` alike.**
Guard on whether a package is installed with an asmdef `versionDefines` symbol instead (e.g. `#if ENABLE_UNITASK`).

## Structure

- Editor extension code goes under the `Editor/` directory.
- Runtime code goes under the `Runtime/` directory.
- A file contains only one public class or interface.
- Namespaces must align with the directory structure relative to the `Scripts` folder.
  For example, a file at `Assets/MyGame/Scripts/Runtime/Foo/Bar.cs` should use the namespace `MyGame.Foo.Bar`.

## MonoBehaviour

- The source file name must match the MonoBehaviour class name. Internal helper classes may live in the same file, but only one MonoBehaviour per file.
- For parameters that need to be tuned in the Inspector, expose them as public properties using the `[field: SerializeField]` pattern:
    ```csharp
    [field: SerializeField]
    public int TunableParameter { get; set; } = defaultValue;
    ```
- When making a property a serialization target, apply Unity serialization-related attributes (`SerializeField`, `HideInInspector`, `Range`, `Tooltip`, `Header`, etc.) using the `field:` target so they attach to the backing field:
    ```csharp
    [field: SerializeField]
    [field: Range(0, 100)]
    public int Health { get; set; }
    ```
- Place property XML documentation comments directly above the property, not above the attribute.
- Values that need to be tuned by playing the game (e.g., bullet speed, spawn intervals) must be defined as either a `SerializeField` or a `const`.
    - For `SerializeField`, describe the purpose with `[Tooltip("...")]` so it is readable in the Inspector.
    - For `const`, describe the purpose with a code comment.

## Events

- Prefer `System.Action` / `Action<T>` over `EventHandler` for events.
- Name events with a verb phrase using a present or past participle to indicate state before or after the change (e.g., `OpeningDoor` before, `DoorOpened` after).
- The method that raises an event is prefixed with `On` (e.g., `OnOpeningDoor`, `OnDoorOpened`).
- Observer-side handler methods are named `<Subject>_<EventName>` (e.g., `GameEvents_DoorOpened`).

## Async / Cancellation

- When `await`-ing an async call inside a `try` block using a `CancellationToken` received as a parameter, re-throw `OperationCanceledException` before any general `catch` so that cancellation propagates to the caller.
    ```csharp
    private async Awaitable SomeMethodAsync(CancellationToken ct)
    {
        try
        {
            await SomethingAsync(ct);
        }
        catch (OperationCanceledException)
        {
            throw; // propagate cancellation to the caller; do not swallow
        }
        catch (Exception e)
        {
            // handle real failures
        }
    }
    ```

## IL2CPP and Reflection

- Do NOT use `System.Reflection.Emit`. It is not supported under IL2CPP.
- Methods invoked only via reflection must be annotated with `[UnityEngine.Scripting.Preserve]` so that managed code stripping does not remove them.

## XML documentation

- When implementing an interface or overriding an abstract member, use `/// <inheritdoc/>` instead of duplicating the documentation.

## "Why Not" Comments

Add a comment whenever a non-obvious implementation choice was made — especially when a natural or standard approach was tried and rejected.
The goal is to prevent future readers (human or AI) from rediscovering the same dead end.

**Triggers that require a "why not" comment:**

- A standard API or language feature is avoided because it misbehaves in a specific environment
  (e.g., `withTimeout` deadlocks on the IntelliJ platform test JVM EDT → use `java.util.Timer`)
- A less-efficient or more verbose pattern is chosen over a simpler one for correctness reasons
- A seemingly redundant guard, indirection, or workaround exists due to a framework constraint
