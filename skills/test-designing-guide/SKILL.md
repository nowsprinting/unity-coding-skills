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

## Reading Code

Derive test cases from the specification, never from the implementation: a test case derived from the implementation passes whatever the implementation does.
Read only the following code, and no method bodies of production code:

- **Existing tests** — when the specification of a test target with tests changes, or a bug report asks for a [reproduction test](resources/reproduction-tests.md), the signatures of the test target's test classes and test methods, with the attributes that give a parameterized test its arguments, to mark the test cases they already implement (see the [output markers](#output-format))
- **Production code** — for unit tests, the signatures and XML documentation comments of the test target's members, to judge whether a test case can observe the actual result (see [Unverifiable, Undefined, and Ambiguous Test Cases](#unverifiable-undefined-and-ambiguous-test-cases)); for a class the input's software design introduces, read the signatures it fixes instead

## Test Layers

A test target's layer follows its subject: a class, or an asset file's own consistency, is a unit test; the data of a `ScriptableObject` class a validator; a scene or a prefab an integration test.
The external specification of a game usually describes a scene or a screen, so it lands in integration tests; when the external specification is an API itself (e.g., a package), it lands in unit tests only, with no integration tests.

- **Unit tests** — for specifications whose subject is a **class or an asset**, written as an **API contract**: a class or method's inputs, return values, state changes, raised events, or calls to its dependencies. This includes behavior driven by Unity's lifecycle (Awake, Start, Update, etc.) or UI events when the specification defines it per component. When the specification defines a class's collaboration with its dependencies, keep test density low and focus on those interactions. Specifications on the content of assets other than `ScriptableObject` data (asset file validation, cross-asset consistency) also belong here.
- **Validators** — for specifications that constrain the data of a `ScriptableObject` class, e.g., "an attack card's attack is greater than 0". The project holds the data as the class's assets, so the subject is those assets; a test that creates its own instance checks only the values the test sets, while a violation lies in the assets authored in the project.
  - The specification's condition selects the assets, and the test case asserts its expected result on every selected asset.
  - Specifications of the class's methods stay unit tests.
  - The folder the specification places the data in is the validator's selection scope: state it in the class description per the output format, not as a test case, since a test checking an asset's location against the scope that selected it always passes. When the specification states no location, record it as an issue in the Assessment.
  - A table listing each asset's concrete values (e.g., a master data table) is the source the assets are authored from, not a constraint on them: a test comparing an asset with it only transcribes the table a second time. Derive validators from the constraints the specification states — value ranges, relations between fields, required references — and design no test case that compares an asset's values or the list of assets with such a table.
- **Integration tests** — for specifications whose subject is a **scene or prefab** (or a screen the player sees): UI operations, on-screen display, scene transitions, and behavior emerging from components and the assets they reference.
  - Add the integration test method to the test class of the **primary class** when the specification names one; OR
  - Create a new dedicated test class named after the scene, prefab, or screen otherwise.
  - For the screen transitions, name the test target `ScreenTransition` (test class `ScreenTransitionTest`). When the project has several screen transition systems, prefix the name with the system, e.g., `EquipmentScreenTransitionTest`.
  - When the **asset itself** is the SUT (file validation, cross-asset consistency), classify it as a **unit test** (a **validator** for `ScriptableObject` data), not an integration test; integration tests assert the runtime behavior that emerges from a scene/prefab's linkage to its assets.

## Contained Test Targets

A test target may contain other test targets, each designed from its own specification: e.g., a screen contains the classes placed on it, and the screen transitions contain the screens.
The container's test cases cover the behavior that emerges from combining its contained targets — e.g., the wiring between a screen and its classes, or the transitions between screens.
A contained target's specifications belong to that target's own test cases; when a container's test case passes through a contained target, give each input the contained target's specification governs one representative value instead of its equivalence partitions and boundary values.
A part of the subject without a specification of its own, e.g., a class no specification describes, is not a contained target; test its behavior as part of the container.

## Test Techniques

Before selecting the techniques, list from the specifications the inputs, states, and outputs of the test target, since a value that does not pass through an argument or a return value is easy to miss:

