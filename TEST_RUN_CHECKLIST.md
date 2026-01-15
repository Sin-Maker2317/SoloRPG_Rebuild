# Test Run Checklist — SoloRPG_Rebuild

Purpose: concise steps to validate combat, persistence, remotes, and the recent roadmap items.

Preparations
- Open the project in Studio with Rojo running (if used).
- Ensure `src/ServerScriptService/ClearPlayerData.server.lua` has `ENABLE_CLEAR_ON_START = false` (default).
- Confirm `ReplicatedStorage/Remotes` is visible (created on server start by `ServerBootstrap`).

Quick smoke tests
1. Remotes existence
   - Verify `Attack`, `CombatEvent`, `UseSkill`, `RequestDodge`, `GetStatsSnapshot`, `GetStamina` exist under `ReplicatedStorage/Remotes`.

2. Basic Attack → HitConfirm
   - Spawn in Dev Platform, target a Grunt, press `F`.
   - Expect: enemy HP decreases and client receives `CombatEvent` payload `{ type = "HitConfirm", damage, targetName }`.

3. Skill usage → cooldown & stamina
   - Use `Q` (QuickSlash) then immediately again.
   - Expect: stamina reduced by 25, second cast blocked until cooldown; `CombatEvent` shows `SkillUsed`/`SkillFailed` as appropriate.

4. Dodge → iframe
   - Trigger `RequestDodge` while enemy is attacking.
   - Expect: stamina used (20) and `CombatEvent` with `DodgeStarted` or `DodgeFailed`.

5. GuardBreak → stun
   - Use `GuardBreak` against guarding enemy.
   - Expect: enemy stunned (1s) and subsequent hits apply full damage.

6. Spawn flags
   - Inspect an enemy model under `Workspace/Enemies` and confirm `IsEnemy` attribute is `true`.

7. Persistence test
   - With `ENABLE_CLEAR_ON_START = false`, earn XP/coins, restart server without enabling clear script, rejoin and verify DataStore keys still contain data.
   - If `ENABLE_CLEAR_ON_START = true`, the script will clear the configured user id on start.

8. Consolidated Attack handler
   - Confirm only one `Attack.OnServerEvent` handler is active in `ServerBootstrap.server.lua` (the authoritative one).

Advanced tests
- Gate & boss run: `StartGate` remote usage, defeat boss, validate reward ranges.
- PvP match creation: `CreateMatch` remote — create match and check `CombatEvent` responses.
- Invalid payloads: call remotes with malformed data and confirm server logs via `DebugService` instead of crashing.

Developer notes
- To run remote harness snippets, paste `tests/remote_harness_examples.lua` lines into Studio's Command Bar or create a small Script under `ServerScriptService/` with the code (adjust `player` references where needed).

Files changed by tests
- `src/ServerScriptService/ClearPlayerData.server.lua`: guard flag added (default disabled)
- `src/ServerScriptService/ServerBootstrap.server.lua`: removed duplicate/simple `Attack` handler; single authoritative handler remains

If you'd like, I can also extract `SoloRPG_Rebuild_inner_backup.zip` and list the files next.
