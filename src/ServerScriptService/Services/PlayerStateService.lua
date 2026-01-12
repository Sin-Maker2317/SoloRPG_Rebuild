-- ServerScriptService/Services/PlayerStateService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))

local PlayerStateService = {}
PlayerStateService.__index = PlayerStateService

-- Stato in memoria (per ora). Più avanti lo leghiamo al profilo salvataggi.
local playerState: {[Player]: string} = {}

function PlayerStateService:Get(player: Player): string
	return playerState[player] or GameState.TutorialFakeDungeon
end

function PlayerStateService:Set(player: Player, state: string)
	playerState[player] = state
end

function PlayerStateService:Init()
	-- puoi aggiungere log qui se vuoi
end

function PlayerStateService:OnPlayerAdded(player: Player)
	-- Stato iniziale: tutorial fake dungeon
	playerState[player] = GameState.TutorialFakeDungeon
end

function PlayerStateService:OnPlayerRemoving(player: Player)
	playerState[player] = nil
end

return PlayerStateService
