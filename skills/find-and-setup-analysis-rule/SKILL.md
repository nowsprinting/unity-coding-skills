---
name: find-and-setup-analysis-rule
description: >-
  Finds an analysis rule that flags a given coding pattern — a Roslyn analyzer package, an IDE inspection, an IDE
  plugin, or a custom Roslyn analyzer — and sets it up in the Unity project at `warning` or higher severity.
  Use this skill when the user wants a coding pattern flagged as the code is written, e.g., to keep a fixed bug from
  recurring, to ban an API, to cap method complexity, or to enforce a coding rule.
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
Combine the argument with the coding pattern in the conversation, if any; when the argument is omitted, take it from the conversation alone.
A named API, e.g., "ban `GameObject.Find`", is the code to flag.
If the code to flag is missing, or the input fits several patterns, use `AskUserQuestion` to ask the user before proceeding.

## Workflow

### Step 1: Find an Analysis Rule

The options are listed in order of preference: an analyzer diagnoses in every IDE and in Unity's compilation, while an IDE inspection or plugin diagnoses in that IDE only.
Look into them in whatever order fits the pattern; when several have an analysis rule that flags the code to flag, choose the earliest listed.

#### Analysis Rules to Apply First

Each of these analysis rules takes precedence over every other rule for its pattern.
When the pattern matches one, propose it in Step 2 without searching the lists of rules below; set it up per its option below.

- **Using a banned API** — a type, a member, a specific overload, or every symbol in a namespace: `RS0030` of BannedApiAnalyzers.Unity, a [Roslyn analyzer package](#1-roslyn-analyzer-package); read `${CLAUDE_SKILL_DIR}/resources/banned-api-analyzers-unity.md`
- **A `switch` statement over an enum that does not list every enum value** — a value added to the enum later falls silently into `default`, or into no branch at all; [IDE inspections](#2-ide-inspection):
  - `resharper_switch_statement_handles_some_known_enum_values_with_default_highlighting` flags a `switch` that lists some enum values and handles the rest in `default`; it catches a `case` left unadded when a value is added to the enum
  - `resharper_switch_statement_missing_some_enum_cases_no_default_highlighting` flags a `switch` without `default` that misses some enum values

#### Searching the Lists of Rules

Search each list of rules in its own general-purpose subagent, launched in parallel, so that the lists stay out of this context.
Give each subagent the URL of the list and the coding pattern, with the code to flag and the code not to flag.
Have it read the whole list, in parts when the page is long (e.g., `WebFetch` with `offset`), then the documentation of each rule that may match, and return only the rules that flag the code to flag — each with its ID, what it flags, and its URL — or that the list has none.

#### 1. Roslyn Analyzer Package

Read `${CLAUDE_SKILL_DIR}/resources/roslyn-analyzer-package.md` first: it lists the known analyzer packages with what each flags, and tells how to choose a version of a package and install it.

Search the lists of rules of the known analyzer packages that may cover the pattern; when several packages flag the code to flag, prefer one the project already has.
Find the installed ones by the installation method:

1. UnityNuGet: the `org.nuget.<package ID in lowercase>` entries in `Packages/manifest.json`; also `com.nowsprinting.test-framework.analyzers`, which bundles NUnit.Analyzers
2. NuGetForUnity: the entries in its `packages.config` (by default in `Assets/`)

When neither has an analyzer package, the project has none.

#### 2. IDE Inspection

Search [Code Inspections in C# | ReSharper](https://www.jetbrains.com/help/resharper/Reference__Code_Inspections_CSHARP.html), which lists every configurable inspection, each with its EditorConfig property (`resharper_<name>_highlighting`).

#### 3. IDE Plugin

A plugin adds an inspection that the IDE lacks.
These are the known plugins, for Rider:

- **A method whose complexity exceeds a threshold** — propose cognitive complexity when the user says just "complexity":
  - Cognitive complexity: [CognitiveComplexity](https://plugins.jetbrains.com/plugin/12024-cognitivecomplexity), threshold 10 by default
  - Cyclomatic complexity: [CyclomaticComplexity](https://plugins.jetbrains.com/plugin/10395-cyclomaticcomplexity), threshold 20 by default

  Each reports a `warning` on a method above the threshold, which the user sets on the plugin's options page.

Only the user can install a plugin: propose it with its link, and in Step 3 ask the user to install it.
Tell the user that every team member has to install it to see the diagnostic.

#### 4. Custom Roslyn Analyzer

When no other option detects the pattern, propose writing an analyzer in the Unity project — the rule, with the code it should flag and should not — rather than setting it up: that is the user's decision.
[TestHelper.UI.Analyzers~](https://github.com/nowsprinting/test-helper.ui/tree/master/TestHelper.UI.Analyzers~) is an example to model it on:

- A .NET solution outside `Assets/`; only a UPM package project, which has no place outside the package, puts it in a `~`-suffixed directory, which Unity's asset importer ignores, as the example does
- The built dll committed next to the `.asmdef` of the assemblies it diagnoses
- Tests with xUnit and `Microsoft.CodeAnalysis.Testing`, runnable without Unity
- `Microsoft.CodeAnalysis` referenced at the version the project's Unity loads (see Choosing a Version in `${CLAUDE_SKILL_DIR}/resources/roslyn-analyzer-package.md`)
- Claude Code skills to specify (`design-diagnostic`) and implement (`implement-diagnostic`) a rule test-first, under `.claude/skills/`

### Step 2: Propose

Present to the user, via `AskUserQuestion`:

- The analysis rule found, and why it fits better than the other options looked into, if any
- The changes that set it up, per [Configuration](#configuration)

### Step 3: Apply

Apply the changes the user approves.
Then ask the user to:

1. Reopen the IDE from the Unity Editor (Assets > Open C# Project), so that the IDE loads the changes
2. Confirm that the code to flag gets the diagnostic at the configured severity, in Rider and, for an analyzer, in Unity's Console: an analyzer Unity cannot load reports nothing

## Configuration

Set every analysis rule to `warning` or `error`: `/resolve-diagnostics` handles only `warning` or higher severity.

### Severity

Two files take the severity of an analysis rule.
Choose the one that fits the files the project already has, with one exception: only `.globalconfig` meets a request to fail the compilation before the tests run, or to change the severity in Unity's compiler.

- **`.editorconfig`** — for an IDE inspection or an analyzer rule; it applies in the IDE only:

  ```ini
  [*.cs]
  resharper_switch_statement_missing_some_enum_cases_no_default_highlighting = warning
  dotnet_diagnostic.RS0030.severity = warning
  ```

  Tell the user that a Rider inspection appears in Rider only: team members on other IDEs do not see it.
- **`.globalconfig`** — for an analyzer rule; it applies in Unity's compilation too, which fails on an `error`:

  ```ini
  is_global = true
  dotnet_diagnostic.RS0030.severity = error
  ```

  `Assets/Default.globalconfig` applies to the whole project.
  A `.globalconfig` next to an `.asmdef` applies to that assembly only, which then reads nothing from `Default.globalconfig`: copy into it the entries the assembly still needs.
  A `.globalconfig` has no sections by file type or path.
  A Unity version without `.globalconfig` support takes a `.ruleset` file instead (see [Analyzer scope and rule set files](https://docs.unity3d.com/Manual/analyzer-scope-and-diagnostics.html)).

### Roslyn Analyzer Package

Choose the version of the package and install it per `${CLAUDE_SKILL_DIR}/resources/roslyn-analyzer-package.md`.
