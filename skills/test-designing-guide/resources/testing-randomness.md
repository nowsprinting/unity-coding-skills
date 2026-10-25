# Testing Randomness

When the system under test (SUT) consumes a pseudo-random number generator (PRNG), e.g., `UnityEngine.Random` or `System.Random`, list the random numbers as an indirect input (see [Test Techniques](../SKILL.md#test-techniques)), and choose the expected result by what the specification pins down:

| The specification pins down                                          | Expected result                                                 | Example                                           |
|----------------------------------------------------------------------|-----------------------------------------------------------------|---------------------------------------------------|
| A deterministic mapping from a random number to behavior             | The exact behavior for a given random number                    | "≥0.5 → heads, <0.5 → tails"                      |
| Only the range of the output                                         | The output falls within the range                               | Random spawn coordinates within a region          |
| The shape of the distribution                                        | Statistics of sampled outputs fall within a tolerance           | Drop rates, the variance of RPG damage            |
| A structural property of generated content                           | The property holds, without asserting the exact output          | The exit of a roguelike maze is reachable         |

When the specification pins down none of them, the test case is ambiguous (see [Unverifiable, Undefined, and Ambiguous Test Cases](../SKILL.md#unverifiable-undefined-and-ambiguous-test-cases)).
