---
name: fix-bug
description: >-
  Diagnoses and fixes bugs using a test-first workflow (reproduce, diagnose, fix).
  Use this skill whenever the user reports a bug, describes unexpected behavior, or asks to
  investigate or fix a defect. Even if the user says "something's broken", "this isn't working",
  "fix this bug", or "why does X happen", load this skill to guide the full
  reproduce → diagnose → fix cycle.
  Typically invoked as `/fix-bug [INCIDENT]`.
argument-hint: "[incident, failing test name, file paths, or issue URLs]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for diagnosing and fixing bugs.
This skill defines a test-first debugging workflow: reproduce the bug with a failing test, diagnose the root cause, then fix it.

## Task Type Check

If the user's request is to implement a new feature, change a specification, or refactor rather than investigate or fix a bug, stop and guide the user to invoke the `/implement` skill instead.

## Input

Take the bug report from the `INCIDENT` argument: the report written directly, the name of a failing test, file paths, or the URLs of issues in an issue tracker, in any combination.
For an issue URL, fetch its body and comments (e.g., `gh issue view <URL> --comments` for GitHub Issues): the comments often correct the body.
When the argument is omitted, take it from the conversation.

## Workflow

**Recording implementation notes:** Notes for this run go in `<scratchpad>/implementation-notes`, where `<scratchpad>` is the scratchpad directory listed in your system prompt (write its absolute path literally): one note per line, in the form `<category>: <note>`.
Immediately before your **first** append in this run — and only then — delete that file if it exists (usually it will not), so this run starts from an empty one: every `/fix-bug` and `/implement` run in the session shares this file, so an earlier run abandoned before its Implementation Notes step would otherwise leak its notes into this one.
Never delete it again afterwards, including when Step 3 sends you back to Step 1 or Step 2; those loops are part of the same run and their notes must survive.

While working through Steps 1-8, whenever one of the following occurs, immediately append a line to that file — do not wait until the end to reconstruct these from memory:

- The confirmed Condition / Expected / Actual differs from what the user first reported, or the documentation conflicted with the report and you resolved which is correct → **Bug report clarifications**
- You established — or later revised — which line(s) or logic are responsible and why they misbehave, including when the fix actually applied differs from the one formulated in Step 5 → **Root cause**
- You investigated a suspected cause, code path, or reproduction approach and eliminated it → **Ruled out**
- You considered alternatives and chose one, and why → **Tradeoffs**
- You modified or deleted test code that was already committed, and why → **Test changes**
- A test design you take test cases from has Issues in its Assessment, or a test case marked unverifiable, undefined, or ambiguous → **Open questions**

Append with `Bash` — the `Write` tool cannot append:

```bash
cat >> "<scratchpad>/implementation-notes" <<'EOF'
Root cause: <one line>
EOF
```

When a step delegates to a subagent or another skill (the test design subagent in Step 6; `/simplify` and `/resolve-diagnostics` in Step 8), append the note yourself from what it returns — they do not write to this file.

### Step 1: Clarify the Bug Report

> Work from the user's report and the documents that state the specification (external specification, software design) only — do not read code yet.
> Reading the implementation here biases "Expected" toward what the code does rather than what the specification says.

