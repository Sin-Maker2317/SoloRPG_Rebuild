local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local useSkill = remotes:FindFirstChild("UseSkill")
if not useSkill or not useSkill:IsA("RemoteEvent") then
    return warn("[UseSkillHandler] UseSkill remote missing")
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
