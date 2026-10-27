---
name: implement
description: >-
  Implements a feature or a specification change test-first, phase by phase
  from the units with no dependencies up: each phase designs its missing test
  cases, then writes failing tests and the production code that passes them.
  Use this skill whenever the user asks to implement or add a feature, or to
  change an existing specification, whether the input is a requirements
  document, a specification, a software design, a test design document, an
  issue URL, or the current conversation.
  Typically invoked as `/implement [SPECIFICATION]`.
argument-hint: "[specification, design, and test design, file paths, or issue URLs]"
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

Take the input from the `SPECIFICATION` argument: the text written directly, file paths, or the URLs of issues in an issue tracker, in any combination.
For an issue URL, fetch its body and comments (e.g., `gh issue view <URL> --comments` for GitHub Issues) and treat them as text written directly: the comments often revise the body, and a subagent may lack the credentials to fetch them.
When the argument is omitted, take it from the conversation.
The input states any of the following:

- **Requirement** — what users need to hold true, e.g., "defeating an enemy feels satisfying"; it has no pass/fail criterion of its own.
- **Specification** — the observable behavior at the boundary of a unit (a scene, prefab, class, or asset).
  The **external specification** is the one at the outermost boundary of the product, as the player or the API user observes it.
- **Software design** — the structure of a unit under test, at any level: the smaller units it divides into (modules, scenes, prefabs, classes), how they depend on one another, method signatures, and the file and assembly (`.asmdef`) of each class; it covers the production code and assets, not the test design.
  The classes and signatures it fixes are the specifications of the units below.
- **Test design document** — the test cases of each **test target** (the unit a test design is made for, e.g., the screen transitions, a screen, a prefab, or a class), as the `design-tests` skill outputs it.

If no specification can be found, use `AskUserQuestion` to ask the user before proceeding.

**TBD items:** If the specification explicitly contains the text "TBD" for any item, treat that item as non-existent — do not design, test, or implement it.
Only ask the user via `AskUserQuestion` if the TBD item is a prerequisite that cannot be deferred without blocking the implementation.

## Implementation Notes

Notes for this run go in `<scratchpad>/implementation-notes`, where `<scratchpad>` is the scratchpad directory listed in your system prompt (write its absolute path literally): one note per line, in the form `<category>: <note>`, where the category is one of `Design decisions`, `Deviations`, `Tradeoffs`, `Test changes`, and `Open questions`.
Before Step 1, delete that file if it exists, so this run starts from an empty one: every `/fix-bug` and `/implement` run in the session shares this file, so an earlier run abandoned before its report would otherwise leak its notes into this one.

The phase subagents append their notes to that file themselves.
Append your own judgment calls in Step 1 as `Design decisions` as soon as you make them — a note left in context until the end is lost when the context is compacted.

## Workflow

### Step 1: Plan the Phases

List the test targets the specification describes: the screen transitions, each screen, prefab, and `ScriptableObject` class, and each class the software design fixes.
Assign each specification to exactly one test target; when the subject of one test target contains others — e.g., a screen contains the classes placed on it — assign the behavior within a contained test target to it, and leave the container only the behavior that combines them.
A class no specification describes is no test target here: the phase that needs it designs it.

Order the test targets so that each comes after every test target it depends on: a class after the classes it calls, and a container after its contained test targets, e.g., a screen after the classes placed on it, and the screen transitions after the screens.

Group the ordered test targets into **phases**: a phase holds only test targets whose dependencies lie in earlier phases.
The tests of a phase then run against the real classes of earlier phases, already implemented and passing, instead of test doubles.
Beyond that rule, choose the size of the phases: split a phase further when the specification is large, e.g., one feature area per phase, so that each phase's diff stays reviewable.

Show the phases to the user as a list.

### Step 2: Run the Phases

Run the phases one at a time, in order, each in its own general-purpose subagent, so that the test design and the code of one phase stay out of your context and the others'.
Instruct the subagent to read `${CLAUDE_SKILL_DIR}/resources/phase-workflow.md` (write its absolute path literally) and follow it, including its commits: the workflow commits at fixed points, so that the test code committed before the implementation stays verifiable — write no instruction that stops the subagent from committing.
Give it:

- The phase's test targets, each with its assigned specifications, which of them are external specifications, and the requirements they realize, if any
- The test bases of each test target: the input files and issue URLs that state its assigned specifications or its test cases, not every input, so that the tests of a specification do not list the specifications of other phases
- The test targets of the earlier phases, already implemented
- The input — the path of each file, or the full text when written directly, fetched from an issue, or taken from the conversation
- The user's instructions on the test techniques, if any
- The absolute path of the notes file (see [Implementation Notes](#implementation-notes))

Act on the `STATUS:` line the subagent returns:

- `STATUS: DONE` → proceed to the next phase
- `STATUS: QUESTION` → ask the user via `AskUserQuestion`, presenting its issues, then run the phase again with the answer.
  When the user cannot resolve them, stop and report them: the specification needs revising before it can be implemented
- `STATUS: BLOCKED` → stop, and report the blocker to the user

### Step 3: Report the Implementation Notes

After the last phase, or when Step 2 stops:

1. `Read` `<scratchpad>/implementation-notes` if it exists
2. Report the notes to the user in chat under an `## Implementation Notes` heading — one bold sub-heading per category, each followed by a bullet list.
   Always include all five categories in this order: **Design decisions**, **Deviations**, **Tradeoffs**, **Test changes**, **Open questions**.
   Write `- None` for any category with nothing recorded, and add any last-minute Open questions before finalizing.
   If the file was never created, report every category as "None"
3. Delete the temporary notes file if it exists
