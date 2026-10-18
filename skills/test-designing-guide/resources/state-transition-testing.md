# State Transition Testing

Apply when the spec defines the behavior of the target as a finite-state machine (FSM): states, and the events that move it from one state to another.

- **State transition table** — model the FSM as a table of every state against every event; each cell holds the destination state, or that the event is not accepted in that state. A cell the spec leaves empty is a gap, and a cell with two destinations a contradiction; abort designing the test target (see [Test Techniques](../SKILL.md#test-techniques)).
  - As the modeling result, draw a state transition diagram in Mermaid (`stateDiagram-v2`) instead of the table, and point out each gap and contradiction on it with a note.
- **Coverage** — design for 0-switch coverage: one test case per direct transition from state A to state B, with no intermediate states in between. Testing longer paths exceeds 0-switch coverage.
- **Test methods** — one test method per transition, with the source state and the event in the `<Condition>` segment and the destination state in the `<Expected>` segment. When the spec defines that an event is not accepted in a state, design a test case that the state does not change.
- **Screen transitions** — model them as an FSM, with screens as states and player operations as events, whether the spec gives them as a screen transition diagram, a sequence, a use case, or button operations written per screen. A sequence or use case is a path through the FSM; do NOT test the path as a whole, but each transition on it. Dialogs are not states of the screen transitions; they belong to the test target of the screen that opens them. For the test class name, see [Test Layers](../SKILL.md#test-layers).
