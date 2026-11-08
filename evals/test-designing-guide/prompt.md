Load the `unity-coding-skills:test-designing-guide` skill with the Skill tool, then read its test design resource.

Model the specification in `spec.md` in this directory for test design, per that resource.
The test target is the unit `spec.md` specifies, and only that unit; take its test layer from the subject of `spec.md` per the resource's Test Layers (a scene or prefab: integration tests; a class API: unit tests).
There is no implementation code.

When `reference.md` exists, it is the specification of the adjacent level: the software design below an external specification, or the external specification above a software design.
Use it only to settle what `spec.md` leaves open, e.g., which inputs a contained test target governs, whether an input can be arranged or an output observed, and which specifications realize a stated requirement. Extract no test target from it.
Treat any other document `spec.md` links to in this directory the same way.

Output only the **modeling result**, in this order, and stop before deriving test cases:

1. The list of inputs, states, and outputs of the test target
2. The test techniques selected, and the test selection criterion chosen for each
3. The model of each selected technique (state transition diagram in Mermaid, decision table, equivalence partition table, ...)
4. The gaps, contradictions, undefined conditions, and unverifiable items the modeling revealed, each with the specification it refers to

Do not output test cases, test method names, or an assessment label.
