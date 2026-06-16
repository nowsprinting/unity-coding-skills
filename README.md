# unity-coding-skills

A [Claude Code](https://claude.ai/code) plugin for Unity development that enables coding agents to work autonomously through a test-first workflow — writing reliable, maintainable tests before production code, then iterating to completion without constant oversight.

Reliable tests give the agent a clear signal: green means done.
This plugin provides the methodology, conventions, and tools to make that signal trustworthy.

## Included Skills

| Skill                      | Description                                                                                                    | Required                                                                                                                                                                                            |
|----------------------------|----------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `code-writing-guide`       | Coding conventions and guidelines for Unity C# projects                                                        |                                                                                                                                                                                                     |
| `edit-scene`               | Creates and modifies `.unity` and `.prefab` files                                                              | JetBrains [MCP server](https://www.jetbrains.com/help/rider/mcp-server.html) and [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin |
| `fix-bug`                  | Diagnoses and fixes bugs using a test-first workflow (reproduce, diagnose, fix)                                |                                                                                                                                                                                                     |
| `plan-feature`             | Orchestrates the test-first planning workflow for feature implementation in plan mode                          |                                                                                                                                                                                                     |
| `refine-tests`             | Reviews existing test code for conformance to the test design and writing guides, then plans the refinement    |                                                                                                                                                                                                     |
| `run-tests`                | Running Unity tests via the `run_unity_tests` tool                                                             | JetBrains [MCP server](https://www.jetbrains.com/help/rider/mcp-server.html) and [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin |
| `test-designing-guide`     | Design maintainable test cases; reduce redundant tests, tests without assertions, and unnecessary test doubles |                                                                                                                                                                                                     |
| `test-writing-guide`       | Conventions for writing Unity Test Framework test code                                                         | [Test Helper](https://github.com/nowsprinting/test-helper) and [UI Test Helper](https://github.com/nowsprinting/test-helper.ui) package                                                             |
| `unity-yaml-editing-guide` | Guidelines for directly hand-editing Unity YAML asset files                                                    |                                                                                                                                                                                                     |

## Included Agents

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

The `run-tests` and `edit-scene` skills require JetBrains built-in MCP server and extension.

1. Enable JetBrains built-in [MCP server](https://www.jetbrains.com/help/rider/mcp-server.html)
2. Install [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity)
3. Add the following to your project `.mcp.json` or user MCP settings:

```json
{
  "mcpServers": {
    "jetbrains": {
      "type": "http",
      "url": "http://localhost:64342/stream"
    }
  }
}
```

> [!IMPORTANT]\
> Do not change the MCP server name `jetbrains`.

> [!TIP]\
> The JetBrains MCP server also provides tools useful for Coding Agents, such as `search_symbol` and `search_in_files_by_regex`.

### 2. Enforcing coding rules via `.editorconfig`

Any coding rules or Roslyn analyzer diagnostics you want Claude to respect should be set to `warning` or higher severity in `.editorconfig`.

For example, to prevent leaving unused code, add the following diagnostics:

```
resharper_unused_type_local_highlighting = warning
resharper_unused_type_global_highlighting = warning
resharper_unused_member_global_highlighting = warning
resharper_unused_member_local_highlighting = warning
```

The Rider plugin for measuring complexity is also useful.
e.g., [CognitiveComplexity](https://plugins.jetbrains.com/plugin/12024-cognitivecomplexity), [CyclomaticComplexity](https://plugins.jetbrains.com/plugin/10395-cyclomaticcomplexity)

## Usage

### Test-first feature implementation planning

Type in plan mode:

```bash
/plan-feature <SPEC>
```

The created plan file includes the following:

- Layered-designed test cases
  - Reduce redundant tests, tests without assertions, and unnecessary test doubles
  - Editor tests
  - Unit tests (Play Mode tests)
  - Integrated tests including UI operation
  - Visual verification tests using image analysis
- Test-first development workflow
  - Effective (failable) test code
  - Definition of Done

### Bug fixes through reproduction testing

Type out of plan mode:

```bash
/fix-bug <INCIDENT>
```

Specify a problem description or a failing test as `INCIDENT`.

First, create, run, and verify a test that reproduces the bug, and then fix the bug.

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
