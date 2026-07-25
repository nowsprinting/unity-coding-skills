# Troubleshooting the `run_unity_tests` Tool

## Tool Not Found

If the `run_unity_tests` tool is not available, consider the following causes:

1. [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin is not installed: Install it from **Settings > Plugins**.
2. Built-in [MCP Server](https://www.jetbrains.com/help/rider/mcp-server.html) is not enabled: Open **Settings > Tools > MCP Server** and turn on **Enable MCP Server**.
3. The tool is disabled: Open **Settings > Tools > MCP Server > Exposed Tools** and turn on **UnityEditorToolset** and **run_unity_tests**.

## When Tool Response Does Not Return

`run_unity_tests` does not return until the test run completes or times out (default: 300 seconds).
**Do not call the tool again while waiting — duplicate calls launch a second test run on top of the first.**

If the response takes longer than expected, check:

1. Unity Editor is still running and connected to Rider.
2. The test run is visible in the **Unity Test Runner** window (play button active or spinner present).
3. If neither is visible, the connection may have been lost — wait for the timeout response, then retry once.

## Triage by Tool Response

Check the tool response before investigating log files. Most failure modes can be identified and resolved from `errorMessage` alone.

### `success: false` — Validation errors

Fix the tool call and retry immediately. No log investigation needed.

| `errorMessage`                   | Problem                          | Fix                                                                        |
|----------------------------------|----------------------------------|----------------------------------------------------------------------------|
| `"assemblyNames is required..."` | Missing or blank `assemblyNames` | Provide at least one valid assembly name (check `.asmdef` `name` property) |
| `"testMode is required..."`      | Missing `testMode`               | Specify `EditMode` or `PlayMode`                                           |
| `"Invalid testMode: '...'"`      | Unrecognised `testMode` value    | Use `EditMode` or `PlayMode` (case insensitive)                            |
| `"No protocol available."`       | Rider solution not fully loaded  | Wait for Rider to finish indexing, then retry                              |

### `success: false` — Unity Editor not connected

`errorMessage`: `"Unity Editor did not connect within 30 seconds."`

Rider cannot see the Unity Editor. Possible causes:

- **Compilation errors**: Play Mode tests cannot run if there are compilation errors. Check with `get_unity_compilation_result` and fix errors before retrying.
- **Editor not running**: Use the `execute_run_configuration` tool to launch the `Start Unity` configuration, then retry.
- **Wrong project open**: Verify the Editor has the correct project loaded.

### `success: false` — Timeout

`errorMessage`: `"Test execution timed out after N seconds."`

This fires the same way whether the Unity Editor is still running normally or has frozen completely — the MCP tool's own timeout (default 300s / `MCP_TOOL_TIMEOUT`) is on a channel independent of the Editor. Distinguishing the two determines whether retrying can help at all.

**Step 1 — Determine whether the Editor actually froze.**

- Inspect `idea.log` for `UnitTestLaunch created` and `RunUnitTestLaunch.Start called` (confirming the run started), then check `Editor.log` for the lifecycle marker sequence described in [Tests launched but timed out](#tests-launched-but-timed-out).
  - Markers 1–3 present but 4–5 absent, and `TestResults.xml` was never written → the Editor froze — see [Editor freeze](#possible-cause-editor-freeze) for causes.
  - `TestResults.xml` was written → the run completed; this was not a freeze — go to Step 2.
- If still unclear, ask the user whether the Unity Editor UI is responding to input at all. A genuinely unresponsive Editor confirms a freeze.

**If frozen, retrying `run_unity_tests` will not help** — it reaches the same frozen Editor and times out again the same way. Report the freeze to the user and ask them to force-quit and relaunch the Unity Editor (`execute_run_configuration` → `Start Unity`), then fix the test code that caused it before re-running.

**Step 2 — If not frozen, reduce scope or increase the timeout.**

- **Narrow the test selection**: Add `assemblyNames`, `testNames`, or `categoryNames` filters to run fewer tests per call.
- **Tests with a long `[Timeout]` attribute**: NUnit's default per-test timeout is 300,000 ms (5 minutes). If tests intentionally take longer, ask the user to increase `MCP_TOOL_TIMEOUT` (e.g., `MCP_TOOL_TIMEOUT=600`).

### `success: false` — Domain reload reconnection failure

`errorMessage`: `"Unity Editor did not reconnect within N seconds after domain reload. This may be caused by a crash or the editor being closed. However, before retrying or restarting Unity Editor, check idea.log and Editor.log to understand the situation."`

Check `Editor.log` for a crash or compilation error that prevented the Editor from recovering. See [Domain reload during test execution](#domain-reload-during-test-execution) for log patterns to look for.

If the Editor is still running, wait 10–30 seconds and retry once. If reconnection fails repeatedly, restart the Unity Editor.

### `success: false` — Protocol disconnection

`errorMessage`: `"Test execution was cancelled due to protocol disconnection or Kotlin coroutine cancellation."`

The MCP client (Claude Code) disconnected, or Rider itself shut down. Confirm both Rider and the MCP connection are healthy, then retry.

### `success: true` — Zero test results

All of `passCount`, `failCount`, `skipCount`, `inconclusiveCount` are `0`.

No tests matched the filter. See [Zero test results returned as success](#zero-test-results-returned-as-success) for log patterns, then:

- Verify `assemblyNames` by running `resolve-test-target.sh` against any test file in the target assembly.
- Check spelling of any `testNames` or `categoryNames` values.

### `success: true` — Failures present

Read `failedTests` and `inconclusiveTests` for test IDs and output. No log investigation needed unless failures point to environment or infrastructure issues.

## Log Files to Investigate

Paths are from Unity's [Log Files](https://docs.unity3d.com/Manual/log-files.html) and JetBrains' [Directories used by the IDE](https://www.jetbrains.com/help/rider/Directories_Used_by_the_IDE_to_Store_Settings_Caches_Plugins_and_Logs.html) documentation. Replace `<version>` with the Rider build directory name (e.g. `Rider2024.3`).

### JetBrains Rider log (primary)

Every `run_unity_tests` invocation writes here. Grep keywords: `UnityTestMcpHandler`, `RunUnityTestsTool`.

| OS      | Path                                              |
|---------|---------------------------------------------------|
| macOS   | `~/Library/Logs/JetBrains/<version>/idea.log`     |
| Windows | `%LOCALAPPDATA%\JetBrains\<version>\log\idea.log` |
| Linux   | `~/.cache/JetBrains/<version>/log/idea.log`       |

In the IDE: **Help → Show Log in Finder / Explorer / Files**.

### Unity Editor log

Editor-side crashes, domain reloads, compile errors, and test-framework lifecycle markers.

| OS      | Path                                     |
|---------|------------------------------------------|
| macOS   | `~/Library/Logs/Unity/Editor.log`        |
| Windows | `%LOCALAPPDATA%\Unity\Editor\Editor.log` |
| Linux   | `~/.config/unity3d/Editor.log`           |

### Editor.log vs Editor-prev.log

Unity's normal convention is `Editor.log` = current session, `Editor-prev.log` = previous session. This does not always hold — some setups (e.g., an Editor session attached to Rider/an IDE) have been observed writing the actively-updated log to `Editor-prev.log` while `Editor.log` sits stale from an earlier session. Before trusting either file, compare their modification times (`ls -la` on both) and read whichever is actually current; do not assume the filename tells you which one is live.

## Log Patterns by Scenario

### Unity Editor not connected

`idea.log`:
```
BackendUnityModel=null
```

Rider cannot see the Unity Editor. For recovery steps, see [Unity Editor not connected](#success-false--unity-editor-not-connected).

### Tests launched but timed out

`idea.log` contains:
```
UnitTestLaunch created, sessionId=XXXX
RunUnitTestLaunch.Start called
```
but `RunResult received` never appears, and the tool eventually returns:
```
Test execution timed out after 300 seconds.
```

For recovery steps, see [Timeout](#success-false--timeout).

#### Possible cause: Editor freeze

The Unity Editor's main thread never yielded, so Unity Test Framework's own timeout mechanism — which needs a yield point to check elapsed time — never got a chance to run either. Only the external MCP tool timeout eventually fires; the Editor itself remains frozen, and `TestResults.xml` is never written, so `idea.log` alone cannot identify the hanging test.

Common causes:

- An infinite loop, or a wait whose condition never becomes true, with **no** `yield return` / `await` reached inside the loop body. (A loop that does yield each iteration lets Unity Test Framework's own timeout fail just that one test instead — the run then continues and completes normally, which does not match this log pattern.)
- An `async` delegate passed to an NUnit assertion overload that accepts one (`Assert.ThrowsAsync`, `Assert.CatchAsync`, `Is.Not.AllocatingGCMemory()`, …) — see `test-writing-guide` → `resources/unity-test-framework.md` → **Async Tests**.

Check `Editor.log` for the test-framework lifecycle marker sequence:

| Marker substring in `Editor.log`                      | Meaning                                           |
|-------------------------------------------------------|---------------------------------------------------|
| `Executing IPrebuildSetup for: ...TestRunBuilder.`    | Test run initiated                                |
| `Reloading assemblies for play mode.`                 | Entering Play Mode                                |
| `- Finished resetting the current domain`             | Play Mode entered — test code is about to execute |
| `Saving results to: ...TestResults.xml`               | All tests completed normally                      |
| `Executing IPostBuildCleanup for: ...TestRunBuilder.` | Runner cleanup complete                           |

If markers 1–3 appear but 4–5 do not, the Editor froze during test execution.

`Editor.log` cannot identify *which* test caused the freeze in interactive mode — per-test `##utp:` messages are only emitted in batch mode. To isolate it: add `Debug.Log` at the start of each test method so the last logged name is visible, run tests one at a time in the Test Runner, or switch to batch-mode execution where `##utp:{"type":"TestStarted",...}` lines appear in `Editor.log`.

### Manually canceled in Unity Test Runner

Same `idea.log` pattern as [timed out](#tests-launched-but-timed-out) — `RunResult` is not fired on manual cancel (known limitation). For recovery steps, see [Timeout](#success-false--timeout).

### Domain reload during test execution

`idea.log`:
```
BackendUnityModel became null (domain reload or disconnection), waiting for reconnection...
Unity Editor reconnected after domain reload, re-launching tests
```

This is normal for Play Mode tests. The framework handles reconnection automatically and relaunches the test run. For recovery steps, see [Domain reload reconnection failure](#success-false--domain-reload-reconnection-failure).

### Protocol disconnection (Kotlin cancellation)

`idea.log`:
```
Test execution was cancelled due to protocol disconnection or Kotlin coroutine cancellation.
```

The MCP client (Claude Code) disconnected, or Rider itself shut down. For recovery steps, see [Protocol disconnection](#success-false--protocol-disconnection).

### Zero test results returned as success

`idea.log`:
```
RunResult received: passed=true, testResults.Count=0
Building response, snapshot.Count=0
```

The test filter matched no tests. For recovery steps, see [Zero test results](#success-true--zero-test-results).

## Diagnostic Workflow

1. Grep `idea.log` for `UnityTestMcpHandler` to find the most recent invocation and see how far it progressed.
2. `BackendUnityModel=null` → Unity Editor is not connected; see [Unity Editor not connected](#unity-editor-not-connected).
3. `UnitTestLaunch created` is present but `RunResult received` is missing → timeout, manual cancel, or Editor freeze. Check `Editor.log` for the lifecycle marker sequence and whether `TestResults.xml` was written: if the Editor froze, retrying or adjusting `MCP_TOOL_TIMEOUT` will not help — ask the user to restart the Editor first. Otherwise, increase `MCP_TOOL_TIMEOUT` or narrow the test filter.
4. `became null` → domain reload occurred; `did not reconnect` → check `Editor.log` for a crash or compile error.
5. `snapshot.Count=0` → filter mismatch; verify `assemblyNames` by running `resolve-test-target.sh` against any test file in the target assembly, or check `testNames` spelling.
6. If `idea.log` shows the launch started but stopped silently, check `Editor.log` for the lifecycle marker sequence to determine whether the hang occurred before or after test code started running.
