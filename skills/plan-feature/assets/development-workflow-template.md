### Step 1: Skeleton (Compilable)

1. Load the `code-writing-guide` skill — the skeleton is production code; do not rely on automatic skill triggering
2. Create types and method signatures only — must compile, need not work yet. **New methods: empty body only** (no logic, no exceptions; value-returning methods must return a literal default: `0`, `false`, or `null`); **modify: signature only, body unchanged**; **delete: remove the entire method** — test code may fail to compile after modify or delete; fix in Step 2. Place each file at the path and in the assembly specified in the Implementation Design section
3. Commit skeleton to git

### Step 2: Test First

1. Launch `failing-test-writer` agent with: path to this plan file
2. Check `STATUS:` line in the `failing-test-writer` output — if `STATUS: NG`, **STOP: do not proceed to Step 3**, report unexpected passes to user
3. Commit test code to git — if test code is modified in Step 3 or later, the integrity of Test First is compromised; commit here without fail so the diff remains verifiable

### Step 3: Implementation

1. Load the `code-writing-guide` skill — do not rely on automatic skill triggering
2. Implement product code
3. Run tests with `/run-tests` and confirm **all pass**
4. Commit product code to Git (including any unavoidable changes to the test code).

### Step 4: Refactoring

1. Launch `test-deduplicator` agent with: list of test files added or modified in Step 2
2. Resolve diagnostics at the `warning` or higher severity level using the following procedure, **one file at a time** — `mcp__ide__getDiagnostics` only returns results for files currently open in editor tabs, and opening all files at once exceeds the tab limit:
     1. `open_file_in_editor` — open the file in the editor
     2. `mcp__ide__getDiagnostics` — collect all diagnostics for that file. Use `mcp__ide__getDiagnostics` instead of `get_file_problems` (unstable) or the Unity compiler output (does not reflect `.editorconfig` severity settings).
     3. Fix all reported issues as a single set before moving to the next file
3. Run tests with `/run-tests` and confirm **all pass**
4. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
5. Run tests with `/run-tests` and confirm **all pass**
6. Commit all remaining changes to git
