### Step 1: Modify Tests

1. Load the `test-writing-guide` skill — and the `code-writing-guide` skill if the Findings include production changes; do not rely on automatic skill triggering
2. Apply the changes described in the Findings section — test edits, plus any production visibility changes (a method demoted to `private`, or a dead test-only seam removed)
3. Run tests with `/run-tests` and confirm **all pass**

### Step 2: Refactoring

1. Resolve diagnostics at the `warning` or higher severity level using the following procedure, **one file at a time** — `mcp__ide__getDiagnostics` only returns results for files currently open in editor tabs, and opening all files at once exceeds the tab limit:
     1. `open_file_in_editor` — open the file in the editor
     2. `mcp__ide__getDiagnostics` — collect all diagnostics for that file. Use `mcp__ide__getDiagnostics` instead of `get_file_problems` (unstable) or the Unity compiler output (does not reflect `.editorconfig` severity settings).
     3. Fix all reported issues as a single set before moving to the next file
2. Run tests with `/run-tests` and confirm **all pass**
3. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
4. Run tests with `/run-tests` and confirm **all pass**
5. Commit all remaining changes to git
