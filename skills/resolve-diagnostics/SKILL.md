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

Resolves IDE diagnostics at the `warning` or higher severity level for the given files, then
reformats them to the solution's code style.

## Input

One or more file path arguments. Resolve them to a concrete set of files, then:

- Keep only `.cs` files that belong to the current Unity solution — they are the only ones that
  carry IDE diagnostics, and `reformat_file` requires solution membership.
- Drop everything else (docs, `.meta`, `.asmdef`, assets, files outside the solution).
- Normalize the remaining paths to project/solution-root-relative form, once, up front —
  `open_file_in_editor` and `reformat_file` both expect that form.

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

Resolve diagnostics at the `warning` or higher severity level, **one file at a time** —
`mcp__ide__getDiagnostics` only returns results for files currently open in editor tabs, and opening
all files at once exceeds the tab limit:

1. `open_file_in_editor` — open the file in the editor
2. `mcp__ide__getDiagnostics` — collect all diagnostics for that file
3. Decide each diagnostic per the criteria read in Step 1, and apply all resulting changes as a
   single set before moving to the next file

Use `mcp__ide__getDiagnostics` instead of `get_file_problems` (unstable) or the Unity compiler
output (does not reflect `.editorconfig` severity settings).

### Step 3: Reformat

Call `reformat_file` once with the full list of files resolved in Input (not one call per file),
passing `rootFolder` as the project/solution root.

### Step 4: Report Suppressions

If any diagnostic was suppressed rather than fixed, list each one for the user together with its
reason. The suppression site itself already carries a "why not" comment per the Step 1 criteria.
