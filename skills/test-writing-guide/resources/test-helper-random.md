# Random Test Helper — Quick Reference

Package: `com.nowsprinting.test-helper.random` (<https://github.com/nowsprinting/test-helper.random>)
Assumes **v1.1.0** or later.

`UnityEngine.Random` exposes only `static` members, so a test cannot replace it with a test double (see `test-doubles.md`).
This package provides the `IRandom` interface, which covers the members of both `UnityEngine.Random` and `System.Random`, and `RandomWrapper`, its implementation.

Add `TestHelper.Random` to the Assembly Definition References of both the production and the test assembly.
The namespace is `TestHelper.Random`.

## Replacing `UnityEngine.Random` in production code

Add the following property to the production class that calls `UnityEngine.Random`:

```csharp
#if UNITY_INCLUDE_TESTS
    internal IRandom Random { private get; set; } = new RandomWrapper();
#endif
```

The property is named `Random`, so the existing calls such as `Random.Range(0, 10)` resolve to it in a build with tests, and to `UnityEngine.Random` in a player build without them; the player build does not need the `TestHelper.Random` assembly.
A test then injects a test stub into the property; the test assembly reaches the `internal` property through `InternalsVisibleTo`.

## Writing a test stub

Every member of `RandomWrapper` is `virtual`; derive from it and override only the members the SUT calls — here, `value`, which `Dice.Roll()` maps to a face:

```csharp
public class StubRandom : RandomWrapper
{
    private readonly float[] _returnValues;
    private int _returnValueIndex;

    public StubRandom(params float[] returnValues)
    {
        _returnValues = returnValues;
    }

    public override float value => _returnValues[_returnValueIndex++];
}

[Test]
public void Roll_PRNGReturnsMinimum_ReturnsOne()
{
    var sut = new Dice();
    sut.Random = new StubRandom(0.0f);

    var actual = sut.Roll();

    Assert.That(actual, Is.EqualTo(1));
}
```

## API

`IRandom` members compatible with `UnityEngine.Random`:

- `float value`, `float Range(float minInclusive, float maxInclusive)`, `int Range(int minInclusive, int maxExclusive)`
- `Vector3 insideUnitSphere`, `Vector2 insideUnitCircle`, `Vector3 onUnitSphere`, `Quaternion rotation`, `Quaternion rotationUniform`
- `Color ColorHSV(...)`
- `void InitState(int seed)`, `UnityEngine.Random.State state` — `RandomWrapper.state` throws `NotSupportedException`, since `System.Random` exposes no compatible state

`IRandom` members compatible with `System.Random`:

- `int Next()`, `int Next(int maxValue)`, `int Next(int minValue, int maxValue)`
- `double NextDouble()`, `void NextBytes(byte[] buffer)`

Others:

- `IRandom Fork()` — a new `IRandom` seeded with the value `Next()` returns
- `new RandomWrapper(int seed)` — wraps `System.Random` with the seed; `new RandomWrapper()` seeds with `Environment.TickCount`
- `IRandomExtensions` — `NextScreenPosition()`, `NextNormalizedVector2()`, `NextNormalizedVector3()`
