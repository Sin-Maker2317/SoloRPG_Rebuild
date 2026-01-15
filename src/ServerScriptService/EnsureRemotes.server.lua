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

-- Try to read canonical remote list from Shared/Net.lua when available
local ok, Net = pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if not shared then return nil end
    local netMod = shared:FindFirstChild("Net")
    if not netMod then return nil end
    return require(netMod)
end)

if ok and Net then
    for k, v in pairs(Net) do
        -- heuristics: names starting with 'Get' are RemoteFunctions; others RemoteEvents
        local kind = "Event"
        if tostring(k):match("^Get") or tostring(k):match("Snapshot") then
            kind = "Function"
        end
        ensureRemote(v, kind)
    end
else
    -- fallback: ensure full canonical set from Net.lua (hardcoded) to avoid client yields
    local ensureList = {
        { name = "GetPlayerState", kind = "Function" },
        { name = "GetRewards", kind = "Function" },
        { name = "GetProgress", kind = "Function" },
        { name = "GetQuests", kind = "Function" },
        { name = "GetInventory", kind = "Function" },
        { name = "GetStatsSnapshot", kind = "Function" },
        { name = "GetCombatStats", kind = "Function" },
        { name = "GetEquipmentSnapshot", kind = "Function" },
        { name = "GetAvailableGates", kind = "Function" },
        { name = "GetStamina", kind = "Function" },
        { name = "QuestUpdate", kind = "Event" },
        { name = "GetGuildSnapshot", kind = "Function" },
        { name = "GetReputationSnapshot", kind = "Function" },
        { name = "GetStorySnapshot", kind = "Function" },

        { name = "ChoosePath", kind = "Event" },
        { name = "Attack", kind = "Event" },
        { name = "ClientLog", kind = "Event" },
        { name = "GateMessage", kind = "Event" },
        { name = "StateChanged", kind = "Event" },
        { name = "SetGuildFaction", kind = "Event" },
        { name = "CompleteTutorial", kind = "Event" },
        { name = "UseTerminal", kind = "Event" },
        { name = "ClaimQuest", kind = "Event" },
        { name = "CombatEvent", kind = "Event" },
        { name = "RequestDodge", kind = "Event" },
        { name = "AllocateStatPoint", kind = "Event" },
        { name = "UseSkill", kind = "Event" },
        { name = "EquipItem", kind = "Event" },
        { name = "EnterGate", kind = "Event" },
        { name = "ReserveGate", kind = "Event" },
        { name = "BuyGuildItem", kind = "Event" },
        { name = "SpawnGuildHelper", kind = "Event" },
        { name = "AdvanceStory", kind = "Event" },
    }
    for _, info in ipairs(ensureList) do
        ensureRemote(info.name, info.kind)
    end
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
