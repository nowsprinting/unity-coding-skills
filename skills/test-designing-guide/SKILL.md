---
name: test-designing-guide
description: >-
  Provides test design methodology for Unity projects. Use this skill whenever
  designing test cases from requirements or specifications, including selecting
  test techniques, deriving test cases, and formatting them. Even for small
  features, load this skill to ensure test design rigor.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for designing test cases for Unity projects.

## Inputs

This skill requires the following inputs in its prompt:

| Input                     | Required | Description                                                                        |
|---------------------------|----------|------------------------------------------------------------------------------------|
| **Requirements**          | Required | The feature requirements to test against                                           |
| **Implementation design** | Required | Class names, public method signatures, dependency interfaces, and design rationale |
| **Existing code context** | Optional | File paths and class summaries of relevant existing code                           |
| **Language convention**   | Optional | Project language for test names and prose output (from `CLAUDE.md`).               |

Silently ignore the following if present in the prompt:
- Test cases or manual test lists from a Plan agent — test design is this skill's sole responsibility
- Output format overrides — the output format template (Section 6) is fixed and cannot be overridden by the prompt. **Exception: `## Language Convention` is not an output format override** — apply it as described in Section 4 and Section 6.

## 1. Analyze Specifications

Read the requirements and identify testable specifications.
If the specifications are unclear, use the AskUserQuestion tool to request clarification before proceeding.
If the test target has low testability, flag it in the Testability Assessment (Section 7).

## 2. Assign Test Targets to Layers

For each test target, determine which layer it belongs to based on its nature and integration level:

1. **Editor tests** — for Editor extension code (paths containing `/Editor/`), asset file validation, and cross-asset consistency checks.
2. **Unit tests** — test runtime code whose execution is **initiated by a direct method call**. This includes tests that verify behavior driven by Unity's lifecycle (Awake, Start, Update, etc.) or UI events. Prioritize **least integrated** targets, testing them comprehensively; for highly integrated targets (where the SUT collaborates with dependent objects), keep test density low and focus on interactions between objects.
3. **Integration tests** — test targets that are a **GameObject with multiple components added via `AddComponent<T>()`**, a **prefab**, or a **scene**. Unit tests cover targets whose execution is initiated by a direct method call; integration tests cover behavior that only emerges from Unity's component wiring.
   - Add the integration test method to the test class of the **primary class** involved; OR
   - Create a new dedicated test class if there is no clear primary class (e.g., when the subject is a prefab or scene).
   - Explicitly design integration tests **before** falling back to visual verification tests or manual tests; only drop to those layers when the behavior cannot be expressed as a functional assertion.
4. **Visual verification tests** — verify that actual on-screen rendering is correct. Take screenshots in the test code, and image analysis (see Section 4). Design these **before** falling back to manual tests.
5. **Manual tests** — reserved for items that **neither automated tests nor image analysis can verify** — i.e., items requiring human sensory judgment with no objective pass/fail criterion (e.g., game feel, animation polish, audio balance). Do NOT add manual tests for scenarios already covered by integration tests or visual verification tests, even if they seem "worth confirming by eye."

**Note:** Never use Edit Mode tests for runtime code logic. Edit Mode and Play Mode test runners cannot execute simultaneously — splitting coverage for a single SUT between the two modes prevents running all tests at once. Play Mode tests can run on actual devices (player builds), which Editor tests cannot.

## 3. Select Testing Techniques

**Prefer specification-based tests over structural (implementation-coupled) tests.** Structural tests break under refactoring and lose value fast. It's fine to write a structural test temporarily when you're unsure about an implementation, but plan to delete it once specification tests cover the same behavior.

For each test target, select appropriate techniques:

