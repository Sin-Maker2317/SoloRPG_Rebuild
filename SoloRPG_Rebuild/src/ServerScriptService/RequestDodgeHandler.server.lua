local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestDodge = remotes:FindFirstChild("RequestDodge")
if not requestDodge or not requestDodge:IsA("RemoteEvent") then
    return warn("[RequestDodgeHandler] RequestDodge RemoteEvent not found")
end

local COOLDOWN = 0.6

local lastUsed = {}

requestDodge.OnServerEvent:Connect(function(player)
    if not player then return end
    local now = tick()
    local last = lastUsed[player.UserId] or 0
    if now - last < COOLDOWN then
        requestDodge:FireClient(player, false)
        return
    end

    lastUsed[player.UserId] = now

    -- mark player's character with a dodge timestamp for CombatResolveService to check
    local char = player.Character
    if char and char.SetAttribute then
        char:SetAttribute("LastDodgeTime", now)
    end
    requestDodge:FireClient(player, true)
end)
