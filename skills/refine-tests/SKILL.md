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

Reviews existing test code for conformance to the test-designing-guide and test-writing-guide, detects `[Category("Internal")]` tests over-promoted for testability and moves them to the public seam (demoting now-unneeded `internal` methods to `private`), then produces a refinement plan.

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

### Step 1: Read the Target Tests

Launch Explore agent(s) to read the target test file(s) and the production code they exercise. Reading the production code is necessary to judge layer-appropriateness and structural-vs-spec-based issues.

### Step 2: Conformance Review

Load the `test-designing-guide` and `test-writing-guide` skills. Apply all rules that are **verifiable from the test code alone** — no requirements document is available.

The following sections of `test-designing-guide` require requirements input or production-design changes and are **out of scope**:
- Section 5 (requirements coverage / traceability / same-layer witness)
- Section 6 (design-document output format)
- Section 7 (Testability Assessment — remedies require production-design changes)

Produce a **Findings** list. Each finding records:
- Location: file path + test method name
- Category: which guide + rule violated, or *duplicate test* (see Step 3)
- Concrete proposed change

### Step 3: Duplicate Detection

Compare the target test files against each other and against other tests in the same test class.

A **true duplicate** has **both** of the following in common with another test:
- **Same condition** — identical setup / input
- **Same assertion** — identical observation / expected value

Do NOT flag tests that share only one:
- Different condition → not a duplicate
- Same condition but different assertion → not a duplicate

For each true duplicate pair, append a Finding to the Findings list from Step 2:
- Proposed change: delete the redundant test (the less accurately named one) and keep the more accurately named one. Name both explicitly.
- Do NOT propose merging same-condition tests into a single multi-assert test.

**Exception — defer to Step 4:** If one test in a duplicate pair is `[Category("Internal")]` and the other is a public-seam test, do **not** apply the name-quality tiebreaker here. Do not delete the public-seam test on naming grounds. Defer the pair to Step 4, which always keeps the public-seam test.

### Step 4: Seam Redundancy — Internal-Method Tests

Test through the same seam production code uses. A `[Category("Internal")]` test exercises an `internal` method directly. For each such test in the targets, append Findings via two passes. Overriding rule: **never trade coverage for a tidier seam; when in doubt, keep the test (and keep `internal`).**

**Layer scope:** This step operates within the **unit test layer only**. Tests marked `[Category("Integration")]` or `[Category("VisualVerification")]` run under different execution contexts and are not candidates for a covering test — do not consider them when searching for a public-seam test that covers the same scenario.

**Pass 1 — classify each `[Category("Internal")]` test:**
1. **A public-seam test already covers it** (from the test code alone): a separate **unit** test asserts the **same observable outcome** for an **equivalent scenario** through a **public** method → Finding: delete the internal test, keep the public-seam test (name both).
2. **No public-seam test covers it** — using the production code read in Step 1:
   a. **Not fully observable through public** — a public caller masks or only partially exposes the asserted outcome → keep the internal test; no Finding. "Cheap to extract" ≠ "observable publicly."
   b. **Sanctioned extraction** — the method takes **3 or more parameters** (a heuristic; the real trigger is that several *independent* conditions combine so exhaustive public-seam coverage cost explodes — this can also occur with fewer parameters that each take many values, and may not apply when the extra parameters don't drive branching), **and** it isolates cohesive sub-logic (a pure computation or decision that depends on only 1–2 of those inputs) → keep the internal test; no Finding. Applies regardless of how the test was created.
   c. **Otherwise (consolidatable into public)** → Finding: rewrite the test to assert the same observable outcome through the public method (merge with an existing public-seam test where natural).

**Pass 2 — visibility sweep:** for each `internal` method whose direct internal test goes away in Pass 1 (deleted via 1 or moved via 2c), search the **whole solution** for usages (`internal` is visible cross-assembly via `InternalsVisibleTo` — check other production and test assemblies, not just files in scope):
- Test-only seam wrapped in `#if UNITY_INCLUDE_TESTS`, test now gone → Finding: remove the dead seam.
- Nothing outside the declaring class still needs `internal` access → Finding: demote the method to `private` (do not break any `#if` conditional compilation).
- Any doubt, or any remaining cross-assembly `internal` use → leave it `internal`; no Finding.

Pass 2 Findings change **production** code — record the file path + method explicitly.

### Step 5: Review

Read the critical test files. Confirm the proposed changes in the Findings list are consistent with each other and that each change preserves what the test verifies. Also cross-check duplicate findings (Step 3) against conformance findings (Step 2): a test slated for rename must not also be the redundant side of a duplicate finding. For seam-redundancy findings (Step 4): confirm each moved test still asserts the same observable outcome through the public seam, and each demotion / seam-removal finding has no remaining cross-assembly `internal` user.

### Step 6: Write the Plan File

Assemble the plan file with these sections:

1. **Context** — what is being refined and why
2. **Findings** — the Findings list from Steps 2–4 (location / rule / proposed change; may include production visibility changes)
3. **Refine Workflow** — Read `${CLAUDE_SKILL_DIR}/resources/refine-workflow-template.md` and paste its full contents verbatim as the body of this section

### Step 7: Call ExitPlanMode
