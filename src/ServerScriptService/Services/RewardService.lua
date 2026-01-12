local RewardService = {}
RewardService.__index = RewardService

local rewards = {} -- [player] = { xp=number, coins=number }

function RewardService:Get(player)
	local r = rewards[player]
	if not r then
		r = { xp = 0, coins = 0 }
		rewards[player] = r
	end
	return r
end

function RewardService:Add(player, xp, coins)
	local r = self:Get(player)
	r.xp += xp
	r.coins += coins
	return r
end

function RewardService:Clear(player)
	rewards[player] = nil
end

return RewardService
