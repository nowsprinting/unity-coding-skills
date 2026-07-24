# Running Play Mode Tests on a Standalone Player

The `run_unity_tests` tool runs tests only inside the Unity Editor. This resource describes how to run Play Mode tests on a standalone player, on the machine the Editor is running on (macOS, Windows, or Linux). Use it to verify behavior that differs on a player — code inside `#if !UNITY_EDITOR`, `Resources`-based loading, player-build hooks such as `ITestPlayerBuildModifier`, and (when the effective scripting backend is IL2CPP — the project's setting by default) AOT and code-stripping behavior.

## Prerequisites

1. **The Unity Editor must be running and connected** (same as for `run_unity_tests`). The player is built by the Editor and reports test results back to it over PlayerConnection.
2. **The target platform must match the host OS**, because the built player is launched locally. Determine the host OS from the platform information in the environment context (or `uname` via the shell), then pick the `BuildTarget` from this table:

   | Host OS | `BuildTarget`         |
   |---------|-----------------------|
   | macOS   | `StandaloneOSX`       |
   | Windows | `StandaloneWindows64` |
   | Linux   | `StandaloneLinux64`   |

## Procedure

There is no MCP tool that runs tests on a player directly, so drive Unity Test Framework's `TestRunnerApi` from a temporary editor script.

### 1. Create a temporary runner script

Copy `${CLAUDE_SKILL_DIR}/assets/PlayerTestRunner.cs` to `Assets/UnityCodingSkills/Editor/PlayerTestRunner.cs` in the project (delete it after verification — see step 5). The script has four parts:

- **`PlayerTestRunner`** — drives `TestRunnerApi.Execute` and writes the results to `Temp/PlayerTestResult.txt` via `ICallbacks`.
- **`PlayerTestBuildSettings`** (`ITestRunSettings`) — bakes the Standalone build settings (`ScriptingBackend` / `CodeGeneration` / `StrippingLevel`) into the test player. Step 1 fills the constants with the project's own PlayerSettings values, so the build diverges from the project configuration only when the user asks for an override (see "Overriding build settings with ITestRunSettings" below).
- **`PlayerTestBuildModifier`** (`ITestPlayerBuildModifier`) — removes `BuildOptions.AutoRunPlayer` and redirects the build into `Temp/PlayerWithTests/`, keeping the file name Unity chose so the platform-correct extension (`.app`/`.exe`/none) comes for free. Auto-run offers no way to pass command-line arguments to the player, so the build must not launch it. Only acts while a run started by `RunOnStandalonePlayer` is in flight (see the note at the end of this step).
- **`PlayerTestLauncher`** (`[PostProcessBuild]`) — launches the built player with the `PlayerArguments` constant. The player still reports results back to the Editor over PlayerConnection, because `BuildOptions.ConnectToHost` is always baked into test player builds (this split build-and-launch flow is explicitly supported — see the `TestPlayerBuildModifier` scripting reference).

Adjust these values before compiling:

| Constant / field   | What to set                                                                                                                                                                                                                                                                                               |
|--------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `targetPlatform`   | The `BuildTarget` for the host OS (table above)                                                                                                                                                                                                                                                           |
| `groupNames`       | Narrow the `Filter` to the tests that matter (a player build compiles and runs everything matching the filter; smaller filters do not shorten the build much, but they shorten the run)                                                                                                                   |
| `PlayerArguments`  | Command-line arguments for the player. Default: the project's own screen settings, from the script output below (see also "Player command-line arguments")                                                                                                                                                |
| `ScriptingBackend` | The project's own value from the script output below. Override (e.g. `IL2CPP` to verify AOT behavior on a Mono project, `Mono2x` for a faster smoke run) only on user instruction. IL2CPP needs the platform's IL2CPP Build Support module; a missing module fails the build (see Troubleshooting item 1) |
| `CodeGeneration`   | The project's own value from the script output below (only takes effect under IL2CPP). Override on user instruction: `OptimizeSize` = "Faster (smaller) builds", `OptimizeSpeed` = runtime performance                                                                                                    |
| `StrippingLevel`   | The project's own value from the script output below. Raising it above `Disabled` can break reflection-based assertions (see "Reflection-based assertion fails only on Player" in Troubleshooting). `Disabled` is a Mono-only option — under IL2CPP, Unity treats it as `Minimal`                         |

Fetch the project's PlayerSettings values with:

```bash
${CLAUDE_SKILL_DIR}/scripts/get-player-settings.sh <project-root>
```

It prints the screen settings (`fullscreenMode`, `defaultScreenWidth`, `defaultScreenHeight`) and the Standalone build settings (`scriptingBackend`, `il2cppCodeGeneration`, `managedStrippingLevel`) from `ProjectSettings/ProjectSettings.asset`. A missing build-settings line means the project uses Unity's default. Mappings:

- `scriptingBackend`: `0` = `Mono2x` (default), `1` = `IL2CPP`
- `il2cppCodeGeneration`: `0` = `OptimizeSpeed` (default), `1` = `OptimizeSize`
- `managedStrippingLevel`: `0` = `Disabled`, `1` = `Low`, `2` = `Medium`, `3` = `High`, `4` = `Minimal` (default: `Disabled` under Mono2x, `Minimal` under IL2CPP)
- `-screen-fullscreen`: `0` if `fullscreenMode` is `3` (Windowed), otherwise `1`; `-screen-width` / `-screen-height` take `defaultScreenWidth` / `defaultScreenHeight` as-is

Passing the project's own screen defaults explicitly matters because once a player has been launched, its resolution is saved to PlayerPrefs, and on later launches that saved value takes precedence over the project defaults baked into the build; an explicit command-line argument wins over both. If the script prints nothing (ProjectSettings serialized as binary), fall back to `-screen-fullscreen 0 -screen-width 1920 -screen-height 1080` and the Unity defaults above, and report the Source as `Fallback`.

Finally, report the effective settings and command-line arguments in chat, so the user can catch a mismatch with their intent (or the test code's intent) before minutes of build time are spent. Use this format, where Source names where each value came from — `Skill default`, `Project setting`, `User instruction`, `CLAUDE.md`, etc.:

```markdown
| Setting                 | Value    | Source          |
|-------------------------|----------|-----------------|
| Scripting Backend       | Mono2x   | Project setting |
| Managed Stripping Level | Disabled | Project setting |

| Command-line Argument | Value | Source          |
|-----------------------|-------|-----------------|
| -screen-fullscreen    | 0     | Project setting |
| -screen-width         | 1920  | Project setting |
| -screen-height        | 1080  | Project setting |
```

Add rows for values that apply to the run: an `IL2CPP Code Generation` row when `IL2CPP` is selected, and a row per extra command-line argument (e.g. `-testHelperScreenshotDirectory`).

Note: while `PlayerTestRunner.cs` exists in the project, its `TestPlayerBuildModifier` attribute is evaluated for **every** test player build, including ones started from the Test Runner window. `ModifyOptions` leaves those builds untouched — it only acts while a run started by `RunOnStandalonePlayer` is in flight, tracked with a static flag that `RunFinished` clears. If a run aborts before `RunFinished` fires (e.g. a failed build), the flag stays set until the next domain reload — one more reason to delete the script right after verification.

### 2. Compile

Run `get_unity_compilation_result` and confirm the script compiles.

### 3. Invoke the runner

Call `run_method_in_unity` with type `UnityCodingSkills.RunTests.PlayerTestRunner` and method `RunOnStandalonePlayer`. For `assemblyName`, run `${CLAUDE_SKILL_DIR}/scripts/resolve-assembly.sh <project-root>/Assets/UnityCodingSkills/Editor/PlayerTestRunner.cs` and use the assembly name it prints.

The tool returns immediately: `TestRunnerApi.Execute` is asynchronous, and the player build plus the test run continue in the Editor. `success: true` means only that the method was invoked.

### 4. Poll for the result

The player build takes minutes. Poll for the result file with a shell loop run **in the background** (e.g., the Bash tool's `run_in_background` option) — a foreground loop would block the session for the entire build:

```bash
for i in $(seq 1 120); do
  if [ -f <project-root>/Temp/PlayerTestResult.txt ]; then cat <project-root>/Temp/PlayerTestResult.txt; exit 0; fi
  sleep 10
done
echo "TIMEOUT after 20 minutes"; exit 1
```

While waiting, do **not**:

- Call any other Unity Editor tool (`run_unity_tests`, `get_unity_compilation_result`, `unity_play_control`, `run_method_in_unity`) — same serialization rule as normal test runs.
- Modify any C# source. A recompile triggers a domain reload, which discards the registered `ICallbacks` instance — the run may finish but the result file will never be written.

A player window opens on the machine during the run and closes when the run finishes. Because `AutoRunPlayer` is removed, Unity Test Framework's player heartbeat timeout is never armed — a hung player will wait forever on the Editor side, so this polling timeout is the only guard. If it fires, quit the player manually.

Don't just wait out the full 20-minute timeout on faith. A failed build never produces a result file, so a silently-failed run and a slow-but-healthy one look identical while polling. If no result has appeared after the build's normal duration for this project (a rough baseline — check a few minutes past what a prior successful run took), read the tail of the Editor log for `Fatal error`, `TestLaunchFailedException`, or other build-failure signals — the live log is not always `Editor.log` (see "Editor.log vs Editor-prev.log" in `troubleshooting-run-unity-tests.md`). This is a plain file read, not a Unity Editor tool call, so it's safe to do while polling. Catching a failed build early saves the rest of the timeout.

### 5. Read the result and clean up

The result file contains the counts on the first line and `FAILED: <FullName>` + message for each failed test. Note that tests gated to the Editor (e.g., `[UnityPlatform(RuntimePlatform.OSXEditor, ...)]`) are reported as skipped on the player — a non-zero skip count is expected, not a problem.

Afterward, delete the temporary file `Assets/UnityCodingSkills/Editor/PlayerTestRunner.cs` with its `.meta`. If `Assets/link.xml` was created or modified for this run (per the "Reflection-based assertion fails only on Player" troubleshooting entry), restore it to its pre-run state: delete it with its `.meta` when the project did not have one before, or revert the added entries (e.g. `git restore Assets/link.xml`) when it did. The result file `Temp/PlayerTestResult.txt` and the built player under `Temp/PlayerWithTests/` can be left in place — Unity clears `Temp/` when the Editor quits.

## Player command-line arguments

`PlayerArguments` in `PlayerTestRunner.cs` is passed to the player at launch. Useful examples:

- `-screen-fullscreen 0 -screen-width 1920 -screen-height 1080` — window mode and resolution. These override both the `PlayerSettings` defaults baked into the build and the resolution persisted from previous runs (standalone players save their last resolution per `CompanyName`/`ProductName`, shared with normal builds of the same project) — which is why step 1 passes the project's own default values explicitly.
- `-testHelperScreenshotDirectory <path>` — output directory for screenshots and videos taken by the [TestHelper](https://github.com/nowsprinting/test-helper) package (`com.nowsprinting.test-helper`). Only meaningful when the project uses that package.

The full list of built-in player arguments is in the Unity Manual page **PlayerCommandLineArguments.html**, included in the documentation downloaded with the Editor — e.g., `/Applications/Unity/Hub/Editor/<version>/Documentation/en/Manual/PlayerCommandLineArguments.html` on macOS, `C:\Program Files\Unity\Hub\Editor\<version>\Editor\Data\Documentation\en\Manual\PlayerCommandLineArguments.html` on Windows. If the documentation component is not installed, use the online version: https://docs.unity3d.com/Manual/PlayerCommandLineArguments.html

## Overriding build settings with ITestRunSettings

`ExecutionSettings.overloadTestRunSettings` accepts an `ITestRunSettings` (namespace `UnityEditor.TestTools.TestRunner.Api`): `Apply()` is called right before the player build and `Dispose()` right after, so settings changed in `Apply()` override the project settings for that build only and are restored automatically — nothing is left dirty.

The runner script wires this up as `PlayerTestBuildSettings`, whose three constants — `ScriptingBackend`, `CodeGeneration`, `StrippingLevel` — step 1 fills with the project's own PlayerSettings values, so by default the test player matches the project configuration. When overriding on user instruction, know that:

- `Mono2x` builds considerably faster than `IL2CPP`; `IL2CPP` is what exercises AOT and code-stripping behavior
- `Il2CppCodeGeneration` only takes effect under IL2CPP; `OptimizeSize` ("Faster (smaller) builds") keeps IL2CPP build time down
- `ManagedStrippingLevel.Disabled` is a Mono-only option — under IL2CPP, Unity treats it as `Minimal`; stripping above `Disabled` can break reflection-based assertions (see Troubleshooting)

To override additional build settings (graphics APIs, other `PlayerSettings` values, etc.), add the corresponding get/set pair to `Apply()` and the restore call to `Dispose()`, following the same save-and-restore pattern.

## Alternative: Unity Command Line (no Editor session)

When no Editor is open (e.g., CI), tests can run on a player via batch mode. The Editor must be **closed** first — the project can only be opened by one Editor at a time:

```bash
<unity-editor-binary> -projectPath <project-root> -batchmode \
  -runTests -testPlatform StandaloneOSX \
  -testResults <absolute-path>/results.xml -forgetProjectPath
```

`-testPlatform` takes the same `BuildTarget` names as the table above. Results are written as NUnit XML to `-testResults`. This route also offers no built-in way to pass command-line arguments to the player; the `ITestPlayerBuildModifier` approach above works here too, since build modifiers apply to batch-mode player builds as well. Prefer the `TestRunnerApi` procedure during interactive sessions; closing the user's Editor just to run tests is rarely worth it.

## Troubleshooting

Investigate in this order when the result file never appears:

1. **Build failed** — check the Unity Console and the Editor log (locations: see "Log Files to Investigate" in `troubleshooting-run-unity-tests.md`, including the "Editor.log vs Editor-prev.log" caveat). Typical cause: the required Build Support module is not installed — building with `ScriptingBackend = IL2CPP` requires the platform's IL2CPP module (e.g., "Mac Build Support (IL2CPP)") via Unity Hub.
2. **Player never launched** — `PlayerTestLauncher` only launches builds placed under `BuildDirectory` (`Temp/PlayerWithTests/`) while a `RunOnStandalonePlayer` run is in flight. If the project defines its own `ITestPlayerBuildModifier` that overrides `locationPathName` after ours (the order in which modifiers apply is unspecified), the output path no longer matches and nothing is launched; check the Editor log for the actual build output path and adjust `BuildDirectory` (or the guard) accordingly.
3. **Player crashed or a test hung** — check `Player.log` (locations below). The last lines show how far the run progressed. Remember there is no heartbeat timeout in this flow (see step 4); quit a hung player manually.
4. **Player could not report back** — PlayerConnection uses a local network connection; an OS firewall prompt (macOS "Allow incoming connections", Windows Defender) may be blocking it. The player runs the tests but the Editor never receives results. PlayerConnection is the **only** result channel in this flow — if unblocking the firewall is not an option, the fallback is a player-side report: include a `TestRunCallback` in an assembly built into the player and save `result.ToXml(true)` from its `RunFinished` to a path passed via `PlayerArguments` (see "Split build and run" in the `TestPlayerBuildModifier` scripting reference). This needs an extra temporary **runtime** script (the runner script is Editor-only and never enters the player build), so reach for it only when the firewall truly cannot be unblocked.
5. **Domain reload during the run** — if any script was recompiled while waiting, the callbacks were lost (see step 4). Re-run from step 3.
6. **Editor exited right after the build** — every `IPostBuildCleanup` implementation across loaded assemblies runs for this build, independent of the test filter. The `TestPlayerBuildModifier` scripting reference's own "Split build and run" sample calls `EditorApplication.Exit(0)` from `Cleanup()` for command-line runs; a project variant that omits the command-line guard kills the Editor — and the PlayerConnection result channel with it — even in an interactive session. Search the project for `IPostBuildCleanup` implementations and ask the user how to proceed (e.g. temporarily guard or disable theirs).

### Reflection-based assertion fails only on Player (code stripping)

A test that passes in the Editor but fails on the player with `System.ArgumentException: Property <Name> was not found` (or a similar "member not found" exception naming a property/method) is very likely hitting managed code stripping — which is either a harmless test-side artifact or a real product bug, depending on whose code lost the member (see below). NUnit constraints such as `Has.Length`, `Has.Count`, `Has.Property(...)`, and `Has.Attribute<T>()` resolve their target via reflection (`Type.GetProperty(name)` or similar) at runtime; UnityLinker cannot see that reference statically, so if nothing else in the codebase touches the member directly, it gets stripped. This happens under **both** `Mono2x` and `IL2CPP` at any `ManagedStrippingLevel` above `Disabled` — whether the settings come from the project's own PlayerSettings (the default) or from a user-requested override. A Mono2x + `Disabled` build performs no stripping and never hits this; under IL2CPP the effective minimum is `Minimal`, so stripping always runs.

Before reaching for link.xml, check **whose** code lost the member. This workaround is strictly for members that only the test code touches — e.g. a BCL property that an NUnit constraint resolves via reflection, which no shipping build needs to keep. If the stripped member is one the **product** code needs at runtime (its own reflection, serialization, a DI container, etc.), the player run has just uncovered a real stripping bug in the product: report it to the user as a finding and fix it on the product side (a permanent link.xml entry committed to the project, a `[Preserve]` attribute, or a static reference) — do **not** mask it with the temporary test-run link.xml and report the tests as passing. The stack trace tells the two apart: an exception thrown from NUnit constraint/assertion frames inside the test is test-side; an exception surfacing from product code frames is a product bug.

Fix (test-side stripping only): keep the requested stripping settings and preserve the member with a temporary `Assets/link.xml` (when the project already has one, add the entries to it instead of overwriting it). It must live directly under `Assets/` — UnityLinker only auto-collects link.xml from the Assets folder, not from `Packages/` (confirmed via the Editor log's UnityLinker command-line arguments, which did not list a link.xml placed under a package's own folder). Example preserving `System.IO.FileInfo.get_Length` for `Has.Length` (BCL types like `FileInfo` live in `mscorlib` on Unity's Mono/IL2CPP class libraries):

```xml
<linker>
  <assembly fullname="mscorlib">
    <type fullname="System.IO.FileInfo">
      <method name="get_Length" />
    </type>
  </assembly>
</linker>
```

Add only the entries the failure needs: read the failing test to find the concrete type the constraint targets, find the assembly it lives in, and nest the `<method>` entry under the matching `<assembly>`/`<type>` blocks as above.

After the run, restore `Assets/link.xml` to its pre-run state alongside the other temporary files in step 5: delete it with its `.meta` when the project did not have one before, or revert the added entries when it did.

### Player.log locations

From Unity's [Log Files](https://docs.unity3d.com/Manual/log-files.html) documentation. `CompanyName` and `ProductName` come from **Project Settings > Player** (`PlayerSettings.companyName` / `productName`).

| OS      | Path                                                                    |
|---------|-------------------------------------------------------------------------|
| macOS   | `~/Library/Logs/<CompanyName>/<ProductName>/Player.log`                 |
| Windows | `%USERPROFILE%\AppData\LocalLow\<CompanyName>\<ProductName>\Player.log` |
| Linux   | `~/.config/unity3d/<CompanyName>/<ProductName>/Player.log`              |
