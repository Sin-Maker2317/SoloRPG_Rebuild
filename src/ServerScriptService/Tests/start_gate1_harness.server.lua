-- start_gate1_harness.server.lua
-- Developer helper: starts the Gate1 deterministic harness for local testing.
-- Disabled by default; set ENABLE_START = true to run in Dev/Studio only.

local ENABLE_START = false -- set to true to enable

if not ENABLE_START then
    print("[start_gate1_harness] Disabled by default. Set ENABLE_START = true to enable.")
    return
end

local Workspace = game:GetService("Workspace")
local TelemetryService = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("TelemetryService"))
local harnessModule = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("BossService_Gate1Harness"))

-- Try to find a suitable boss model: first look in Workspace.Enemies, then Workspace.Bosses
local bossModel = nil
local enemies = Workspace:FindFirstChild("Enemies")
if enemies and #enemies:GetChildren() > 0 then
    bossModel = enemies:GetChildren()[1]
end

if not bossModel then
    local bosses = Workspace:FindFirstChild("Bosses")
    if bosses and #bosses:GetChildren() > 0 then
        bossModel = bosses:GetChildren()[1]
    end
end

if not bossModel then
    warn("[start_gate1_harness] No boss model found in Workspace.Enemies or Workspace.Bosses. Place a boss model and restart.")
    return
end

local harness = harnessModule.new(bossModel)
harness:Start()
print("[start_gate1_harness] Gate1 harness started for boss:", bossModel.Name)
TelemetryService:Emit("Gate1HarnessStarted", { boss = bossModel.Name })
