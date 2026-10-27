# Test Helper Statistics APIs — Quick Reference

Part of the `com.nowsprinting.test-helper` package (see `test-helper.md`): the `TestHelper` assembly, namespace `TestHelper.Statistics`.
Use it to verify statistical properties of a SUT that consumes a pseudo-random number generator (PRNG), e.g., a drop rate or the shape of a damage distribution.

Package: `com.nowsprinting.test-helper` (<https://github.com/nowsprinting/test-helper>)
Assumes **v1.6.4** or later.

> The APIs are experimental, and may change without following SemVer.
> They summarize samples; they are not a statistical hypothesis testing tool.

`Experiment.Run` runs the trials, so the test method needs no loop and stays within [No Control Flow in Tests](unity-test-framework.md#no-control-flow-in-tests).

## Experiment

`Experiment.Run<T>(Func<T> method, int trialCount)` calls `method` `trialCount` times and returns a sample space with `Samples`, `Min`, and `Max` (`T` must implement `IComparable`).

```csharp
[Test]
public void Roll_2D6_RangesFromTwoToTwelve()
{
    var sampleSpace = Experiment.Run(
        () => DiceGenerator.Roll(2, 6),
        1 << 20);

    Assert.That(sampleSpace.Max, Is.EqualTo(12), "max");
    Assert.That(sampleSpace.Min, Is.EqualTo(2), "min");
}
```

## DescriptiveStatistics

`DescriptiveStatistics<T>` calculates the frequency summary of a sample space.

- `Calculate(sampleSpace)` — calculate the summary
- `PeakFrequency`, `ValleyFrequency`, `MedianFrequency`, `MeanFrequency` — frequencies of the values
- `Bins` — the frequency of each bin; `new DescriptiveStatistics<T>(min, max, binSize)` sets the bins, while the default constructor bins each value
- `GetSummary()` — a summary string with an ASCII histogram; write it to the console with `Debug.Log` to read the distribution on failure

Assert a frequency with a tolerance (`Within`):

```csharp
[Test]
public void Roll_2D6_FrequenciesFollowTriangularDistribution()
{
    const int TrialCount = 1 << 20;
    const double Tolerance = TrialCount * 0.001d;
    var sampleSpace = Experiment.Run(
        () => DiceGenerator.Roll(2, 6),
        TrialCount);

    var statistics = new DescriptiveStatistics<int>();
    statistics.Calculate(sampleSpace);
    Debug.Log(statistics.GetSummary());

    Assert.That(statistics.PeakFrequency, Is.EqualTo(TrialCount / 6).Within(Tolerance), "peak");
    Assert.That(statistics.ValleyFrequency, Is.EqualTo(TrialCount / 36).Within(Tolerance), "valley");
}
```

## PixelPlot

`PixelPlot<T>` writes the samples as a pixel plot image, which shows a weak (short-period) PRNG as a visible pattern.
It accepts value-type samples only.

```csharp
var pixelPlot = new PixelPlot<float>();
pixelPlot.Plot(sampleSpace);
pixelPlot.WriteToFile();
```

`WriteToFile(directory, filename)` saves to `Application.persistentDataPath/TestHelper/Statistics/<TestContext.Test.Name>.png` by default; the command line argument `-testHelperStatisticsDirectory` also sets the directory.
