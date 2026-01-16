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

local function normalizeQuest(q)
	local out = {}
	out.id = q.id or q.name or q.title or "unnamed"
	out.title = q.title or q.name or q.id or "Quest"
	out.description = q.description or (q.objectives and table.concat(q.objectives, "; ")) or q.title or ""
	out.progress = q.progress or 0
	out.completed = q.completed or false
	out.objectives = q.objectives or {}
	return out
end

function QuestService:CreatePlayer(player)
	playerQuests[player] = { active = {}, completed = {} }
end

-- AddQuest: ensure only one active quest at a time for tutorial flows.
function QuestService:AddQuest(player, quest)
	if not playerQuests[player] then self:CreatePlayer(player) end
	local q = normalizeQuest(quest)
	-- enforce single active quest: replace existing active list
	playerQuests[player].active = { q }
	if questUpdateRemote then
		pcall(function() questUpdateRemote:FireClient(player, { action = "start", quest = q }) end)
	end
	return q
end

function QuestService:UpdateQuestProgress(player, questId, progress, detail)
	local qlist = playerQuests[player]
	if not qlist then return false end
	for _,q in ipairs(qlist.active) do
		if q.id == questId then
			q.progress = math.clamp(progress or q.progress, 0, 100)
			if questUpdateRemote then
				pcall(function() questUpdateRemote:FireClient(player, { action = "progress", quest = q, detail = detail }) end)
			end
			return true
		end
	end
	return false
end

function QuestService:CompleteQuest(player, questId)
	local qlist = playerQuests[player]
	if not qlist then return false end
	for i,q in ipairs(qlist.active) do
		if q.id == questId then
			q.completed = true
			q.progress = 100
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
			q.completed = true
			q.progress = 100
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
