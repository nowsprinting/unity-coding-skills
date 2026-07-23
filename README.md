# unity-coding-skills

A [Claude Code](https://claude.ai/code) plugin for Unity development that enables coding agents to work autonomously through a test-first workflow — writing reliable, maintainable tests before production code, then iterating to completion without constant oversight.

Reliable tests give the agent a clear signal: green means done.
This plugin provides the methodology, conventions, and tools to make that signal trustworthy.

## Included Skills

| Skill                      | Description                                                                                                    | Required                                                                                                                                                                                  |
|----------------------------|----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `code-writing-guide`       | Coding conventions and guidelines for Unity C# projects                                                        |                                                                                                                                                                                           |
| `edit-scene`               | Creates and modifies `.unity` and `.prefab` files                                                              | [MCP server](https://www.jetbrains.com/help/rider/mcp-server.html) and [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin |
| `fix-bug`                  | Diagnoses and fixes bugs using a test-first workflow (reproduce, diagnose, fix)                                |                                                                                                                                                                                           |
| `plan-feature`             | Orchestrates the test-first planning workflow for feature implementation in plan mode                          |                                                                                                                                                                                           |
| `refine-tests`             | Reviews existing test code for conformance to the test design and writing guides, then plans the refinement    |                                                                                                                                                                                           |
| `run-tests`                | Running Unity tests via the `run_unity_tests` tool                                                             | [MCP server](https://www.jetbrains.com/help/rider/mcp-server.html) and [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin |
| `test-designing-guide`     | Design maintainable test cases; reduce redundant tests, tests without assertions, and unnecessary test doubles |                                                                                                                                                                                           |
| `test-writing-guide`       | Conventions for writing Unity Test Framework test code                                                         | [Test Helper](https://github.com/nowsprinting/test-helper) and [UI Test Helper](https://github.com/nowsprinting/test-helper.ui) package                                                   |
| `unity-yaml-editing-guide` | Guidelines for directly hand-editing Unity YAML asset files                                                    |                                                                                                                                                                                           |

## Included Subagents

| Agent                 | Description                                                                                                             |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------|
| `failing-test-writer` | Implements test code from the plan file's Test Cases table and confirms tests fail as expected (Step 2 of dev workflow) |
| `test-deduplicator`   | Removes duplicate tests and merges parameterizable tests in modified test files (Step 4 of dev workflow)                |
| `test-designer`       | Designs test cases during plan mode after class/method designs are produced, using the `test-designing-guide` skill     |

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

## Recommended Project Settings

### 1. MCP Server Configuration

The `run-tests` and `edit-scene` skills require the JetBrains Rider built-in MCP server and extension.

1. Enable built-in [MCP Server](https://www.jetbrains.com/help/rider/mcp-server.html)
2. Click the "Auto-Configure" button
3. Install [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin

> [!IMPORTANT]\
> When Rider is earlier than 2026.2 and you are using other JetBrains IDEs simultaneously with Rider, port numbers are assigned in the order they are launched.
> For example, if you launch Rider after IDEA, the port number for Rider will be `64343`.

> [!TIP]\
> The MCP server is registered under different names depending on your Rider version: `rider` on Rider 2026.2 or later, `jetbrains` on versions earlier than 2026.2.

> [!TIP]\
> The JetBrains MCP server also provides tools useful for the coding agents, e.g., `search_symbol`, `find_files_by_glob`.

### 2. Enforcing coding rules via `.editorconfig`

Any coding rules or Roslyn analyzer diagnostics you want Claude to respect should be set to `warning` or higher severity in `.editorconfig`.

For example, to prevent leaving unused code, add the following diagnostics:

```
resharper_unused_type_local_highlighting = warning
resharper_unused_type_global_highlighting = warning
resharper_unused_member_global_highlighting = warning
resharper_unused_member_local_highlighting = warning
```

The Rider plugins for measuring complexity are also useful:

- [CognitiveComplexity](https://plugins.jetbrains.com/plugin/12024-cognitivecomplexity)
- [CyclomaticComplexity](https://plugins.jetbrains.com/plugin/10395-cyclomaticcomplexity)

### 3. Ignoring temporary files via `.gitignore`

The skills place temporary editor script files under `Assets/UnityCodingSkills/`. Adding the following pattern to your project's `.gitignore` is recommended:

```gitignore
Assets/UnityCodingSkills*
```

## Usage

### Test-first feature implementation planning

Type in plan mode:

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
  - Run static analysis to improve internal quality
  - Run the Claude Code built-in `/simplify` skill

### Bug fixes through reproduction testing

Type out of plan mode:

```bash
/fix-bug <INCIDENT>
```

Create, run, and verify tests to reproduce the bug, then fix it.

> [!TIP]\
> The `INCIDENT` can specify an issue description or the failed test name.

> [!NOTE]\
> Depending on the incident, the root cause may be identified before writing a reproduction test. Under adjustment.

### Refine existing test code for conformance to the test design and writing guides

Type in plan mode:

```bash
/refine-tests <PATH>
```

## Contributing

Contributions are welcome. However, we will decline contributions that we cannot maintain — such as adding support for different coding agents or MCP servers. Please fork this repository and customize it for your needs instead.

## License

This project is released into the public domain under the [Unlicense](LICENSE).
