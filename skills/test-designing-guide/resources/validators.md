# Validators

Covers deriving the test cases of a validator from the specifications that constrain the data of a `ScriptableObject` class.

Out of scope:

- Specifications of the class's methods — design them as unit tests of the same test target (see [Test Layers](../SKILL.md#test-layers))

## Properties

A validator verifies a **property**: a predicate on one asset, e.g., "an attack card's attack is greater than 0".
Each test case is one property, asserted on every asset in the selection scope.
The subject is the assets authored in the project, so the test cannot choose its inputs; a test that creates its own instance checks only the values the test sets.

A property has two parts:

- **Precondition** — selects the assets the property applies to, e.g., "an attack card", "`Damage > 0`"; without one, the property applies to every asset
- **Constraint** — what the fields of each selected asset satisfy, e.g., "attack is greater than 0"

Derive the properties from the constraints the specification states on one asset: value ranges, relations between fields, and required references.
A specification on the set of assets, e.g., the number of assets or the presence of a specific asset, is not a property of one asset; design a test case for it only when the user explicitly asks.
A table listing each asset's concrete values (e.g., a master data table) is the source the assets are authored from, not a property: a test comparing an asset or the list of assets with it only transcribes the table a second time.

## Modeling with Equivalence Partitioning

Model each property with [equivalence partitioning](equivalence-partitioning.md) of the fields its precondition and constraint refer to, e.g., `DisplayName` into `null`, an empty string, a whitespace-only string, and any other string.
The equivalence partitions define the predicate instead of becoming test cases with representative values: label each one as satisfying or violating the constraint.

- An equivalence partition the specification leaves unlabeled is a gap: design a separate undefined test case with it as the precondition, e.g., `DisplayNameIsWhitespaceOnly_UNDEFINED`, and keep the property's constraint to the labeled equivalence partitions
- A constraint that admits more than one reading makes the property ambiguous (see [Unverifiable, Undefined, and Ambiguous Test Cases](../SKILL.md#unverifiable-undefined-and-ambiguous-test-cases))

The unit tests of the class's methods in the same test target may partition the same fields: share those equivalence partitions, and derive the test cases separately — the unit tests take representative values from each partition, while the validator only labels them.

## Test Methods

Name a test method `<Condition>_<Expected>`, with the precondition as `<Condition>` and the constraint as `<Expected>`, e.g., `AttackCard_AttackIsGreaterThanZero`.
A property without a precondition is named `<Expected>` alone, e.g., `NameIsNotEmpty`.

The asset is the input of every test case; state it in the Notes, never in the parameter notation.
When one property applies to several fields of the same asset, e.g., the stats before and after an upgrade, consolidate them with the [parameterized test](../SKILL.md#parameterized-tests) notation, e.g., `AttackCard_DamageIsGreaterThanZero (stats: {Base, Upgraded})`.

## Selection Scope

The folder the specification places the data in is the validator's selection scope: state it in the Notes per the [output format](../SKILL.md#output-format), not as a test case, since a test checking an asset's location against the scope that selected it always passes.
When the specification states no location, record it as an issue in the [Assessment](../SKILL.md#assessment).
