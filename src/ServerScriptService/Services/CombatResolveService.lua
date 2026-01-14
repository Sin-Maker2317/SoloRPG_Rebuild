-- ServerScriptService/Services/CombatResolveService.lua
local PlayerStatsService = require(script.Parent:WaitForChild("PlayerStatsService"))

local CombatResolveService = {}
CombatResolveService.__index = CombatResolveService

function CombatResolveService:CalculatePlayerDefense(player)
    -- Use PlayerStatsService to compute a simple defense value
    local def = PlayerStatsService:GetDefense(player)
    return tonumber(def) or 0
end

return CombatResolveService
