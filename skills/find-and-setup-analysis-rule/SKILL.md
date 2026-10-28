---
name: find-and-setup-analysis-rule
description: >-
  Finds an analysis rule that flags a given coding pattern — an IDE inspection, a Roslyn analyzer package, or a custom
  Roslyn analyzer — and sets it up in the Unity project at `warning` or higher severity.
  Use this skill when the user wants a coding pattern flagged as the code is written, e.g., to keep a fixed bug from
  recurring, to ban an API, or to enforce a coding rule.
  Typically invoked as `/find-and-setup-analysis-rule [PATTERN]`.
argument-hint: "[coding pattern, with code that should be flagged and code that should not]"
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Finds an analysis rule that flags a coding pattern as the code is written, and sets it up in the Unity project.
An analysis rule is an IDE inspection or a Roslyn analyzer rule, and a diagnostic is what it reports on the code it flags.

## Input

Take the coding pattern from the `PATTERN` argument: a description, the code the analysis rule should flag, and optionally the code it should not, e.g., the code before and after a bug fix.
When the argument is omitted, take it from the conversation.
If the code to flag is missing, or the input fits several patterns, use `AskUserQuestion` to ask the user before proceeding.

## Workflow

### Step 1: Find an Analysis Rule

Try the options in order and stop at the first whose analysis rule flags the code to flag: each later option costs the user more to adopt and maintain.

#### 1. Known Analysis Rules

These are hard to find by searching, so check them first:

- **A `switch` statement over an enum that does not list every enum value** — a value added to the enum later falls silently into `default`, or into no branch at all:
  - `resharper_switch_statement_handles_some_known_enum_values_with_default_highlighting` flags a `switch` that lists some enum values and handles the rest in `default`
  - `resharper_switch_statement_missing_some_enum_cases_no_default_highlighting` flags a `switch` without `default` that misses some enum values
