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
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local devRemote = remotes:WaitForChild("DevTools")
local useSkill = remotes:FindFirstChild("UseSkill")
local getStats = remotes:FindFirstChild("GetStatsSnapshot")

local SKILLS = {
    { id = "Slash", label = "Slash", cooldown = 2 },
    { id = "Heavy", label = "Heavy", cooldown = 5 },
    { id = "PowerStrike", label = "PowerStrike", cooldown = 8 },
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevTestPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,260,0,340)
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

local function makeButton(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-12,0,32)
    btn.Position = UDim2.new(0,6,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = frame
    return btn
end

-- static dev controls
local y = 36
local spawnBtn = makeButton("Spawn NPC", y)
spawnBtn.MouseButton1Click:Connect(function() pcall(function() devRemote:FireServer("SpawnNPC") end) end)
y = y + 36
local tpBtn = makeButton("Teleport To NPC", y)
tpBtn.MouseButton1Click:Connect(function() pcall(function() devRemote:FireServer("TeleportToNPC") end) end)
y = y + 36
local toggleAiBtn = makeButton("Toggle AI", y)
toggleAiBtn.MouseButton1Click:Connect(function() pcall(function() devRemote:FireServer("ToggleAI") end) end)
y = y + 36
local dmgBtn = makeButton("Damage Self (10)", y)
dmgBtn.MouseButton1Click:Connect(function() pcall(function() devRemote:FireServer("DamageSelf", 10) end) end)
y = y + 36
local healBtn = makeButton("Heal Self (10)", y)
healBtn.MouseButton1Click:Connect(function() pcall(function() devRemote:FireServer("HealSelf", 10) end) end)

y = y + 44

-- Skill buttons with cooldown overlays and keybind hints
local skillButtons = {}
local cooldowns = {}

for i, skill in ipairs(SKILLS) do
    local btn = makeButton(string.format("[%d] %s", i, skill.label), y)
    local overlay = Instance.new("TextLabel")
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.Position = UDim2.new(0,0,0,0)
    overlay.BackgroundTransparency = 0.6
    overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    overlay.TextColor3 = Color3.fromRGB(255,255,255)
    overlay.Text = ""
    overlay.TextScaled = true
    overlay.Font = Enum.Font.SourceSansBold
    overlay.Visible = false
    overlay.Parent = btn

    local function trigger()
        if cooldowns[skill.id] and cooldowns[skill.id] > 0 then return end
        if useSkill then
            pcall(function() useSkill:FireServer(skill.id) end)
        end
        cooldowns[skill.id] = skill.cooldown
        overlay.Visible = true
        overlay.Text = tostring(math.ceil(cooldowns[skill.id]))
        btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    end

    btn.MouseButton1Click:Connect(function() pcall(trigger) end)

    skillButtons[skill.id] = { button = btn, overlay = overlay }
    y = y + 36
end

-- Stats label
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1,-12,0,64)
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

-- Keybinds (1/2/3)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.One or key == Enum.KeyCode.KeypadOne then
        local s = SKILLS[1]
        if s then skillButtons[s.id].button:Activate() end
    elseif key == Enum.KeyCode.Two or key == Enum.KeyCode.KeypadTwo then
        local s = SKILLS[2]
        if s then skillButtons[s.id].button:Activate() end
    elseif key == Enum.KeyCode.Three or key == Enum.KeyCode.KeypadThree then
        local s = SKILLS[3]
        if s then skillButtons[s.id].button:Activate() end
    end
end)

-- RunService loop to decrement cooldowns and update overlays
RunService.Heartbeat:Connect(function(dt)
    for _, skill in ipairs(SKILLS) do
        local id = skill.id
        if cooldowns[id] and cooldowns[id] > 0 then
            cooldowns[id] = math.max(0, cooldowns[id] - dt)
            local entry = skillButtons[id]
            if entry then
                entry.overlay.Text = tostring(math.ceil(cooldowns[id]))
                if cooldowns[id] <= 0 then
                    entry.overlay.Visible = false
                    entry.button.BackgroundColor3 = Color3.fromRGB(60,60,60)
                end
            end
        end
    end
end)
