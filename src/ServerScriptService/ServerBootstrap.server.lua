local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("DebugService"))

local PlayerStateService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerStateService"))

local WorldService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("WorldService"))

local CombatService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("CombatService"))

local ProfileMemoryService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("ProfileMemoryService"))

local RewardService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("RewardService"))
local AwakeningDeathService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("AwakeningDeathService"))
local AwakeningPuzzleService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("AwakeningPuzzleService"))
local ProgressService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("ProgressService"))
local QuestService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("QuestService"))
local InventoryService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("InventoryService"))

DebugService:Log("[ServerBootstrap] STARTING...")

WorldService:Init()
AwakeningDeathService:Init()

-- === REMOTES SETUP ===
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = ReplicatedStorage
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local rf = RemotesFolder:FindFirstChild(name)
	if rf and rf:IsA("RemoteFunction") then return rf end
	if rf then rf:Destroy() end

	rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = RemotesFolder
	return rf
end

local function ensureRemoteEvent(name: string): RemoteEvent
	local re = RemotesFolder:FindFirstChild(name)
	if re and re:IsA("RemoteEvent") then return re end
	if re then re:Destroy() end

	re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = RemotesFolder
	return re
end

local GetPlayerState = ensureRemoteFunction("GetPlayerState")
local GetRewards = ensureRemoteFunction("GetRewards")
local GetProgress = ensureRemoteFunction("GetProgress")
local GetQuests = ensureRemoteFunction("GetQuests")
local GetInventory = ensureRemoteFunction("GetInventory")
local ChoosePath = ensureRemoteEvent("ChoosePath")
local Attack = ensureRemoteEvent("Attack")
local ClientLog = ensureRemoteEvent("ClientLog")
local GateMessage = ensureRemoteEvent("GateMessage")
local StateChanged = ensureRemoteEvent("StateChanged")
local SetGuildFaction = ensureRemoteEvent("SetGuildFaction")
local CompleteTutorial = ensureRemoteEvent("CompleteTutorial")
local UseTerminal = ensureRemoteEvent("UseTerminal")
local ClaimQuest = ensureRemoteEvent("ClaimQuest")

ClientLog.OnServerEvent:Connect(function(player, msg)
	DebugService:Log("[ClientLog]", player.Name, msg)
end)

-- === REMOTES LOGIC ===
GetPlayerState.OnServerInvoke = function(player)
	return PlayerStateService:Get(player)
end

local RewardService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("RewardService"))

GetRewards.OnServerInvoke = function(player)
	local r = RewardService:Get(player)
	return { xp = r.xp, coins = r.coins }
end

GetProgress.OnServerInvoke = function(player)
	local p = ProgressService:Get(player)
	return { awakened = p.awakened, pathChoice = p.pathChoice, faction = p.faction }
end

GetQuests.OnServerInvoke = function(player)
	return QuestService:Snapshot(player)
end

GetInventory.OnServerInvoke = function(player)
	return InventoryService:List(player)
end

ChoosePath.OnServerEvent:Connect(function(player, choice)
	DebugService:Log("[ChoosePath] from", player.Name, "choice:", choice)

	-- Only accept valid path choices
	if choice ~= "Solo" and choice ~= "Guild" then
		return
	end

	ProgressService:SetPathChoice(player, choice)
	ProgressService:Save(player)

	if choice == "Solo" then
		PlayerStateService:Set(player, "SoloGateTutorial")
	elseif choice == "Guild" then
		PlayerStateService:Set(player, "GuildGateTutorial")
	end
end)

SetGuildFaction.OnServerEvent:Connect(function(player, factionId: string)
	DebugService:Log("[SetGuildFaction] from", player.Name, "faction:", factionId)

	if type(factionId) ~= "string" then
		return
	end

	if factionId ~= "Hunters" and factionId ~= "WhiteTiger" and factionId ~= "ChoiAssoc" then
		return
	end

	ProfileMemoryService:SetGuildFaction(player, factionId)
	ProgressService:SetFaction(player, factionId)
	ProgressService:Save(player)
end)

CompleteTutorial.OnServerEvent:Connect(function(player)
	PlayerStateService:Set(player, "HospitalChoice")
end)

UseTerminal.OnServerEvent:Connect(function(player, terminalName)
	if type(terminalName) ~= "string" then
		return
	end

	if terminalName == "GateTerminal_SoloE" then
		PlayerStateService:Set(player, "SoloGateTutorial")
		DebugService:Log("[UseTerminal]", player.Name, "used", terminalName)
	elseif terminalName == "GateTerminal_SoloE2" then
		PlayerStateService:Set(player, "SoloGateTutorial")
		DebugService:Log("[UseTerminal]", player.Name, "used", terminalName)
	end
end)

ClaimQuest.OnServerEvent:Connect(function(player, questId)
	local ok, msg = QuestService:TryClaim(player, questId)
	GateMessage:FireClient(player, msg)
end)

Attack.OnServerEvent:Connect(function(player)
	DebugService:Log("[Attack] received from", player.Name)

	local character = player.Character
	if not character then
		DebugService:Log("[Attack] no character")
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		DebugService:Log("[Attack] no HRP")
		return
	end

	local closestHumanoid = nil
	local closestDist = 999

	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m.Name == "DummyEnemy" then
			local h = m:FindFirstChildOfClass("Humanoid")
			local rp = m:FindFirstChild("HumanoidRootPart")
			if h and rp and h.Health > 0 then
				local d = (rp.Position - hrp.Position).Magnitude
				if d < closestDist then
					closestDist = d
					closestHumanoid = h
				end
			end
		end
	end

	DebugService:Log("[Attack] closestDist:", closestDist, "found:", closestHumanoid ~= nil)

	if closestHumanoid and closestDist <= 30 then
		CombatService:DealDamage(closestHumanoid)
		DebugService:Log("[Attack] damage applied, target HP now:", closestHumanoid.Health)
	else
		DebugService:Log("[Attack] no target in range")
	end
end)

-- === PLAYER LIFECYCLE ===
PlayerStateService:Init()
AwakeningPuzzleService:Init(
	function(player) return PlayerStateService:Get(player) end,
	function(player, state) PlayerStateService:Set(player, state) end
)

Players.PlayerAdded:Connect(function(player)
	RewardService:Load(player)
	PlayerStateService:OnPlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	RewardService:Save(player)
	PlayerStateService:OnPlayerRemoving(player)
	AwakeningPuzzleService:OnPlayerRemoving(player)
end)

DebugService:Log("[ServerBootstrap] Server started, remotes ready.")
DebugService:Log("[ServerBootstrap] Remotes children:", table.concat((function()
	local t = {}
	for _, c in ipairs(RemotesFolder:GetChildren()) do
		table.insert(t, c.Name .. ":" .. c.ClassName)
	end
	return t
end)(), ", "))