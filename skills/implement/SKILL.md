---
name: implement
description: >-
  Implements a feature or a specification change test-first, phase by phase
  from the units with no dependencies up: each phase designs its missing test
  cases, then writes failing tests and the production code that passes them.
  Use this skill whenever the user asks to implement or add a feature, or to
  change an existing specification, whether the input is a requirements
  document, an external specification, design docs, a test design document, an
  issue URL, or the current conversation.
  Typically invoked as `/implement [SPECIFICATION]`.
argument-hint: "[specification, design, and/or test design, file paths, or issue URLs]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Implements a specification test-first: splits it into phases, and runs each phase in a subagent that designs the missing test cases, then writes failing tests and the production code that passes them.

Out of scope:

- A test design document with an assessment of each test target — see the `design-tests` skill
- Fixing a bug — see the `fix-bug` skill

## Task Type Check

If the user's request is to investigate or fix a bug rather than implement a new feature, change a specification, or refactor, stop and guide the user to invoke the `/fix-bug` skill instead.

## Input

Take the input from the `SPECIFICATION` argument, or from the conversation when the argument is omitted:

- **Specification** — the specification to implement: written directly, file paths, or the URLs of issues in an issue tracker, in any combination.
  If no specification can be found, use `AskUserQuestion` to ask the user before proceeding.
- **Test design document** (optional) — the test cases of each **test target** (the unit a test design is made for, e.g., the screen transitions, a screen, a prefab, or a class), as the `design-tests` skill outputs it.
  Also take as the specification the files and issues its `test-basis` frontmatter lists: the production code implements every specification, including those no test case covers.
- **Reference** (optional) — what the user gives to read besides the specification.
  Read it only to settle what the specification leaves open; derive no implementation target and no test case from it.
- **Instruction** (optional):
  - Which part of a given document is the specification
  - The test techniques to apply or to suppress, e.g., error guessing, or their test selection criteria, e.g., 1-switch coverage

For an issue URL, fetch its body and comments (e.g., `gh issue view <URL> --comments` for GitHub Issues) and treat them as text written directly: the comments often revise the body, and a subagent may lack the credentials to fetch them.

In this skill, the terms mean:

- **Specification** — the observable behavior at the boundary of a unit (a scene, prefab, class, or asset); it covers both kinds below.
  The **external specification** is the one at the outermost boundary of the product, as the player or the API user observes it.
  The **design docs** are the one inside the product, at any level: the smaller units a unit divides into (modules, scenes, prefabs, classes), how they depend on one another, method signatures, and the file and assembly (`.asmdef`) of each class; they cover the production code and assets, not the test design.

**TBD items:** If the specification explicitly contains the text "TBD" for any item, treat that item as non-existent — do not design, test, or implement it.
Only ask the user via `AskUserQuestion` if the TBD item is a prerequisite that cannot be deferred without blocking the implementation.

## Implementation Notes

Notes for this run go in `<scratchpad>/implementation-notes`, where `<scratchpad>` is the scratchpad directory listed in your system prompt (write its absolute path literally): one note per line, in the form `<category>: <note>`, where the category is one of `Design decisions`, `Deviations`, `Tradeoffs`, `Test changes`, and `Open questions`.
Before Step 1, delete that file if it exists, so this run starts from an empty one: every `/fix-bug` and `/implement` run in the session shares this file, so an earlier run abandoned before its report would otherwise leak its notes into this one.

The phase subagents append their notes to that file themselves.
Append your own judgment calls in Step 1 as `Design decisions` as soon as you make them — a note left in context until the end is lost when the context is compacted.

## Workflow

### Step 1: Plan the Phases

List the implementation targets the specification describes — the units a phase implements: the screen transitions, each screen, prefab, and `ScriptableObject` class, and each class the design docs fix.
Assign each specification to exactly one implementation target; when the subject of one implementation target contains others — e.g., a screen contains the classes placed on it — assign the behavior within a contained implementation target to it, and leave the container only the behavior that combines them.
A class no specification describes is no implementation target here: the phase that needs it designs it.

Order the implementation targets so that each comes after every implementation target it depends on: a class after the classes it calls, and a container after its contained implementation targets, e.g., a screen after the classes placed on it, and the screen transitions after the screens.

Group the ordered implementation targets into **phases**: a phase holds only implementation targets whose dependencies lie in earlier phases.
The tests of a phase then run against the real classes of earlier phases, already implemented and passing, instead of test doubles.
Beyond that rule, choose the size of the phases: split a phase further when the specification is large, e.g., one feature area per phase, so that each phase's diff stays reviewable.

Show the phases to the user as a list.

### Step 2: Run the Phases

Run the phases one at a time, in order, each in its own general-purpose subagent, so that the test design and the code of one phase stay out of your context and the others'.
Instruct the subagent to read `${CLAUDE_SKILL_DIR}/resources/phase-workflow.md` (write its absolute path literally) and follow it, including its commits: the workflow commits at fixed points, so that the test code committed before the implementation stays verifiable — write no instruction that stops the subagent from committing.
Give it:

- The phase's implementation targets, each with its assigned specifications, and which of them are external specifications
- The test bases of each implementation target: the input files and issue URLs that state its assigned specifications or its test cases, not every input, so that the tests of a specification do not list the specifications of other phases; add every reference the user gave to each, whether or not it was consulted
- The implementation targets of the earlier phases, already implemented
- The input — the path of each file, or the full text when written directly, fetched from an issue, or taken from the conversation
- The user's instructions on the test techniques, if any
- The absolute path of the notes file (see [Implementation Notes](#implementation-notes))

Act on the `STATUS:` line the subagent returns:

- `STATUS: DONE` → proceed to the next phase
- `STATUS: QUESTION` → ask the user via `AskUserQuestion`, presenting its issues, then send the answer to the same subagent with `SendMessage` so it continues the phase: a new subagent would find the phase's uncommitted skeleton and test code, and take those tests for existing ones.
  When the user cannot resolve them, stop and report them
- `STATUS: BLOCKED` → stop, and report the blocker to the user

### Step 3: Report the Implementation Notes

After the last phase, or when Step 2 stops:

1. `Read` `<scratchpad>/implementation-notes` if it exists
2. Report the notes to the user in chat under an `## Implementation Notes` heading — one bold sub-heading per category, each followed by a bullet list.
   Always include all five categories in this order: **Design decisions**, **Deviations**, **Tradeoffs**, **Test changes**, **Open questions**.
   Write `- None` for any category with nothing recorded, and add any last-minute Open questions before finalizing.
   If the file was never created, report every category as "None"
3. Delete the temporary notes file if it exists
