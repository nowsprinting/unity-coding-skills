---
name: test-design
description: >-
  Designs tests from a product spec, design, or ADR: extracts the test
  targets, then creates test cases for each target at the test layer its
  specifications are written at — e.g., integration tests for UI operations,
  unit tests for an API specification.
  Use this skill whenever the product spec is settled and the next step is to
  design the tests, whether the input is a file path, a spec written directly
  in the argument, or the current conversation.
  Typically invoked as `/test-design [PRODUCT SPEC]`.
argument-hint: "[product spec or its path]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Produces a test specification document: the test cases and the assessment of each test target in the product spec.
The test design knowledge lives in the `test-designing-guide` skill; this skill defines the procedure.

## Input

Take the product spec — the specifications to test against, e.g., UI operations or an API specification, written as a spec, a design, or an ADR — from the `PRODUCT SPEC` argument: either a file path or the spec written directly.
When the argument is omitted, take it from the conversation.
If the product spec cannot be found, use `AskUserQuestion` to ask the user before proceeding.
A bug report (Condition / Expected / Actual) with a request for a reproduction test is also a product spec.

Read existing code and tests only as needed, e.g., to place test cases in an existing test class; do not derive test cases from the implementation (Step 1).

## Rules

- Modify no files other than the output file (Step 5). Record a gap or a contradiction in the product spec in the target's Assessment instead of editing the input documents.

## Workflow

### Step 1: Extract Test Targets

Read the product spec and extract the test targets it covers, e.g.:

- The screen transitions
- A screen
- A character (actor)
- A component (class)
- A method

Extract only targets the spec describes; do NOT derive targets at a level the spec does not describe — e.g., internal classes guessed from a UI spec — because such tests couple to an implementation the spec leaves open.

Extract all the screen transitions as a single test target, whatever form the spec gives them in — a screen transition diagram, a sequence, a use case, or button operations written per screen.
The behavior within each screen, including the dialogs opened from it, stays in that screen's target; dialogs are not part of the screen transitions.

Assign each specification to exactly one test target, so that targets designed in parallel do not produce duplicate test cases.

### Step 2: Design Each Test Target

Design each test target in its own general-purpose subagent, launched in parallel, so the working material of one target stays out of the others' context.
Instruct each subagent to load the `test-designing-guide` skill — do not rely on automatic skill triggering — and apply it:

1. Determine the target's layer (Test Layers)
2. Model its specifications with test techniques, and derive test cases from the results (Test Techniques)
3. Name the test cases (Test Case Naming) and write their Verification column (Verification Column)
4. Re-check every parameterized row against the one-partition-per-method rule (`resources/equivalence-partitioning.md`, Deriving test methods from equivalence partitions): if substituting any listed value would change the expected outcome, split the row
5. Assess the target (Assessment)
6. Write the test cases and the Assessment in the output format (Output Format)

Give each subagent the test target with its assigned specifications, and the product spec — its file path, or the full text when it was written directly or taken from the conversation — and have it return its output verbatim.
A subagent cannot ask the user, so it records every question as an issue in the Assessment.

When a target's Assessment raises an issue — an unclear specification, a contradiction, or an undefined expected outcome — ask the user via `AskUserQuestion`, presenting the Issues together with the modeling result, then design that target again with the answer.
When the user cannot resolve an issue that makes the Assessment `ASSESSMENT: FAIL` — it requires revising the spec — stop and report its Issues and modeling result to the user; revising the spec is up to the user or the caller.

### Step 3: Assemble the Test Cases

Arrange the outputs of Step 2 as one `## <Test target>` section per test target, in the order of Step 1.
Do not regroup the test cases by layer.

### Step 4: Review the Coverage

Review the assembled test cases against the product spec: every specification and behavior it states must be covered by the test cases of the target it was assigned to.
When one is not covered, run Step 2 again for that target.

### Step 5: Write the Output

Choose the destination in this order:

1. The user or the caller specified a destination → write there.
2. The product spec came from a file → write a Markdown file next to it, named after the input file with a `-tests` suffix (e.g., `docs/inventory-spec.md` → `docs/inventory-spec-tests.md`). When several input files were given, name it after the first one.
3. Otherwise (the spec was written directly in the argument, or taken from the conversation) → output in the conversation.

Write the output verbatim per Step 3; when writing a file, add only a top-level heading naming the source document above it.
