# Testing Randomness

When the system under test (SUT) consumes a pseudo-random number generator (PRNG), e.g., `UnityEngine.Random` or `System.Random`, choose one of these strategies based on what the spec actually pins down:

- **Stub the PRNG** — when the spec defines a deterministic mapping from random output to behavior (e.g., "≥0.5 → heads, <0.5 → tails"). Replace the PRNG with a stub that returns canned values; assert exact outcomes.
- **Range / bounds verification** — when only the output range is specified (e.g., random spawn coordinates within a region). Assert with `And`/`Range` constraints, or `Within`/custom comparer for tolerances. Combine with `Repeat` attribute so flakiness isn't masked by a single lucky run.
- **Statistical-property verification** — when the spec is about distribution shape (RPG damage variance, drop rates). Sample the SUT in a loop, compute statistics (mean, variance, histogram bucket counts), and assert on those. The `test-helper` package (`com.nowsprinting.test-helper`) provides lightweight sampling helpers; reach for `MathNet.Numerics` only when you need rigorous statistics.
- **Characteristic verification** — when the SUT generates procedural content (e.g., roguelike maze). Don't assert exact output; assert structural properties the spec requires — e.g., "the exit is reachable from the entrance via path-finding," plus any algorithm-specific invariants.
