# Combinatorial Testing

Apply to test that the inputs a test case's expected result does not depend on (factors) leave it unchanged in combination — e.g., the other ability scores and equipment slots when damage depends only on strength and the weapon.
The other techniques leave those inputs out of the test cases, and the test-writing phase gives them neutral values; a neutral value shows only that one value is inert, so an implementation that wrongly reads such an input, e.g., adds dexterity to damage, still passes them.
Unlike [decision table testing](decision-table-testing.md), where rules map each combination of conditions to a different outcome, every combination here expects the same behavior; the test cases look for combinations whose interaction breaks it.

## Test Cases

Derive one combinatorial test case from each test case of equivalence partitioning and decision table testing that leaves out an input the expected result does not depend on; a test case leaving out none derives none, and an unverifiable, undefined, or ambiguous one derives none either.
The derived test case keeps the source test case's `<MethodName>` and `<Condition>`, and fixes the inputs the expected result depends on at the source test case's representative values, without its boundary values.

Its factors are the inputs the source test case leaves out: those the specification states do not affect the outputs, those the expected result of that condition does not depend on, and the conditions marked "don't care" in a decision table rule.
A single factor is enough.
An input the expected result depends on is never a factor, nor is an input a [contained test target](../SKILL.md#contained-test-targets) governs: both keep their values.

E.g., when damage is computed from the character's strength and the attack of the equipped weapon, equivalence partitioning derives `GetDamage_WithWeapon_ReturnsDamageValue` and `GetDamage_WithoutWeapon_ReturnsDamageValue`, and combinatorial testing derives one test case from each, taking the other ability scores and the other equipment slots as the factors.

## One Expected Result

Every combination shares one expected result, the source test case's, even when it is a number: the inputs it depends on stay fixed, so the asserting test neither computes nor branches on its parameters.
When a factor turns out to change the expected result, it is no factor: the specification makes the expected result depend on it, so model it with the other techniques instead.

## Naming

Name the `<Expected>` segment after the absence of effect: the factors, as the inputs other than those the expected result depends on, do not affect the quantity or the state the source test case verifies.
Name the quantity as the source test case's `<Expected>` does, e.g., damage for `ReturnsDamageValue`.

- `GetDamage_WithWeapon_InputsOtherThanStrengthAndWeaponAttackDoNotAffectDamage`
- `GetDamage_WithoutWeapon_InputsOtherThanStrengthDoNotAffectDamage`
- In Japanese: `GetDamage_武器あり_筋力と武器の攻撃力以外はダメージ値に影響しない`

The Verification column states the source test case's expected result with the input values it depends on, e.g., "When Strength is 5 and the weapon's attack is 3, returns 8".

## Levels

The levels are the values of each factor.
Since the output has one equivalence partition, partition the factor by its own kinds, and take one representative per input equivalence partition as its levels: positive, zero, and negative at most for a number; every member for an enum; every type the factor can take for a type, e.g., the classes implementing an interface; `null` and one instance for a reference that may be empty, e.g., an equipment slot.
Choose the levels so that no combination falls in a condition the specification explicitly states as undefined; when no choice of levels avoids it, write the combinations with the limited-combinations notation.

## Classification Tree

To choose the combinations, draw each factor as a classification and its levels as classes under it; each test case then picks one class from every classification.

## Test Selection Criterion

Choose one of the following; the default is pairwise in integration tests and all combinations in unit tests:

- **All combinations** — every combination of the levels of all factors
- **Pairwise** — every combination of the levels of any two factors (2-wise)

Unity Test Framework generates no other combination set, so for an instruction naming another criterion, e.g., base choice or 3-wise, write its combinations with the limited-combinations notation.

The unit test framework generates the combinations from the levels, so the test case lists each factor with its levels in the [parameterized test](../SKILL.md#parameterized-tests) notation, not the combinations, e.g., `(dexterity: {0, 7}, shield: {null, Shield}, armor: {null, Armor})`; for pairwise, append `by pairwise` to it, e.g., `(dexterity: {0, 7}, shield: {null, Shield}, armor: {null, Armor}, by pairwise)`.

Validators get no combinatorial testing: their input is the assets authored in the project, which the test cannot choose.

## Combinatorial Explosion

In integration tests, with many factors or levels, even pairwise combinations explode.
Judge the testability low: assess it as `⚠️WARN` (combinatorial explosion), and propose in the Issues to break the test down into tests at a more detailed level.
Unit tests are not judged for combinatorial explosion.
