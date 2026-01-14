-- ServerScriptService/Services/PlayerStatsService.lua
local PlayerStatsService = {}
PlayerStatsService.__index = PlayerStatsService

local stats = {} -- [player] = { def = number, points = number }

function PlayerStatsService:Load(player)
    if not stats[player] then
        stats[player] = { def = 0, points = 0 }
    end
    return stats[player]
end

function PlayerStatsService:Get(player)
    return stats[player] or self:Load(player)
end

function PlayerStatsService:AllocatePoint(player, field)
    local p = self:Load(player)
    if p.points <= 0 then return false end
    if field == "def" then
        p.def = p.def + 1
        p.points = p.points - 1
        return true
    end
    return false
end

function PlayerStatsService:GetDefense(player)
    local p = self:Load(player)
    return p.def or 0
end

function PlayerStatsService:Clear(player)
    stats[player] = nil
end

return PlayerStatsService
