# unity-coding-skills

A [Claude Code](https://claude.ai/code) plugin for Unity development that enables coding agents to work autonomously through a test-first workflow — writing reliable, maintainable tests before production code, then iterating to completion without constant oversight.

Reliable tests give the agent a clear signal: green means done.
This plugin provides the methodology, conventions, and tools to make that signal trustworthy.

> [!TIP]\
> This plugin relies on Claude Code-specific features, such as the bundled `/simplify` skill and frontmatter fields of skills and subagents.
> If you use the skills with a different coding agent, please modify them accordingly.

## Skills

| Skill                      | Description                                                                                                    | Required                                                                                                                                                                                      | User-invocable |
|----------------------------|----------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| `code-writing-guide`       | Coding conventions and guidelines for Unity C# projects                                                        |                                                                                                                                                                                               |                |
| `edit-scene`               | Creates and modifies `.unity` and `.prefab` files                                                              | Rider built-in [MCP Server](https://www.jetbrains.com/help/rider/mcp-server.html) and [Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin | ✅             |
| `fix-bug`                  | Diagnoses and fixes bugs using a test-first workflow (reproduce, diagnose, fix)                                |                                                                                                                                                                                               | ✅             |
| `plan-feature`             | Orchestrates the test-first planning workflow for feature implementation in plan mode                          |                                                                                                                                                                                               | ✅             |
| `refine-tests`             | Reviews existing test code for conformance to the test design and writing guides, then applies the refinements |                                                                                                                                                                                               | ✅             |
| `resolve-diagnostics`      | Resolves IDE diagnostics at `warning` or higher severity in the specified files, then reformats them           | Rider built-in [MCP Server](https://www.jetbrains.com/help/rider/mcp-server.html)                                                                                                             | ✅             |
| `run-tests`                | Running Unity tests via the `run_unity_tests` tool                                                             | Rider built-in [MCP Server](https://www.jetbrains.com/help/rider/mcp-server.html) and [Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin | ✅             |
| `test-designing-guide`     | Design maintainable test cases; reduce redundant tests, tests without assertions, and unnecessary test doubles |                                                                                                                                                                                               |                |
| `test-writing-guide`       | Conventions for writing Unity Test Framework test code                                                         | [Test Helper](https://github.com/nowsprinting/test-helper) and [UI Test Helper](https://github.com/nowsprinting/test-helper.ui) package                                                       |                |
| `unity-yaml-editing-guide` | Guidelines for directly hand-editing Unity YAML asset files                                                    |                                                                                                                                                                                               |                |

> [!TIP]\
> Some skills require the JetBrains Rider built-in MCP server, IDE plugins, or UPM packages listed in the "Required" column above.
> If you don't use Rider or these packages, please modify the skill accordingly.

> [!TIP]\
> The Rider built-in MCP server also provides tools useful for coding agents, such as `list_directory_tree`, `search_file`, `search_regex`, `search_symbol`, and `search_text`.

## Subagents

| Agent                 | Description                                                                                                             |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------|
| `failing-test-writer` | Implements test code from the plan file's Test Cases table and confirms tests fail as expected (Step 2 of dev workflow) |
| `test-deduplicator`   | Removes duplicate tests and merges parameterizable tests in modified test files (Step 4 of dev workflow)                |
| `test-designer`       | Designs test cases during plan mode after class/method designs are produced, using the `test-designing-guide` skill     |

## Usage

### Test-first feature implementation planning

```bash
/plan-feature <SPEC>
```

The created plan file includes the following:

- Layered-designed test cases to reduce redundant tests, tests without assertions, and unnecessary test doubles:
  - Editor tests (Edit Mode tests for editor extensions and validate assets)
  - Unit tests (Play Mode tests for runtime code)
  - Integration tests including UI operation and layout assertions
  - Visual verification tests using image analysis
- Test-first development workflow
  - Effective (failable) test code
  - Definition of Done
  - Safe refactoring to improve internal quality (uses `/simplify` skill and static analysis)

> [!IMPORTANT]\
> This skill requires plan mode.

### Bug fixes through reproduction testing

```bash
/fix-bug <INCIDENT>
```

Create, run, and verify tests to reproduce the bug, then fix it.

> [!IMPORTANT]\
> This skill must be used outside plan mode.

> [!TIP]\
> The `INCIDENT` can specify an issue description or the failed test name.

> [!NOTE]\
> Depending on the incident, the root cause may be identified before writing a reproduction test. Under adjustment.

### Refine existing test code for conformance to the test design and writing guides

```bash
/refine-tests <PATH>
```

> [!NOTE]\
> This skill is intended for use outside plan mode, but it can also be used from plan mode.

## Installation

### User-scope installation

Add the marketplace and install the plugin:

```shell
/plugin marketplace add nowsprinting/unity-coding-skills
/plugin install unity-coding-skills@nowsprinting-unity-coding-skills
```

### Project-scope installation (team sharing)

Add the marketplace and install the plugin with `--scope project`:

```shell
/plugin marketplace add nowsprinting/unity-coding-skills
/plugin install unity-coding-skills@nowsprinting-unity-coding-skills --scope project
```

Commit the resulting `.claude/settings.json` to your repository.

> [!NOTE]\
> When team members trust the project folder, Claude Code prompts them to install the marketplace and plugin automatically.

## Recommended Rider and Unity Project Settings

### 1. MCP server configuration

Some skills require the JetBrains Rider built-in [MCP Server](https://www.jetbrains.com/help/rider/mcp-server.html) and extension plugin.

1. Open **Settings > Tools > MCP Server**
2. Turn on **Enable MCP Server**
3. Click the **Auto-Configure** button for the coding agent you use (e.g., Claude Code)
4. Install the [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin

> [!IMPORTANT]\
> JetBrains Rider 2026.2.1 or later is recommended.

> [!IMPORTANT]\
> On Rider 2026.2, when both the JetBrains and Rider MCP toolsets are enabled, they expose tools with the same name.
> Prefer the tools provided by Rider, and disable the duplicates:
> - Under the **Analysis** toolset: `get_file_problems`, `lint_files`
> - Under the **Formatting** toolset: `reformat_file`

> [!NOTE]\
> The MCP server is registered under different names depending on your Rider version: `rider` on Rider 2026.2 or later, `jetbrains` on versions earlier than 2026.2.

> [!NOTE]\
> When Rider is earlier than 2026.2 and you are using other JetBrains IDEs simultaneously with Rider, port numbers are assigned in the order they are launched.
> For example, if you launch Rider after IDEA, the port number for Rider will be `64343`.

> [!NOTE]\
> Once configured in Rider, the Rider built-in MCP Server and extension plugin work in other Unity projects without additional setup.

### 2. Install UTF Analyzers (strongly recommended)

[UTF Analyzers](https://github.com/nowsprinting/test-framework.analyzers) diagnose Unity Test Framework API usages that freeze the Unity Editor (e.g., `Assert.ThrowsAsync`, `async` delegates in `Throws` constraints, `DelayedConstraint`) before tests run.
Install either the [UPM package](https://openupm.com/packages/com.nowsprinting.test-framework.analyzers/) via OpenUPM or the [NuGet package](https://www.nuget.org/packages/UTFAnalyzers) via NuGetForUnity.

> [!TIP]\
> If you install the [UPM package](https://openupm.com/packages/com.nowsprinting.test-framework.analyzers/), you do not need to add a reference to the test assembly definition file (asmdef).
> It also installs the following:
> - Unity Test Framework v1.4.6 (dependency)
> - [NUnit.Analyzers](https://www.nuget.org/packages/NUnit.Analyzers) v3.9.0 (bundled)

### 3. Enforcing coding rules via analyzers and inspections

Some skills resolve Roslyn analyzer and IDE inspection diagnostics at `warning` or higher severity during the refactoring phase.
Therefore, any coding rule you want coding agents to respect must be set to `warning` or higher severity in `.editorconfig` or `.globalconfig`.

> [!TIP]\
> To add coding rules not covered by IDE inspections, you can install open-source Roslyn analyzers.
> Unity can load only analyzers built against the Roslyn version it supports, so check
> [Which version of Roslyn analyzers should I use with Unity?](https://github.com/nowsprinting/which-version-of-roslyn-analyzers-should-i-use-with-unity)
> for the version compatible with your project's Unity version.

Code written by coding agents often has maintainability problems, such as leftover unused members and overly complex methods.
The following settings examples help coding agents avoid them.

#### Example: Unused types and members

To prevent leaving unused types and members, add the following to `.editorconfig`:

```
resharper_unused_type_local_highlighting = warning
resharper_unused_type_global_highlighting = warning
resharper_unused_member_global_highlighting = warning
resharper_unused_member_local_highlighting = warning
```

#### Example: Method complexity

To keep method complexity under control, install one of the following Rider plugins:

- [CognitiveComplexity](https://plugins.jetbrains.com/plugin/12024-cognitivecomplexity) plugin
- [CyclomaticComplexity](https://plugins.jetbrains.com/plugin/10395-cyclomaticcomplexity) plugin

> [!WARNING]\
> In Rider 2026.2.1, there is an issue where the `get_file_problems` and `lint_files` tools fail to correctly return diagnostic messages from plugins.
> see: [RIDER-142275](https://youtrack.jetbrains.com/issue/RIDER-142275)

### 4. Untracking temporary files via `.gitignore`

Some skills place temporary editor script files under `Assets/UnityCodingSkills/`. Adding the following pattern to your project's `.gitignore` is recommended:

```gitignore
Assets/UnityCodingSkills*
```

## Contributing

Contributions are welcome. However, we will decline contributions that we cannot maintain — such as adding support for different coding agents or MCP servers. Please fork this repository and customize it for your needs instead.

## License

This project is released into the public domain under the [Unlicense](LICENSE).
