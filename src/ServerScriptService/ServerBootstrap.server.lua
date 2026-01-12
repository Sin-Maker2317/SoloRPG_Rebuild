-- ServerScriptService/ServerBootstrap.server.lua
local Players = game:GetService("Players")

local PlayerStateService = require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerStateService"))

PlayerStateService:Init()

Players.PlayerAdded:Connect(function(player)
	PlayerStateService:OnPlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerStateService:OnPlayerRemoving(player)
end)

print("[ServerBootstrap] Server avviato.")
