local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerStateService"))

local WorldService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("WorldService"))

local CombatService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("CombatService"))

local ProfileMemoryService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("ProfileMemoryService"))

WorldService:Init()

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
local ChoosePath = ensureRemoteEvent("ChoosePath")
local Attack = ensureRemoteEvent("Attack")
local ClientLog = ensureRemoteEvent("ClientLog")
local GateMessage = ensureRemoteEvent("GateMessage")
local SetGuildFaction = ensureRemoteEvent("SetGuildFaction")
local CompleteTutorial = ensureRemoteEvent("CompleteTutorial")

ClientLog.OnServerEvent:Connect(function(player, msg)
	print("[ClientLog]", player.Name, msg)
end)

-- === REMOTES LOGIC ===
GetPlayerState.OnServerInvoke = function(player)
	return PlayerStateService:Get(player)
end

ChoosePath.OnServerEvent:Connect(function(player, choice)
	print("[ChoosePath] from", player.Name, "choice:", choice)

	ProfileMemoryService:SetPathChoice(player, choice)

	if choice == "Solo" then
		PlayerStateService:Set(player, "SoloGateTutorial")
	elseif choice == "Guild" then
		PlayerStateService:Set(player, "GuildGateTutorial")
	end
end)

SetGuildFaction.OnServerEvent:Connect(function(player, factionId: string)
	ProfileMemoryService:SetGuildFaction(player, factionId)
end)

CompleteTutorial.OnServerEvent:Connect(function(player)
	PlayerStateService:Set(player, "HospitalChoice")
end)

Attack.OnServerEvent:Connect(function(player)
	print("[Attack] received from", player.Name)

	local character = player.Character
	if not character then
		print("[Attack] no character")
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		print("[Attack] no HRP")
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

	print("[Attack] closestDist:", closestDist, "found:", closestHumanoid ~= nil)

	if closestHumanoid and closestDist <= 30 then
		CombatService:DealDamage(closestHumanoid)
		print("[Attack] damage applied, target HP now:", closestHumanoid.Health)
	else
		print("[Attack] no target in range")
	end
end)

-- === PLAYER LIFECYCLE ===
PlayerStateService:Init()

Players.PlayerAdded:Connect(function(player)
	PlayerStateService:OnPlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerStateService:OnPlayerRemoving(player)
end)

print("[ServerBootstrap] Server avviato + Remotes pronti.")
print("[ServerBootstrap] Remotes children:", table.concat((function()
	local t = {}
	for _, c in ipairs(RemotesFolder:GetChildren()) do
		table.insert(t, c.Name .. ":" .. c.ClassName)
	end
	return t
end)(), ", "))