- **Inputs** — direct inputs (arguments, UI operations) and indirect inputs (return values of dependencies, random numbers, time, assets the target references, the order of Unity's lifecycle events)
- **States** — the states the target holds across operations, e.g., flags and remaining counts, even when the specification does not describe them as an FSM
- **Outputs** — direct outputs (return values, on-screen display) and indirect outputs (raised events, calls to dependencies, saved data, logs)

The inputs and states drive the techniques: e.g., equivalence partitioning for each input, state transition testing for the states. An output without a means to observe it marks its test cases unverifiable, and a combination of inputs and states with no specified output marks its test case undefined. Include the list in the modeling result only when the [Assessment](#assessment) is `ASSESSMENT: WARN` or `ASSESSMENT: FAIL`.

When an output of one operation is the input of its inverse, e.g., serialize and deserialize, and the specification does not define that intermediate form, neither operation has an expected result of its own; verify the pair by a round trip → `resources/round-trip-testing.md`

When modeling the specifications with a test technique reveals a gap or a contradiction in them, do not guess the outcome: design the test case of a gap as undefined (see [Unverifiable, Undefined, and Ambiguous Test Cases](#unverifiable-undefined-and-ambiguous-test-cases)), design no test case for a contradiction, and include the modeling result (e.g., the equivalence partition table, the decision table, the state transition diagram) in the [Assessment](#assessment), so the user can see where the specification breaks.

**Prefer specification-based tests over structural (implementation-coupled) tests.** Structural tests break under refactoring and lose value fast. It's fine to write a structural test temporarily when you're unsure about an implementation, but plan to delete it once specification tests cover the same behavior.

Select the techniques that fit the test target, and read the resource of each one you apply:

- **Equivalence partitioning** — for every input except those a contained target governs (see [Contained Test Targets](#contained-test-targets)); group the values the specification says produce the same outcome → `resources/equivalence-partitioning.md`
- **Boundary value analysis** — when the specification differentiates behavior at the edges of equivalence partitions → `resources/boundary-value-analysis.md`
- **Decision table testing** — when a combination of multiple conditions produces different outcomes according to rules → `resources/decision-table-testing.md`
- **Combinatorial testing** — when multiple data-driven parameters (factors) combine and the expected result itself stays the same, e.g., the selected character and equipment → `resources/combinatorial-testing.md`
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
  - **Non-method target** — `<Condition>_<Expected>`: all **Integration tests** and **Visual verification tests** (multi-component interaction or on-screen rendering), **Unit tests whose target is an asset** (asset file validation, cross-asset consistency checks — the SUT is an asset or set of assets), and **Validators**. Do NOT include a method name. Do NOT add a feature-area or category prefix before `<Condition>` — the name starts directly with the condition (e.g., `OnVictoryForced_AllCardViewsAreFullyWithinHandArea`, not `Reward_OnVictoryForced_AllCardViewsAreFullyWithinHandArea`).
  - For **parameterized tests**, the `<Condition>` segment is the **equivalence partition name**, not an enumeration of individual argument values.
  - For **Validators**, the `<Condition>` segment names the assets the specification's condition selects, e.g., `AttackCard_AttackIsGreaterThanZero`; when the specification covers every asset of the class, the name is `<Expected>` alone, e.g., `NameIsNotEmpty`.
  - The `<Expected>` segment names the **concrete resulting state or value** of that one partition (e.g. `IsNotInteractable`, `ReturnsFizz`), never a condition or comparison. **Exceptions**: an undefined or ambiguous test case uses `UNDEFINED` or `AMBIGUOUS` (see [Unverifiable, Undefined, and Ambiguous Test Cases](#unverifiable-undefined-and-ambiguous-test-cases)); a consolidated layout assertion test may use the generic `LayoutIsCorrect` (see [Integration testing](resources/integration-testing.md#perspectives), UI layout). Words like `Matches…`, `OnlyWhen…`, `DependingOn…`, `BasedOn…` in the name — or "only when / only if / depending on" in the verification description — signal that the outcome varies with input, meaning two partitions were merged into one method — split into one method per outcome (see [Deriving test methods from equivalence partitions](resources/equivalence-partitioning.md#deriving-test-methods-from-equivalence-partitions)).
  - Write `<Expected>` in active voice: `ReturnsTrue`, `ThrowsArgumentException`, `ReducesHpBy3`, etc. For an exception, include its type: `ThrowsArgumentException`, not just `ThrowsException`.
- Do NOT create sequential IDs in test case names
- Verify one condition per test. **Exception (multi-property)**: when multiple properties of the state resulting from a transition must all be correct simultaneously, a single test may assert all of them together. The same applies to a consolidated layout assertion test asserting multiple layout properties under one condition (see [Integration testing](resources/integration-testing.md#perspectives), UI layout).
- Test concerns separately

## Verification Column

In the **Verification** column, state **which observable property or behavior** is checked and **what its expected value or state** is — this corresponds to the `<Expected>` segment of the test method name, not the `<Condition>` segment, which the method name already captures.
Write the prose in the project language.
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
  - Example: `IsValidLevel_WithinRange_ReturnsTrue` (level: {1, 50, 99}) | `Returns true`
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
The Bad (condition restated) row repeats the method name's `<Condition>` segment ("WhenBossNext") as a precondition clause; Verification states only the expected result, since the condition already lives in the method name.
The Good rows state the observable behavior only; all other concerns go in the Test Method column or the test-writing phase.

## Unverifiable, Undefined, and Ambiguous Test Cases

Design a test case even when it cannot be verified as specified, and mark it instead of guessing, so the user sees every place the specification needs revising:

- **Unverifiable** — in a unit test, the test cannot observe the actual result through the test target's API: a return value, a field or property of the instance, a raised event, or a call to a dependency a spy records. Judge it from what [Reading Code](#reading-code) allows; a `private` member is not observable. Write `**unverifiable**` in front of the expected result in the Verification column.
  - Example: `Attack_HpIsPositive_ReducesHpByDamage` | **unverifiable** the remaining HP is reduced by the damage
- **Undefined** — the specification states no expected result for the test case: e.g., an equivalence partition, a decision table combination, or a state transition table cell it leaves empty. End the method name with `_UNDEFINED` in place of `<Expected>`, and write `**undefined**` in the Verification column.
  - Example: `Attack_HpIsNegative_UNDEFINED` | **undefined**
- **Ambiguous** — the specification states an expected result that admits more than one reading, so it gives no deterministic pass/fail criterion: e.g., "attack +2" while a buff multiplies attack, without stating whether the addition comes before or after the multiplication; random behavior without a specified distribution, range, or structural property (see [Testing randomness](resources/testing-randomness.md)). The author of a specification rarely notices its own ambiguity, so state the reason. End the method name with `_AMBIGUOUS` in place of `<Expected>`, and write `**ambiguous**` followed by the reason in the Verification column.
  - Example: `GetAttack_AttackUpWithMultiplyingBuff_AMBIGUOUS` | **ambiguous** whether "attack +2" applies before or after the multiplying buff
  - In integration tests, a sensory outcome that neither an assertion nor image analysis can verify, e.g., "defeating an enemy feels satisfying", is not ambiguous: design it as a [manual test](resources/integration-testing.md#manual-tests), where a human judges it and the Verification column may stay subjective. Unit tests have no such escalation: an ambiguous specification at the unit test layer is always ambiguous.

## Output Format

Output the test cases of a test target as the blocks of its layers that have test cases, in this order (omit blocks with none), followed by its [Assessment](#assessment):

- Unit tests: `### Unit tests`
- Validators: `### Validators`
- Integration tests (including visual verification tests and manual tests): `### Integration tests`, `### Visual verification tests`, `### Manual tests` — one layer, split into blocks by the means of verification: assertions, image analysis, and a human

> **Note:** Do NOT write "Edit Mode" or "Play Mode" in test case output — that is a test-writing concern, not a test design concern.

Structure by layer:
- **Unit tests**: `#### <ClassName>Test` → table
- **Validators**: `#### <ClassName>Validator` → table
- **Integration tests** (including visual verification tests and manual tests): `#### <ClassName>Test`, or the scene, prefab, or screen name followed by `Test` when the specification names no primary class (see [Test Layers](#test-layers)) → table; manual tests have no class/method section and use a table of test cases with a "Test perspectives / Verification method" column instead of "Verification"
  - Test perspectives — *what* behavioral aspects, conditions, or interactions are verified for this target. NOT a test technique name

**Output markers** — annotations that flag test case categories; append to the specified field only, not the Verification column:

- `(acceptance test)` — append to the **Test Method column** when the input explicitly states requirements and the test directly verifies a specification that realizes one of them. Without stated requirements, mark no test as an acceptance test.
- `(reproduction test)` — append to the **Test Method column** when the test reproduces a reported bug (see [Reproduction tests](resources/reproduction-tests.md))
- `(existing)` — append to the **Test Method column** when an existing test implements the test case and needs no change.
- `(test fix)` — append to the **Test Method column** when an existing test implements the test case but disagrees with a specification that has not changed, e.g., its name, arguments, or expected result is wrong.
- `(spec change)` — append to the **Test Method column** when an existing test implements the test case and the change of the specification affects it: its expected result, its arguments, or its construction (e.g., wrapping `Foo`→`FooRef` in the SUT's signature).

A test case without `(existing)`, `(test fix)`, or `(spec change)` is a new test.
Write the markers in English whatever the project language.

Read the output format template for the layer and follow it exactly (templates are in `${CLAUDE_SKILL_DIR}/assets/`):

| Layer                                                                    | Default                       | Japanese                         |
|--------------------------------------------------------------------------|-------------------------------|----------------------------------|
| Unit tests                                                               | `unit-tests-format.md`        | `unit-tests-format-ja.md`        |
| Validators                                                               | `validators-format.md`        | `validators-format-ja.md`        |
| Integration tests (including visual verification tests and manual tests) | `integration-tests-format.md` | `integration-tests-format-ja.md` |

When no template exists for the project language, use the default one as the structural reference and write `<Condition>`, `<Expected>`, and the prose columns in the project language.

## Assessment

Assess whether the specifications of a test target can be tested as written, and assign one of the following labels.
Record every issue found while designing instead of guessing.

| Label              | Meaning                                                           |
|--------------------|-------------------------------------------------------------------|
| `ASSESSMENT: PASS` | None of the FAIL or WARN criteria apply                           |
| `ASSESSMENT: WARN` | Only WARN criteria apply                                          |
| `ASSESSMENT: FAIL` | A FAIL criterion applies; the specification needs revising        |

**FAIL criteria**:

- **Contradictory specification** — two specifications demand incompatible outcomes
- **Unverifiable, undefined, or ambiguous acceptance test** — an acceptance test is unverifiable, undefined, or ambiguous

**WARN criteria**:

- **Unverifiable, undefined, or ambiguous test case** — see [Unverifiable, Undefined, and Ambiguous Test Cases](#unverifiable-undefined-and-ambiguous-test-cases)
- **Combinatorial explosion** — in integration tests, test case count grows faster than O(n) relative to the number of conditions

**Output format**:

```markdown
### Assessment

ASSESSMENT: PASS

```

or, for WARN/FAIL, include Issues with the affected specification and a proposed remedy, and the modeling result:

```markdown
### Assessment

ASSESSMENT: FAIL

#### Issues

| Issue                                                                       | Specification               | Proposed Remedy                                  |
|-----------------------------------------------------------------------------|-----------------------------|--------------------------------------------------|
| Contradictory specification: the button is both hidden and disabled at zero | "Draw button" in §2.1, §3.4 | Specify which one applies                        |
| Ambiguous test case: "rewards are random" with no distribution              | "Reward selection" in §4    | Specify the drop rates or the allowed reward set |

#### Modeling result

<the equivalence partition table, decision table, state transition diagram, etc. that revealed the issues>
```

Output the test cases whatever the label.
