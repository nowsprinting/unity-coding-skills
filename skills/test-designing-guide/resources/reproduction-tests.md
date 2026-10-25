# Reproduction Tests (bug reports only)

When the request is to reproduce a reported bug, additionally apply the following during technique selection.

## Reproduction Test

Design one test case that directly triggers the reported bug, at the layer the bug report is written at (see [Test Layers](../SKILL.md#test-layers)).
Apply error guessing and, if the system under test (SUT) has state, state transition testing to identify the minimal trigger condition.
This test must fail before the fix and pass after.

## Regression Tests

Identify adjacent behavior the fix might disturb, and apply the same techniques (equivalence partitioning, boundary value analysis, etc.) to derive coverage for those areas.
