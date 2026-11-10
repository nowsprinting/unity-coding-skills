---
name: test-designing-guide
description: >-
  Test analysis and test design knowledge for Unity projects: extracting test
  targets from specifications and leaving out the specifications that need no
  test case; test layers, test techniques for modeling specifications
  (equivalence partitioning, boundary value analysis, state transitions,
  decision tables, combinatorial testing, error guessing) and their test
  selection criteria, test case naming, test case notation and output formats,
  and assessment of specifications.
  Use this skill whenever extracting test targets, such as a screen or a
  class, from specifications, or designing the test cases of a test target.
  Even for small features, load this skill to ensure test design rigor.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Knowledge for testing a test target (e.g., a screen, a class) from its specifications, in two activities, as the ISTQB Foundation Level defines them:

- **Test analysis** — what to test?
- **Test design** — how to test?

In this skill, the terms mean:

- **Specification** — the observable behavior at the boundary of a unit (a scene, prefab, class, or asset).
  It covers both kinds: the external specification and the design docs.
  It is the content wherever it is stated: a file, an issue, or what the user says in the conversation.
- **External specification** — the specification at the outermost boundary of the product, as the player or the API user observes it.
- **Design docs** — the specification inside the product, at any level, e.g., a class's method signatures and their contracts.

Read the resource of each activity the task involves:

- Before extracting test targets from specifications, or deciding which specifications get test cases: Read `${CLAUDE_SKILL_DIR}/resources/test-analysis.md`
- Before designing the test cases of a test target from the specifications test analysis assigned to it: Read `${CLAUDE_SKILL_DIR}/resources/test-design.md`

Out of scope:

- Assembling the test design document — see the `design-tests` skill
- Writing test code — see the `test-writing-guide` skill
