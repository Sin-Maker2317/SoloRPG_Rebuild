-- ServerScriptService/Services/AwakeningPuzzleService.lua

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugService = require(script.Parent:WaitForChild("DebugService"))
local ProgressService = require(script.Parent:WaitForChild("ProgressService"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))

local AwakeningPuzzleService = {}
AwakeningPuzzleService.__index = AwakeningPuzzleService

local solvedByPlayer = {} -- [player] = true
local plateState = {} -- [player] = {p1=true,p2=true,p3=true}

local function getPlayerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then return nil end
	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	return player
end

function AwakeningPuzzleService:Init(getStateFn, setStateFn)
	self.GetState = getStateFn
	self.SetState = setStateFn

	local world = Workspace:WaitForChild("World")
	local awakening = world:WaitForChild("Awakening")
	local plates = awakening:WaitForChild("Plates")
	local exitFolder = awakening:WaitForChild("Exit")
	local exitTrigger = exitFolder:WaitForChild("ExitTrigger")

	local p1 = plates:WaitForChild("Plate1")
	local p2 = plates:WaitForChild("Plate2")
	local p3 = plates:WaitForChild("Plate3")

	local function touchPlate(player, key)
		if not player then return end
		if self.GetState(player) ~= GameState.AwakeningDungeon then return end
		plateState[player] = plateState[player] or {p1=false,p2=false,p3=false}
		plateState[player][key] = true
		DebugService:Log("Plate touched:", player.Name, key)

		local st = plateState[player]
		if st.p1 and st.p2 and st.p3 and not solvedByPlayer[player] then
			solvedByPlayer[player] = true
			DebugService:Log("Puzzle solved by:", player.Name)

			local remotes = ReplicatedStorage:WaitForChild("Remotes")
			remotes:WaitForChild("GateMessage"):FireClient(player, "SYSTEM: Trial complete. Proceed to the exit.")
		end
	end

	p1.Touched:Connect(function(hit) touchPlate(getPlayerFromHit(hit), "p1") end)
	p2.Touched:Connect(function(hit) touchPlate(getPlayerFromHit(hit), "p2") end)
	p3.Touched:Connect(function(hit) touchPlate(getPlayerFromHit(hit), "p3") end)

	exitTrigger.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player then return end
		if self.GetState(player) ~= GameState.AwakeningDungeon then return end
		if not solvedByPlayer[player] then
			ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GateMessage"):FireClient(player, "SYSTEM: You cannot leave yet.")
			return
		end

		DebugService:Log("Exit reached:", player.Name)
		ProgressService:SetAwakened(player, true)
		ProgressService:Save(player)
		-- Transition to HospitalChoice (awakening ends)
		self.SetState(player, GameState.HospitalChoice)
	end)
end

function AwakeningPuzzleService:OnPlayerRemoving(player)
	solvedByPlayer[player] = nil
	plateState[player] = nil
end

return AwakeningPuzzleService