- **Equivalence partitioning** — group inputs into valid/invalid partitions; one representative per partition. When an **invalid** equivalence partition exists but the spec does not define its behavior (e.g., what happens for negative input, out-of-range values, null), use the `AskUserQuestion` tool to confirm the expected behavior before deriving test cases. Do not guess or invent the behavior.
- **Boundary value analysis** — test at the edges of each equivalence partition. Over-testing boundaries inflates the number of test cases and increases maintenance cost on every spec change. Mitigate this with parameterized tests that consolidate boundary cases into a single test method. When the spec doesn't differentiate behavior near edges (e.g., display color mapping), a representative per equivalence partition is sufficient and boundary testing can be skipped entirely.
- **State transition testing** — if the target has a finite-state-machine (FSM); one test case covers only 0-switch coverage (covering every direct transition from state A to state B, with no intermediate states in between)
- **Decision table testing** — if multiple conditions combine to produce different outcomes
- **Error guessing** — experience-based; derive cases from failure patterns common in game development. Examples to consider: rapid button mashing, simultaneous button press, input during scene transition / loading, collision tunneling, random distribution bias or PRNG sequence looping, numeric overflow, network failure. Use this to surface implementation concerns that spec-based techniques don't reach.

### Deriving test methods from equivalence partitions

The most common derivation error is merging partitions with **different** expected outcomes into one (parameterized) method, encoding the difference as a condition in the name/Verification (e.g. `..._InteractableMatchesNonEmpty`, "interactable is true *only when* non-empty"). One rule prevents it:

**One test method = one equivalence partition = one definite expected outcome.** Never parameterize the expected outcome. If the expected value changes with the input, the inputs belong to **different** partitions → **separate** test methods, each named after its own outcome.

