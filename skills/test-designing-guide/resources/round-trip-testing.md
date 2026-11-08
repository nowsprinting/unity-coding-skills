# Round-Trip Testing

Covers verifying a pair of inverse operations — e.g., serialize and deserialize, save and load, encode and decode — whose intermediate form, e.g., the serialized format, the specification does not define.
Round-trip testing is a verification method, not a test technique: [equivalence partitioning](equivalence-partitioning.md) models the inputs (see [Inputs](#inputs)), and the round trip supplies the expected result and the test method name; list the test cases in the equivalence partitioning table (see [Output Format](test-design.md#output-format)).

Out of scope:

- Inverse operations whose intermediate form the specification defines, e.g., a file format shared with another tool, or compatibility with data saved by an earlier version — test each direction against that form with the [test techniques](test-design.md#test-techniques), since a round trip passes even when both operations share a defect, e.g., the same wrong byte order on both sides

## Expected Result

Without a specified intermediate form, no test can state the expected result of the forward operation alone.
Apply the forward operation and then the inverse one, and expect a value equal to the original, e.g., the deserialized save data equals the saved data.
Every test case shares this one expected result.

## Equality

Compare what the specification says the round trip preserves, e.g., every serialized field.
When the specification excludes some fields, e.g., a cache rebuilt on load, or allows a tolerance, e.g., float precision, compare per that.
When the specification does not say what the round trip preserves, the test case is ambiguous (see [Unverifiable, Undefined, and Ambiguous Test Cases](test-design.md#unverifiable-undefined-and-ambiguous-test-cases)).

## Inputs

Since the output has one equivalence partition, partition the original by its own kinds, as for the levels of [combinatorial testing](combinatorial-testing.md): e.g., empty and non-empty collections, `null` fields, the bounds of a value, multi-byte characters.
Consolidate the representatives into one [parameterized test](test-design.md#parameterized-tests).

## Test Methods

Name the test method after the inverse operation, since the test asserts its result, e.g., `Deserialize_SerializedInventory_EqualsOriginal`.

## Acceptance Tests

Mark the test case as an acceptance test (see [Output Format](test-design.md#output-format)) when an external specification, or a specification that realizes a stated requirement, explicitly states the round trip, e.g., "loading restores the saved game".
This rule applies to these test cases in place of the rule of equivalence partitioning.
