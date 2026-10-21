---
name: test-designing-guide
description: >-
  Test design knowledge for Unity projects: test layers, test techniques for
  modeling specifications (equivalence partitioning, boundary value analysis,
  state transitions, decision tables, error guessing), test case naming,
  test case notation and output formats, and assessment of specifications.
  Use this skill whenever designing test cases for a test target, such as a
  screen or a class, from its specifications. Even for small features, load
  this skill to ensure test design rigor.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Knowledge for designing the test cases of a test target (e.g., a screen, a class) from its specifications.

Out of scope:

- Extracting test targets from a specification and assembling the test design document — see the `design-tests` skill
- Writing test code — see the `test-writing-guide` skill

## Test Layers

A test target's layer follows its subject: a class or an asset is a unit test, a scene or a prefab an integration test.
The external specification of a game usually describes a scene or a screen, so it lands in integration tests; when the external specification is an API itself (e.g., a package), it lands in unit tests only, with no integration tests.

- **Unit tests** — for specifications whose subject is a **class or an asset**, written as an **API contract**: a class or method's inputs, return values, state changes, raised events, or calls to its dependencies. This includes behavior driven by Unity's lifecycle (Awake, Start, Update, etc.) or UI events when the specification defines it per component. When the specification defines a class's collaboration with its dependencies, keep test density low and focus on those interactions. Specifications on asset content (asset file validation, cross-asset consistency) also belong here.
- **Integration tests** — for specifications whose subject is a **scene or prefab** (or a screen the player sees): UI operations, on-screen display, scene transitions, and behavior emerging from components and the assets they reference.
  - Add the integration test method to the test class of the **primary class** when the specification names one; OR
  - Create a new dedicated test class named after the scene, prefab, or screen otherwise.
  - For the screen transitions, name the test target `ScreenTransition` (test class `ScreenTransitionTest`). When the project has several screen transition systems, prefix the name with the system, e.g., `EquipmentScreenTransitionTest`.
  - When the **asset itself** is the SUT (file validation, cross-asset consistency), classify it as a **unit test**, not an integration test; integration tests assert the runtime behavior that emerges from a scene/prefab's linkage to its assets.

## Contained Test Targets

A test target may contain other test targets, each designed from its own specification: e.g., a screen contains the classes placed on it, and the screen transitions contain the screens.
The container's test cases cover the behavior that emerges from combining its contained targets — e.g., the wiring between a screen and its classes, or the transitions between screens.
A contained target's specifications belong to that target's own test cases; when a container's test case passes through a contained target, give each input the contained target's specification governs one representative value instead of its equivalence partitions and boundary values.
A part of the subject without a specification of its own, e.g., a class no specification describes, is not a contained target; test its behavior as part of the container.

## Test Techniques

