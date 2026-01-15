-- remote_harness_examples.lua
-- Paste snippet lines into Studio Command Bar or run as a small server script for quick remote checks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Example: invoke GetStatsSnapshot (RemoteFunction)
local function test_GetStatsSnapshot(player)
    local GetStatsSnapshot = Remotes:FindFirstChild("GetStatsSnapshot")
    if GetStatsSnapshot and GetStatsSnapshot:IsA("RemoteFunction") then
        local ok, res = pcall(function() return GetStatsSnapshot:InvokeServer() end)
        print("GetStatsSnapshot result:", ok and res or ("ERROR: " .. tostring(res)))
    else
        warn("GetStatsSnapshot not found")
    end
end

-- Example: fire Attack event
local function test_Attack()
    local Attack = Remotes:FindFirstChild("Attack")
    if Attack and Attack:IsA("RemoteEvent") then
        Attack:FireServer()
        print("Attack fired")
    else
        warn("Attack remote not found")
    end
end

-- Example: request dodge
local function test_RequestDodge()
    local RequestDodge = Remotes:FindFirstChild("RequestDodge")
    if RequestDodge and RequestDodge:IsA("RemoteEvent") then
        RequestDodge:FireServer()
        print("RequestDodge fired")
    else
        warn("RequestDodge remote not found")
    end
end

-- Example: use skill
local function test_UseSkill(skillId)
    local UseSkill = Remotes:FindFirstChild("UseSkill")
    if UseSkill and UseSkill:IsA("RemoteEvent") then
        UseSkill:FireServer(skillId)
        print("UseSkill fired for", skillId)
    else
        warn("UseSkill remote not found")
    end
end

-- Run quick examples (uncomment to run in command bar)
-- test_GetStatsSnapshot() -- RemoteFunction (ServerInvoke)
-- test_Attack()
-- test_RequestDodge()
-- test_UseSkill("QuickSlash")

return {
    test_GetStatsSnapshot = test_GetStatsSnapshot,
    test_Attack = test_Attack,
    test_RequestDodge = test_RequestDodge,
    test_UseSkill = test_UseSkill
}
