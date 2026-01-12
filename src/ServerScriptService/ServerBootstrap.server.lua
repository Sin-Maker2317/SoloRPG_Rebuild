local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerStateService"))

local WorldService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("WorldService"))

WorldService:Init()

-- === REMOTES SETUP ===
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = ReplicatedStorage
end

local GetPlayerState = RemotesFolder:FindFirstChild("GetPlayerState")
if not GetPlayerState then
	GetPlayerState = Instance.new("RemoteFunction")
	GetPlayerState.Name = "GetPlayerState"
	GetPlayerState.Parent = RemotesFolder
end

local ChoosePath = RemotesFolder:FindFirstChild("ChoosePath")
if not ChoosePath then
	ChoosePath = Instance.new("RemoteEvent")
	ChoosePath.Name = "ChoosePath"
	ChoosePath.Parent = RemotesFolder
end

-- === REMOTES LOGIC ===
GetPlayerState.OnServerInvoke = function(player)
	return PlayerStateService:Get(player)
end

ChoosePath.OnServerEvent:Connect(function(player, choice)
	if choice == "Solo" then
		PlayerStateService:Set(player, "SoloGateTutorial")
	elseif choice == "Guild" then
		PlayerStateService:Set(player, "GuildGateTutorial")
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
