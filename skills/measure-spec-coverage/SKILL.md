---
name: measure-spec-coverage
description: >-
  Measures the specification coverage of one specification document: models its specifications with test techniques
  into coverage items, then checks off each coverage item a test verifies, finding the tests by the `// Test-basis:`
  comments in test files.
  Use this skill when the user asks how well a specification is tested, or which of its behaviors no test verifies.
  Typically invoked as `/measure-spec-coverage <PATH>`.
argument-hint: "<specification document path>"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Measures how much of one specification document the tests verify, and lists the coverage items no test verifies.

## Input

Take the specification document from the `PATH` argument: any document that states specifications, e.g., a requirements document, a software design document, or an ADR.
If it is omitted or names no file, use `AskUserQuestion` to ask the user for it.

In this skill, the terms mean:

- **Specification** — the observable behavior at the boundary of a unit (a scene, prefab, class, or asset).
  "Specification" names the behavior, never a document.
- **Coverage item** — in the ISTQB CT-MBT sense, one item of the specification model that a test case exercises: an equivalence partition, a decision table rule, or a state transition.
  The coverage items are the denominator of the coverage.
  Boundary values are not coverage items: equivalence partitioning, decision table testing, and state transition testing model only the conditions the specification states, and a combination or a transition they find missing is a gap in the specification, whereas boundary value analysis adds conditions the specification does not state, so counting them would charge the tests for conditions no specification asks for.
- **Test basis** — a file or an issue that the tests of a test file were written from, listed at the top of the file as a `// Test-basis: <path or URL>` line.
  The test bases may be outdated or incomplete: use them only to find tests, never to judge what a test covers.

## Rules

- Modify no files; report what needs changing instead.
- Model the specification before reading any test code: a coverage item taken from the tests is covered by whatever tests exist.

## Workflow

### Step 1: Extract Test Targets

Read the specification document and extract the test targets it describes, e.g., the screen transitions, a screen, a prefab, a class, or a `ScriptableObject` class.
Assign each specification to exactly one test target, so that no coverage item is counted twice; when the subject of one test target contains others, e.g., a screen contains the classes placed on it, assign the behavior within a contained test target to it.
Leave out each specification that `test-designing-guide` designs no test case for, e.g., a table of each asset's concrete values (see its Validators resource): it is the source the assets are authored from, not a property, so counting it lowers the coverage for tests that should not exist.

### Step 2: Measure Each Test Target

Measure each test target in its own general-purpose subagent, launched in parallel, so that the model and the test code of one target stay out of the others' context.
Before launching them, list the test files that name the specification document with `${CLAUDE_SKILL_DIR}/scripts/find-test-files.sh <PATH>`: it prints the path of each `.cs` file with a `// Test-basis:` line naming the document, one per line, searching each repository level from the document's own repository up to its superprojects, and exits with code 3 when none has one.
On exit code 3, proceed with an empty list: a project whose tests predate the `// Test-basis:` lines still has tests, and item 4 below finds them by name.
Give each subagent the test target with its assigned specifications, the list of test files, and the definitions of coverage item and test basis above, and instruct it to:

1. Load the `test-designing-guide` skill — do not rely on automatic skill triggering — and model the target's specifications with its Test Techniques, with boundary value analysis suppressed, reading the resource of each technique applied, into a list of coverage items.
   Leave out the items marked "TBD" and the conditions the specification states as undefined.
   For the data of a `ScriptableObject` class, model only the properties per the Validators resource; never model a table of each asset's concrete values as coverage items.
   List apart, as untestable, each coverage item whose test case would be unverifiable, undefined, or ambiguous.
   Finish the list before reading any test code
2. Read the test classes in the listed test files whose subject is the test target
3. Check off each coverage item that a test method verifies: its Arrange puts the test target in the coverage item — an input in the partition, the conditions of the rule, or the source state of the transition — and its assertions verify the coverage item's expected result.
   A test method name alone checks off nothing, and neither does a method with `[Ignore]`
4. For each coverage item still unchecked, search the test classes named after the test target or its classes, e.g., `<ClassName>Test`, and check it off the same way: a test without the `// Test-basis:` line still verifies the coverage item.
   Mark each test class found only this way
5. Return a table of the coverage items — `| Coverage item | Technique | Verified by |`, with `<TestClass>.<TestMethod>` or `—` in the last column — followed by the untestable coverage items and the test classes marked in item 4

### Step 3: Report

Report to the user in the conversation:

1. The coverage: the checked coverage items over all coverage items, excluding the untestable ones, overall and per test target
2. The table of each test target, as the subagent returned it
3. The untestable coverage items: a gap in the specification, not in the tests
4. The test classes found without the `// Test-basis:` line: suggest adding `// Test-basis: <path>` to their files, so that the next run finds them directly
5. The specifications left out in Step 1, with the reason

The coverage items depend on the modeling of each run: compare the unchecked coverage items between runs, not the percentages.
