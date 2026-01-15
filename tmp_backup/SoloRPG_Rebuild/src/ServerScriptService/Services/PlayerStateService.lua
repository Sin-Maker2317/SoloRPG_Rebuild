-- ServerScriptService/Services/PlayerStateService.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameState = require(SharedFolder:WaitForChild("GameState"))

local WorldService = require(script.Parent:WaitForChild("WorldService"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))
local ProgressService = require(script.Parent:WaitForChild("ProgressService"))
local MobService = require(script.Parent:WaitForChild("MobService"))
local LootService = require(script.Parent:WaitForChild("LootService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))

local PlayerStateService = {}
PlayerStateService.__index = PlayerStateService

local playerState = {}
local lastSoloGateClear = {}

local COOLDOWN = 30

local function teleportToSpawn(player, spawnName)
	local cf = WorldService:GetSpawnCFrame(spawnName)
	if not cf then
		DebugService:Warn("Missing spawn:", spawnName)
		return
	end

	local function tp(char)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = cf + Vector3.new(0, 3, 0)
		end
	end

	if player.Character then
		tp(player.Character)
	else
		player.CharacterAdded:Once(tp)
	end
end

local function fireGateMessage(player, msg)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("GateMessage"):FireClient(player, msg)
end

local function fireStateChanged(player, state)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("StateChanged"):FireClient(player, state)
end

function PlayerStateService:Init() end

function PlayerStateService:Get(player)
	return playerState[player] or GameState.AwakeningDungeon
end

function PlayerStateService:Set(player, state)
	playerState[player] = state
	fireStateChanged(player, state)
	DebugService:Log("State set:", player.Name, state)

	if state == GameState.AwakeningDungeon then
		teleportToSpawn(player, "Spawn_AwakeningDungeon")
		return
	end

	if state == GameState.HospitalChoice then
		teleportToSpawn(player, "Spawn_Town")
		return
	end

	if state == GameState.OpenWorld then
		teleportToSpawn(player, "Spawn_Town")
		return
	end

	if state == GameState.SoloGateTutorial then
		local last = lastSoloGateClear[player]
		if last and os.clock() - last < COOLDOWN then
			fireGateMessage(player, "Gate is recharging...")
			self:Set(player, GameState.OpenWorld)
			return
		end

		local spawn = (math.random(1, 2) == 1) and "Spawn_SoloGate" or "Spawn_SoloGate2"
		teleportToSpawn(player, spawn)

		local dummyPosition = (spawn == "Spawn_SoloGate") and Vector3.new(0, 5, -240) or Vector3.new(-250, 5, 10)
		MobService:SpawnRandom(dummyPosition, function(mobKey, cfg, model)
			local r, item, xp, coins = LootService:AwardKill(player, mobKey)
			QuestService:OnKill(player)
			
			lastSoloGateClear[player] = os.clock()
			QuestService:OnGateCleared(player)
			
			local itemText = item and (" | Item: " .. item) or ""
			fireGateMessage(player, ("GATE CLEARED! Defeated %s: +%d XP +%d COINS%s | Total: %d XP, %d COINS"):format(mobKey, xp, coins, itemText, r.xp, r.coins))
			self:Set(player, GameState.OpenWorld)
		end)

		return
	end

	if state == GameState.GuildGateTutorial then
		teleportToSpawn(player, "Spawn_GuildHome")
		return
	end
end

function PlayerStateService:OnPlayerAdded(player)
	local prog = ProgressService:Get(player)
	playerState[player] = (prog.awakened and GameState.HospitalChoice) or GameState.AwakeningDungeon

	player.CharacterAdded:Connect(function()
		local s = self:Get(player)
		if s == GameState.AwakeningDungeon then
			teleportToSpawn(player, "Spawn_AwakeningDungeon")
		elseif s == GameState.HospitalChoice then
			teleportToSpawn(player, "Spawn_Town")
		else
			teleportToSpawn(player, "Spawn_Town")
		end
	end)
end

function PlayerStateService:OnPlayerRemoving(player)
	playerState[player] = nil
	lastSoloGateClear[player] = nil
	RewardService:Clear(player)
	ProgressService:Clear(player)
end

return PlayerStateService
