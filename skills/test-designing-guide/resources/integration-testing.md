# Integration Testing

## Perspectives

Verify from the user's perspective — assert on-screen display and UI interactions as much as possible. Avoid relying on internal state or property checks when user-visible behavior can be asserted instead.

When the test target is a scene or prefab (or an equivalent GameObject hierarchy assembled in test code) with interplaying components and assets, consider the following test perspectives:

- **Multi-frame event system interactions** — behaviors triggered by Unity's event system that unfold across multiple frames
- **Scene transitions** — behaviors that span or depend on scene loading and unloading
- **Asset linkage** — runtime behaviors that emerge when placed components load or reference assets (e.g., ScriptableObject data, referenced prefabs)
- **UI operation sequences** — click, drag, and other player operations that advance game mechanics over one or more frames
- **UI blocking** — verify that UI elements behind a modal dialog or overlay are unreachable (blocked from interaction); conversely, verify those elements are reachable when no overlay is present
- **UI layout (layout assertion tests)** — verify that buttons, toggles, and other interactive elements and text components do not overlap each other or overflow their parent containers, and that text does not overflow, using deterministic assertions:
  - A **layout assertion test** verifies a condition expressible as a deterministic assertion (e.g., "no overlap", "no overflow", "the element is reachable"); displayed content (card data, text length, item count) is a test *input*, and the pass criterion never varies with it. Contrast with [visual verification tests](#visual-verification), which verify conformance to a screen-specific design intent — positional relationships like "A is displayed to the right of B", color, and typography (font size, font style, font family) are design decisions likely to change, unsuited to strict assertions; legibility (text/background contrast) is impractical to assert.
  - Any layout bug expressible as a geometric predicate warrants a deterministic integration test assertion — e.g., "the element is within screen bounds", "elements do not overlap", "text does not overflow its container". Design these as **integration tests only**; do NOT additionally design a visual verification test for the same geometric property. Font size and style are typographic **design** properties, not geometric predicates, so this rule does not apply to them — but a BestFit readability floor (auto-shrunk text must not fall below a minimum readable size) has a content-independent pass criterion and stays a layout assertion test.
  - **One test method per condition, not per perspective**: do NOT split layout assertion perspectives (no overlap, no overflow, containment, reachability, BestFit floor) into one test method each. When perspectives share the same test condition (same scene/state/inputs/resolution), consolidate them into a **single test method**; the `<Expected>` segment may then be the generic `LayoutIsCorrect` (in the project language, e.g., `レイアウトが正しいこと`), and the test asserts every layout property under that condition (per the multi-property exception in [Test Case Naming](../SKILL.md#test-case-naming)).
  - **Within-screen-bounds vs. within-container**: design a "within screen bounds" check only for a screen's top-level container (a dialog, popup, context menu, or other root panel whose position or size is computed dynamically) — that is the element actually at risk of clipping past the screen edge. Do NOT design a "within screen bounds" check for an element nested inside such a container; instead check it for containment in its **immediate parent container**. If every element already sits within a parent that is itself verified within the screen, each nested element is transitively within the screen too — a per-element screen-bounds check on top of that is redundant.
  - Parameterizing a layout assertion test over all production assets (e.g., every card defined in the master data) also validates the content itself — a newly authored asset whose text overflows its view fails the test.
  - Do NOT verify positional relationships between elements or on-screen positions (e.g., "A is displayed to the right of B") — approximate positions have no meaningful pass/fail criterion, and precise coordinate checks are brittle. Use [visual verification tests](#visual-verification) for these instead — including coarse screen-region checks (e.g., "the version label is in the bottom-right region"). **Exception (only when the user explicitly instructs)**: a coarse screen-region predicate (e.g., "within the bottom-right region: below 10% of screen height and right of the horizontal center") becomes deterministic when the resolution is fixed as a test condition — design it as a layout assertion test. A single fixed resolution gives no confidence that the layout holds across screens, so parameterize over the expected resolutions (at least the largest and smallest supported resolutions and the widest and narrowest supported aspect ratios), one test case per resolution with the resolution in the `<Condition>` segment.

## Verification methods

Choose the verification method of each test case in this order:

1. **Deterministic assertions** — the default, including the layout assertion tests in [Perspectives](#perspectives)
2. **[Visual verification](#visual-verification)** — when the behavior cannot be expressed as a functional assertion
3. **[Manual tests](#manual-tests)** — when image analysis cannot verify it either

### Visual verification

Visual verification tests are integration tests verified by image analysis of a screenshot saved during test execution, instead of assertions.
They verify that actual on-screen rendering conforms to the intended design: positional relationships between elements, typography, text/background contrast and legibility, visual state representation, and rendering quality.
A deterministic mid-point of an animation (e.g., an attack lunge at its peak, a fade-out at half time) can also be captured and verified here; only subjective motion feel belongs to manual tests.

- **Placement priority**: (1) when a layout assertion test already exists — or is being designed — for the same test condition, attach the screenshot verification to that test case instead of creating a new one; (2) otherwise, add the visual verification test method to the same test class as the functional tests. Never create a dedicated visual verification test class.
- **Screenshot resolution**: By default, do not fix a specific resolution for screenshot tests — let them run at whatever resolution the test environment provides. Only fix a resolution when the test condition explicitly depends on it (e.g., verifying element positions at a stated viewport size).
- **Resolution as test condition**: When a test targets a specific resolution as part of its verification (e.g., layout at 960×540) — whether a screenshot test or a resolution-fixed layout assertion test — include the resolution in the `<Condition>` segment of the test method name — e.g., `At960x540_RendersVersionLabelAtBottomRight`. This makes each resolution a distinct, independently runnable test case.

#### Visual aspects to verify

Always verify the following in screenshot image analysis when applicable:

- **Text/background contrast** — verify that text color has sufficient contrast against its background so text is clearly legible
- **Typography** — verify that font size, font style (bold/italic), and font family match the intended design and are consistent across equivalent elements; verify that glyphs actually render (no missing-glyph "tofu" boxes or blanks for characters the assigned font doesn't support)
- **Visual state representation** — when a UI state is communicated visually (a disabled button grayed out, a gauge's fill amount, a fading sprite's transparency), verify the rendering reflects that state
- **Rendering quality** — no sprite distortion (squashing/stretching), ghosting/afterimages, or unintended clipping

**Scope**: list only aspects suited to visual verification. Facts that are mechanically assertable — a panel's active state, exact text content — belong in integration test assertions, not in image analysis.

### Manual tests

Manual tests are integration tests verified by a human, reserved for items that **neither automated tests nor image analysis can verify** — i.e., items requiring human sensory judgment with no objective pass/fail criterion (e.g., game feel, animation polish, audio balance).
Do NOT add manual tests for scenarios already covered by integration tests or visual verification tests, even if they seem "worth confirming by eye."
