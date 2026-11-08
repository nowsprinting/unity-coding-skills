# Reproduction Tests (bug reports only)

When the request is to reproduce a reported bug, additionally apply the following during technique selection.

## Reproduction Test

Design one test case that directly triggers the reported bug, at the layer the bug report is written at (see [Test Layers](test-design.md#test-layers)).
Apply error guessing and, if the system under test (SUT) has state, state transition testing to identify the minimal trigger condition.
This test must fail before the fix and pass after.
