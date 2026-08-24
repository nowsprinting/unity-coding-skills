# Unity Performance Testing — Gotchas

Pitfalls in the `com.unity.test-framework.performance` package that fail silently — wrong numbers, not errors.

Out of scope:

- General Unity Test Framework usage — see `unity-test-framework.md`
- Asserting that a delegate allocates nothing — see "GC Allocation Constraint" in `unity-test-framework.md`

**Observed on**: package **3.5.0**, Unity **6000.4.12f1**, macOS (OSXEditor, Play Mode). Re-check before assuming these still hold.

## Results are written to `persistentDataPath`

`RunFinished` always writes `Application.persistentDataPath/PerformanceTestResults.json` (parsed from a `TestResults.xml` beside it).
Resolve the directory with the `run-tests` skill's `get-persistent-data-path.sh`.

## `Measure.Method()` takes synchronous delegates only (3.5.0)

There is no async overload, so `async`/`UniTask` APIs cannot go through it — and passing an `async` delegate to NUnit assertion overloads deadlocks the Editor (`unity-test-framework.md` → Async Tests). Sample manually with `Measure.Custom` instead; see **Measuring async allocations** below.

## `.GC()` counts allocation events, not bytes (3.5.0)

`Measure.Method().GC()` samples `ProfilerRecorder.GetSample(0).Count` into a group named `Time.GC()` with unit `Undefined`. Read it as "how many times this allocated", never as a byte figure.

## `GC.GetAllocatedBytesForCurrentThread()` always returns 0 (Unity 6000.4.12f1)

A stub on Unity's Mono runtime: allocating 1 MB moves it by 0 bytes, Profiler enabled or not. It never throws, so any measurement built on it reports "allocates nothing" for every input — which reads like a finding rather than a broken instrument.

## `ProfilerRecorder` for `GC.Alloc` needs the Profiler recording (Unity 6000.4.12f1)

`new ProfilerRecorder(ProfilerCategory.Memory, "GC.Alloc", ...)` yields meaningful data only while the Profiler records. In a plain Editor test run `Profiler.enabled` is `false`, and it then returns values unrelated to the measured block — a 1 MB allocation was indistinguishable from an idle frame (16,255 vs 15,916 bytes). `recorder.Valid` stays `true`, so nothing flags it. Setting `Profiler.enabled = true` from test code does not help.

## Measuring async allocations

On Unity's Mono runtime, sample managed heap growth with `GC.GetTotalMemory(false)` around the awaited call, recording via `Measure.Custom`. Four things are load-bearing:

- **Probe the counter first.** A dead counter reports zeros instead of failing. Allocate a known buffer and `Assume.That` the counter moved by at least that much, so the test goes inconclusive rather than publishing a silent "allocates nothing".
- **Read the counter before `Measure.Custom`.** It appends to a `List<double>` whose capacity periodically doubles, charging its own allocations to the sample.
- **Warm up generously** (30 iterations worked; 5 did not). The heap grows in pages, so early iterations measure the expansion, not the steady-state cost — samples came out bimodal at 28% deviation, and one test read 0 for its first 9 samples.
- **Never force a collection per sample.** `GC.Collect()` before each iteration frees enough space that later allocations no longer grow the heap, flattening every sample to 0.

Heap growth is a relative measure: every sample is a multiple of 4,096, and an allocation fitting in already-reserved space contributes 0. Compare medians between branches; never quote a sample as "this operation allocates N bytes".

Finally, comparisons only hold when the workload is deterministic — pin any PRNG the code consumes (e.g. `new RandomWrapper(0)`, see `test-helper-ui.md`), and confirm the fixture actually exercises the path. An operation that silently no-ops still produces clean, meaningless numbers.
