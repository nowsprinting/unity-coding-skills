---
name: design-tests
description: >-
  Designs tests from a specification, whatever document states it — a
  requirements document, design docs, or an ADR:
  extracts the test targets, then creates test cases for each target at the
  test layer of its subject — e.g., integration tests for a scene or prefab,
  unit tests for a class's API.
  Use this skill whenever the specification is settled and the next step is to
  design the tests, whether the input is written directly in the argument,
  given as file paths or issue URLs, or taken from the current conversation.
  Typically invoked as `/design-tests [SPECIFICATION]`.
argument-hint: "[specification, file paths, or issue URLs]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Produces a test design document: the test cases and the assessment of each test target in the specification.
The test design knowledge lives in the `test-designing-guide` skill; this skill defines the procedure.

## Input

Take the input from the `SPECIFICATION` argument, or from the conversation when the argument is omitted:

- **Specification under test** — the specification to design tests for: written directly, file paths, or the URLs of issues in an issue tracker, in any combination; "the specification" below means it.
  If no specification can be found, use `AskUserQuestion` to ask the user before proceeding.
- **Reference** (optional) — what the user gives to read besides the specification under test.
  Read it only to settle what the specification leaves open; extract no test target and derive no test case from it.
- **Instruction** (optional):
  - Which part of a given document is the specification under test
  - The test techniques to apply or to suppress, e.g., error guessing, or their test selection criteria, e.g., 1-switch coverage

When the input alone leaves a specification, or its split into test targets, unsettled, consult the documents it links to, e.g., another file or an issue: read only the parts that settle it, up to two hops from the input — a document the input links to, and a document that one links to.
For an issue URL, fetch its body and comments (e.g., `gh issue view <URL> --comments` for GitHub Issues) and treat them as text written directly: the comments often revise the body, and a subagent may lack the credentials to fetch them.

The input may state the specification in any document: a requirements document, design docs, or an ADR.
Note which specifications are external specifications (as `test-designing-guide` defines them), to mark acceptance tests.

## Rules

- Modify no files in the repository other than the output file (Step 5) and the documents Step 6 writes the resolutions into.
  Record a gap or a contradiction in the specification that stays unresolved in the target's Assessment instead of editing the input documents.

## Workflow

### Step 1: Extract Test Targets

Load the `test-designing-guide` skill — do not rely on automatic skill triggering — and extract the test targets from the specification per its test analysis resource.
The targets are designed in parallel in Step 2, so a specification assigned to two targets would produce duplicate test cases.

### Step 2: Design Each Test Target

Design each test target in its own general-purpose subagent, launched in parallel, so the working material of one target stays out of the others' context.
Instruct each subagent to load the `test-designing-guide` skill — do not rely on automatic skill triggering — and apply its test design resource:

1. Determine the layer of each of the target's specifications (Test Layers)
2. Model its specifications with test techniques, and derive test cases from the results (Test Techniques)
3. Name the test cases (Test Case Naming) and write their Verification column (Verification Column)
4. Re-check every parameterized row against the one-partition-per-method rule (`resources/equivalence-partitioning.md`, Deriving test methods from equivalence partitions): if substituting any listed value would change the expected result, split the row
5. Tag the test cases that existing tests implement (Existing Tests)
6. Assess the target (Assessment)
7. Write the test cases and the Assessment in the output format (Output Format)

