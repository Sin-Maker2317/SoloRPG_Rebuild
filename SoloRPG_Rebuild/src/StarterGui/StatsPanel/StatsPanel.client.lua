local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getStatsRF = remotes:WaitForChild("GetStatsSnapshot")

-- Build a minimal stats panel
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatsPanelGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "StatsFrame"
frame.Size = UDim2.new(0, 200, 0, 180)
frame.Position = UDim2.new(0.02, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
frame.BackgroundTransparency = 0.12
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "Stats"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.Padding = nil

local statsOrder = {"STR", "AGI", "VIT", "INT", "Level", "Points"}
local labels = {}
for i, name in ipairs(statsOrder) do
    local lbl = Instance.new("TextLabel")
    lbl.Name = name.."Label"
    lbl.Size = UDim2.new(1, -8, 0, 22)
    lbl.Position = UDim2.new(0, 8, 0, 28 + (i-1) * 26)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl.Text = name..": ..."
    labels[name] = lbl
end

local function updateStats()
    local ok, data = pcall(function()
        return getStatsRF:InvokeServer()
    end)
    if not ok or type(data) ~= "table" then
        return
    end
    for _, name in ipairs(statsOrder) do
        local v = data[name]
        if v == nil then v = 0 end
        labels[name].Text = name..": "..tostring(v)
    end
end

spawn(function()
    wait(1)
    updateStats()
    while true do
        wait(5)
        updateStats()
    end
end)
