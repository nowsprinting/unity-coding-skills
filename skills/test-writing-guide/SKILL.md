---
name: test-writing-guide
description: >-
  Provides guidelines for writing test code for Unity projects.
  Make sure to use this skill whenever writing, creating, editing, or modifying test code files (files under Tests/).
  This includes implementing new tests, fixing test failures, adding test cases, or any task that results in test code changes.
  Even for small edits or one-line fixes, load this skill to ensure test conventions are followed.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for writing test code for Unity projects.

Test code is code: load the `code-writing-guide` skill too, which holds the Unity rules that apply to every code file (checking Play Mode before editing, never creating `.meta` files, etc.).

## Rules

### Test Design Tags

- Do not touch the test of a test case tagged `existing`.
- For a test case tagged `test fix` or `spec change`, change the existing test to match the test case instead of adding a new one.
- Do not implement a test case whose Verification column starts with `**unverifiable**`, `**undefined**`, or `**ambiguous**`: the test cannot arrange its input, cannot observe its actual result, or has no single expected result to assert.

### Test Basis

A **test basis** is a file or an issue that states the specification the test code is written from, or that the user gave to read with it; text written directly or taken from the conversation is no test basis.
A test design document is no test basis, but list it with them: the lines are for searching.
List the test bases at the top of each test file you write or modify, below its header comment if any, one `// Test-basis:` line each:

```csharp
// Copyright (c) 2026 Example Inc.

// Test-basis: docs/battle.md
// Test-basis: docs/battle-tests.md
// Test-basis: https://github.com/owner/repo/issues/42

using NUnit.Framework;
```

The file is the unit: `/measure-spec-coverage` finds a file by these lines and reads every test class in it, so one file needs no rule on which of its classes is the test class.

- Write a file as its path from the root of the repository you work in (the superproject, when the file lies in a submodule), and an issue as its URL
- For a test design document, also list each test basis in its `test-basis` frontmatter
- Add only the test bases not yet listed, and keep the existing lines even when they look outdated: `/measure-spec-coverage` uses them only to find the tests of a specification, and reads the tests themselves to judge what they cover

### Categories

- For a test case tagged `acceptance` in the test design, apply `[Category("Acceptance")]` to the test method.
- When implementing tests designed as integration tests, apply `[Category("Integration")]` to the test method.
- When implementing tests designed as visual verification tests, apply `[Category("VisualVerification")]` to the test method.
- For test methods that depend on animation timing or other timing-sensitive conditions that may cause instability on slow CPUs, apply `[Category("IgnoreCI")]`.

### Neutral Values

Arrange the input values the test design states — the parameters of a parameterized test and the input values in the Verification column — as given: the expected result depends on them.
Give every other value — the values the test's outcome does not depend on, e.g., an argument of the SUT, a field of an object passed to the SUT, the default of a creation-method parameter — a value that declares "this value does not matter here":

- Use a **neutral** value: `0`, `null`, `false`, empty string/collection.
  A domain-plausible value (e.g. `hp = 79`) reads as a deliberate Arrange choice, and no reader can tell it apart from a value the outcome depends on.
- If no neutral value works — `0`/`null` breaks the object graph or crashes something downstream — then nothing can mean "does not matter", so the test states the value it needs.
  Substituting a different "safe" value just hides the same problem behind a less obvious number.

A value no assertion can depend on (e.g. a display name used only for logging) genuinely does not matter, so a descriptive placeholder such as `"TestEnemy"` is fine in place of `null` — but default to neutral, and deviate only when you can state why the value is provably inert.

### Object Creation Pattern

Use a creation method for objects needed in tests:

```csharp
private SomeClass CreateSystemUnderTest() { ... }
```

Give a creation-method parameter a default so that tests state only the values their outcome depends on, and pick it per [Neutral Values](#neutral-values).
If no neutral value works, **give no default at all**: make the parameter required so every call site states its own value.

```csharp
// Do NOT do this — 79/80 reads as an intentional Arrange choice; 2 silently hides that 0 throws
private RunState CreateRunState(int hp = 79, int maxHp = 80) { ... }
private static Catalog CreateCatalog(int midCount = 2) { ... }

// Do this — neutral where a "does not matter" value exists; required where none does
private RunState CreateRunState(int hp = 0, int maxHp = 0) { ... }
private static Catalog CreateCatalog(int midCount) { ... }
```

### Parameterized Tests

Implement a test case whose Test Method column has parameters after the method name as one parameterized test.
The parameter notation of the test design and the attribute that implements each form are in `unity-test-framework.md` → Parameterized Tests.

### Layout Assertion Tests

Implement a test case the test design gives as a layout assertion test — the element is within the screen, elements do not overlap, text does not overflow its container — with deterministic assertions, as designed; do not substitute a screenshot: a boolean assertion runs unattended in CI, and an overlap assertion names the two elements where a screenshot cannot.
The constraint that implements each condition, and the layout settling to do before asserting, are in `test-helper.md` → Layout constraints.

### UI Tests

In an integration test of a scene, prefab, or screen, find a GameObject the user interacts with through `GameObjectFinder`, reproduce the user's operation (click, drag, text input) through an operator, and verify that a modal or overlay blocks the elements behind it by their reachability; never through `GameObject.Find`, a direct event invocation, or a field assignment.
The APIs and the reasons are in `test-helper-ui.md`: read it before writing or modifying such a test.

### Visual Verification Tests

When implementing a visual verification test (a test designed to verify on-screen rendering via screenshot and image analysis):

1. Take a screenshot using `[TakeScreenshot]` or `ScreenshotHelper.TakeScreenshotAsync()` (see `test-helper.md`).
2. Apply `[Description("After running this test, verify the screenshots from the following perspectives: <verification aspects>")]` to the test method.
   The verification aspects are taken directly from the **Image analysis by saved screenshot** column in the test case design.
3. Apply `[Category("VisualVerification")]` to the test method.
4. You can omit writing `Assert` statements.

When a designed visual verification test shares its test condition with a designed layout assertion test, you may implement both as a single test method: take the screenshot in the layout assertion test, apply steps 2–3 to it, and keep the layout assertions (step 4 does not apply).

## Resources

Read the appropriate resource file based on the situation:

- Before writing or modifying any test code file: Read `${CLAUDE_SKILL_DIR}/resources/unity-test-framework.md` and `${CLAUDE_SKILL_DIR}/resources/test-helper.md`
- Before writing or modifying tests that use test doubles (stub, spy, mock, fake, dummy): Read `${CLAUDE_SKILL_DIR}/resources/test-doubles.md`
- Before writing or modifying tests that verify statistical properties of samples (e.g., a drop rate, a damage distribution) with the `TestHelper.Statistics` namespace API: Read `${CLAUDE_SKILL_DIR}/resources/test-helper-statistics.md`
- Before writing or modifying UI tests (see [UI Tests](#ui-tests)): Read `${CLAUDE_SKILL_DIR}/resources/test-helper-ui.md`
- Before writing or modifying performance tests (`com.unity.test-framework.performance`, `[Performance]`, `Measure.*`): Read `${CLAUDE_SKILL_DIR}/resources/unity-test-framework-performance.md`
