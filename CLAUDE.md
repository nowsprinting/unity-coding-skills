# CLAUDE.md

## Terminology

`GLOSSARY.md` defines the terms the skills share, e.g., specification, design docs, test design.
Follow it when writing or editing skills.
A plugin user's agent cannot read `GLOSSARY.md`, so define inline in a skill any term whose misreading could confuse the agent at runtime.

## Code Samples

Write the code samples in a skill so that they run on Unity 2019.
Where a newer Unity replaces an API a sample uses, leave the sample as it is: the agent reads it with the replacement.

## Scripts

Write a skill's scripts in Bash, not Python: on native Windows, Claude Code runs them with Git Bash, and Python is not guaranteed to be installed.
Name script files in snake_case (e.g., `resolve_test_target.sh`), following the Google Shell Style Guide.
Name AppleScript files in CamelCase (e.g., `DiscardCloseSceneHaveBeenModified.applescript`).
