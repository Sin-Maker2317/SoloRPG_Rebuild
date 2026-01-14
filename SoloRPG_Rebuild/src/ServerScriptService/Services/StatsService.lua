local Players = game:GetService("Players")

local StatsService = {}

-- Simple in-memory stats service v1
-- Stats: STR, AGI, VIT, INT, Level, Points

local defaultStats = function()
    return { STR = 1, AGI = 1, VIT = 5, INT = 1, Level = 1, Points = 0 }
end

local playerStats = {}

local function ensure(player)
    if not player then return end
    if not playerStats[player.UserId] then
        playerStats[player.UserId] = defaultStats()
    end
    return playerStats[player.UserId]
end

function StatsService:GetStats(player)
    return ensure(player)
end

function StatsService:GetDefense(player)
    local s = ensure(player)
    if not s then return 0 end
    -- simple formula: VIT contributes most to defense
    return (s.VIT * 1.5) + (s.Level * 0.5)
end

function StatsService:AllocatePoint(player, statName)
    local s = ensure(player)
    if not s or s.Points <= 0 then return false end
    if not s[statName] then return false end
    s[statName] = s[statName] + 1
    s.Points = s.Points - 1
    return true
end

Players.PlayerRemoving:Connect(function(p)
    playerStats[p.UserId] = nil
end)

return StatsService