Extract the following from the bug report (see [Input](#input)):

- **Condition**: the setup or scenario that triggers the bug
- **Expected**: the expected behavior
- **Actual**: the observed behavior

If any of the three cannot be determined from the bug report, use `AskUserQuestion` to ask the user before proceeding.
All three must be known before moving to Step 2.

Also determine the **report type**:

- **Existing test failure** — the user reports that an existing test is failing.
  The specific failing test method need not be known at this stage; note the scope (class name, scene name, or test assembly) from the bug report.
  **Step 2 is skipped** — proceed directly to Step 3.
- **Behavioral bug** — the user describes unexpected runtime behavior with no mention of a failing test.
  Proceed normally through Step 2.

Also check the relevant documentation (external specification, software design) for consistency with the user's bug report.
If the documentation and the report conflict, use `AskUserQuestion` to clarify with the user which is correct.
If the user answers that the specification itself is to change, rather than that the documentation misstates it, the request is a specification change: stop and guide the user to invoke the `/implement` skill instead.
If the docs contain errors or are missing relevant information, add them to the list of files to be modified in this bug fix.

### Step 2: Write the Reproduction Test

> **Skip this step** if Step 1 identified this as an **existing test failure** case.
> Proceed directly to Step 3.

Search the project's test code for existing tests closest to the bug scenario.
These serve two purposes:
- Placement anchor — add the reproduction test nearby
- Style reference — follow the same test conventions

**When the bug condition involves on-screen display or a user-facing UI operation**, search for **integration tests with UI operations or visual verification tests** — the reproduction test must be at that layer, so the placement anchor and style reference must be too.

Use Explore agents to locate relevant test files and test cases.

Load the `test-designing-guide` skill — do not rely on automatic skill triggering — and design the reproduction test of the bug report from Step 1 (Condition / Expected / Actual) per its Reproduction tests resource.
Design no regression test cases: Step 6 designs them against the code the fix changes, which is unknown until Step 5.
Skip the Assessment; when the reproduction test case would be unverifiable, undefined, or ambiguous, return to Step 1 and re-clarify the bug report with the user via `AskUserQuestion`.

Then load the `test-writing-guide` and `code-writing-guide` skills — test code is code, so both guides apply; do not rely on automatic skill triggering — and implement the reproduction test.
Place it near the similar tests found above.

If an existing test is testing the wrong behavior (i.e., the test itself is buggy), rewrite that test to correctly reproduce the bug rather than adding a new one.

### Step 3: Verify the Reproduction Test Fails

Run tests using the `/run-tests` skill and verify that the reproduction test **fails**:

- **If a test was added in Step 2**: run that specific test.
- **If Step 2 was skipped (existing test failure)**: narrow down the test to run using the scope identified in Step 1 (e.g., a specific test class or assembly).
  If narrowing down is not possible, run all tests.

If multiple tests fail and it is unclear which one corresponds to the reported bug, use `AskUserQuestion` to ask the user which test to focus on.

#### If the test does not fail (Step 2 path only)

- Delete the reproduction test
- Return to Step 2 and search more broadly

If reproduction has been attempted **3 times** without success, return to **Step 1** and use `AskUserQuestion` to re-clarify the bug report with the user.

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
3. Write a unit-level reproduction test that calls the suspected code directly (per `test-writing-guide`; load it and `code-writing-guide` if Step 2 was skipped — do not rely on automatic skill triggering), and run it with `/run-tests` to verify it **fails** — this confirms the suspected cause before changing the production code, and pins the defect at the unit layer where the Step 2 test cannot locate it.
   Take its expected result from the specification of the called code — the documentation from Step 1, or its XML documentation comment — not from the code traced in items 1-2: an expected result derived from the implementation passes whatever the implementation does.
   If it passes, the suspect is wrong: delete the test, record it under **Ruled out**, and return to item 1.
   Skip this item when the cause lies outside code a unit test can call (e.g., scene/prefab wiring or asset settings)
4. Commit the unit-level reproduction test, for the same reason as Step 4
5. Formulate a fix

### Step 6: Regression Test Coverage

Before applying the fix, cover the adjacent behavior the fix could disturb:

1. Run a general-purpose subagent that loads the `test-designing-guide` skill — do not rely on automatic skill triggering — and designs the test cases of each test target the fix formulated in Step 5 changes, e.g., the class that owns the changed lines.
   Give it the test targets, the documentation from Step 1 — its file path, or the full text when it came from the conversation — and the user's instructions on the test techniques, if any (e.g., error guessing); have it return the test cases verbatim.
   Designing in a subagent keeps the method bodies you read in Step 5 out of the test design: a test case derived from the implementation passes whatever the implementation does
2. Read the test files for the affected production code
3. From the returned test cases, choose those that verify behavior the fix could disturb and no existing test covers
4. Add regression tests for them (per `test-writing-guide`) and run them — they must **pass** (they test existing correct behavior, not the bug itself).
   Write no test code for a test case marked unverifiable, undefined, or ambiguous

### Step 7: Apply Fix & Verify

1. Load the `code-writing-guide` skill — do not rely on automatic skill triggering
2. Apply the fix formulated in Step 5 to the production code
3. Run all affected tests using `/run-tests`
4. Confirm:
   - The reproduction tests from Step 2 and Step 5 now **pass** (bug is fixed)
   - All regression tests still **pass**
5. Commit production code fix to git (includes regression tests from Step 6 and any unavoidable changes to the reproduction test)

### Step 8: Refactoring

1. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
2. Re-run tests using `/run-tests` command to confirm they still pass
3. Run `/resolve-diagnostics` with the files added or modified in this iteration — compute the list **after** `/simplify` finishes, so its edits are covered too
4. Commit all remaining changes to git

### Step 9: Implementation Notes

1. `Read` `<scratchpad>/implementation-notes` if it exists
2. Report the notes to the user in chat under an `## Implementation Notes` heading — one bold sub-heading per category, each followed by a bullet list.
   Always include all six categories in this order: **Bug report clarifications**, **Root cause**, **Ruled out**, **Tradeoffs**, **Test changes**, **Open questions**.
   Write `- None` for any category with nothing recorded, and add any last-minute Open questions before finalizing.
   If the file was never created, report every category as "None"
3. Delete the temporary notes file if it exists
