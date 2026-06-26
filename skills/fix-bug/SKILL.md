---
name: fix-bug
description: >-
  Diagnoses and fixes bugs using a test-first workflow (reproduce, diagnose, fix).
  Use this skill whenever the user reports a bug, describes unexpected behavior, or asks to
  investigate or fix a defect. Even if the user says "something's broken", "this isn't working",
  "fix this bug", or "why does X happen", load this skill to guide the full
  reproduce → diagnose → fix cycle.
argument-hint: "[incident or failing-test-name]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for diagnosing and fixing bugs. This skill defines a test-first debugging workflow:
reproduce the bug with a failing test, diagnose the root cause, then fix it.

## Mode Check

This skill must be used **outside plan mode**. Before doing anything else, check the current mode:

- `ExitPlanMode` is NOT in the deferred tools list (i.e., directly callable) → **in plan mode** → stop immediately and tell the user:
  > "This skill (`/fix-bug`) must be used outside plan mode. Please exit plan mode first."
- `ExitPlanMode` is in the deferred tools list → not in plan mode → proceed.

## Workflow

### Step 1: Clarify the Bug Report

> **Do not read code files during this step.** You may only read specs and design docs.

Extract the following from the user's prompt:

- **Condition**: the setup or scenario that triggers the bug
- **Expected**: the expected behavior
- **Actual**: the observed behavior

If any of the three cannot be determined from the prompt, use `AskUserQuestion` to ask
the user before proceeding. All three must be known before moving to Step 2.

Also determine the **report type**:

- **Existing test failure** — the user reports that an existing test is failing. The specific failing test method need not be known at this stage; note the scope (class name, scene name, or test assembly) from the prompt. **Step 2 is skipped** — proceed directly to Step 3.
- **Behavioral bug** — the user describes unexpected runtime behavior with no mention of a failing test. Proceed normally through Step 2.

Also check the relevant documentation (specs, design docs) for consistency with the
user's bug report. If the documentation and the report conflict, use `AskUserQuestion`
to clarify with the user which is correct. If the docs contain errors or are missing
relevant information, add them to the list of files to be modified in this bug fix.

### Step 2: Write the Reproduction Test

> **Skip this step** if Step 1 identified this as an **existing test failure** case. Proceed directly to Step 3.

Search the project's test code for existing tests closest to the bug scenario. These serve two purposes:
- Placement anchor — add the reproduction test nearby
- Style reference — follow the same test conventions

**When the bug condition involves on-screen display or a user-facing UI operation**, search for **integration tests with UI operations or visual verification tests** — the reproduction test must be at that layer, so the placement anchor and style reference must be too.

Use Explore agents to locate relevant test files and test cases.

Load the `test-designing-guide` skill to design the reproduction test case, then load `test-writing-guide` to implement it. Place the reproduction test near the similar tests found above.

If an existing test is testing the wrong behavior (i.e., the test itself is buggy), rewrite
that test to correctly reproduce the bug rather than adding a new one.

### Step 3: Verify the Reproduction Test Fails

Run tests using the `/run-tests` skill and verify that the reproduction test **fails**:

- **If a test was added in Step 2**: run that specific test.
- **If Step 2 was skipped (existing test failure)**: narrow down the test to run using the scope identified in Step 1 (e.g., a specific test class or assembly). If narrowing down is not possible, run all tests.

If multiple tests fail and it is unclear which one corresponds to the reported bug, use
`AskUserQuestion` to ask the user which test to focus on.

#### If the test does not fail (Step 2 path only)

- Delete the reproduction test
- Return to Step 2 and search more broadly

If reproduction has been attempted **3 times** without success, return to **Step 1** and
use `AskUserQuestion` to re-clarify the bug report with the user.

### Step 4: Confirm Reproduction with User

**Present the reproduction evidence to the user** via `AskUserQuestion` before proceeding.
Include:
- Reproduction test: file path and method name
- Test failure message (actual output from the test run)

Once the user confirms the reproduction is as expected:
1. Commit the reproduction test — if test code is modified in a later step, the integrity of Test First is compromised; commit here without fail so the diff remains verifiable
2. Proceed to Step 5

### Step 5: Diagnose & Formulate Fix

With the reproduction confirmed, investigate the root cause:

1. Trace through the code path triggered by the reproduction test
2. Identify the specific line(s) or logic responsible for the bug
3. Formulate a fix

### Step 6: Regression Test Coverage

Before applying the fix, check whether the affected area has adequate coverage for adjacent behavior:

1. Read the test files for the affected production code
2. Identify behaviors that could regress from the change but are not currently tested
3. If gaps exist, add regression tests and run them — they must **pass**
   (they test existing correct behavior, not the bug itself)

### Step 7: Apply Fix & Verify

1. Apply the fix formulated in Step 5 to the production code
2. Run all affected tests using `/run-tests`
3. Confirm:
   - The reproduction test now **passes** (bug is fixed)
   - All regression tests still **pass**
4. Commit production code fix to git (includes regression tests from Step 6 and any unavoidable changes to the reproduction test)

### Step 8: Refactoring

1. Launch `test-deduplicator` agent with: list of test files added or modified in this iteration
2. Resolve diagnostics at the `warning` or higher severity level using the following procedure,
   **one file at a time** — `mcp__ide__getDiagnostics` only returns results for files currently open
   in editor tabs, and opening all files at once exceeds the tab limit:
   1. `mcp__jetbrains__open_file_in_editor` — open the file in the editor
   2. `mcp__ide__getDiagnostics` — collect all diagnostics for that file
   3. Fix all reported issues as a single set before moving to the next file

   Use `mcp__ide__getDiagnostics` instead of `mcp__jetbrains__get_file_problems` (unstable) or
   the Unity compiler output (does not reflect `.editorconfig` severity settings).
3. Re-run tests using `/run-tests` command to confirm they still pass
4. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
5. Re-run tests using `/run-tests` command to confirm they still pass
6. Commit all remaining changes to git
