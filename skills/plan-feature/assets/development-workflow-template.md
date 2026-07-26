**Recording implementation notes:** Notes for this run go in `/tmp/plan-feature-notes-<plan-file-basename>.md`, where `<plan-file-basename>` is this plan file's filename without its `.md` extension. Immediately before your **first** append in this run — and only then — delete that file if it exists (usually it will not), so this run starts from an empty one: an earlier execution of this same plan file, abandoned before Step 5, would otherwise leak its notes into this run.

While working through Steps 1-4, whenever one of the following occurs, immediately append a line to that file — do not wait until the end to reconstruct these from memory:

- The spec was ambiguous and you made a judgment call → **Design decisions**
- You intentionally departed from the spec, and why → **Deviations**
- You considered alternatives and chose one, and why → **Tradeoffs**
- You modified or deleted test code already committed in Step 2, and why → **Test changes**

Append with `Bash` — the `Write` tool cannot append:

```bash
cat >> "/tmp/plan-feature-notes-<plan-file-basename>.md" <<'EOF'
- **Design decisions**: <one line>
EOF
```

When a step delegates to a subagent or another skill (`failing-test-writer` in Step 2; `test-deduplicator`, `/simplify`, and `/resolve-diagnostics` in Step 4), append the note yourself from what it returns — they do not write to this file.

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
2. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
3. Run tests with `/run-tests` and confirm **all pass**
4. Run `/resolve-diagnostics` with the files added or modified in Steps 1-3 — compute the list **after** the `test-deduplicator` agent and `/simplify` finish, so their edits are covered too
5. Run tests with `/run-tests` and confirm **all pass**
6. Commit all remaining changes to git

### Step 5: Implementation Notes

1. `Read` `/tmp/plan-feature-notes-<plan-file-basename>.md` if it exists — if it was never created, every category is "None"
2. Organize its entries under `## Implementation Notes` at the end of this plan file — one bold sub-heading per category, each followed by a bullet list. Always include all five categories in this order: **Design decisions**, **Deviations**, **Tradeoffs**, **Test changes**, **Open questions**. Write `- None` for any category with nothing recorded, and add any last-minute Open questions before finalizing
3. Report the same block to the user in chat
4. Delete the temporary notes file if it exists
