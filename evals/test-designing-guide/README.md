# test-designing-guide eval

Measures whether the skill's **modeling result** (not the test cases) stays stable across models and effort levels.

Each fixture is a game specification with no implementation code, plus `golden.md`: a checklist of items the model must state (`## must`), must not state (`## must_not`), and regexes the raw output must match (`## regex`). A judge model answers present/absent per item by majority vote; the scores and the run-to-run stability are computed from those verdicts.

Current scores per fixture, model, and effort: [RESULTS.md](RESULTS.md).

**Stability** is the mean pairwise Jaccard of the sets of satisfied `must` items across the runs of one configuration. It measures agreement on the checklist, not identical models: two runs that model the same FSM as product states and as guarded transitions both score 1.0. Representation drift shows only by reading `run-N.md`.

## Running an eval

```sh
cd evals/test-designing-guide
python3 run.py fsm-card-draw --model opus --effort high --runs 3
python3 run.py fsm-card-draw --model sonnet --effort medium --runs 3
python3 run.py fsm-card-draw --report-only                      # table over every configuration run so far
python3 run.py --report-only                                    # every fixture; paste into RESULTS.md with the skill version and judge setup
python3 run.py fsm-card-draw --model sonnet --effort medium --judge-only   # re-judge after editing golden.md
```

Each run launches `claude -p` in an empty temporary directory holding the fixture's files, with only project-level settings (the user's `~/.claude/CLAUDE.md` is excluded), tools limited to Read/Glob/Grep/Skill/Agent, and the shared `prompt.md` as the task. The judge (`--judge-model`, default sonnet; `--votes`, default 3) gets `judge.md` with the golden items and the run's output.

Results land in `results/<fixture>/<model>-<effort>/`: `run-N.md` (raw output), `run-N.json` (cost, duration, permission denials), `judge-N.json` (verdicts with evidence). Rerunning the same configuration appends runs. The report prints one row per configuration and, below it, every missed `must`, hit `must_not`, and unmatched regex per run.

## Creating a fixture

A fixture is `fixtures/<name>/` with `spec.md` (the specification under test) and `golden.md`.

### Files

Every file in the directory except `golden.md`, `draft-golden.md`, `instruction.md`, and `prompt.md` is copied into the run's workspace.

1. **`spec.md` is always the specification under test; `reference.md` is an optional reference.** The test layer follows the subject of `spec.md`, as the skill's Test Layers rule says:
   - `spec.md` alone, describing a screen → integration tests
   - `spec.md` an external specification, `reference.md` its design docs → integration tests only; the design docs only settle what `spec.md` leaves open, e.g., whether an input can be arranged or an output observed
   - `spec.md` design docs (class API), `reference.md` the external specification → unit tests only; the external specification settles what the design docs leave open
2. **Linked documents**: `spec.md` may link to other files in the directory (`[報酬テーブル](docs/rewards.md)`). They are read the same way as `reference.md`: only to settle what `spec.md` leaves open, never as a source of test targets.
3. **Project settings**: a `CLAUDE.md` in the fixture is the run's project memory, e.g., to state the project language the skill reads from it. Without one, the skill's default is English; the judge compares by meaning and the regexes list both languages, so the language of the output does not affect the scores.
4. **Custom instruction**: the text of an optional `instruction.md` is put into the prompt as the skill's instruction, e.g., which part of `spec.md` to design tests for, or the test techniques and test selection criteria to use.
5. **Custom prompt**: a fixture-local `prompt.md` replaces the shared one, for a case the shared prompt does not fit (e.g., a validator).

### Golden

```sh
python3 run.py <name> --model opus --effort xhigh --runs 1 --draft-golden   # run once, draft fixtures/<name>/draft-golden.md from it
python3 run.py <name> --model opus --effort xhigh --runs 0 --draft-golden   # draft again from the newest existing run, without running
```

`prompt-draft-golden.md` turns one run's output into `draft-golden.md`. Review it against `spec.md` — every `must` item must follow from the specification, not from what that one run happened to say — then fix it and rename it to `golden.md`. `draft-golden.md` is ignored by git.

Phrase items by meaning, not notation, so that a run modeling the same facts differently still passes; keep `regex` items to fixed vocabulary (`stateDiagram-v2`, `0.?switch|0 ?スイッチ`). Before trusting a new golden, judge the run it came from (`--judge-only`): it should score 1.0 with no forbidden hits.
