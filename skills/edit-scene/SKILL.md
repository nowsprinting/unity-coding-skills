---
name: edit-scene
description: >-
  Creates and modifies Unity scene and prefab files. Use this skill whenever
  creating, editing, or modifying .unity scene files or .prefab prefab files.
  This includes adding GameObjects, building uGUI hierarchies, wiring up
  components, and any task that results in changes to .unity or .prefab files.
context: fork
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for creating and editing Unity scene files in Unity projects.

## Rules

- Do not directly Edit or Write `.unity` or `.prefab` files. Instead, write an editor script under `Assets/UnityCodingSkills/Editor/` and execute it in Unity to create or update the scene or prefab — those carry GameObject/Prefab-instance structure that is unsafe to author by hand.
- **Editor scripts must always end with `EditorSceneManager.SaveScene` (or `PrefabUtility.SaveAsPrefabAsset` for prefabs).** Treat "no dirty scenes/assets at script exit" as a hard postcondition.
  - Scene: `EditorSceneManager.SaveScene(scene, path)` (new) or `EditorSceneManager.SaveScene(scene)` (existing). The return value is `true` on success.
  - Prefab: `PrefabUtility.SaveAsPrefabAsset(go, path)`. When editing via `LoadPrefabContents`, always pair with `SaveAsPrefabAsset` → `UnloadPrefabContents`.
  - When the script also creates side-effect assets (Materials, ScriptableObjects, etc.), call `AssetDatabase.SaveAssets()` after the per-object saves to flush pending writes.
- Before running an editor script, check if the editor is in Play Mode using the `unity_play_control` tool. If it is, stop it first — Play Mode may skip recompilation, leaving stale code active.
- After modifying code, confirm compilation success using the `get_unity_compilation_result` tool before running.
- **To determine which assembly an editor script belongs to**, run `${CLAUDE_SKILL_DIR}/scripts/resolve-assembly.sh <cs-file-path>`. It walks up directories to find the nearest `.asmdef`; if none is found, it falls back to `Assembly-CSharp-Editor` (path contains `/Editor/`) or `Assembly-CSharp`.
- **Prefer the `run_method_in_unity` tool (MCP Server Extension for Unity) for execution.** Define a `public static` method in the script (adding `[MenuItem("Tools/...")]` is optional) and invoke it directly via `run_method_in_unity`. Only fall back to `execute_run_configuration` or other alternatives when `run_method_in_unity` is unavailable.
- **Delete the editor script (and its `.meta`) immediately after a successful run — do not leave it for manual removal.** Delete both from the filesystem after the run returns; never have the script delete itself — `AssetDatabase.DeleteAsset` on its own file triggers a domain reload mid-call (see the Troubleshooting resource below).
  - Treat a run as successful only when the response carries no `"type": "Error"` entry in `logs`. `success: true` alone means only that the method was invoked, not that it completed without throwing.
  - Confirm the change landed: `git diff` for an existing scene/prefab; for a newly created one (untracked, so no diff) confirm the file exists and its saved hierarchy matches the intent.
  - If the run failed, or the change did not fully land, keep the script until a fix succeeds — don't delete a script you may still need to correct and re-run.
  - The same applies when a fallback runner (`execute_run_configuration`, etc.) was used instead of `run_method_in_unity`.
- For uGUI buttons and text, use the **legacy variants** (`UnityEngine.UI.Button` / `UnityEngine.UI.Text`). Do not use TextMeshPro unless the user explicitly requests it.
- Apply context-menu-equivalent defaults when creating uGUI components (see Resources below).
- Give every GameObject the user operates (buttons, toggles, input fields, etc.) a name that makes its hierarchy path unique within the scene/prefab. Otherwise, automated tests cannot identify the GameObject.

## Gotchas

- **Never call two Unity Editor tools in parallel.** `unity_play_control`, `get_unity_compilation_result`, `run_method_in_unity`, and `run_unity_tests` must be called strictly one at a time — always wait for each call to return before making the next one. Calling them concurrently causes domain-reload conflicts that result in "canceled" or "did not connect within 30 seconds" errors.
- **When a Unity Editor tool returns `error` or `canceled`, wait 10 seconds before retrying.** Domain reload typically takes several seconds; immediate retry hits the same in-flight reload and fails again. Do not switch tools in the meantime (e.g., calling `unity_play_control` to verify state) — that just compounds the multiplexed calls. If the same tool returns `error` or `canceled` on two consecutive attempts (with the 10-second wait between them), stop and consult the user instead of retrying further.
- **`.meta` files follow an asymmetric lifecycle.** Never create them manually — Unity generates them automatically. Scene/prefab files (`.unity`, `.prefab`) and their referenced assets (materials, SOs, etc.) must be **committed** (required for GUID resolution); editor scripts under `Assets/UnityCodingSkills/Editor/` and their `.meta` must **never be committed** — see "Rules" above: delete both right after a successful run instead of leaving them behind. When a script must survive because the run failed and you stopped to consult the user, leave it out of the commit — but do not add it to `.gitignore` yourself; the plugin README recommends the user add `Assets/UnityCodingSkills*` to `.gitignore`, and otherwise the user excludes them at commit time.

## Scene lifecycle

- **New scene**: First determine whether the scene will be loaded additively or as a single scene, then choose the setup accordingly.
  - **Additive** (`LoadSceneMode.Additive`): `EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single)` — no camera or light needed.
  - **Single** (`LoadSceneMode.Single`): `EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single)` — Main Camera and Directional Light are included automatically; do not add a camera manually.
  - In both cases, place additional GameObjects via `ObjectFactory.CreateGameObject` and save with `EditorSceneManager.SaveScene(scene, "Assets/YourFeature/Scenes/XxxScene.unity")`.
- **Edit existing scene**: `EditorSceneManager.OpenScene(path, OpenSceneMode.Single)` → make changes → `EditorSceneManager.SaveScene(scene)`.
- **New prefab**: build the GameObject hierarchy in memory, then save with `PrefabUtility.SaveAsPrefabAsset(go, "Assets/YourFeature/Prefabs/XxxPrefab.prefab")`.
- **Edit existing prefab**: open with `PrefabUtility.LoadPrefabContents(path)` → modify → `PrefabUtility.SaveAsPrefabAsset(root, path)` → `PrefabUtility.UnloadPrefabContents(root)`.
- Use `ObjectFactory.CreateGameObject` / `ObjectFactory.AddComponent` so Undo history and Presets are applied automatically.
- Parent child objects with `transform.SetParent(parent, worldPositionStays: false)`.

## Resources

- Before writing or modifying any editor script that creates or manipulates uGUI components: Read `${CLAUDE_SKILL_DIR}/resources/ugui.md`

## Troubleshooting

- The `run_method_in_unity` tool is not available or fails with a connection error: Read `${CLAUDE_SKILL_DIR}/resources/troubleshooting-run-method-in-unity.md`
