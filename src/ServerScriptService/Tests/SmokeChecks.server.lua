-- SmokeChecks.server.lua
-- Lightweight runtime checks to verify remotes and workspace layout.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

local requiredRemotes = {
    "Attack",
    "CombatEvent",
    "UseSkill",
    "RequestDodge",
    "GetStatsSnapshot",
    "GetStamina"
}

task.spawn(function()
    wait(3) -- allow server bootstrap to create remotes

    print("[SmokeChecks] Starting checks...")

    if not Remotes then
        warn("[SmokeChecks] Remotes folder not found in ReplicatedStorage")
    else
        for _, name in ipairs(requiredRemotes) do
            local r = Remotes:FindFirstChild(name)
            if not r then
                warn("[SmokeChecks] Missing remote:", name)
            else
                print("[SmokeChecks] Found remote:", name, "(", r.ClassName, ")")
            end
        end
    end

    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then
        warn("[SmokeChecks] Workspace/Enemies folder not found; spawners may create it dynamically")
    else
        print("[SmokeChecks] Enemies folder present with", #enemies:GetChildren(), "children")
    end

    -- List first available player for manual remote tests
    local p = Players:GetPlayers()[1]
    if p then
        print("[SmokeChecks] Sample player for manual tests:", p.Name)
    else
        print("[SmokeChecks] No players online. For runtime remote tests, run the client harness in Studio.")
    end

    print("[SmokeChecks] Done.")
end)
