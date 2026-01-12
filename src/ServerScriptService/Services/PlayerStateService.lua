-- ServerScriptService/Services/PlayerStateService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameState = require(SharedFolder:WaitForChild("GameState"))

-- WorldService è nella stessa cartella Services
local WorldService = require(script.Parent:WaitForChild("WorldService"))
local EnemyService =
	require(script.Parent:WaitForChild("EnemyService"))

local PlayerStateService = {}
PlayerStateService.__index = PlayerStateService

-- Stato in memoria (per ora). Più avanti lo leghiamo ai profili / DataStore.
local playerState: {[Player]: string} = {}

local function isValidState(state: string): boolean
	for _, v in pairs(GameState) do
		if v == state then
			return true
		end
	end
	return false
end

local function teleportToSpawn(player: Player, spawnName: string)
	local cf = WorldService:GetSpawnCFrame(spawnName)
	if not cf then
		warn("[PlayerStateService] Spawn non trovato:", spawnName)
		return
	end

	local function doTeleport(character: Model)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		hrp.CFrame = cf + Vector3.new(0, 3, 0)
	end

	if player.Character then
		doTeleport(player.Character)
	else
		-- Se il character non è ancora pronto, teletrasporta appena spawnato
		local conn
		conn = player.CharacterAdded:Connect(function(char)
			conn:Disconnect()
			doTeleport(char)
		end)
	end
end

function PlayerStateService:Init()
	-- spazio per init futura
end

function PlayerStateService:Get(player: Player): string
	return playerState[player] or GameState.HospitalChoice
end

function PlayerStateService:Set(player: Player, state: string)
	if not isValidState(state) then
		warn(("[PlayerStateService] Stato non valido '%s' per %s"):format(tostring(state), player.Name))
		return
	end

	playerState[player] = state

	-- Teleport base per test flow
	if state == GameState.SoloGateTutorial then
		teleportToSpawn(player, "Spawn_SoloGate")
		EnemyService:SpawnDummyEnemy(Vector3.new(0, 5, -240))
	elseif state == GameState.GuildGateTutorial then
		teleportToSpawn(player, "Spawn_GuildHome")
	end
end

function PlayerStateService:OnPlayerAdded(player: Player)
	-- Per ora testiamo direttamente la scelta ospedale
	playerState[player] = GameState.HospitalChoice
end

function PlayerStateService:OnPlayerRemoving(player: Player)
	playerState[player] = nil
end

return PlayerStateService
