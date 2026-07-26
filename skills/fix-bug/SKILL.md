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

**Recording implementation notes:** Notes for this run go in `/tmp/fix-bug-notes-$CLAUDE_CODE_SESSION_ID.md`. Immediately before your **first** append in this run — and only then — delete that file if it exists (usually it will not), so this run starts from an empty one: the session id is shared by every `/fix-bug` run in the session, so an earlier run abandoned before Step 9 would otherwise leak its notes into this one. Never delete it again afterwards, including when Step 3 sends you back to Step 1 or Step 2; those loops are part of the same run and their notes must survive.

While working through Steps 1-8, whenever one of the following occurs, immediately append a line to that file — do not wait until the end to reconstruct these from memory:

- The confirmed Condition / Expected / Actual differs from what the user first reported, or the documentation conflicted with the report and you resolved which is correct → **Bug report clarifications**
- You established — or later revised — which line(s) or logic are responsible and why they misbehave, including when the fix actually applied differs from the one formulated in Step 5 → **Root cause**
- You investigated a suspected cause, code path, or reproduction approach and eliminated it → **Ruled out**
- You considered alternatives and chose one, and why → **Tradeoffs**
- You modified or deleted test code that was already committed, and why → **Test changes**

Append with `Bash` so the shell expands `$CLAUDE_CODE_SESSION_ID` — the `Write` tool cannot append and does not expand environment variables:

```bash
cat >> "/tmp/fix-bug-notes-$CLAUDE_CODE_SESSION_ID.md" <<'EOF'
- **Root cause**: <one line>
EOF
```

When a step delegates to a subagent or another skill (`test-designer` in Step 2; `test-deduplicator`, `/simplify`, and `/resolve-diagnostics` in Step 8), append the note yourself from what it returns — they do not write to this file.

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

Launch the `test-designer` agent to design the reproduction test case — do not design it in the main context; the agent is pinned to Opus so test design stays on the stronger model even when the implementation model is faster. Use the following prompt structure:

```
## Requirements
[Bug report from Step 1: Condition / Expected / Actual.
Task type: bug-fix — design a reproduction test and regression tests per the reproduction-tests section of the guide.]

## Implementation Design
[Existing class/method structure of the affected production code, from the Explore results — this is the design; there is no new design for a bug fix]

## Existing Code Context
[Nearby test files, test classes, and conventions found above]

## Language Convention
[Project language resolved from CLAUDE.md; default English]
```

From the agent's output, take the test case marked `(reproduction test)`. Keep any regression test cases for Step 6 — do not implement them yet.

Then load the `test-writing-guide` skill and implement the reproduction test. Place it near the similar tests found above.

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

1. Start from the regression test cases the `test-designer` agent produced in Step 2 (if Step 2 ran)
2. Read the test files for the affected production code
3. Identify behaviors that could regress from the change but are not currently tested
4. If gaps exist, add regression tests (per `test-writing-guide`) and run them — they must **pass**
   (they test existing correct behavior, not the bug itself)

### Step 7: Apply Fix & Verify

1. Load the `code-writing-guide` skill — do not rely on automatic skill triggering
2. Apply the fix formulated in Step 5 to the production code
3. Run all affected tests using `/run-tests`
4. Confirm:
   - The reproduction test now **passes** (bug is fixed)
   - All regression tests still **pass**
5. Commit production code fix to git (includes regression tests from Step 6 and any unavoidable changes to the reproduction test)

### Step 8: Refactoring

1. Launch `test-deduplicator` agent with: list of test files added or modified in this iteration
2. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
3. Re-run tests using `/run-tests` command to confirm they still pass
4. Run `/resolve-diagnostics` with the files added or modified in this iteration — compute the list **after** the `test-deduplicator` agent and `/simplify` finish, so their edits are covered too
5. Re-run tests using `/run-tests` command to confirm they still pass
6. Commit all remaining changes to git

### Step 9: Implementation Notes

1. Resolve the notes file path with `Bash` (`echo "/tmp/fix-bug-notes-$CLAUDE_CODE_SESSION_ID.md"`), then `Read` the resolved literal path if it exists — the `Read` tool does not expand environment variables
2. Report the entries to the user in chat under an `## Implementation Notes` heading — one bold sub-heading per category, each followed by a bullet list. Always include all six categories in this order: **Bug report clarifications**, **Root cause**, **Ruled out**, **Tradeoffs**, **Test changes**, **Open questions**. Write `- None` for any category with nothing recorded, and add any last-minute Open questions before finalizing. If the file was never created, report every category as "None"
3. Delete the temporary notes file if it exists
