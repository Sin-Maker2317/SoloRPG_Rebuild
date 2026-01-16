-- SaveService.lua
-- Thin wrapper around DataStoreService to allow disabling saves in Studio/test mode.
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local SaveService = {}
SaveService.__index = SaveService

-- Config: by default saves enabled; disabled automatically in Studio
local ENABLE_SAVES = true
if RunService:IsStudio() then
    ENABLE_SAVES = false
end

-- Optional list of usernames for which saves are disabled (test accounts)
local TEST_DISABLE_USERS = {
    -- add usernames here to disable saves for them
}

local inMemoryStores = {}
local warned = false

local function makeMemoryStore(name)
    local t = {}
    return {
        GetAsync = function(key)
            return t[key]
        end,
        SetAsync = function(key, value)
            t[key] = value
        end,
        _raw = t,
    }
end

function SaveService:IsSaveEnabledForPlayer(player)
    if not ENABLE_SAVES then return false end
    if player and type(player.Name) == "string" then
        for _, n in ipairs(TEST_DISABLE_USERS) do
            if n == player.Name then return false end
        end
    end
    return true
end

function SaveService:GetDataStore(name)
    if ENABLE_SAVES then
        -- returns real DataStore
        return DataStoreService:GetDataStore(name)
    end

    if not warned then
        warn("[SaveService] SAVE DISABLED (TEST MODE)")
        warned = true
    end
    inMemoryStores[name] = inMemoryStores[name] or makeMemoryStore(name)
    return inMemoryStores[name]
end

-- Expose config for runtime toggling in tests if needed
function SaveService:SetGlobalSavesEnabled(val)
    ENABLE_SAVES = not not val
end

return SaveService
