-- ServerScriptService/Services/ProgressService.lua
local RunService = game:GetService("RunService")
local SaveService = require(script.Parent:WaitForChild("SaveService"))

local store = SaveService:GetDataStore("PlayerProgress_V1")

local ProgressService = {}
ProgressService.__index = ProgressService

local cache = {}
local IS_STUDIO = RunService:IsStudio()

local function key(userId: number)
	return "u_" .. tostring(userId)
end

function ProgressService:Load(player: Player)
	if not SaveService:IsSaveEnabledForPlayer(player) then
		cache[player] = { awakened = false, pathChoice = nil, faction = nil }
		return cache[player]
	end

	local data
	pcall(function()
		data = store:GetAsync(key(player.UserId))
	end)

	cache[player] = (type(data) == "table") and data or {
		awakened = false,
		pathChoice = nil,
		faction = nil
	}

	return cache[player]
end

function ProgressService:Get(player: Player)
	return cache[player] or self:Load(player)
end

function ProgressService:SetAwakened(player: Player, value: boolean)
	local p = self:Get(player)
	p.awakened = value
end

function ProgressService:SetPathChoice(player: Player, choice: string)
	if choice ~= "Solo" and choice ~= "Guild" then return end
	local p = self:Get(player)
	p.pathChoice = choice
end

function ProgressService:SetFaction(player: Player, faction: string)
	local p = self:Get(player)
	p.faction = faction
end

function ProgressService:Save(player: Player)
	if not SaveService:IsSaveEnabledForPlayer(player) then return end

	local p = cache[player]
	if not p then return end
	pcall(function()
		store:SetAsync(key(player.UserId), p)
	end)
end

function ProgressService:Clear(player: Player)
	self:Save(player)
	cache[player] = nil
end

return ProgressService

