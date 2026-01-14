local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local devRemote = remotes:WaitForChild("DevTools")
local useSkill = remotes:FindFirstChild("UseSkill")
local getStats = remotes:FindFirstChild("GetStatsSnapshot")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevTestPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,240,0,320)
frame.Position = UDim2.new(0,8,0,8)
frame.BackgroundTransparency = 0.25
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,28)
title.BackgroundTransparency = 1
title.Text = "Dev Test Panel"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

local function makeButton(text, y, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-12,0,28)
    btn.Position = UDim2.new(0,6,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        pcall(cb)
    end)
    return btn
end

local y = 36
makeButton("Spawn NPC", y, function()
    devRemote:FireServer("SpawnNPC")
end)
y = y + 34
makeButton("Teleport To NPC", y, function()
    devRemote:FireServer("TeleportToNPC")
end)
y = y + 34
makeButton("Toggle AI", y, function()
    devRemote:FireServer("ToggleAI")
end)
y = y + 34
makeButton("Damage Self (10)", y, function()
    devRemote:FireServer("DamageSelf", 10)
end)
y = y + 34
makeButton("Heal Self (10)", y, function()
    devRemote:FireServer("HealSelf", 10)
end)

y = y + 34
makeButton("Skill: Slash", y, function()
    if useSkill then useSkill:FireServer("Slash") end
end)
y = y + 34
makeButton("Skill: Heavy", y, function()
    if useSkill then useSkill:FireServer("Heavy") end
end)
y = y + 34
makeButton("Skill: PowerStrike", y, function()
    if useSkill then useSkill:FireServer("PowerStrike") end
end)

y = y + 36
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1,-12,0,60)
statsLabel.Position = UDim2.new(0,6,0,y)
statsLabel.BackgroundTransparency = 0
statsLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
statsLabel.TextColor3 = Color3.fromRGB(220,220,220)
statsLabel.Text = "Stats: (click)\nClick to refresh"
statsLabel.TextWrapped = true
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 14
statsLabel.Parent = frame

statsLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if getStats and getStats:IsA("RemoteFunction") then
            local ok, result = pcall(function()
                return getStats:InvokeServer()
            end)
            if ok and type(result) == "table" then
                statsLabel.Text = "STR:"..tostring(result.STR or "-").." AGI:"..tostring(result.AGI or "-").." VIT:"..tostring(result.VIT or "-").." INT:"..tostring(result.INT or "-").."\nLevel:"..tostring(result.Level or "-").." Points:"..tostring(result.Points or "-")
            else
                statsLabel.Text = "Stats: (error)"
            end
        else
            statsLabel.Text = "GetStatsSnapshot remote missing"
        end
    end
end)