For each input variable:
1. Partition the input domain into classes the spec says produce the **same** outcome.
2. Emit **one method per partition**, named `..._<Partition>_<ThatPartitionsOutcome>`. The `<Expected>` segment is a concrete state/value (`IsInteractable`, `IsNotInteractable`), never a condition word (`Matches…`, `…WhenNonEmpty`, `DependingOn…`).
3. Within one partition, consolidate multiple representatives (and that partition's boundary values) into **one parameterized** method — they share the outcome (see [Parameterized tests](#parameterized-tests)).

**Worked example** — `drawPileButton.interactable` driven by the draw pile count:

| Partition               | Representative values | Expected outcome          |
|-------------------------|-----------------------|---------------------------|
| Empty (`count == 0`)    | `0`                   | `interactable` is `false` |
| Non-empty (`count ≥ 1`) | `1` (boundary), `5`   | `interactable` is `true`  |

Two partitions, two outcomes → **two** methods (NOT one parameterized method over `{0, 1, 5}`):

| Test Method                                                         | Verification                             |
|---------------------------------------------------------------------|------------------------------------------|
| `Sync_DrawPileIsEmpty_DrawPileButtonIsNotInteractable`              | the draw pile button is not interactable |
| `Sync_DrawPileIsExist_DrawPileButtonIsInteractable` (count: {1, 5}) | the draw pile button is interactable     |

The non-empty method keeps both `1` and `5` because they share the outcome `true`; `1` is the partition's boundary value, `5` an interior representative.

**Boundary value analysis** locates where partitions meet. For a field valid in `1–99`: partitions `<1` / `1–99` / `>99`; boundaries `0, 1` and `99, 100`. Fold each partition's boundary representatives into that partition's parameterized method (e.g., valid partition over `{1, 99}`) — never one method per boundary. When the spec does not differentiate behavior near an edge, one representative per partition suffices and boundaries can be skipped entirely (per the Boundary value analysis technique above).

### Parameterized tests

When an equivalence partition includes multiple test cases — such as argument variations within the same partition or boundary values at the partition's edges — consolidate them into a single parameterized test. All cases must belong to the **same equivalence partition** and share the same expected outcome.

**Specifying parameter name and values in the Test Method column** — write values after the method name:

- **Bool parameter, all values**: `(flag: (bool))`
- **Enum parameter, all values**: `(direction: (Direction))`
- **Multiple parameters, all combinations (exhaustive)**: `(param1: {0, 1, 2}, param2: {3, 4, 5})` — when a param is `bool` or enum covering all its values, use the shorthand in place of the braces: `(flag: (bool), count: {0, 1, 5})`
- **Multiple parameters, limited to specific combinations**: `({param1: 0, param2: 3}, {param1: 1, param2: 4})`
- **Three or more parameters each with many values**: write `(use pairwise)` — the test-writing phase applies the pairwise (all-pairs) method to select a covering combination set

Do NOT over-consolidate: keep separate rows for tests that belong to **different** equivalence partitions or produce **different** expected outcomes.

### Invalid partition

- **UI input validation** — test invalid inputs that a user can enter through the UI (e.g., out-of-range values in a numeric text field). These represent real failure paths at the system boundary and must be tested.
- **Dependency error returns** — whether to test error/failure paths from a dependency depends on its origin:
  - **Library or framework** (external, not owned by this project) → test it; use a stub to inject the error condition.
  - **Game's own code** (another component in this project) → skip; trust internal code correctness.
  - **Uncertain** → use `AskUserQuestion` to confirm with the user before designing test cases.

### Testing randomness (PRNG-dependent SUT)

When the SUT consumes a pseudo-random number generator (`UnityEngine.Random`, `System.Random`, etc.), choose one of these strategies based on what the spec actually pins down:

- **Stub the PRNG** — when the spec defines a deterministic mapping from random output to behavior (e.g., "≥0.5 → heads, <0.5 → tails"). Replace the PRNG with a stub that returns canned values; assert exact outcomes.
- **Range / bounds verification** — when only the output range is specified (e.g., random spawn coordinates within a region). Assert with `And`/`Range` constraints, or `Within`/custom comparer for tolerances. Combine with `Repeat` attribute so flakiness isn't masked by a single lucky run.
- **Statistical-property verification** — when the spec is about distribution shape (RPG damage variance, drop rates). Sample the SUT in a loop, compute statistics (mean, variance, histogram bucket counts), and assert on those. The `test-helper` package (`com.nowsprinting.test-helper`) provides lightweight sampling helpers; reach for `MathNet.Numerics` only when you need rigorous statistics.
- **Characteristic verification** — when the SUT generates procedural content (e.g., roguelike maze). Don't assert exact output; assert structural properties the spec requires — e.g., "the exit is reachable from the entrance via path-finding," plus any algorithm-specific invariants.

### Integration test perspectives

Verify from the user's perspective — assert on-screen display and UI interactions as much as possible. Avoid relying on internal state or property checks when user-visible behavior can be asserted instead.

When the test target is a prefab, scene, or a GameObject composed of multiple components, consider the following test perspectives:

- **Multi-frame event system interactions** — behaviors triggered by Unity's event system that unfold across multiple frames
- **Scene transitions** — behaviors that span or depend on scene loading and unloading
- **UI operation sequences** — click, drag, and other player operations that advance game mechanics over one or more frames
- **UI blocking** — verify that UI elements behind a modal dialog or overlay are unreachable (blocked from interaction); conversely, verify those elements are reachable when no overlay is present
- **UI layout** — verify that buttons, toggles, and other interactive elements and text components do not overlap each other or overflow their parent containers, and that text does not overflow, using rect-comparison assertions:
  - Any layout bug expressible as a geometric predicate warrants a deterministic integration test assertion — e.g., "is element within screen bounds?", "do two elements overlap?", "does text overflow its container?" Design these as **integration tests only**; do NOT additionally design a visual verification test for the same geometric property.
  - Do NOT verify positional relationships between elements or on-screen positions (e.g., "A is displayed to the right of B") — approximate positions have no meaningful pass/fail criterion, and precise coordinate checks are brittle. Use visual verification tests for these instead.

### Reproduction tests (bug-fix tasks only)

When the task type is bug-fix, additionally apply the following during technique selection:

- **Reproduction test** — design one test case that directly triggers the reported bug. Apply error guessing and, if the SUT has state, state transition testing to identify the minimal trigger condition. This test must fail before the fix and pass after.
- **Regression tests** — identify adjacent behavior the fix might disturb, and apply the same techniques (equivalence partitioning, boundary value analysis, etc.) to derive coverage for those areas.

### Cover and modify (refactoring tasks only)

For refactoring work, apply **cover and modify**: design regression coverage before changing the implementation. Treat every bug as an opportunity to grow the regression suite.

## 4. Create Test Cases

For each technique, derive coverage-aware test cases:

**Language:** `<MethodName>` must always match the production method name exactly — never translate it. `<Condition>`, `<Expected>`, and the Verification column prose follow the project language from the **Language convention** input. If no language is specified, default to English.

- Use the naming convention based on whether the test target is a method:
  - **Method target** — `<MethodName>_<Condition>_<Expected>`: all **Unit tests**, and **Editor tests whose target is a method** (Editor extension code under `/Editor/`).
  - **Non-method target** — `<Condition>_<Expected>`: all **Integration tests** and **Visual verification tests** (multi-component interaction or on-screen rendering), and **Editor tests whose target is not a method** (asset file validation, cross-asset consistency checks — the SUT is an asset or set of assets). Do NOT include a method name. Do NOT add a feature-area or category prefix before `<Condition>` — the name starts directly with the condition (e.g., `OnVictoryForced_AllCardViewsAreWithinScreen`, not `Reward_OnVictoryForced_AllCardViewsAreWithinScreen`).
  - For **parameterized tests**, the `<Condition>` segment is the **equivalence partition name**, not an enumeration of individual argument values.
  - The `<Expected>` segment names the **concrete resulting state or value** of that one partition (e.g. `IsNotInteractable`, `ReturnsFizz`), never a condition or comparison. Words like `Matches…`, `OnlyWhen…`, `DependingOn…`, `BasedOn…` in the name — or "only when / only if / depending on" in the Verification — signal that the outcome varies with input, meaning two partitions were merged into one method — split into one method per outcome (see [Deriving test methods from equivalence partitions](#deriving-test-methods-from-equivalence-partitions) in Section 3).
- Do NOT create sequential IDs in test case names
- Describe the verification clearly
  - Verify one condition per test. **Exception**: when multiple properties of the state resulting from a transition must all be correct simultaneously, a single test may assert all of them together. In that case, list each property being verified in the Verification column.
  - Test concerns separately
- In the **Verification** column, state **which observable property or behavior** is checked and **what its expected value or state** is — this corresponds to the `Expected` segment of the test method name, not the `<Condition>` segment, which the method name already captures. Write from the information already available in the prompt (requirements and design inputs); abstract descriptions are acceptable — reading source to obtain more concrete identifiers is not required. Describe observable behavior only; do NOT include any of the following **anywhere in the test case output** — this prohibition applies to the Verification column, class header descriptions (text after `#### ClassName`), and any other field:
  - Test framework attributes (`[Test]`, `[UnityTest]`, `[LoadScene]`, `[Category(...)]`, `[TakeScreenshot]`, etc.)
  - Sync vs async / coroutine choice
  - Construction details of test inputs (e.g., how to build `PointerEventData`, how to instantiate fixtures)
  - The test's **precondition or arranged state** — anything that restates the `<Condition>` segment already encoded in the method name (e.g., for `..._WhenBossNext_...`, do NOT write "When the holder RunState has IsBossNext true, …" in Verification). State only the expected observable outcome.
  - Assertion helper class names (e.g., `LayoutAssert`, `GameObjectFinder`)
  - Exact private or serialized field names, or field-qualified member access (e.g., `drawPileButton.interactable`) whose owner is not present in the implementation design inputs — name the element descriptively instead (e.g., "the draw pile button is not interactable"). Exact identifiers are not required at design time; resolving the precise field name is a test-writing concern. You MAY name exactly: public framework API members (e.g., `CanvasGroup.blocksRaycasts`) and identifiers that appear in the design inputs.
  - Rationale or intent text — why the test exists, what it proves about the design, or what the current (buggy) behavior is. Observable behavior only.
  - Any other implementation/mechanism detail — those decisions belong to the test-writing phase
- **Parameterized tests** — consolidate same-partition test cases into a single table row per [Parameterized tests](#parameterized-tests) in Section 3. Do NOT specify the framework mechanism (`TestCase`, `Values`, etc.) in the Test Method column — that's a test-writing decision.
  - Example: `FizzBuzz_MultipleOfThree_ReturnsFizz` (n: 3, 6, 9) | `Returns "Fizz"`
- If a test case uses a **spy** to verify interactions, note it in the Verification column: e.g., `(uses spy: <TargetDependency>)`. Do NOT note stubs or fakes — those are arrange/action concerns. xUTP definitions for reference:
  - **Stub** — returns canned responses to isolate the SUT from a dependency. Arrange/action concern; do NOT mention in Verification.
  - **Spy** — records interactions (calls, arguments) for later verification. Note it in Verification.
  - **Fake** — a simplified but working implementation of a dependency. Arrange/action concern; do NOT mention in Verification.
- For visual verifications (e.g., on-screen rendering, UI layout), save a screenshot during test execution and verify it via image analysis. Note this in the Verification column along with the specific visual aspects to verify — e.g., `(saves screenshot for image analysis: element positions within screen, no overlap between elements, correct visibility state, text/background contrast)`.
  - **NEVER create a dedicated visual verification test class** — add visual verification test methods to the *same test class* as the functional tests.
  - **Screenshot resolution**: By default, do not fix a specific resolution for screenshot tests — let them run at whatever resolution the test environment provides. Only fix a resolution when the test condition explicitly depends on it (e.g., verifying element positions at a stated viewport size).
  - **Resolution as test condition**: When a screenshot test targets a specific resolution as part of its verification (e.g., layout at 960×540), include the resolution in the `<Condition>` segment of the target method name — e.g., `At960x540_RendersVersionLabelAtBottomRight` (visual verification tests use `<Condition>_<Expected>`, with no method name). This makes each resolution a distinct, independently runnable test case.
  - **Visual aspects to verify in screenshots** — always include the following in the `(saves screenshot for image analysis: ...)` list when applicable:
    - Element positions within screen, no overlap between elements, correct visibility state
    - **Text/background contrast** — verify that text color has sufficient contrast against its background so text is clearly legible

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
The Bad (parameterized) row hides the concrete argument values in a vague phrase in Verification; they belong in the Test Method column as named parameters, e.g. `(phase: {Defeat, Victory})`.
The Bad (condition restated) row repeats the method name's `<Condition>` segment ("WhenBossNext") as a precondition clause; Verification states only the expected outcome, since the condition already lives in the method name.
The Good rows state the observable behavior only; all other concerns go in the Test Method column or the test-writing phase.

The **merged-partitions** error — encoding two different expected outcomes into one method — deserves a dedicated example (see [Deriving test methods from equivalence partitions](#deriving-test-methods-from-equivalence-partitions) in Section 3 for the full worked example with partition tables):

| Style                   | Test Method                                                                            | Verification                                                               |
|-------------------------|----------------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| Bad (merged partitions) | `Sync_GivenDrawPileCount_DrawPileButtonInteractableMatchesNonEmpty` (count: {0, 1, 5}) | the draw pile button is interactable only when the draw pile is non-empty  |
| Good                    | `Sync_DrawPileIsEmpty_DrawPileButtonIsNotInteractable`                                 | the draw pile button is not interactable                                   |
| Good                    | `Sync_DrawPileIsExist_DrawPileButtonIsInteractable` (count: {1, 5})                    | the draw pile button is interactable                                       |

The Bad (merged partitions) row collapses two partitions — empty (→ not interactable) and non-empty (→ interactable) — into one method, betrayed by `Matches…` in the name and "only when" in the Verification. Split into one method per partition with a single definite outcome; parameterize only the same-outcome representatives (`1`, `5`).

## 5. Requirements Coverage Check

After completing Section 4, perform a traceability pass (acceptance tests coverage check) before writing the final output:

1. Re-read the original user prompt and extract every stated requirement or behavior.
2. For each requirement, identify which test case(s) designed in Section 4 cover it.
   - **Requirements must be covered by a same-layer witness test**: the covering test must directly exercise the behavior the requirement describes — not a component that contributes to satisfying it. A requirement about on-screen display or user interaction must be covered by an **integration or visual verification test**; a unit test that only calls a method is not a same-layer witness for a UI-layer requirement. A requirement about method-level behavior may be witnessed by a unit test. If no same-layer test covers a requirement, record it as a gap and handle it in step 3.
3. For any requirement with no covering test case:
   - Add a test case, **or**
   - Document explicitly why it is not tested (out of scope, untestable by design, etc.)

Output a **coverage summary table** only when gaps were found or a requirement was explicitly waived. Omit the table when all requirements are covered without exception.

| Requirement (from prompt) | Covering test(s)              | Gap / Waiver reason                                |
|---------------------------|-------------------------------|----------------------------------------------------|
| XXX should do Y           | `MethodName_ConditionA_DoesY` | —                                                  |
| ZZZ must not allow W      | (none)                        | Waived: prevented at a lower layer, not this class |

Finally, run a **partition-split self-check** on every test row that has parameter values in the Test Method column: for each listed parameter value, ask "does the expected outcome change when I substitute this value?" If any substitution produces a different expected outcome, those values belong to different partitions — split into one method per outcome, each with a single definite expected value, before producing final output. Reliable symptoms of a merged partition: `Matches…`, `OnlyWhen…`, `DependingOn…` in the `<Expected>` segment; "only when", "only if", or "depending on" in the Verification cell. (A plain temporal phrase such as "when drag starts" in Verification describes the test condition, not a varying outcome — it is not a symptom.)

## 6. Test Case Format

Output must contain the following blocks **in this order**:
1. Test Cases — one block per layer, in this order:
   - `### Editor tests`
   - `### Unit tests`
   - `### Integration tests`
   - `### Visual verification tests`
   - `### Manual tests`
2. Testability Assessment (Section 7)

> **Note:** All layers may contain `(none)` when no test cases apply to that layer.
> Do NOT write "Edit Mode" or "Play Mode" in test case output — that is a test-writing concern, not a design concern.

Structure by layer:
- **Editor tests / Unit tests / Integration tests / Visual verification tests**: `#### <ClassName>` → table
- **Manual tests**: no class/method section; uses a table of test cases with "Test perspectives / Verification method" column instead of "Verification"
  - Test perspectives — *what* behavioral aspects, conditions, or interactions are verified for this target. NOT a test technique name

**Output markers** — annotations that flag test case categories; append to the specified field only, not the Verification column:

- `(reproduction test)` — append to the **Test Method column** when the test reproduces a reported bug (see Section 3, Reproduction tests)
- `(acceptance test)` — append to the **Test Method column** when the test is the **same-layer witness** (see Section 5) for a requirement stated in the prompt: it must directly exercise the behavior the requirement describes — not a component that contributes to satisfying it. A requirement about on-screen display or user interaction requires an integration or visual verification test; a requirement about method-level behavior may be witnessed by a unit test.
- `(spec change)` — append to the **Test Method column** ONLY when updating an existing test whose **Verification (observable expected outcome) changes**. A change to the SUT signature/type that requires only arrange/action construction updates (e.g., wrapping `Foo`→`FooRef`) while the expected observable behavior stays identical is NOT a spec change — leave such tests **unmarked** (construction details are a test-writing concern per Section 4, not a design concern). Litmus test: **if the Verification column wording is unchanged, do NOT append `(spec change)`.**

Read the output format template for the project language and follow it exactly:
- Japanese: `${CLAUDE_SKILL_DIR}/resources/output-format-ja.md`
- All other languages (default): `${CLAUDE_SKILL_DIR}/resources/output-format.md`

If the project language is neither Japanese nor English, use `output-format.md` as the structural reference and write `<Condition>`, `<Expected>`, and Verification prose in the project language.

## 7. Testability Assessment

After designing all test cases, evaluate and output a **Testability Assessment** at the end of your response.

Use one of the following labels:

| Label               | Meaning                                                                                                |
|---------------------|--------------------------------------------------------------------------------------------------------|
| `TESTABILITY: PASS` | All public methods are independently testable; test case count is realistic                            |
| `TESTABILITY: WARN` | Localized concerns (e.g., too many test doubles, large integration tests, high FSM state combinations) |
| `TESTABILITY: FAIL` | Fundamental testability issues that require design revision                                            |

**FAIL criteria** — flag FAIL if any of the following apply:

- Unit test boundaries cannot be drawn (SUT is too large)
- State is hidden and cannot be verified externally
- Combinatorial explosion: test case count grows faster than O(n) relative to the number of conditions
- Dependencies cannot be injected (static/global coupling, `new` inside constructor, etc.)

**Output format** for the assessment section:

```markdown
### Testability Assessment

TESTABILITY: PASS

```

or, for WARN/FAIL, include Testability Issues with specific problem locations and proposed remedies:

```markdown
### Testability Assessment

TESTABILITY: FAIL

#### Testability Issues

| Issue                                                  | Location             | Proposed Remedy                        |
|--------------------------------------------------------|----------------------|----------------------------------------|
| Hidden state: `_score` modified by private method only | `GameManager._score` | Expose via read-only property or event |
| Static coupling: `Random.Range` called directly        | `CardSelector.Pick`  | Inject `IRandomSource` interface       |
```