- **Calling a banned API** — a type, a member, a specific overload, or every symbol in a namespace: [BannedApiAnalyzers.Unity](#bannedapianalyzersunity)

#### 2. IDE Inspection

[Rider's C# code inspections](https://www.jetbrains.com/help/rider/Reference__Code_Inspections_CSHARP.html) lists every configurable inspection, each with its EditorConfig property (`resharper_<name>_highlighting`).
The page is long: read all of it, in parts (e.g., `WebFetch` with `offset`).

#### 3. Roslyn Analyzer Package

Search the analyzers the project already has first, then the others in [Known analyzer packages](#known-analyzer-packages).
Find the installed ones by the installation method:

1. UnityNuGet: the `org.nuget.<package ID in lowercase>` entries in `Packages/manifest.json`; also `com.nowsprinting.test-framework.analyzers`, which bundles NUnit.Analyzers
2. NuGetForUnity: the entries in its `packages.config` (by default in `Assets/`)

When neither has an analyzer package, the project has none.

#### 4. Custom Roslyn Analyzer

When no option above detects the pattern, propose writing an analyzer in the Unity project — the rule, with the code it should flag and should not — rather than setting it up: that is the user's decision.
[TestHelper.UI.Analyzers~](https://github.com/nowsprinting/test-helper.ui/tree/master/TestHelper.UI.Analyzers~) is an example to model it on:

- A .NET solution in a `~`-suffixed directory, which Unity's asset importer ignores; the built dll is committed next to the `.asmdef` of the assemblies it diagnoses
- Tests with xUnit and `Microsoft.CodeAnalysis.Testing`, runnable without Unity
- `Microsoft.CodeAnalysis` referenced at the version the project's Unity loads (see [Choosing a version](#choosing-a-version))
- Claude Code skills to specify (`design-diagnostic`) and implement (`implement-diagnostic`) a rule test-first, under `.claude/skills/`

### Step 2: Propose

Present to the user, via `AskUserQuestion`:

- The analysis rule found, and why each earlier option does not detect the pattern
- The changes that set it up, per [Configuration](#configuration)

### Step 3: Apply

Apply the changes the user approves.
Then ask the user to confirm that the code to flag gets the diagnostic at the configured severity, in Rider and, for an analyzer, in Unity's Console: an analyzer Unity cannot load reports nothing.

## Configuration

Set every analysis rule to `warning` or `error`: `/resolve-diagnostics` handles only `warning` or higher severity.

### Severity

Choose the file by where the diagnostic must appear:

- **In the IDE only** — `.editorconfig`, for an IDE inspection or an analyzer rule:

  ```ini
  [*.cs]
  resharper_switch_statement_missing_some_enum_cases_no_default_highlighting = warning
  dotnet_diagnostic.RS0030.severity = warning
  ```

  Tell the user that a Rider inspection appears in Rider only: team members on other IDEs do not see it.
- **In Unity's compilation too** — `.globalconfig`, for an analyzer rule; at `error`, the rule fails the compilation:

  ```ini
  is_global = true
  dotnet_diagnostic.RS0030.severity = error
  ```

  `Assets/Default.globalconfig` applies to the whole project; a `.globalconfig` next to an `.asmdef` applies to that assembly only, and replaces `Default.globalconfig` for it rather than merging with it.
  A `.globalconfig` has no sections by file type or path.
  A Unity version without `.globalconfig` support takes a `.ruleset` file instead (see [Analyzer scope and rule set files](https://docs.unity3d.com/Manual/analyzer-scope-and-diagnostics.html)).

### Roslyn Analyzer Package

#### Known analyzer packages

[Which version of Roslyn analyzers should I use with Unity?](https://github.com/nowsprinting/which-version-of-roslyn-analyzers-should-i-use-with-unity) lists these packages; each link is its list of rules:

- [IDisposableAnalyzers](https://github.com/DotNetAnalyzers/IDisposableAnalyzers#readme)
- [Meziantou.Analyzer](https://github.com/meziantou/Meziantou.Analyzer/blob/main/docs/README.md)
- [Microsoft.CodeAnalysis.NetAnalyzers](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/)
- [Microsoft.Unity.Analyzers](https://github.com/microsoft/Microsoft.Unity.Analyzers/blob/main/doc/index.md)
- [Microsoft.VisualStudio.Threading.Analyzers](https://github.com/microsoft/vs-threading/blob/main/docfx/analyzers/index.md)
- [NSubstitute.Analyzers.CSharp](https://github.com/nsubstitute/NSubstitute.Analyzers/blob/dev/documentation/rules/README.md)
- [NUnit.Analyzers](https://github.com/nunit/nunit.analyzers/blob/master/documentation/index.md)
- [Roslynator.Analyzers](https://josefpihrt.github.io/docs/roslynator/analyzers)
- [UTFAnalyzers](https://github.com/nowsprinting/test-framework.analyzers#readme)
- BannedApiAnalyzers.Unity and Microsoft.CodeAnalysis.BannedApiAnalyzers: see [BannedApiAnalyzers.Unity](#bannedapianalyzersunity)

#### Choosing a version

Unity bundles a fixed version of `Microsoft.CodeAnalysis.CSharp` and does not load an analyzer built against a newer one: the Console shows nothing, and only `Editor.log` has `warning CS9057`.
In the repository above, `<package ID>.md` tabulates which Unity versions load each version of the package: choose the newest version marked ✅ for the project's Unity version (`ProjectSettings/ProjectVersion.txt`).
For a package not listed there, tell the user that the repository's README describes how to have it checked.

#### Installing

Prefer UnityNuGet, which hosts NuGet packages as UPM packages on OpenUPM:

1. Add a scoped registry to `Packages/manifest.json` with the URL `https://package.openupm.com` and the scope `org.nuget`; when an entry with that URL exists, add the scope to it
2. Add the package as `org.nuget.<package ID in lowercase>` at the chosen version
3. Add `<package ID>_Unity` to the Assembly Definition References of each `.asmdef` to analyze; the analyzer also runs on every assembly that depends on it, directly or indirectly

Caveats:

- Before Unity 2022.2, turn off Assembly Version Validation (Project Settings > Player > Other Settings > Configuration); before Unity 2021.2, use NuGetForUnity instead
- A package installed with NuGetForUnity runs on every assembly in the project, including those in the package cache
- An analyzer dll added directly needs, in its import settings, every platform under Select platform for plugin turned off and the asset label `RoslynAnalyzer`; it runs on the assembly of the `.asmdef` in its directory or above, and on every assembly when there is none

### BannedApiAnalyzers.Unity

[BannedApiAnalyzers.Unity](https://github.com/nowsprinting/BannedApiAnalyzers.Unity) reports `RS0030` on any use of a banned symbol.
Prefer it to `Microsoft.CodeAnalysis.BannedApiAnalyzers`, which needs the path of its list in the `.csproj`; this fork reads Unity additional files instead, and requires Unity 2021.3 or later.
Install it as `BannedApiAnalyzers.Unity` per [Installing](#installing).

List the banned symbols in a file named `<Filename>.BannedApiAnalyzers.Unity.additionalfile` anywhere under `Assets/`, where `<Filename>` contains no period; split them into one file per concern when that helps.
Each line is a [documentation comment ID](https://github.com/dotnet/csharpstandard/blob/standard-v6/standard/documentation-comments.md#d42-id-string-format) with an optional description after `;`, shown in the diagnostic; `//` starts a comment:

```txt
// Finding by name breaks silently when the object is renamed
M:UnityEngine.GameObject.Find(System.String);Use a serialized reference instead
N:System.Reflection
```

Write the full parameter list of a method: an entry without one matches only an overload with no parameters, so on any other overload it silently matches nothing.
The repository's README tabulates the entry for each kind of symbol.
