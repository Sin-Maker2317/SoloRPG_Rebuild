-- RemoteGuardService.lua
-- Centralized lightweight remote validation: rate-limiting, basic input sanitization, and helper checks.

local RemoteGuardService = {}
RemoteGuardService.__index = RemoteGuardService

local DebugService = nil
pcall(function()
    DebugService = require(script.Parent:WaitForChild("DebugService"))
end)

local HttpService = game:GetService("HttpService")

-- per-player last-invoke timestamps: weak keys to avoid leaks
local lastInvoke = setmetatable({}, { __mode = "k" })

-- default minimum intervals (seconds) per event to avoid spam
local DEFAULT_INTERVAL = 0.1
local MIN_INTERVALS = {
    Attack = 0.25,
    UseSkill = 0.25,
    RequestDodge = 0.5,
    StartGate = 1.0,
    CreateMatch = 1.0,
    EquipItem = 0.1,
}

local function log(...)
    if DebugService then
        DebugService:Log("[RemoteGuard]", ...)
    else
        print("[RemoteGuard]", ...)
    end
end

function RemoteGuardService:CanInvoke(player, eventName)
    if not player or not player.Parent then
        return false, "InvalidPlayer"
    end

    local now = os.clock()
    local per = lastInvoke[player]
    if not per then
        per = {}
        lastInvoke[player] = per
    end

    local min = MIN_INTERVALS[eventName] or DEFAULT_INTERVAL
    local last = per[eventName]
    if last and now - last < min then
        -- Throttle logging to avoid spamming output for aggressive clients
        local logKey = "_lastLog_" .. tostring(eventName)
        local lastLog = per[logKey] or 0
        local LOG_THROTTLE = 1.0
        if now - lastLog > LOG_THROTTLE then
            log(player.Name, "rate-limited for", eventName, string.format("(%.2fs < %.2fs)", now - last, min))
            per[logKey] = now
        end
        return false, "RateLimited"
    end

    per[eventName] = now
    return true
end

function RemoteGuardService:ValidateSkillId(skillId)
    if type(skillId) ~= "string" then return false end
    local ok, Skills = pcall(function()
        return require(script.Parent.Parent:WaitForChild("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Skills"))
    end)
    if not ok or not Skills or not Skills.Definitions then return true end -- be permissive if module missing
    return Skills.Definitions[skillId] ~= nil
end

function RemoteGuardService:IsTargetInRange(player, targetModel, maxRange)
    if not player or not player.Character then return false end
    if typeof(targetModel) ~= "Instance" or not targetModel:IsA("Model") then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local trp = targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
    if not hrp or not trp then return false end
    local dist = (hrp.Position - trp.Position).Magnitude
    return dist <= (maxRange or 40)
end

return RemoteGuardService
