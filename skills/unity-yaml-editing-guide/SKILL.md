---
name: unity-yaml-editing-guide
description: >-
  Provides guidelines for directly editing Unity YAML-serialized asset files for Unity projects.
  Make sure to use this skill whenever creating, editing, or modifying simple YAML asset files (ScriptableObjects, Materials, etc.) via Edit/Write tools without going through the Unity Editor.
  This includes adjusting ScriptableObject field values, modifying material shader properties, or any task that results in direct changes to allowlisted Unity YAML asset files.
  Even for small edits or one-line value changes, load this skill to ensure Unity asset-YAML conventions are followed.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for directly editing Unity YAML-serialized asset files for Unity projects.

## Rules

- **Edit only the following allowlist of simple YAML asset types.**
  Other YAML assets (`AnimationClip`, `AnimatorController`, `Texture2D`, `Mesh`, `AudioClip`, `LightingDataAsset`, etc.) carry binary-derived data or complex internal structure — open them in Unity Editor instead.
  - ScriptableObject (`MonoBehaviour`, class ID 114) — files `*.asset`
  - Material (`Material`, class ID 21) — files `*.mat`

  `PhysicsMaterial` and `PhysicsMaterial2D` are excluded due to Unity version naming discrepancies — request user confirmation before editing one.
- **Never directly edit `.unity` or `.prefab` files.**
  Use `edit-scene` skill — those carry GameObject/Prefab-instance structure that is unsafe to author by hand.
- **Never touch `.meta` files.**
  Unity owns `.meta` content (GUIDs, importer settings); hand-edits corrupt asset references project-wide.
- **Use 2-space indent, LF line endings, UTF-8 without BOM, and a trailing newline at EOF.**
  Tabs, CRLF, or a BOM round-trip badly when Unity re-saves the file.
- **Do not add comments, YAML aliases (`*name`), extra tags, or chomping indicators (`|`, `>`).**
  Unity's YAML parser drops or rejects them, and re-save would strip cosmetic formatting anyway — don't bother polishing what Unity will normalize.
- **After editing, let Unity re-import the asset** (focus the Editor, or call `AssetDatabase.Refresh()` via `run_method_in_unity`) and confirm successful import using `get_unity_compilation_result`.
  Review the diff Unity produces on next save (`git diff`) to confirm the edit was accepted as intended and no data was dropped.
- **After editing a ScriptableObject asset, run its validator with the `run-tests` skill when the project has one.**
  A validator is an Edit Mode test that verifies the data of every asset of a `ScriptableObject` class, e.g., `CardValidator` for `Card`.
  A project may name it differently, so search the Edit Mode tests for the class name; when none exists, skip this.

## Resources

- Before editing any `.asset` or `.mat` file (header, `m_Script`, class-typed contents, or unfamiliar field): Read `${CLAUDE_SKILL_DIR}/resources/asset-yaml-format.md`
