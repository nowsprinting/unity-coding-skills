---
name: refine-tests
description: >-
  Reviews existing test code for conformance to the test-designing-guide and
  test-writing-guide, then produces a refinement plan. Use this skill in plan
  mode when the user wants to review or refine existing test code (a single
  test file or a directory of tests) so it follows the project's test design
  and writing conventions. Typically invoked as `/refine-tests <path>`.
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Reviews existing test code for conformance to the test-designing-guide and test-writing-guide, then produces a refinement plan.

## Mode Check

This skill requires **plan mode**. Before doing anything else, check the current mode:

- `ExitPlanMode` is in the deferred tools list → **not in plan mode** → stop immediately and tell the user:
  > "This skill (`/refine-tests`) requires plan mode. Enter plan mode first: use `/plan` or press Shift+Tab to toggle."
- `ExitPlanMode` is NOT in the deferred tools list (i.e., directly callable) → in plan mode → proceed.

## Scope Check

This skill is for refining **existing** tests for conformance to the guides. If the request is out of scope, redirect:

- Adding tests for a new feature or spec change → use `/plan-feature` instead
- A failing test, or a test that verifies incorrect behavior → use `/fix-bug` instead

## Input

One or more target path arguments. Each may be a single test file, a directory (resolved recursively to its test files), or a glob. Resolve the argument(s) to the concrete set of test files to review before proceeding.

## Workflow

### Phase 1: Read the Target Tests

Launch Explore agent(s) to read the target test file(s) and the production code they exercise. Reading the production code is necessary to judge layer-appropriateness and structural-vs-spec-based issues.

### Phase 2: Conformance Review

Load the `test-designing-guide` and `test-writing-guide` skills. Apply all rules that are **verifiable from the test code alone** — no requirements document is available.

The following sections of `test-designing-guide` require requirements input or production-design changes and are **out of scope**:
- Section 5 (requirements coverage / traceability / same-layer witness)
- Section 6 (design-document output format)
- Section 7 (Testability Assessment — remedies require production-design changes)

Produce a **Findings** list. Each finding records:
- Location: file path + test method name
- Category: which guide + rule violated, or *duplicate test* (see Phase 3)
- Concrete proposed change

### Phase 3: Duplicate Detection

Compare the target test files against each other and against other tests in the same test class.

A **true duplicate** has **both** of the following in common with another test:
- **Same condition** — identical setup / input
- **Same assertion** — identical observation / expected value

Do NOT flag tests that share only one:
- Different condition → not a duplicate
- Same condition but different assertion → not a duplicate

For each true duplicate pair, append a Finding to the Findings list from Phase 2:
- Proposed change: delete the redundant test (the less accurately named one) and keep the more accurately named one. Name both explicitly.
- Do NOT propose merging same-condition tests into a single multi-assert test.

### Phase 4: Review

Read the critical test files. Confirm the proposed changes in the Findings list are consistent with each other and that each change preserves what the test verifies. Also cross-check duplicate findings (Phase 3) against conformance findings (Phase 2): a test slated for rename must not also be the redundant side of a duplicate finding.

### Phase 5: Write the Plan File

Assemble the plan file with these sections:

1. **Context** — what is being refined and why
2. **Findings** — the Phase 2 list (location / rule / proposed change)
3. **Refine Workflow** — paste the **Template** from `## Refine Workflow` verbatim as the body of this section

### Phase 6: Call ExitPlanMode

---

## Refine Workflow

Paste the **Template** below verbatim as the body of the `## Refine Workflow` section in the plan file.

### Template

```markdown
### Step 1: Modify Tests

1. Apply the test changes described in the Findings section
2. Run tests with `/run-tests` and confirm **all pass**

### Step 2: Refactoring

1. Resolve diagnostics at the `warning` or higher severity level using the following procedure,
   **one file at a time** — `mcp__ide__getDiagnostics` only returns results for files currently open
   in editor tabs, and opening all files at once exceeds the tab limit:
   1. `mcp__jetbrains__open_file_in_editor` — open the file in the editor
   2. `mcp__ide__getDiagnostics` — collect all diagnostics for that file
   3. Fix all reported issues as a single set before moving to the next file

   Use `mcp__ide__getDiagnostics` instead of `mcp__jetbrains__get_file_problems` (unstable) or
   the Unity compiler output (does not reflect `.editorconfig` severity settings).
2. Run tests with `/run-tests` and confirm **all pass**
3. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
4. Run tests with `/run-tests` and confirm **all pass**
5. Commit all remaining changes to git
```
