---
name: refine-tests
description: >-
  Reviews existing test code for conformance to the test-designing-guide and
  test-writing-guide, then applies the refinements. Use this skill when the
  user wants to review or refine existing test code so it follows the
  project's test design and writing conventions.
  Typically invoked as `/refine-tests <PATH>`.
argument-hint: "[file paths]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Reviews existing test code for conformance to the test-designing-guide and test-writing-guide, then applies the refinements.

## Scope Check

This skill is for refining **existing** tests for conformance to the guides. If the request is out of scope, redirect:

- Adding tests for a new feature or spec change → use `/plan-feature` instead
- A failing test, or a test that verifies incorrect behavior → use `/fix-bug` instead

## Input

One or more file path arguments. Resolve them to the concrete set of test files to review before proceeding.

If no path argument is given, use `AskUserQuestion` to ask the user for the targets. Do not derive targets from `git status` — that would silently widen the scope beyond what was requested.

## Workflow

**Recording implementation notes:** Notes for this run go in `/tmp/refine-tests-notes-$CLAUDE_CODE_SESSION_ID.md`. Immediately before your **first** append in this run — and only then — delete that file if it exists (usually it will not), so this run starts from an empty one: the session id is shared by every `/refine-tests` run in the session, so an earlier run abandoned before Step 7 would otherwise leak its notes into this one.

While working through Steps 5–6, whenever one of the following occurs, immediately append a line to that file — do not wait until the end to reconstruct these from memory:

- A Finding was ambiguous, or proved wrong once applied, and you made a judgment call → **Design decisions**
- You intentionally departed from a Finding, and why → **Deviations**
- You considered alternatives and chose one, and why → **Tradeoffs**
- You changed production code — a method demoted to `private`, a dead test-only seam removed, or any other production edit — and why → **Production code changes**

Append with `Bash` so the shell expands `$CLAUDE_CODE_SESSION_ID` — the `Write` tool cannot append and does not expand environment variables:

```bash
cat >> "/tmp/refine-tests-notes-$CLAUDE_CODE_SESSION_ID.md" <<'EOF'
- **Production code changes**: <one line>
EOF
```

When a step delegates to another skill (`/simplify` and `/resolve-diagnostics` in Step 6), append the note yourself from what it returns — they do not write to this file.

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
   c. **Otherwise (consolidatable into public)** → Finding: rewrite the test to assert the same observable outcome through the public method (merge with an existing public-seam test where natural). The Finding must name explicitly: the target **public method** to go through, the **existing public-seam test to merge into** (or state that a new test method is created, with its name), and the **observable outcome to assert** — the implementer applies the Finding as written and must not need to re-derive these decisions.

**Pass 2 — visibility sweep:** for each `internal` method whose direct internal test goes away in Pass 1 (deleted via 1 or moved via 2c), search the **whole solution** for usages (`internal` is visible cross-assembly via `InternalsVisibleTo` — check other production and test assemblies, not just files in scope):
- Test-only seam wrapped in `#if UNITY_INCLUDE_TESTS`, test now gone → Finding: remove the dead seam.
- Nothing outside the declaring class still needs `internal` access → Finding: demote the method to `private` (do not break any `#if` conditional compilation).
- Any doubt, or any remaining cross-assembly `internal` use → leave it `internal`; no Finding.

Pass 2 Findings change **production** code — record the file path + method explicitly.

### Step 5: Modify Tests

1. Load the `test-writing-guide` skill — and the `code-writing-guide` skill if the Findings include production changes; do not rely on automatic skill triggering
2. Apply the changes described in the Findings list from Steps 2–4 — test edits, plus any production visibility changes (a method demoted to `private`, or a dead test-only seam removed)
3. Run tests with `/run-tests` and confirm **all pass**

### Step 6: Refactoring

1. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
2. Run tests with `/run-tests` and confirm **all pass**
3. Run `/resolve-diagnostics` with the files modified in Step 5 — compute the list **after** `/simplify` finishes, so its edits are covered too
4. Commit all remaining changes to git

### Step 7: Implementation Notes

1. `Read` `/tmp/refine-tests-notes-$CLAUDE_CODE_SESSION_ID.md` if it exists — if it was never created, every category is "None"
2. Report its entries to the user in chat under `## Implementation Notes` — one bold sub-heading per category, each followed by a bullet list. Always include all five categories in this order: **Design decisions**, **Deviations**, **Tradeoffs**, **Production code changes**, **Open questions**. Write `- None` for any category with nothing recorded, and add any last-minute Open questions before finalizing
3. Delete the temporary notes file if it exists
