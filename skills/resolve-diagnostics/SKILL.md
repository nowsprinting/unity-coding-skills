---
name: resolve-diagnostics
description: >-
  Resolves IDE diagnostics (inspections and analyzer findings) at the `warning` or higher severity
  level for a given set of files, then applies the solution's code style. Use this skill when a
  workflow's refactoring step calls for resolving diagnostics, or when the user asks to fix
  warnings, inspections, or static analysis findings in specific files.
  Typically invoked as `/resolve-diagnostics <PATH>`.
argument-hint: "[file paths]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Resolves IDE diagnostics at the `warning` or higher severity level for the given files, reformats
them to the solution's code style, then runs the tests.

## Input

One or more file path arguments. Resolve them to a concrete set of files, then:

- Keep only `.cs` files that belong to the current Unity solution — they are the only ones that
  carry IDE diagnostics, and `reformat_file` requires solution membership.
- Drop everything else (docs, `.meta`, `.asmdef`, assets, files outside the solution).
- Normalize the remaining paths to project/solution-root-relative form, once, up front —
  `lint_files`, `get_file_problems`, and `reformat_file` all expect that form.

If no path argument is given, use `AskUserQuestion` to ask the user for the targets. Do not derive
targets from `git status` — that would silently widen the scope beyond what was requested.

If no files remain after filtering, stop and report that — there is nothing to resolve.

## Workflow

### Step 1: Load the Coding Guide

1. Load the `code-writing-guide` skill — do not rely on automatic skill triggering. Every fix
   applied in Step 2 must follow it.
2. Read its `resources/diagnostics-review-feedback.md` now, **before collecting any diagnostics**
   in Step 2 — do not wait for its `## Resources` bullet to be reached incidentally; a diagnostic
   fix decision must never be made before this file has been read in this run.

Never leave a `warning`-or-higher diagnostic unaddressed — each one is either fixed or explicitly
suppressed per the criteria just read.

### Step 2: Resolve Diagnostics

Resolve diagnostics at the `warning` or higher severity level, collecting them for all resolved
files via `lint_files` rather than one file at a time. Both `lint_files` and its fallback
`get_file_problems` require Rider 2026.2 or later.

1. `lint_files` — pass every resolved file in one call
   - If the call errors, fall back to `get_file_problems`, called once per file
   - On a `timedOut` or `more` result, retry the outstanding file(s) with `get_file_problems`
   - If a timeout persists, use `AskUserQuestion` to confirm the user is running Rider 2026.2 or
     later before retrying further
   - Files reported as not analyzed carry into Step 5 as skipped
2. Decide each diagnostic per the criteria read in Step 1, and apply all resulting changes as a
   single set per file
   - When a fix is a rename (naming-convention inspections) or a symbol removal (unused-member
     findings), apply it via `rename_refactoring` / `safe_delete` so references are updated across
     the solution

Do not use `mcp__ide__getDiagnostics` (limited to files open in editor tabs) or the Unity compiler
output (does not reflect `.editorconfig` severity settings).

### Step 3: Reformat

Call `reformat_file` once with the full list of files resolved in Input (not one call per file),
passing `rootFolder` as the project/solution root.

### Step 4: Run Tests

If any file was modified in Step 2 — a fix or a suppression — load the `run-tests` skill (do not
rely on automatic skill triggering) and run the tests for the affected assemblies, then confirm they
still pass. Step 3's reformatting alone does not change behavior, so skip this step when Step 2
applied no changes.

### Step 5: Report Suppressions and Known-Issue Items

If any diagnostic was suppressed rather than fixed, list each one for the user together with its
reason. The suppression site itself already carries a "why not" comment per the Step 1 criteria.

Also list any files skipped in Step 2 as not analyzed, together with the reason given.

Also list any diagnostics handled under the Gotchas below, each with the user-verification request
described there.

## Gotchas

Known issues in `lint_files` / `get_file_problems` as of Rider 2026.2.1:

- [RIDER-142275](https://youtrack.jetbrains.com/issue/RIDER-142275): inspections from ReSharper
  plugins are returned with an empty description. Do not guess what such a diagnostic means or
  attempt a fix — leave it as is, and in Step 5 ask the user to open the file in the editor and
  check what the inspection actually reports (e.g., whether it is a complexity finding).
- [RIDER-142276](https://youtrack.jetbrains.com/issue/RIDER-142276): Roslyn analyzer diagnostics
  that are already suppressed in source are still reported. Once a `#pragma warning disable` for
  the diagnostic is in place, treat it as resolved and move on even if the tools keep reporting
  it — do not re-fix or re-suppress. In Step 5, ask the user to confirm the suppression is
  effective in the editor.