Give each subagent the test target with its assigned specifications, which of them are external specifications, the test targets it contains with their assigned specifications if any, whether the user states the specification changed since the existing tests were written, and the user's instructions on the test techniques and their test selection criteria if any, and have it return its output verbatim.
Quote each specification verbatim with its source, e.g., the file path and heading or the issue URL, together with the passages it depends on, e.g., the definitions of the terms it uses, whether they lie in the input or in a linked document you read (see Input).
Instruct the subagent to derive no test case from a specification stated in a quoted dependency passage, as for a passed link below: the passage may state a specification Step 1 assigned to another target or left out, and it is quoted only to define what the target's specifications use.
Pass the links within two hops of the input that the quoted passages cite and you did not read, each with the sentence that cites it.
Instruct the subagent not to read the source documents: a subagent reading a whole document would see the specifications Step 1 assigned to other targets, and could design duplicate test cases for them.
Allow it to read a passed link only to fill in what the quoted passages leave undefined or ambiguous: only the part that fills it in, without following the links there, and deriving no test case from a specification stated there.
When the link cannot be fetched or does not fill it in, the subagent records the question as an issue in the Assessment.
Also have it write the modeling result to `<scratchpad>/modeling-results/<test target>.md`, where `<scratchpad>` is the scratchpad directory listed in your system prompt (write its absolute path literally in the instruction): a subagent's context is gone once it returns, and you need the modeling result to show it when the user asks to see it, without holding every target's modeling result in your context.
A subagent cannot ask the user, so it records every question as an issue in the Assessment.

When a target's Assessment is `❌FAIL` — e.g., a contradictory specification, or an ambiguous or unverifiable acceptance test — ask the user via `AskUserQuestion`, presenting the Issues that make it FAIL, then design that target again with the answer.
When the user cannot resolve them — they require revising the specification — stop and report the Issues and modeling result to the user; revising the specification is up to the user or the caller.
Proceed with an `⚠️WARN` target as it is: its Issues stay in its Assessment, which the output carries for the user or the caller to act on.

### Step 3: Assemble the Test Cases

Arrange the outputs of Step 2 as one `## <Test target>` section per test target, in the order of Step 1.
Do not regroup the test cases by layer.

### Step 4: Review the Coverage

Review the assembled test cases against the input: every specification it states, except those Step 1 left out, must be covered by the test cases of the target it was assigned to.
When one is not covered, run Step 2 again for that target.

### Step 5: Write the Output

Choose the destination in this order:

1. The user or the caller specified a destination → write there.
2. The input includes a file → write a Markdown file next to it, named after the input file with a `-tests` suffix (e.g., `docs/inventory.md` → `docs/inventory-tests.md`).
   When several input files were given, name it after the first one.
   When a file of that name already exists, ask the user via `AskUserQuestion` whether to overwrite it or to write to a file name they specify.
3. Otherwise (the specification was written directly in the argument, fetched from issues, or taken from the conversation) → output in the conversation.

Write the output verbatim per Step 3; when writing a file, add only a frontmatter holding the prompt and the test bases, and a top-level heading naming the input above it.
The prompt is the user's message that invoked this skill, verbatim, as a YAML block scalar; when you cannot see it, e.g., a caller's instruction invoked the skill, write the `SPECIFICATION` argument instead.
The test bases are the files of the specification under test and of every reference the user gave, whether or not it was consulted, as paths from the root of the repository you work in (the superproject, when the file lies in a submodule), and the issue URLs; text written directly or taken from the conversation is no test basis.
`test-writing-guide` copies the test bases into the test files written from the test design document:

```markdown
---
prompt: |
  /design-tests docs/inventory.md
  Design only the "Sorting" section, with 1-switch coverage.
test-basis:
  - docs/inventory.md
  - https://github.com/owner/repo/issues/42
---

# Test design of docs/inventory.md
```

### Step 6: Feed Back the Answers to the Specification

When Step 2 resolved the Issues of a `❌FAIL` target — by the user's answer, or by a source the user instructed you to consult — write each resolution into the document that states the specification it settles, so that the specification agrees with the test design document:

- A file → edit the passage the Issue concerns, in the document's own style; place a specification the resolution adds beside the specifications it relates to.
- An issue → post the resolution as a comment, quoting the passage it settles (e.g., `gh issue comment <URL> --body-file -` for GitHub Issues): the comments revise the body (see Input), and a comment leaves the author's body intact.
- Text written directly, the conversation, or a document you cannot edit, e.g., a web page → list the resolutions in your reply, each with the passage it settles.

Tell the user which documents you changed and which comments you posted.

End your reply by telling the user that you can show the modeling result of each target on request: the test design document leaves it out, so the user has no other way to learn it exists.
