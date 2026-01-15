Start Gate1 Harness (developer)

This folder contains test helpers for local Studio testing.

start_gate1_harness.server.lua
- Guarded by `ENABLE_START = false` at top of file. Set to `true` in local development to run the Gate1 deterministic harness.
- The script looks for a boss model in `Workspace.Enemies` or `Workspace.Bosses` and starts the harness.
- Uses `TelemetryService` to emit simple events during the harness run.

run_smoke_checks.server.lua
- Generates `ReplicatedStorage.SmokeReport` (StringValue) with a JSON snapshot of remotes and counts. Useful for quick verification in Studio.

How to run
1. Open project in Studio with Rojo linked.
2. Ensure you have a boss model under `Workspace.Enemies` or `Workspace.Bosses`.
3. Set `ENABLE_START = true` in `start_gate1_harness.server.lua` and save.
4. Play (Start Server + Start Player) to observe telemetry logs and harness behavior.

Notes
- Keep `ENABLE_START` disabled on commit to avoid accidental runs in CI or teammates' environments.
- Harness and telemetry are minimal and intended for development only.
