# Test Doubles

When the system under test (SUT) uses another class, that class is a **depended-on component (DOC)**.
A DOC the test cannot control — a pseudo-random number generator (PRNG), the current date and time, communication with a server, or a feature still in development — makes the SUT's output nondeterministic and forces vague assertions.

Before reaching for a test double, try to separate the logic under test from the DOC, e.g., by splitting a method so that the logic no longer depends on it (the Humble Object pattern).
When separation is impractical, replace the DOC with a **test double**: a controllable stand-in.

## Dependency injection

A test double works only when the SUT receives its DOC from outside.
Prefer constructor injection; method, property, or field injection also works.
A DI container is not required.
The examples below inject a PRNG through a minimal `IRandom` interface that declares only `float Range(float minInclusive, float maxInclusive)`.

```csharp
public class Janken
{
    private readonly IRandom _random;

    public Janken(IRandom random = null)
    {
        _random = random ?? new UnityEngineRandom();
    }

    public Hand Pon()
    {
        var value = _random.Range(0.0f, 1.0f);
        if (value < 0.33f)
        {
            return Hand.Rock;
        }
        if (value < 0.66f)
        {
            return Hand.Scissors;
        }
        return Hand.Paper;
    }
}
```

When production code calls a `static` API such as `UnityEngine.Random` directly, it cannot be replaced; see `test-helper-random.md` for a wrapper.

## Patterns

The patterns follow xUnit Test Patterns (xUTP).
Name a test double class and variable with its role as a prefix, e.g., `StubRandom`, `spy`, and place the class under `Tests/Runtime/TestDoubles/` (see `unity-test-framework.md`).

### Test stub

A return value from a DOC to the SUT is an **indirect input**.
A test stub fixes the indirect input so that the SUT's output becomes predictable.

```csharp
public class StubRandom : IRandom
{
    private readonly float _value;

    public StubRandom(float value)
    {
        _value = value;
    }

    public float Range(float minInclusive, float maxInclusive)
    {
        return _value;
    }
}

[Test]
public void Pon_PRNGReturnsZero_ReturnsRock()
{
    var stub = new StubRandom(0.0f);
    var sut = new Janken(stub);

    var actual = sut.Pon();

    Assert.That(actual, Is.EqualTo(Hand.Rock));
}
```

A stub-driven test like this pins the mapping from the random value to the output; it tests the specification only when the specification defines that mapping, and the implementation otherwise.

### Test spy

An argument the SUT passes to a DOC is an **indirect output**.
A test spy records the calls and their arguments so that the test can assert on them.
What a spy returns is up to the test: a fixed value like a stub, or a delegation to the real DOC.

```csharp
public class SpyRandom : IRandom
{
    public float LastMinInclusive { get; private set; }
    public float LastMaxInclusive { get; private set; }

    public float Range(float minInclusive, float maxInclusive)
    {
        LastMinInclusive = minInclusive;
        LastMaxInclusive = maxInclusive;
        return 0.0f;
    }
}

[Test]
public void Pon_Always_RequestsRangeFromZeroToOne()
{
    var spy = new SpyRandom();
    var sut = new Janken(spy);

    sut.Pon();

    Assert.That(spy.LastMinInclusive, Is.EqualTo(0.0f), "min");
    Assert.That(spy.LastMaxInclusive, Is.EqualTo(1.0f), "max");
}
```

Use a spy when the specification defines the indirect output, e.g., the arguments sent to a server.
For a spy `MonoBehaviour` that captures Unity events, see Spy MonoBehaviour Conventions in `unity-test-framework.md`.

### Mock object

A mock object holds the expected indirect outputs in advance and asserts them itself.
Mock objects usually come from a library rather than a hand-written class.
A loose (nice) mock verifies each call on its own; a strict mock also fails the test when the calls arrive in a different order.
A mock moves the assertion out of the test method and breaks the four-phase structure, so do not overuse it.

### Fake object

A fake object behaves like the real DOC within the scope of the test.
Use it when the test needs neither to control indirect inputs nor to record indirect outputs, but should not use the real DOC for stability or speed, e.g., a module that sends achievement logs to a backend.

### Dummy object

A dummy object has no effect on the test; it exists only to satisfy a parameter or to compile, e.g., a delegate that must not be `null`, or a structure that defines only the properties the test needs out of complex game state.
