---
name: design-tests
description: >-
  Designs tests from a specification, whatever document states it — a
  requirements document, a software design document, an ADR, or a bug report:
  extracts the test targets, then creates test cases for each target at the
  test layer of its subject — e.g., integration tests for a scene or prefab,
  unit tests for a class's API.
  Use this skill whenever the specification is settled and the next step is to
  design the tests, whether the input is a file path, a specification written
  directly in the argument, or the current conversation.
  Typically invoked as `/design-tests [SPECIFICATION]`.
argument-hint: "[specification or its path]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Produces a test design document: the test cases and the assessment of each test target in the specification.
The test design knowledge lives in the `test-designing-guide` skill; this skill defines the procedure.

## Input

Take the specification to test against from the `SPECIFICATION` argument: either a file path or the specification written directly.
When the argument is omitted, take it from the conversation.
The argument or the conversation may also include instructions on the test techniques to apply, e.g., combinatorial testing.
If no specification can be found, use `AskUserQuestion` to ask the user before proceeding.

In this skill and `test-designing-guide`, the terms mean:

- **Specification** — the observable behavior at the boundary of a unit (a scene, prefab, class, or asset).
  It is relative: the software design of one unit, e.g., a class's method signatures and their contracts, is the specification of the units below it.
  "Specification" names the behavior, never a document.
- **External specification** — the specification at the outermost boundary of the product, as the player or the API user observes it.
- **Requirement** — what users need to hold true, e.g., "defeating an enemy feels satisfying".
  A requirement alone has no pass/fail criterion; the specification that realizes it does.

The input may state the specification in any document: a requirements document, a software design document, an ADR, or a bug report (its Expected is the specification; see `resources/reproduction-tests.md` in `test-designing-guide`).
When the input also states requirements, note which specifications realize them; `test-designing-guide` marks their test cases as acceptance tests.

Read existing code and tests only as `test-designing-guide` allows (Reading Code).

## Rules

- Modify no files other than the output file (Step 5).
  Record a gap or a contradiction in the specification in the target's Assessment instead of editing the input documents.

## Workflow

### Step 1: Extract Test Targets

Read the specification and extract the test targets it covers, e.g.:

- The screen transitions
- A screen
- A character (actor)
- A component (class)
- A `ScriptableObject` class (its methods implemented as unit tests, the constraints on its data as a validator)

Extract only targets the specification describes; do NOT derive targets at a level no specification describes — e.g., internal classes guessed from the external specification of a screen — because such tests couple to an implementation no specification fixes.
When the input includes a software design, the classes and signatures it fixes are specifications, and are valid targets.

Assign each specification to exactly one test target, so that targets designed in parallel do not produce duplicate test cases.
When the subject of one test target contains the subjects of others — e.g., a screen contains the classes placed on it, and the screen transitions contain the screens — assign the behavior within a contained target to that target, and leave the container only the behavior that combines them.
Record the test targets each target contains.

#### Screen Transitions

Extract all the screen transitions as a single test target, whatever form the specification gives them in — a screen transition diagram, a sequence, a use case, or button operations written per screen.

#### ScriptableObject Classes

Extract a `ScriptableObject` class as one test target holding both the specifications of its methods (unit tests) and the constraints the specification states on its data (a validator); each constraint is a property of one asset (see `resources/validators.md` in `test-designing-guide`).
The unit tests and the validator then share the equivalence partitions of the fields both refer to, and a gap in a field reaches the user as one issue.
A table listing each asset's concrete values is the source the assets are authored from, not a specification: extract no constraint from it.

### Step 2: Design Each Test Target

Design each test target in its own general-purpose subagent, launched in parallel, so the working material of one target stays out of the others' context.
Instruct each subagent to load the `test-designing-guide` skill — do not rely on automatic skill triggering — and apply it:

1. Determine the layer of each of the target's specifications (Test Layers)
2. Model its specifications with test techniques, and derive test cases from the results (Test Techniques)
3. Name the test cases (Test Case Naming) and write their Verification column (Verification Column)
4. Re-check every parameterized row against the one-partition-per-method rule (`resources/equivalence-partitioning.md`, Deriving test methods from equivalence partitions): if substituting any listed value would change the expected result, split the row
5. Assess the target (Assessment)
6. Write the test cases and the Assessment in the output format (Output Format)

Give each subagent the test target with its assigned specifications and the requirements they realize if any, the test targets it contains with their assigned specifications if any, the user's instructions on the test techniques if any, and the input — its file path, or the full text when it was written directly or taken from the conversation — and have it return its output verbatim.
Also have it write the modeling result to `<scratchpad>/modeling-results/<test target>.md`, where `<scratchpad>` is the scratchpad directory listed in your system prompt (write its absolute path literally in the instruction): a subagent's context is gone once it returns, and you need the modeling result to show it when the user asks to see it, without holding every target's modeling result in your context.
A subagent cannot ask the user, so it records every question as an issue in the Assessment.

When a target's Assessment is `❌FAIL` — e.g., a contradictory specification, or an undefined, ambiguous, or unverifiable acceptance test — ask the user via `AskUserQuestion`, presenting the Issues that make it FAIL, then design that target again with the answer.
When the user cannot resolve them — they require revising the specification — stop and report the Issues and modeling result to the user; revising the specification is up to the user or the caller.
Proceed with an `⚠️WARN` target as it is: its Issues stay in its Assessment, which the output carries for the user or the caller to act on.

### Step 3: Assemble the Test Cases

Arrange the outputs of Step 2 as one `## <Test target>` section per test target, in the order of Step 1.
Do not regroup the test cases by layer.

### Step 4: Review the Coverage

Review the assembled test cases against the input: every specification it states must be covered by the test cases of the target it was assigned to.
When one is not covered, run Step 2 again for that target.

### Step 5: Write the Output

Choose the destination in this order:

1. The user or the caller specified a destination → write there.
2. The specification came from a file → write a Markdown file next to it, named after the input file with a `-tests` suffix (e.g., `docs/inventory.md` → `docs/inventory-tests.md`).
   When several input files were given, name it after the first one.
3. Otherwise (the specification was written directly in the argument, or taken from the conversation) → output in the conversation.

Write the output verbatim per Step 3; when writing a file, add only a top-level heading naming the source document above it.

End your reply by telling the user that you can show the modeling result of each target on request: the test design document leaves it out, so the user has no other way to learn it exists.
