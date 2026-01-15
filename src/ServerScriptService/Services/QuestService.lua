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

-- Ensure player entry is created when they join
Players.PlayerAdded:Connect(function(player)
	if not playerQuests[player] then
		QuestService:CreatePlayer(player)
	end
end)

function QuestService:Snapshot(player)
	if not player then return { active = {}, completed = {} } end
	if not playerQuests[player] then self:CreatePlayer(player) end
	local q = playerQuests[player]
	return { active = q.active or {}, completed = q.completed or {} }
end

function QuestService:TryClaim(player, questId)
	if not player or type(questId) ~= "string" then return false, "invalid" end
	local qlist = playerQuests[player]
	if not qlist then return false, "no_quests" end
	for i,q in ipairs(qlist.active) do
		if q.id == questId then
			table.remove(qlist.active, i)
			table.insert(qlist.completed, q)
			if questUpdateRemote then
				pcall(function()
					questUpdateRemote:FireClient(player, { action = "complete", quest = q })
				end)
			end
			return true, "claimed"
		end
	end
	return false, "not_found"
end

return QuestService
