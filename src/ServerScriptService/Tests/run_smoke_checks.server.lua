-- run_smoke_checks.server.lua
-- Programmatic smoke test runner. Creates a JSON-like summary in ReplicatedStorage and prints it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local TelemetryService = nil
pcall(function()
    TelemetryService = require(script.Parent.Parent:WaitForChild("Services"):FindFirstChild("TelemetryService") or nil)
end)

local function make_summary()
    local remotes = {}
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        for _, c in ipairs(remotesFolder:GetChildren()) do
            table.insert(remotes, { name = c.Name, className = c.ClassName })
        end
    end

    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    local enemiesCount = enemiesFolder and #enemiesFolder:GetChildren() or 0

    local playersCount = #Players:GetPlayers()

    local summary = {
        timestamp = os.time(),
        remotes = remotes,
        enemiesCount = enemiesCount,
        playersOnline = playersCount
    }

    return summary
end

local function to_json(tbl)
    -- lightweight serialization for simple tables
    local HttpService = game:GetService("HttpService")
    return pcall(function() return HttpService:JSONEncode(tbl) end) and HttpService:JSONEncode(tbl) or tostring(tbl)
end

task.spawn(function()
    wait(3) -- allow ServerBootstrap to initialize Remotes
    local s = make_summary()
    local j = to_json(s)

    -- Store in ReplicatedStorage for easy inspection in Studio
    local existing = ReplicatedStorage:FindFirstChild("SmokeReport")
    if existing and existing:IsA("StringValue") then
        existing.Value = j
    else
        local sv = Instance.new("StringValue")
        sv.Name = "SmokeReport"
        sv.Value = j
        sv.Parent = ReplicatedStorage
    end

    print("[run_smoke_checks] Smoke report:\n", j)

    if TelemetryService then
        pcall(function()
            TelemetryService:Emit("SmokeCheckRan", { remotes = #s.remotes, enemies = s.enemiesCount, players = s.playersOnline })
        end)
    end
end)
