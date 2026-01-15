-- QuestService.lua
-- Lightweight server-side quest manager for Test Phase (temporary, extendable)

local QuestService = {}
QuestService.__index = QuestService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
local questUpdateRemote = nil
if remoteFolder then
    questUpdateRemote = remoteFolder:FindFirstChild("QuestUpdate") or Instance.new("RemoteEvent")
    questUpdateRemote.Name = "QuestUpdate"
    questUpdateRemote.Parent = remoteFolder
end

local playerQuests = {}

function QuestService:CreatePlayer(player)
    playerQuests[player] = { active = {}, completed = {} }
end

function QuestService:AddQuest(player, quest)
    if not playerQuests[player] then self:CreatePlayer(player) end
    table.insert(playerQuests[player].active, quest)
	return QuestService
		claimedKills = p.claimedKills,
	}
end

function QuestService:TryClaim(player, questId)
	local p = self:Get(player)

	if questId == "ClearGates" then
		if p.claimedGate then return false, "Already claimed." end
		if p.gateClears < 3 then return false, "Not complete." end
		p.claimedGate = true
		return true, "Claimed ClearGates."
	end

	if questId == "KillEnemies" then
		if p.claimedKills then return false, "Already claimed." end
		if p.kills < 10 then return false, "Not complete." end
		-- QuestService.lua
		-- Lightweight server-side quest manager for Test Phase (temporary, extendable)

		local QuestService = {}
		QuestService.__index = QuestService

		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local questUpdateRemote = nil
		if remotes then
			questUpdateRemote = remotes:FindFirstChild("QuestUpdate")
			if not questUpdateRemote then
				questUpdateRemote = Instance.new("RemoteEvent")
				questUpdateRemote.Name = "QuestUpdate"
				questUpdateRemote.Parent = remotes
			end
		end

		local playerQuests = {}

		function QuestService:CreatePlayer(player)
			playerQuests[player] = { active = {}, completed = {} }
		end

		function QuestService:AddQuest(player, quest)
			if not playerQuests[player] then self:CreatePlayer(player) end
			table.insert(playerQuests[player].active, quest)
			if questUpdateRemote then
				pcall(function() questUpdateRemote:FireClient(player, { action = "start", quest = quest }) end)
			end
		end

		function QuestService:CompleteQuest(player, questId)
			local qlist = playerQuests[player]
			if not qlist then return end
			for i,q in ipairs(qlist.active) do
				if q.id == questId then
					table.remove(qlist.active, i)
					table.insert(qlist.completed, q)
					if questUpdateRemote then
						pcall(function() questUpdateRemote:FireClient(player, { action = "complete", quest = q }) end)
					end
					return true
				end
			end
			return false
		end

		function QuestService:GetActiveQuests(player)
			return (playerQuests[player] and playerQuests[player].active) or {}
		end

		Players.PlayerRemoving:Connect(function(player)
			playerQuests[player] = nil
		end)

		return QuestService
