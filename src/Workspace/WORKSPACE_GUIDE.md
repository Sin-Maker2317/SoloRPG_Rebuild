# Workspace Guide — SoloRPG_Rebuild

Goal: make `src/Workspace` understandable and safe to work with. This guide documents purpose, recommended structure, naming conventions, and non-destructive refactor suggestions.

**Purpose of `Workspace`**
- Holds in-world prefabs, dev/test platforms, and runtime scene objects that `ServerScriptService` handlers (e.g., `DevSpawnHandler`, `SpawnHandler`, enemy spawners) expect to find under `game.Workspace` at runtime.
- Should contain only assets intended to be instantiated or referenced at runtime; UI and scripts remain in their respective `StarterGui` / `ServerScriptService` folders.

**Recommended minimal structure**
- `Workspace/` (project folder)
  - `Enemies/` — enemy model prefabs referenced by `EnemyService` / `MobService` (kept as templates)
  - `DevPlatform/` — developer spawn platform used by `DevSpawnHandler` and tests
  - `TestNPCs/` — small folder for test-only NPCs (cleared in production)
  - `Gates/` — gate terminals and associated trigger parts
  - `Props/` — static world props used for blocking/visuals only
  - `README.txt` — this file (brief pointer)

Note: these are logical groupings inside the Workspace, not file-system moves. At runtime Roblox `Workspace` is a live container; this guide documents how to keep content organized during Studio editing.

**Naming conventions**
- Models: `Category_Name_Version` or `Name_Type` (e.g., `Enemy_Grunt_v1`, `Gate_SoloE`)
- Parts used as primary roots: include `HumanoidRootPart` for characters or `PrimaryPart` for rigid props
- Attributes: use `SetAttribute("IsEnemy", true)` on enemy templates so client lock-on logic (`LockOnController`) can identify them easily

**How code expects runtime layout**
- `EnemyService:SpawnEnemy` places spawned models under `Workspace:FindFirstChild("Enemies")` and sets `IsEnemy` attribute. Keep `Enemies` folder present in the Workspace while testing.
- `DevSpawnHandler`/`SpawnHandler` may rely on named parts under `DevPlatform` or other folders; keep those names stable to avoid runtime nil lookups.

**Safe, non-destructive refactors (recommended)**
- Add documentation files (this guide, README in subfolders) — safe.
- Create the logical subfolders described above and move template models into them — safe if you do NOT rename objects referenced by code. If a script references an object by name/path, update the script accordingly (do this with a single change and test).
- Add `IsEnemy` attribute to enemy templates (safe). Avoid deleting or renaming runtime objects unless you update all references.

**Refactors that require caution**
- Renaming or moving objects that are `FindFirstChild`-ed by server scripts (e.g., `DevPlatform`, `Enemies`) — you must update those scripts' lookup strings.
- Changing model primary part names or removing essential children (Humanoid, HumanoidRootPart) — will break spawns.

**Developer workflow recommendations**
- Keep a `Workspace/Dev/` folder for temporary artifacts used only during development and cleared before commits to `main`.
- When adding or moving prefabs, run the smoke tests in `TEST_RUN_CHECKLIST.md` (Attack, UseSkill, RequestDodge, Spawn flags) immediately to detect missing references.
- Use the `EnemyService` factory (`EnemyService:SpawnEnemy`) for runtime instantiation; prefer prefab templates with attributes instead of ad-hoc script-created parts.

**Checklist before committing Workspace changes**
- Verify `Workspace/Enemies` exists and enemy templates include `Humanoid` + `HumanoidRootPart` and `IsEnemy` attribute.
- Run `TEST_RUN_CHECKLIST.md` steps in Studio to confirm remotes and spawn handlers function.
- Search scripts for literal paths/names you changed and update them in a single commit.

**If you want, I can:**
- Create the proposed subfolders under `src/Workspace` and add placeholder README files inside each (non-destructive).  
- Add `IsEnemy` attribute to any enemy template models found in the repo (requires explicit permission to edit models/files).  

This guide is intentionally conservative: prefer adding docs and small non-destructive moves first, then make name/path changes only after updating code references and running the smoke tests.
