-- ServerScriptService/Services/RewardService.lua
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("PlayerRewards_V1")

local RewardService = {}
RewardService.__index = RewardService

local cache = {}

function RewardService:Load(player)
	local data
	local ok = pcall(function()
		data = store:GetAsync("u_"..player.UserId)
	end)
	cache[player] = data or { xp = 0, coins = 0 }
end

function RewardService:Get(player)
	if not cache[player] then
		self:Load(player)
	end
	return cache[player]
end

function RewardService:Add(player, xp, coins)
	local r = self:Get(player)
	r.xp += xp
	r.coins += coins
	return r
end

function RewardService:Save(player)
	local r = cache[player]
	if not r then return end
	pcall(function()
		store:SetAsync("u_"..player.UserId, r)
	end)
end

function RewardService:Clear(player)
	self:Save(player)
	cache[player] = nil
end

return RewardService
