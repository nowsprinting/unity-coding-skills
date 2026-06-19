# Unity References

Always verify facts against primary sources before implementing.

## Unity Official Documentation

### Detected Unity Version

Project Unity version:
!`grep "m_EditorVersion:" ProjectSettings/ProjectVersion.txt 2>/dev/null | sed 's/m_EditorVersion: //' | grep . || echo unknown`

This returns a string like `6000.3.7f1`. Call it `<FULL_VERSION>`.  
For web URLs, truncate to `MAJOR.MINOR` (e.g., `6000.3`). Call it `<SHORT_VERSION>`.

**If version detected (not "unknown"):**
- Say: "This project is using Unity X.Y, so I'll use modern Unity APIs and C# features up to this version."
- Do NOT list features, do NOT ask for confirmation

**If version is "unknown":**
- Say: "Could not detect Unity version in this repository"
- Use AskUserQuestion: "Which Unity version should I target?" with common version options

### Official documentation

Check documentation in this order:

1. **Local**
    – macOS: `/Applications/Unity/Hub/Editor/<FULL_VERSION>/Documentation/`
    - Windows: `C:\Program Files\Unity\Hub\Editor\<FULL_VERSION>\Documentation\`
2. **Web**
    - `https://docs.unity3d.com/<SHORT_VERSION>/Documentation/Manual/UnityManual.html`
    - `https://docs.unity3d.com/<SHORT_VERSION>/Documentation/ScriptReference/index.html`

### Unity C# Reference

To access the C# portion of the Unity engine and editor source code, use the following repository:

`https://github.com/Unity-Technologies/UnityCsReference`

To match the project version, refer to the branch corresponding to `<SHORT_VERSION>` or the tag corresponding to `<FULL_VERSION>`.

### Unity Discussions

Unity Discussions (formerly the Unity Forum) uses Discourse, which employs virtual scrolling and is difficult for AI to read.
Use the print view by appending `/print` to the URL to retrieve the full content.

e.g., `https://discussions.unity.com/t/render-pipelines-strategy-for-2026/1710004/print`

## UPM Packages

Installed packages are cached under `Library/PackageCache/`. Start with `README.md`; refer to source files as needed.

## NuGet Packages

Installed packages are listed in `Assets/packages.config`. Find the source repository on nuget.org and reference it.