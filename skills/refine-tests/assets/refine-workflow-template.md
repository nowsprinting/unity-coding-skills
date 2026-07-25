**Recording implementation notes:** Notes for this run go in `/tmp/refine-tests-notes-<plan-file-basename>.md`, where `<plan-file-basename>` is this plan file's filename without its `.md` extension. Immediately before your **first** append in this run — and only then — delete that file if it exists (usually it will not), so this run starts from an empty one: an earlier execution of this same plan file, abandoned before Step 3, would otherwise leak its notes into this run.

While working through Steps 1-2, whenever one of the following occurs, immediately append a line to that file — do not wait until the end to reconstruct these from memory:

- A Finding was ambiguous, or proved wrong once applied, and you made a judgment call → **Design decisions**
- You intentionally departed from a Finding, and why → **Deviations**
- You considered alternatives and chose one, and why → **Tradeoffs**
- You changed production code — a method demoted to `private`, a dead test-only seam removed, or any other production edit — and why → **Production code changes**

Append with `Bash` — the `Write` tool cannot append:

```bash
cat >> "/tmp/refine-tests-notes-<plan-file-basename>.md" <<'EOF'
- **Production code changes**: <one line>
EOF
```

When a step delegates to another skill (`/resolve-diagnostics` and `/simplify` in Step 2), append the note yourself from what it returns — they do not write to this file.

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

### Step 3: Implementation Notes

1. `Read` `/tmp/refine-tests-notes-<plan-file-basename>.md` if it exists — if it was never created, every category is "None"
2. Organize its entries under `## Implementation Notes` at the end of this plan file — one bold sub-heading per category, each followed by a bullet list. Always include all five categories in this order: **Design decisions**, **Deviations**, **Tradeoffs**, **Production code changes**, **Open questions**. Write `- None` for any category with nothing recorded, and add any last-minute Open questions before finalizing
3. Report the same block to the user in chat
4. Delete the temporary notes file if it exists
