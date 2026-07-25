### Step 1: Modify Tests

1. Load the `test-writing-guide` skill — and the `code-writing-guide` skill if the Findings include production changes; do not rely on automatic skill triggering
2. Apply the changes described in the Findings section — test edits, plus any production visibility changes (a method demoted to `private`, or a dead test-only seam removed)
3. Run tests with `/run-tests` and confirm **all pass**

### Step 2: Refactoring

1. Run `/resolve-diagnostics` with the files modified in Step 1
2. Run tests with `/run-tests` and confirm **all pass**
3. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
4. Run tests with `/run-tests` and confirm **all pass**
5. Commit all remaining changes to git
