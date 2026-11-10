Load the `unity-coding-skills:test-designing-guide` skill with the Skill tool.

Per that skill, do the test analysis of the input below:

- Specification under test: `spec.md` in this directory
- Reference: `reference.md` in this directory, when it exists
- Instruction: the text in the `<instruction>` tags below, unless it is "none"

<instruction>
{instruction}
</instruction>

There is no implementation code.

Then do the test design of each test target in its own general-purpose subagent, launched in parallel, so that the working material of one target stays out of the others' context.
Give each subagent its test target with its assigned specifications quoted verbatim, the test targets it contains with their assigned specifications if any, the reference if any, and the instruction if any.
Instruct it to load the `unity-coding-skills:test-designing-guide` skill with the Skill tool, to do the test design per that skill up to modeling the specifications with test techniques, and to return only the **modeling result**, in this order, stopping before deriving test cases:

1. The list of inputs, states, and outputs of the test target
2. The test techniques selected, and the test selection criterion chosen for each
3. The model of each selected technique (state transition diagram in Mermaid, decision table, equivalence partition table, ...)
4. The gaps, contradictions, undefined conditions, and unverifiable items the modeling revealed, each with the specification it refers to

Output the list of test targets, each with the test targets it contains if any, then each subagent's modeling result verbatim under a heading naming its test target.
Do not output test cases, test method names, or an assessment label.
