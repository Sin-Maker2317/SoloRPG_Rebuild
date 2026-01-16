local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Wait up to 10 seconds for the remote to be created by EnsureRemotes
local useSkill = remotes:WaitForChild("UseSkill", 10)
if not useSkill then
    warn("[UseSkillHandler] UseSkill remote not found after 10s; handler disabled")
    return
end
if not useSkill:IsA("RemoteEvent") then
    warn("[UseSkillHandler] UseSkill exists but is not a RemoteEvent; handler disabled")
    return
end

local function safeRequire(name)
    local ok, mod = pcall(function()
        local s = script.Parent:FindFirstChild(name) or (script.Parent:FindFirstChild("Services") and script.Parent.Services:FindFirstChild(name))
        if s then return require(s) end
        return nil
    end)
    return ok and mod or nil
end

useSkill.OnServerEvent:Connect(function(player, skillId, target)
    local SkillService = safeRequire("SkillService")
    if not SkillService then
        useSkill:FireClient(player, { success = false, reason = "no_skill_service" })
        return
    end
    pcall(function()
        SkillService:Init()
        local res = SkillService:UseSkill(player, skillId, target)
        useSkill:FireClient(player, res)
    end)
end)
