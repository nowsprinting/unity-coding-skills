# Roslyn Analyzer Package

Covers the known Roslyn analyzer packages for Unity, choosing the version of a package that the project's Unity loads, and installing it.

Out of scope:

- Severity of an analyzer rule — see Severity in the skill's `SKILL.md`
- Banning APIs with BannedApiAnalyzers.Unity — see [banned-api-analyzers-unity.md](banned-api-analyzers-unity.md)

## Known Analyzer Packages

The packages are listed from the narrowest purpose to the broadest; each link is the package's list of rules, and what follows it is what the rules flag, by the categories of that list:

- BannedApiAnalyzers.Unity and Microsoft.CodeAnalysis.BannedApiAnalyzers — uses of the APIs a project bans: see [banned-api-analyzers-unity.md](banned-api-analyzers-unity.md)
- [IDisposableAnalyzers](https://github.com/DotNetAnalyzers/IDisposableAnalyzers#readme) — `IDisposable` misuse: a created disposable left undisposed or ignored, a wrongly implemented dispose pattern
- [NSubstitute.Analyzers.CSharp](https://github.com/nsubstitute/NSubstitute.Analyzers/blob/dev/documentation/rules/README.md) — NSubstitute misuse: non-substitutable member, substitute creation, argument specification, call configuration, usage
- [NUnit.Analyzers](https://github.com/nunit/nunit.analyzers/blob/master/documentation/index.md) — NUnit test code: structure (test methods and their attributes), assertion, style
- [UTFAnalyzers](https://github.com/nowsprinting/test-framework.analyzers#readme) — Unity Test Framework test code, e.g., NUnit APIs it does not support: structure, assertion, style, extensions (custom attributes)
- [Microsoft.VisualStudio.Threading.Analyzers](https://github.com/microsoft/vs-threading/blob/main/docfx/analyzers/index.md) — `async` and threading misuse: critical (often results in a deadlock), advisory (e.g., `async void`, an unobserved async call), guideline (e.g., the `Async` suffix)
- [Microsoft.Unity.Analyzers](https://github.com/microsoft/Microsoft.Unity.Analyzers/blob/main/doc/index.md) — Unity API misuse: performance, correctness, type safety, readability
- [Microsoft.CodeAnalysis.NetAnalyzers](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/) — .NET code quality: design, documentation, globalization, portability and interoperability, maintainability, naming, performance, reliability, security, usage
- [Meziantou.Analyzer](https://github.com/meziantou/Meziantou.Analyzer/blob/main/docs/README.md) — general C# good practices: design, usage, performance, style, naming, security
- [Roslynator.Analyzers](https://josefpihrt.github.io/docs/roslynator/analyzers) — general C#, uncategorized: mostly simplification and readability, with some correctness and performance

## Choosing a Version

Unity bundles a fixed version of `Microsoft.CodeAnalysis.CSharp` and does not load an analyzer built against a newer one: the Console shows nothing, and only `Editor.log` has `warning CS9057`.
In the repository [Which version of Roslyn analyzers should I use with Unity?](https://github.com/nowsprinting/which-version-of-roslyn-analyzers-should-i-use-with-unity), `<package ID>.md` tabulates which Unity versions load each version of the package: choose the newest version marked ✅ for the project's Unity version (`ProjectSettings/ProjectVersion.txt`).
For a package not listed there, tell the user that the repository's README describes how to have it checked.

## Installing

Install with UnityNuGet, which serves NuGet packages as UPM packages, when all the conditions hold; otherwise, with NuGetForUnity:

- The project's Unity version is 2021.2 or later
- The project has no `Assets/NuGet.config`, the sign of a project that uses NuGetForUnity
- UnityNuGet serves the package:
  for a package listed in the repository in [Choosing a Version](#choosing-a-version), its `<package ID>.md` says so with "You can install … as a UPM package converted by UnityNuGet";
  when the page lacks that sentence, or the repository does not list the package, UnityNuGet's [registry.json](https://raw.githubusercontent.com/bdovaz/UnityNuGet/master/registry.json) has the package ID as a key

### UnityNuGet

1. Add a scoped registry to `Packages/manifest.json`:

   ```json
   {
     "name": "UnityNuGet packages via OpenUPM",
     "url": "https://unitynuget-registry.openupm.com",
     "scopes": [
       "org.nuget"
     ]
   }
   ```

   When an entry with the URL `https://package.openupm.com` exists, add the scope `org.nuget` to that entry instead: the OpenUPM registry serves the UnityNuGet packages too.
2. Add the package to `dependencies` as `org.nuget.<package ID in lowercase>` at the chosen version
3. Add `<package ID>_Unity` to the Assembly Definition References of each `.asmdef` to analyze; the analyzer also runs on every assembly that depends on it, directly or indirectly
4. Before Unity 2022.2, turn off Assembly Version Validation (Project Settings > Player > Other Settings > Configuration)

### Other Methods

- A package installed with NuGetForUnity runs on every assembly in the project, including those in the package cache
- An analyzer dll added directly needs, in its import settings, every platform under Select platform for plugin turned off and the asset label `RoslynAnalyzer`; it runs on the assembly of the `.asmdef` in its directory or above, and on every assembly when there is none
