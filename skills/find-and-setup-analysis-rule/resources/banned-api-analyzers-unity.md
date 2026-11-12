# BannedApiAnalyzers.Unity

Covers banning APIs with the BannedApiAnalyzers.Unity package: why to prefer it, and how to write its banned symbols list.

Out of scope:

- Installation steps — see [Installing](roslyn-analyzer-package.md#installing)
- Severity of `RS0030` — see Severity in the skill's `SKILL.md`

## Package

[BannedApiAnalyzers.Unity](https://github.com/nowsprinting/BannedApiAnalyzers.Unity) reports `RS0030` where the code uses a banned symbol: a call, a member access, an object creation, `typeof`, an attribute, or a base type.
A declaration that only names a banned type, e.g., a parameter or a field, gets no diagnostic.
Prefer it to `Microsoft.CodeAnalysis.BannedApiAnalyzers`, which needs the path of its list in the `.csproj`; this fork reads Unity additional files instead, and requires Unity 2021.3 or later.
Its package ID is `BannedApiAnalyzers.Unity`.

## Banned Symbols List

List the banned symbols in a file named `<Filename>.BannedApiAnalyzers.Unity.additionalfile` anywhere under `Assets/`, where `<Filename>` contains no period; split them into one file per concern when that helps.
Each line is a [documentation comment ID](https://github.com/dotnet/csharpstandard/blob/standard-v6/standard/documentation-comments.md#d42-id-string-format), then `;` and the message the diagnostic shows; `//` starts a comment:

```txt
M:UnityEngine.GameObject.Find(System.String); It walks every GameObject in the loaded scenes. Resolve the reference once in Awake, or serialize it in the Inspector.
M:UnityEngine.Component.GetComponentsInChildren(System.Type); It allocates a new array on every call. Use the generic overload that fills a caller-supplied List<T> instead.
M:UnityEngine.Component.GetComponentsInChildren(System.Type,System.Boolean); It allocates a new array on every call. Use the generic overload that fills a caller-supplied List<T> instead.
M:UnityEngine.Component.GetComponentsInChildren`1; It allocates a new array on every call. Use the overload that fills a caller-supplied List<T> instead.
M:UnityEngine.Component.GetComponentsInChildren`1(System.Boolean); It allocates a new array on every call. Use the overload that fills a caller-supplied List<T> instead.
```

- **Message**: write why the symbol is banned and what to write instead; it is all the developer sees at the flagged code.
- **Overloads**: write one line per overload, each with its full parameter list.
  An entry without a parameter list matches only the overload with no parameters, so on any other overload it silently matches nothing.
- **Parameter types**: write the full type name, e.g., `System.Boolean` for `bool` and `System.String` for `string`.
- **Generic methods**: append `` `<number of type parameters> `` to the method name.

The repository's README tabulates the entry for each kind of symbol.
