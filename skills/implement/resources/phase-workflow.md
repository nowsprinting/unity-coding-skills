# Phase Workflow

Implements the implementation targets of one phase test-first: designs their missing test cases, writes failing tests, then the production code that passes them, and refactors it.

The caller gives you the phase's implementation targets with their specifications and test bases, the implementation targets of the earlier phases (already implemented), the input (the specification and the test design document, if any), the user's instructions on the test techniques, if any, and the notes file.
You cannot ask the user: return `STATUS: QUESTION` instead (see [Report](#report)).

## Notes

As soon as one of the following occurs, append a line to the notes file the caller gives, in the form `<category>: <note>` — your context is gone once you return:

- You designed a class no specification describes, or the specification was ambiguous and you made a judgment call → `Design decisions`
- You intentionally departed from the specification or the software design, and why → `Deviations`
- You considered alternatives and chose one, and why → `Tradeoffs`
- You modified or deleted test code already committed in Step 2, and why → `Test changes`
- An undefined, ambiguous, or unverifiable test case, or an Issue in the Assessment of a given test target → `Open questions`

Append with `Bash` — the `Write` tool cannot append:

```bash
cat >> "<notes file>" <<'EOF'
Design decisions: <one line>
EOF
```

## Step 1: Test Design

Design the test cases before reading any method body of production code: a test case derived from the implementation passes whatever the implementation does.

1. When the input includes a test design document, take from it the test cases of each implementation target of the phase it has
2. Design the test cases of the implementation targets without test cases in a general-purpose subagent, so that the specifications test analysis leaves out stay out of the test design while you keep every specification for the implementation.
   Give it those implementation targets, each with its specifications quoted verbatim, which of them are external specifications, and the requirements they realize, if any, and the user's instructions on the test techniques, if any.
   Instruct it to load the `test-designing-guide` skill — do not rely on automatic skill triggering — and:
   1. Analyze the specifications per the guide's test analysis resource, taking each implementation target as a test target
   2. Design the test cases of each test target per the guide's test design resource: Test Layers, Contained Test Targets, Test Techniques, Test Case Naming, Parameterized Tests, Verification Column, and Existing Tests.
      Mark acceptance tests per the Acceptance Tests section of each test technique's resource, and apply the user's instructions on the test techniques, if any
   3. Assess each test target (Assessment), without the modeling result
   4. Return the test cases, the Assessment, and the specifications the analysis left out with their reasons, verbatim

   When the `Agent` tool is unavailable, e.g., at the subagent depth limit, do what you would instruct the subagent yourself.
3. Design the classes the implementation targets need beyond those the specification fixes — their signatures, dependencies, and file and assembly — and design the test cases of each class per the guide's test design resource, loading the `test-designing-guide` skill yourself

When a test design gives a test target whose Assessment is `❌FAIL`, return `STATUS: QUESTION` with its Issues.

For the test cases you design in item 3, skip the modeling result and the Assessment, and hold the test cases in your context only; instead, settle each problem they would surface:

- A contradiction in the specification, or an acceptance test that is ambiguous or unverifiable → return `STATUS: QUESTION` before writing any code
- A test case you would mark unverifiable under a class you designed → revise the class so that the test can arrange the input and observe the result
- Any other undefined, ambiguous, or unverifiable test case → keep it marked, and write no test code for it

Step 1 is complete when every implementation target of the phase and every class you designed has its test cases; when the test design document gives them all and you design no class, it needs nothing beyond item 1.

## Step 2: Test First

1. Load the `code-writing-guide` and `test-writing-guide` skills — test code is code, so both guides apply; do not rely on automatic skill triggering
2. Write the skeleton of the production code: types and method signatures only — must compile, need not work yet.
   **New methods: empty body only** (no logic, no exceptions; value-returning methods must return a literal default: `0`, `false`, or `null`); **modify: signature only, body unchanged**; **delete: remove the entire method**.
   For a `ScriptableObject` class with a validator, also declare the fields the validator reads.
   Place each file at the path and in the assembly of the software design
3. Write the test code of the test cases, including the updates to existing tests tagged `test fix` or `spec change`, and list the test bases of its test target in each test file (`test-writing-guide`, Test Basis).
   Use the real classes of the earlier phases as the dependencies of the test targets.
   When the structure of the existing production code keeps a test case from being written as designed, e.g., a class creates its dependency itself, weigh the approaches *Working Effectively with Legacy Code* (Michael Feathers) gives and take the one that fits; when none fits, return `STATUS: QUESTION` with the approaches you weighed
4. Run the added and modified tests with `/run-tests` and confirm they **fail**.
   A test tagged `test fix` or `spec change` whose expected result stays the same may pass — only its name, arguments, or construction changed.
   A validator may pass too: it verifies the data of the assets, not the production code, so assets that already satisfy the specification pass it.
   A new test that runs no method the skeleton added may pass too: the production code from before this phase already produces its expected result, e.g., for a test case of an unchanged specification that no existing test covered.
   A new test whose expected result is what an empty body already gives — the literal default it returns, or no state change, event, or call — may pass too, e.g., `CanAttack_HpIsZero_ReturnsFalse` against `return false`.
   When any other test passes, return `STATUS: BLOCKED` with the unexpected passes.
   When the tests fail to compile repeatedly, return `STATUS: BLOCKED` with the blocker rather than looping
5. Commit the skeleton and the test code to git — if test code is modified in Step 3 or later, the integrity of Test First is compromised; commit here without fail so the diff remains verifiable

## Step 3: Implementation

1. Implement the production code of every specification of the implementation targets, including those without test cases: no test fails when one of them is missing
2. Run tests with `/run-tests` and confirm **all pass**
3. Commit the production code to git (including any unavoidable changes to the test code)

## Step 4: Refactoring

1. Run the Claude Code built-in `/simplify` skill (`Skill({skill: "simplify"})` — not a plugin skill) to apply quality improvements to the modified code
2. Run tests with `/run-tests` and confirm **all pass**
3. Run `/resolve-diagnostics` with the files added or modified in Steps 2-3 — compute the list **after** `/simplify` finishes, so its edits are covered too
4. Commit all remaining changes to git

## Report

Return a report with the `STATUS:` line first:

```
STATUS: DONE      ← all steps completed
STATUS: QUESTION  ← a step found a problem only the user can settle, e.g., a skill it loads says to consult the user
STATUS: BLOCKED   ← Step 2 found an unexpected pass or a compile blocker
```

Then:

- For `STATUS: QUESTION`: each issue with the affected specification and a proposed remedy
- For `STATUS: BLOCKED`: the tests that passed unexpectedly and why they were not judged legitimate, or the blocker
- For `STATUS: DONE`: the classes added or modified, and the commits
