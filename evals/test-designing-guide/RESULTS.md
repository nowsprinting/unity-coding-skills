# Results

Scores per fixture and configuration (`<model>-<effort>`), from `python3 run.py --report-only`. A row is comparable only within the same skill version and judge setup, so each table states both.

## Plugin 2.0.0-alpha (f1280d2), 2026-11-09

Judge: sonnet, 3 votes. The opus-xhigh run is the one `golden.md` was drafted from, so its row is the golden sanity check, not a measurement.

| fixture | config | runs | recall | forbidden hits | regex | stability (Jaccard) | $/run | s/run |
|---|---|---|---|---|---|---|---|---|
| fsm-card-draw | opus-xhigh | 1 | 1.00 | 0 | 1.00 | — | 1.00 | 335 |
| fsm-card-draw | sonnet-low | 1 | 0.86 | 1 | 1.00 | — | 0.21 | 51 |
| fsm-card-draw | sonnet-medium | 3 | 0.94 | 2 | 0.92 | 0.90 | 0.25 | 80 |

Observations: sonnet selects decision table testing in 3 of 4 runs (the golden forbids it: every event depends on one condition) and omits combinatorial testing with the card color as a factor in every run.
