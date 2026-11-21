# Validators

Covers deriving the test cases of a validator from the specifications that constrain the data of the master data records of a master data class.

Out of scope:

- Specifications of the master data class's methods — design them as unit tests of the class, a separate test target (see [Test Levels](test-design.md#test-levels))

Terms:

- **Master data class** — a class that holds master data, e.g., a subclass of `ScriptableObject`.
- **Master data record** — one instance of a master data class authored in the project, e.g., one asset.

## Properties

A validator verifies a **property**: a predicate on one master data record, e.g., "an attack card's attack is greater than 0".
Each test case is one property, asserted on every master data record in the selection scope.
The subject is the master data records authored in the project, so the test cannot choose its inputs; a test that creates its own instance checks only the values the test sets.

A property has two parts:

- **Precondition** — selects the master data records the property applies to, e.g., "an attack card", "`Damage > 0`"; without one, the property applies to every master data record
- **Constraint** — what the fields of each selected master data record satisfy, e.g., "attack is greater than 0"

Derive the properties from the constraints the specification states on one master data record: value ranges, relations between fields, and required references.

## Modeling with Equivalence Partitioning

Model each property with [equivalence partitioning](equivalence-partitioning.md) of the fields its precondition and constraint refer to, e.g., `DisplayName` into `null`, an empty string, a whitespace-only string, and any other string.
The equivalence partitions define the predicate instead of becoming test cases with representative values: label each one as satisfying or violating the constraint.

- An equivalence partition the specification leaves unlabeled is a gap: design a separate undefined test case with it as the precondition, e.g., `DisplayNameIsWhitespaceOnly_UNDEFINED`, and keep the property's constraint to the labeled equivalence partitions
- A constraint that admits more than one reading makes the property ambiguous (see [Unverifiable, Undefined, and Ambiguous Test Cases](test-design.md#unverifiable-undefined-and-ambiguous-test-cases))

## Test Methods

Name a test method `<Condition>_<Expected>`, with the precondition as `<Condition>` and the constraint as `<Expected>`, e.g., `AttackCard_AttackIsGreaterThanZero`.
A property without a precondition is named `<Expected>` alone, e.g., `NameIsNotEmpty`.

The master data record is the input of every test case; state it in the Notes, never in the parameter notation.
When one property applies to several fields of the same master data record, e.g., the stats before and after an upgrade, consolidate them with the [parameterized test](test-design.md#parameterized-tests) notation, e.g., `AttackCard_DamageIsGreaterThanZero (stats: {Base, Upgraded})`.

## Selection Scope

The location the specification places the master data records in, e.g., a folder of assets, is the validator's selection scope: state it in the Notes per the [output format](test-design.md#output-format), not as a test case, since a test checking a master data record's location against the scope that selected it always passes.
When the specification states no location, record it as an issue (an unclear specification).

## Acceptance Tests

Mark as an acceptance test (see [Output Format](test-design.md#output-format)) the test case of each property that an external specification explicitly states.
