---
name: run-tests
description: >-
  Provides guidelines for running Unity tests using the run_unity_tests tool.
  Make sure to use this skill whenever running, executing, or re-running tests on the Unity editor.
  This includes verifying implementations, debugging test failures, running specific test assemblies, or any task that involves the run_unity_tests tool.
  Also covers running Play Mode tests on the player for verifying player-only behavior (e.g., #if directives and code stripping).
  Also covers verifying `[Category("VisualVerification")]` tests after a run by analyzing the saved screenshots.
  Even if the user just says "run the tests" or "check if it passes", use this skill.
license: Unlicense
metadata:
  author: Koji Hasegawa
---

## Gotchas

- **Never call two Unity Editor tools in parallel.** `unity_play_control`, `get_unity_compilation_result`, `run_unity_tests`, and `run_method_in_unity` must be called strictly one at a time — always wait for each call to return before making the next one. Calling them concurrently causes domain-reload conflicts that result in "canceled" or "did not connect within 30 seconds" errors.
- **When a Unity Editor tool returns `error` or `canceled`, wait 10 seconds before retrying.** Domain reload typically takes several seconds; immediate retry hits the same in-flight reload and fails again. Do not switch tools in the meantime (e.g., calling `unity_play_control` to verify state) — that just compounds the multiplexed calls. If the same tool returns `error` or `canceled` on two consecutive attempts (with the 10-second wait between them), stop and consult the user instead of retrying further.

## Run Tests

Before running tests, complete the following steps in order:

1. If any code was modified, confirm compilation success using the `get_unity_compilation_result` tool before proceeding.
2. To determine `assemblyNames` and `testMode` for a specific test class, run `${CLAUDE_SKILL_DIR}/scripts/resolve-test-target.sh <test-class-cs-path>`. The script prints `<assemblyName>\t<testMode>` (e.g. `MyGame.Tests\tPlayMode`). Skip this step when running an already-known assembly.

Then use the `run_unity_tests` tool to run the tests on the Unity editor.

Test execution can take several minutes. Do not re-run while a test is in progress — always wait for it to complete or time out. If a timeout occurs, narrow down the tests using filter settings and re-run.

## Run Tests on the Player

`run_unity_tests` runs tests only inside the Unity Editor. Run tests on a player instead when the user asks for it (e.g., "run on player", "standalone", "実機で実行"), or when player-only behavior must be verified (code inside `#if !UNITY_EDITOR`, `Resources`-based loading, IL2CPP, player-build hooks such as `ITestPlayerBuildModifier`). Pick the section below by target platform.

### Standalone Player

For a standalone player running on the host OS (macOS, Windows, or Linux): Read `${CLAUDE_SKILL_DIR}/resources/run-on-standalone-player.md`. It covers the build-and-run procedure and troubleshooting including `Player.log` locations.

### Other Players

TBD

## Visual Verification

A test method carrying `[Category("VisualVerification")]` has no `Assert` statements (see `test-writing-guide` skill), so `Passed` only means the test ran without throwing — it says nothing about whether the screen actually looks right. That judgment has to come from analyzing the screenshot the test captured.

**Only analyze when the run was to confirm a change made in this session** — production code, test code, a scene, a prefab, or another asset. Skip the analysis when nothing is under verification: a regression run over unchanged code, or when the user only asked whether the tests pass. When in doubt, skip.

This applies to Editor runs (`run_unity_tests`) only. A standalone-player run writes `Temp/PlayerTestResult.txt`, not an XML result file, and on macOS the Player's `persistentDataPath` differs from the Editor's — see `resources/run-on-standalone-player.md`. `[TakeScreenshot]` itself is Play Mode only.

### Procedure

1. Run: `python3 ${CLAUDE_SKILL_DIR}/scripts/extract-visual-verification.py <unity-project-root>`
   This prints, per `[Category("VisualVerification")]` test found in `Application.persistentDataPath/TestResults.xml`, its NUnit `result`, its `Description` property (the verification aspects), and its `Screenshot` propert(y/ies) (absolute path(s)). See the script's own comments for why an XML library is used instead of grep/awk (class-scoped `[Category]` lands on the ancestor `<test-suite>`, not the `<test-case>`; a test can record more than one `Screenshot`).
2. Check freshness before trusting the output: compare the printed list of "All N test(s) in this result file" against the tests you actually just ran. A filtered run's XML contains only the test-cases that were executed, so a mismatch (extra tests you didn't run, or missing ones you did) means this file is from an earlier run — `TestResults.xml` is overwritten on each run, not appended. Treat the printed age (`— N seconds ago`) as a secondary signal only; it can't discriminate a stale file from a few minutes ago from a run that legitimately took a few minutes. On either signal of staleness, stop and report it instead of analyzing.
3. For each test whose `result` is `Passed`, read the image(s) at its `Screenshot` path(s) and judge them against the aspects listed in `Description`. Report each aspect's verdict with what you actually saw in the image.
4. For a test whose `result` is not `Passed`, do not analyze — report it as a failure instead (the screenshot, if any, may be from a partial run).

### If no TestResults.xml is found (exit code 3)

`TestResults.xml` under `persistentDataPath` is written by the `com.unity.test-framework.performance` package's `RunFinished` callback, not by Unity Test Framework itself — UTF only writes a result XML for CLI/batchmode runs (to `<project-root>/TestResults-<ticks>.xml`), never for Test Runner window / MCP-driven runs. If that package isn't installed, fall back:

- **Screenshot paths**: `[TakeScreenshot]`/`ScreenshotHelper` log `Save screenshot to <absolute path>` on every capture. Find the current log file (compare mtimes of `Editor.log` and `Editor-prev.log` — see `resources/troubleshooting-run-unity-tests.md` → "Editor.log vs Editor-prev.log"), then take the `Save screenshot to` lines that appear **after** the last `- Finished resetting the current domain` line (the lifecycle marker for the run you just triggered — same resource, "Tests launched but timed out" table).
- **Verification aspects**: read the `[Description(...)]` attribute directly from the test's source file.

### Helper script

`${CLAUDE_SKILL_DIR}/scripts/get-persistent-data-path.sh <unity-project-root>` prints the Editor's `Application.persistentDataPath` for the current OS (from `companyName`/`productName` in `ProjectSettings/ProjectSettings.asset`, per [Unity's docs](https://docs.unity3d.com/ScriptReference/Application-persistentDataPath.html)). `extract-visual-verification.py` calls it automatically; use it directly only when you need the raw directory.

## Rules for Test Failures

If the same test(s) fail on two or more consecutive runs, stop and consult the user rather than continuing to fix.

When consulting, clarify:

- Current failure status: what is failing and the likely cause
- Fix history: what was changed, how many times, and the scope of impact
- Planned approach: what options are being considered next

## Troubleshooting

Read the appropriate resource file based on the situation:

- Any Unity MCP tool (`run_unity_tests`, `unity_play_control`, `get_unity_compilation_result`) is not available or fails with a connection error: Read `${CLAUDE_SKILL_DIR}/resources/troubleshooting-run-unity-tests.md`
- A test fails due to an assertion, constraint, or comparer in the `TestHelper` namespace (excluding `TestHelper.UI`): Read `${CLAUDE_SKILL_DIR}/resources/troubleshooting-test-helper.md`
- A test fails due to an exception thrown from the `TestHelper.UI` namespace: Read `${CLAUDE_SKILL_DIR}/resources/troubleshooting-test-helper-ui.md`