When modeling the specifications with a test technique reveals a gap or a contradiction in them, abort designing the test target: assess it as `ASSESSMENT: FAIL` and include the modeling result (e.g., the equivalence partition table, the decision table, the state transition diagram) in the [Assessment](#assessment), so the user can see where the specification breaks.

**Prefer specification-based tests over structural (implementation-coupled) tests.** Structural tests break under refactoring and lose value fast. It's fine to write a structural test temporarily when you're unsure about an implementation, but plan to delete it once specification tests cover the same behavior.

Select the techniques that fit the test target, and read the resource of each one you apply:

- **Equivalence partitioning** — for every input except those a contained target governs (see [Contained Test Targets](#contained-test-targets)); group the values the specification says produce the same outcome → `resources/equivalence-partitioning.md`
- **Boundary value analysis** — when the specification differentiates behavior at the edges of equivalence partitions → `resources/boundary-value-analysis.md`
- **Decision table testing** — when a combination of multiple conditions produces different outcomes according to rules → `resources/decision-table-testing.md`
- **Combinatorial testing** — when multiple data-driven parameters (factors) combine and the expected behavior itself stays the same, e.g., the selected character and equipment → `resources/combinatorial-testing.md`
- **State transition testing** — when the target has a finite-state-machine (FSM), including screen transitions → `resources/state-transition-testing.md`
- **Error guessing** — to surface failure patterns common in game development that specification-based techniques don't reach → `resources/error-guessing.md`

Also read the following when they apply to the test target:

- **Integration testing** — when the test target is an integration test → `resources/integration-testing.md`
- **Testing randomness** — when the SUT consumes a pseudo-random number generator → `resources/testing-randomness.md`
- **Reproduction tests** — when the request is to reproduce a reported bug → `resources/reproduction-tests.md`

## Test Case Naming

**Language:** `<MethodName>` must always match the production method name exactly — never translate it. `<Condition>` and `<Expected>` follow the project language (the language specified in `CLAUDE.md` for test method names / code comments). If no language is specified, default to English.

- Use the naming convention based on whether the test target is a method:
  - **Method target** — `<MethodName>_<Condition>_<Expected>`: **Unit tests whose target is a method**.
  - **Non-method target** — `<Condition>_<Expected>`: all **Integration tests** and **Visual verification tests** (multi-component interaction or on-screen rendering), and **Unit tests whose target is an asset** (asset file validation, cross-asset consistency checks — the SUT is an asset or set of assets). Do NOT include a method name. Do NOT add a feature-area or category prefix before `<Condition>` — the name starts directly with the condition (e.g., `OnVictoryForced_AllCardViewsAreFullyWithinHandArea`, not `Reward_OnVictoryForced_AllCardViewsAreFullyWithinHandArea`).
  - For **parameterized tests**, the `<Condition>` segment is the **equivalence partition name**, not an enumeration of individual argument values.
  - The `<Expected>` segment names the **concrete resulting state or value** of that one partition (e.g. `IsNotInteractable`, `ReturnsFizz`), never a condition or comparison. **Exception**: a consolidated layout assertion test may use the generic `LayoutIsCorrect` (see [Integration testing](resources/integration-testing.md#perspectives), UI layout). Words like `Matches…`, `OnlyWhen…`, `DependingOn…`, `BasedOn…` in the name — or "only when / only if / depending on" in the verification description — signal that the outcome varies with input, meaning two partitions were merged into one method — split into one method per outcome (see [Deriving test methods from equivalence partitions](resources/equivalence-partitioning.md#deriving-test-methods-from-equivalence-partitions)).
- Do NOT create sequential IDs in test case names
- Verify one condition per test. **Exception (multi-property)**: when multiple properties of the state resulting from a transition must all be correct simultaneously, a single test may assert all of them together. The same applies to a consolidated layout assertion test asserting multiple layout properties under one condition (see [Integration testing](resources/integration-testing.md#perspectives), UI layout).
- Test concerns separately

## Verification Column

In the **Verification** column, state **which observable property or behavior** is checked and **what its expected value or state** is — this corresponds to the `<Expected>` segment of the test method name, not the `<Condition>` segment, which the method name already captures.
Write the prose in the project language.
Write from the information already available in the specification; abstract descriptions are acceptable — reading source to obtain more concrete identifiers is not required.
Describe observable behavior only; do NOT include any of the following **anywhere in the test case output** — this prohibition applies to the Verification column, class header descriptions (text after `#### ClassName`), and any other field:

- Test framework attributes (`[Test]`, `[UnityTest]`, `[LoadScene]`, `[Category(...)]`, `[TakeScreenshot]`, etc.)
- Sync vs async / coroutine choice
- Construction details of test inputs (e.g., how to build `PointerEventData`, how to instantiate fixtures)
- The test's **precondition or arranged state** — anything that restates the `<Condition>` segment already encoded in the method name (e.g., for `..._WhenBossNext_...`, do NOT write "When the holder RunState has IsBossNext true, …" in Verification). State only the expected observable outcome.
- Assertion helper class names (e.g., `LayoutAssert`, `GameObjectFinder`)
- Exact private or serialized field names, or field-qualified member access (e.g., `drawPileButton.interactable`) whose owner is not present in the specification — name the element descriptively instead (e.g., "the draw pile button is not interactable"). Exact identifiers are not required at design time; resolving the precise field name is a test-writing concern. You MAY name exactly: public framework API members (e.g., `CanvasGroup.blocksRaycasts`) and identifiers that appear in the specification.
- Rationale or intent text — why the test exists, which requirement it serves, or what the current (buggy) behavior is. Observable behavior only.
- Any other detail of how the test is built — those decisions belong to the test-writing phase

Further notation rules:

- When a single test asserts multiple properties (the multi-property exception in [Test Case Naming](#test-case-naming)), list each property being verified in the Verification column.
- **Parameterized tests** — write each consolidated parameterized test as a single table row, with the parameter notation from [Parameterized tests](resources/equivalence-partitioning.md#parameterized-tests) in the Test Method column. Do NOT specify the framework mechanism (`TestCase`, `Values`, etc.) — that's a test-writing decision.
  - Example: `FizzBuzz_MultipleOfThree_ReturnsFizz` (n: 3, 6, 9) | `Returns "Fizz"`
- If a test case uses a **spy** to verify an interaction the API specification defines, note it in the Verification column: e.g., `(uses spy: <TargetDependency>)`. Do NOT note stubs or fakes — those are arrange/action concerns. xUTP definitions for reference:
  - **Stub** — returns canned responses to isolate the SUT from a dependency. Arrange/action concern; do NOT mention in Verification.
  - **Spy** — records interactions (calls, arguments) for later verification. Note it in Verification.
  - **Fake** — a simplified but working implementation of a dependency. Arrange/action concern; do NOT mention in Verification.
- **Screenshot verification** — for a Visual verification tests row, list the visual aspects (see [Visual aspects to verify](resources/integration-testing.md#visual-aspects-to-verify)) in the **Image analysis by saved screenshot** column. When the screenshot is attached to a layout assertion test, append them to that row's Verification column as `(saves screenshot for image analysis: text/background contrast, typography)`.

### Example: Verification — Bad vs. Good

| Style                    | Test Method                                               | Verification                                                                                                                                                                        |
|--------------------------|-----------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Bad (mechanism)          | `OnBeginDrag_WhenDragStarts_BlocksRaycastsIsDisabled`     | Call `OnBeginDrag` synchronously with `[Test]` and Assert that `CanvasGroup.blocksRaycasts == false`                                                                                |
| Good                     | `OnBeginDrag_WhenDragStarts_BlocksRaycastsIsDisabled`     | `CanvasGroup.blocksRaycasts` is disabled                                                                                                                                            |
| Bad (rationale)          | `StartRun_SameSeed_ProducesSameMap`                       | The map structure is reproduced when a run is started twice with the same seed. Fails in the current implementation where RNG is not stored in the holder (BUG 1 reproduction test) |
| Good                     | `StartRun_SameSeed_ProducesSameMap` (reproduction test)   | The map structures of the two runs are identical                                                                                                                                    |
| Bad (not parameterized)  | `Sync_GivenPhase_PanelVisible`                            | The panel is visible only during the Defeat or Victory phase (verifies multiple argument patterns)                                                                                  |
| Good                     | `Sync_GivenPhase_PanelVisible` (phase: {Defeat, Victory}) | The panel is visible                                                                                                                                                                |
| Bad (condition restated) | `MapScene_OnLoad_WhenBossNext_FloorTextIsBoss`            | When the holder RunState has IsBossNext true, the floor text shows "Boss"                                                                                                           |
| Good                     | `MapScene_OnLoad_WhenBossNext_FloorTextIsBoss`            | the floor text shows "Boss"                                                                                                                                                         |

The Bad (mechanism) row leaks the test-writing mechanism (attribute choice, sync invocation, exact assertion form).
The Bad (rationale) row leaks why the test exists and what the current behavior is — none of that belongs in Verification; `(reproduction test)` goes in the Test Method column instead.
The Bad (not parameterized) row hides the concrete argument values in a vague phrase in Verification; they belong in the Test Method column as named parameters, e.g. `(phase: {Defeat, Victory})`.
The Bad (condition restated) row repeats the method name's `<Condition>` segment ("WhenBossNext") as a precondition clause; Verification states only the expected outcome, since the condition already lives in the method name.
The Good rows state the observable behavior only; all other concerns go in the Test Method column or the test-writing phase.

## Output Format

Output the test cases of a test target as the blocks of its layer that have test cases, in this order (omit blocks with none), followed by its [Assessment](#assessment):

- Unit tests: `### Unit tests`
- Integration tests: `### Integration tests`, `### Visual verification tests` (integration tests verified by image analysis), `### Manual tests` (integration tests verified by a human)

> **Note:** Do NOT write "Edit Mode" or "Play Mode" in test case output — that is a test-writing concern, not a test design concern.

Structure by layer:
- **Unit tests**: `#### <ClassName>` → table
- **Integration tests / Visual verification tests**: `#### <ClassName>`, or the scene, prefab, or screen name when the specification names no primary class (see [Test Layers](#test-layers)) → table
- **Manual tests**: no class/method section; uses a table of test cases with "Test perspectives / Verification method" column instead of "Verification"
  - Test perspectives — *what* behavioral aspects, conditions, or interactions are verified for this target. NOT a test technique name

**Output markers** — annotations that flag test case categories; append to the specified field only, not the Verification column:

- `(reproduction test)` — append to the **Test Method column** when the test reproduces a reported bug (see [Reproduction tests](resources/reproduction-tests.md))
- `(acceptance test)` — append to the **Test Method column** when the input explicitly states requirements and the test directly verifies a specification that realizes one of them. Without stated requirements, mark no test as an acceptance test.
- `(spec change)` — append to the **Test Method column** ONLY when updating an existing test whose **Verification (observable expected outcome) changes**. A change to the SUT signature/type that requires only arrange/action construction updates (e.g., wrapping `Foo`→`FooRef`) while the expected observable behavior stays identical is NOT a spec change — leave such tests **unmarked** (construction details are a test-writing concern per [Verification Column](#verification-column), not a test design concern). Litmus test: **if the Verification column wording is unchanged, do NOT append `(spec change)`.**

Read the output format template for the layer and follow it exactly (templates are in `${CLAUDE_SKILL_DIR}/assets/`):

| Layer                                                      | Default                       | Japanese                         |
|------------------------------------------------------------|-------------------------------|----------------------------------|
| Unit tests                                                 | `unit-tests-format.md`        | `unit-tests-format-ja.md`        |
| Integration tests, Visual verification tests, Manual tests | `integration-tests-format.md` | `integration-tests-format-ja.md` |

When no template exists for the project language, use the default one as the structural reference and write `<Condition>`, `<Expected>`, and the prose columns in the project language.

## Assessment

Assess whether the specifications of a test target can be tested as written, and assign one of the following labels.
Record every issue found while designing — an undefined, ambiguous, or contradictory specification — instead of guessing.

| Label              | Meaning                                                                                                                        |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------|
| `ASSESSMENT: PASS` | Every specification has a deterministic pass/fail criterion at its layer; none of the FAIL criteria apply                      |
| `ASSESSMENT: WARN` | Localized concerns (e.g., a large integration test, high FSM state combinations, an ambiguous specification the user resolved) |
| `ASSESSMENT: FAIL` | Fundamental issues that require revising the specification                                                                     |

**FAIL criteria** — flag FAIL if any of the following apply:

- **Undefined specification** — the expected outcome of a behavior is not stated, or an API specification leaves it unobservable (e.g., state that changes but is exposed through no member, event, or dependency call)
- **Ambiguous specification** — a stated behavior has no deterministic pass/fail criterion and is not suited to manual tests, e.g.:
  - A requirement given without the specification that realizes it ("defeating an enemy feels satisfying")
  - Random behavior without a specified distribution, range, or structural property (see [Testing randomness](resources/testing-randomness.md))
- **Contradictory specification** — two specifications demand incompatible outcomes
- Combinatorial explosion: test case count grows faster than O(n) relative to the number of conditions

**Output format**:

```markdown
### Assessment

ASSESSMENT: PASS

```

or, for WARN/FAIL, include Issues with the affected specification and a proposed remedy; for FAIL, also include the modeling result:

```markdown
### Assessment

ASSESSMENT: FAIL

#### Issues

| Issue                                                                       | Specification               | Proposed Remedy                                  |
|-----------------------------------------------------------------------------|-----------------------------|--------------------------------------------------|
| Contradictory specification: the button is both hidden and disabled at zero | "Draw button" in §2.1, §3.4 | Specify which one applies                        |
| Ambiguous specification: "rewards are random" with no distribution          | "Reward selection" in §4    | Specify the drop rates or the allowed reward set |

#### Modeling result

<the equivalence partition table, decision table, state transition diagram, etc. that revealed the issues>
```

On `ASSESSMENT: FAIL`, abort designing the test target: output the Assessment only, without test cases.
