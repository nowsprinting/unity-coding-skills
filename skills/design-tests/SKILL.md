---
name: design-tests
description: >-
  Designs tests from a specification, whatever document states it — a
  requirements document, design docs, or an ADR:
  extracts the test targets, then creates test cases for each target at the
  test level of its subject — e.g., integration tests for a scene or prefab,
  unit tests for a class's API.
  Use this skill whenever the specification is settled and the next step is to
  design the tests, whether the input is written directly in the argument,
  given as file paths or URLs, or taken from the current conversation.
argument-hint: "[specification, file paths, or URLs]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Produces a test design document: the test cases and the assessment of each test target in the specification.
The test design knowledge lives in the `test-designing-guide` skill; this skill defines the procedure.

## Input

Take the input from the `specification` argument combined with the conversation, if any; when the argument is omitted, take it from the conversation alone:

- **Specification under test** — the specification to design tests for, what the user gives as the specification: written directly, file paths, or URLs (e.g., an issue, a wiki page, or a Google Docs document), in any combination; "the specification" below means it.
  If no specification can be found, use `AskUserQuestion` to ask the user before proceeding.
- **Instruction** (optional):
  - Which part of a given document is the specification under test
  - The test techniques to apply or to suppress, e.g., error guessing, or their test selection criteria, e.g., 1-switch coverage

Read a URL yourself and treat what you read as text written directly, since a subagent may lack the credentials to read it.
Read it with the access the user set up, e.g., an MCP server or a CLI of the service (`gh issue view <URL> --comments` for GitHub Issues).
For an issue, read its comments as well as its body: the comments often revise the body.

The input may state the specification in any document: a requirements document, design docs, or an ADR.
Note which specifications are external specifications (as `test-designing-guide` defines them), to mark acceptance tests.

## Rules

- Modify no files in the repository other than an output file the user or the caller asks for and the documents Step 6 writes the resolutions into.
  Record a gap or a contradiction in the specification that stays unresolved in the target's Assessment instead of editing the input documents.

## Workflow

### Step 1: Extract Test Targets

Load the `test-designing-guide` skill — do not rely on automatic skill triggering — and extract the test targets from the specification per its test analysis resource.
The targets are designed in parallel in Step 2, so a specification assigned to two targets would produce duplicate test cases.

### Step 2: Design Each Test Target

Design each test target in its own general-purpose subagent, launched in parallel, so the working material of one target stays out of the others' context.
Instruct each subagent to load the `test-designing-guide` skill — do not rely on automatic skill triggering — and apply its test design resource, `resources/test-design.md`, in full.

Give each subagent the test target with its assigned specifications, which of them are external specifications, the test targets it contains with their assigned specifications if any, the constraints on its master data records if Step 1 recorded any with it, whether the user states the specification changed since the existing tests were written, and the user's instructions on the test techniques and their test selection criteria if any, and have it return its output verbatim.
Quote each specification verbatim with its source, e.g., the file path and heading or the URL, together with the passages it depends on, e.g., the definitions of the terms it uses, whether they lie in the specification or in another document you read.
Also have it write the modeling result to `<scratchpad>/modeling-results/<test class>.md`, named after the `##` heading of its output, e.g., `FooTest.md`, where `<scratchpad>` is the scratchpad directory listed in your system prompt (write its absolute path literally in the instruction): a subagent's context is gone once it returns, and you need the modeling result to show it when the user asks to see it, without holding every target's modeling result in your context.
A subagent cannot ask the user, so it records every question as an issue in the Assessment.

When a target's Assessment is `❌FAIL`, ask the user via `AskUserQuestion`, presenting the Issues that make it FAIL, then design that target again with the answer.
When the user cannot resolve them — they require revising the specification — stop and report the Issues and modeling result to the user; revising the specification is up to the user or the caller.
Proceed with an `⚠️WARN` target as it is: its Issues stay in its Assessment, which the output carries for the user or the caller to act on.

### Step 3: Assemble the Test Cases

Arrange the outputs of Step 2, each a `## <test class>` section, in the order of Step 1.
Do not regroup the test cases by test level.

### Step 4: Review the Coverage

Review the assembled test cases against the input: every specification it states, except those Step 1 left out, must be covered by the test cases of the target it was assigned to.
When one is not covered, run Step 2 again for that target.

### Step 5: Output

#### Write the Output to a Spreadsheet

When the user or the caller asks for the output in a spreadsheet, write the test design document as one spreadsheet:

- One sheet per test target, named after its test class, holding all its test cases in a single table, in the order of its Step 3 section, with the columns "Test level", "Test technique, etc.", "Test method name", "Parameters", "Verification", and "Tags":
  - "Test level" — `Integration` or `Unit`; `-` for a validator, which belongs to no test level
  - "Test technique, etc." — the line above the test case's table, naming the technique and its test selection criteria; for a table without that line, what takes the technique's place: `Visual verification`, `Manual`, or `Validator`
  - "Test method name" and "Parameters" — the two parts of the "Test case" column; a manual test case has neither, so it goes in "Test method name"
  - "Verification" — also holds the "Image analysis by saved screenshot" and "Test perspectives / Verification method" columns

  Write the Notes below the table, one note per row.
- One "Test basis" sheet gathering the test bases of all test targets, one row per test basis, with a column for the test class
- One "Assessment" sheet with one row per issue across all test targets, with only the columns test class, issue, affected specification, and proposed remedy: leave out the label, and leave out a target with no issue

Leave the Test basis and Assessment sections out of the per-target sheets.

### Step 6: Feed Back the Answers to the Specification

When Step 2 resolved the Issues of a `❌FAIL` target — by the user's answer, or by a source the user instructed you to consult — write each resolution into the document that states the specification it settles, so that the specification agrees with the test design document:

- A document you can edit, e.g., a file or a wiki page → edit the passage the Issue concerns, in the document's own style; place a specification the resolution adds beside the specifications it relates to.
- A document you cannot edit but can comment on → post the resolution as a comment, quoting the passage it settles (e.g., `gh issue comment <URL> --body-file -` for GitHub Issues).
- Text written directly, the conversation, or a document you can neither edit nor comment on → list the resolutions in your reply, each with the passage it settles.

Tell the user which documents you changed and which comments you posted.

End your reply by telling the user that you can show the modeling result of each target on request: the test design document leaves it out, so the user has no other way to learn it exists.
