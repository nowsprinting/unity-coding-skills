# State Transition Testing

Apply when the specification defines the behavior of the target as a finite-state machine (FSM): states, and the events that move it from one state to another.

## State Transition Table

Model the FSM as a table of every state against every event; each cell holds the destination state, or that the event is not accepted in that state.
A cell the specification leaves empty is a gap, and a cell with two destinations a contradiction; design the test case of a gap as undefined and no test case for a contradiction (see [Test Techniques](../SKILL.md#test-techniques)).
A cell the specification explicitly states as undefined is not a gap: design no test case for it (see [Unverifiable, Undefined, and Ambiguous Test Cases](../SKILL.md#unverifiable-undefined-and-ambiguous-test-cases)).

As the modeling result, draw a state transition diagram in Mermaid (`stateDiagram-v2`) instead of the table, and point out each gap and contradiction on it with a note.

## Test Selection Criterion

Choose one of the following; the default is 0-switch coverage:

- **State coverage** — every state is visited by at least one test case; select the fewest transitions that visit them all
- **0-switch coverage** — one test case per direct transition from state A to state B, with no intermediate states in between
- **N-switch coverage** (N ≥ 1) — the 0-switch test cases, plus one test case per sequence of N+1 consecutive transitions.
  Build the sequences only from the cells that hold a destination state: an event not accepted, a gap, and a contradiction already get their test cases, or none, at 0-switch coverage.

Whatever the criterion, design the test case of each gap as undefined.

When the specification explicitly states that one state is reachable from another, e.g., "the player can reach the shop screen from the title screen", also apply **state-to-state reachability**: add one test case per such statement, following the shortest path of transitions in the model from the source state to the destination state.
A sequence or a use case states its transitions, not a reachability; its transitions get their test cases by the criterion above (see [Screen Transitions](#screen-transitions)).

## Test Methods

Design one test method per transition, with the source state and the event in the `<Condition>` segment and the destination state in the `<Expected>` segment.
When the specification defines that an event is not accepted in a state, design a test case that the state does not change.
For an N-switch or a state-to-state reachability test case, write the source state and the events in order in the `<Condition>` segment, and the state after the last event in the `<Expected>` segment; for a method target, the `<MethodName>` segment names the method of the last event.

## Acceptance Tests

Mark as an acceptance test (see [Output Format](../SKILL.md#output-format)) only the state-to-state reachability test case of each reachability that an external specification, or a specification that realizes a stated requirement, explicitly states.
The test cases the test selection criterion selects get no mark, even for a transition the specification describes.

## Screen Transitions

Model the screen transitions as an FSM, with screens as states and player operations as events, whether the specification gives them as a screen transition diagram, a sequence, a use case, or button operations written per screen.
A dialog that only completes or cancels an operation of the screen that opens it, or only returns to that screen, e.g., a confirmation or notice dialog, is part of that screen, not a state of its own, and its behavior belongs to that screen (see [Contained Test Targets](../SKILL.md#contained-test-targets)).
A dialog with transitions of its own, e.g., one with tabs or sub-dialogs, is a state, like a screen.
For the test class name, see [Test Layers](../SKILL.md#test-layers).
