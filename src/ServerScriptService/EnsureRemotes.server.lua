local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureRemotesFolder()
    local ok, remotes = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 5)
    end)

    if not ok or not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "Remotes"
        remotes.Parent = ReplicatedStorage
    end

    return remotes
end

local remotes = ensureRemotesFolder()

local function ensureRemote(name, kind)
    if remotes:FindFirstChild(name) then
        return
    end

    if kind == "Function" then
        local rf = Instance.new("RemoteFunction")
        rf.Name = name
        rf.Parent = remotes
    else
        local re = Instance.new("RemoteEvent")
        re.Name = name
        re.Parent = remotes
    end
end

-- Names observed in client scripts / Net.lua that were not created previously
local ensureList = {
    { name = "GetStatsSnapshot", kind = "Function" },
    { name = "GetEquipmentSnapshot", kind = "Function" },
    { name = "UseSkill", kind = "Event" },
}

for _, info in ipairs(ensureList) do
    ensureRemote(info.name, info.kind)
end

-- wire GetStatsSnapshot to StatsService if available
local function safeRequire(moduleName)
    local servicesFolder = script.Parent:FindFirstChild("Services")
    if not servicesFolder then return nil end
    local mod = servicesFolder:FindFirstChild(moduleName)
    if not mod then return nil end
    local ok, res = pcall(function() return require(mod) end)
    return ok and res or nil
end

local statsService = safeRequire("StatsService") or safeRequire("PlayerStatsService")
local getStatsRF = remotes:FindFirstChild("GetStatsSnapshot")
if getStatsRF and getStatsRF:IsA("RemoteFunction") then
    if statsService and type(statsService.GetStats) == "function" then
        getStatsRF.OnServerInvoke = function(player)
            return statsService:GetStats(player)
        end
    else
        getStatsRF.OnServerInvoke = function()
            return {}
        end
    end
end

print("[EnsureRemotes] ensured basic client remotes are present and wired")
