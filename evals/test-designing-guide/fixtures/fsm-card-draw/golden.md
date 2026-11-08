# Golden: fsm-card-draw

Items the modeling result must state (`must`), must not state (`must_not`), and regexes the raw output must match (`regex`).
Phrase each item by meaning, not by one notation: a run may model screen × count as product states or as three screens with guards, and both are correct.

## must

- The random card color is listed as an indirect input that the test cannot arrange
- The remaining count is listed as a state with the range 0–3 and the initial value 3
- The current screen (title, draw, result) is listed as a state
- The remaining-count display and the enabled/disabled state of the 引く button are listed as outputs
- Equivalence partitioning is selected as a technique
- State transition testing is selected with 0-switch coverage as its test selection criterion
- Combinatorial testing is selected with the card color as a factor
- The initial state is the title screen with count 3
- Pressing はじめる on the title screen transitions to the draw screen
- Pressing 引く on the draw screen with count 1 or more transitions to the result screen and lowers the count by 1
- Pressing 引く on the draw screen with count 0 is not accepted: no transition and the count stays 0
- Pressing 戻る on the draw screen transitions to the title screen and keeps the count
- Pressing 次へ on the result screen transitions to the draw screen
- Pressing はじめる with count 0 resets the count to 3
- Pressing はじめる with count 1 or more keeps the count
- The count at はじめる is partitioned into 0 and 1–3
- The count at 引く is partitioned into 0 (rejected) and 1–3 (accepted)
- The three colors 赤, 青, 緑 are partitions whose test cases are unverifiable because the test cannot arrange the random outcome
- The expected result for randomness is stated as each color's frequency over many draws being within a tolerance of 1/3
- The finding that the count is observable only on the draw screen, so a count on the title or result screen cannot be checked directly
- The finding that the display format of the count or the color text is not specified

## must_not

- A contradiction in the specification is reported as found
- Decision table testing is selected as a technique to apply
- Error guessing is selected as a technique to apply
- A transition from the result screen to the title screen
- Test cases or test method names are listed

## regex

- stateDiagram-v2
- 0.?switch|0 ?スイッチ|ゼロスイッチ
- equivalence partition|同値分割
- pairwise|ペアワイズ
