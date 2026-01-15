local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Restrict DevTestPanel to known developer accounts only (temporary)
local ALLOWED_DEVS = {
    ["Azathiell"] = true,
    ["Marietto_Crg"] = true,
}

if not player or not ALLOWED_DEVS[player.Name] then
    -- Do not load dev UI for non-dev players
    return
end
local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local devRemote, useSkill, getStats
if remotes then
    devRemote = remotes:FindFirstChild("DevTools")
    useSkill = remotes:FindFirstChild("UseSkill")
    getStats = remotes:FindFirstChild("GetStatsSnapshot")
end

-- default cooldowns for known test skills
local DEFAULT_COOLDOWNS = {
    Slash = 2,
    Heavy = 5,
    PowerStrike = 8,
}

local function normalizeKeyText(txt)
    if not txt then return "" end
    txt = tostring(txt):gsub("%s+","")
    if txt == "1" then return "One" end
    if txt == "2" then return "Two" end
    if txt == "3" then return "Three" end
    if txt:lower() == "shift" then return "Shift" end
    return txt:sub(1,1):upper()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevTestPanel"
screenGui.ResetOnSpawn = false

-- robust parenting: prefer player.PlayerGui when available
local parentGui = nil
if player and player:FindFirstChild("PlayerGui") then
    parentGui = player.PlayerGui
elseif script.Parent and script.Parent:IsA("PlayerGui") then
    parentGui = script.Parent
else
    parentGui = player and player:FindFirstChild("PlayerGui") or script.Parent
end
screenGui.Parent = parentGui

-- debug print
pcall(function() print("DevTestPanel loaded. parentGui=", tostring(parentGui)) end)


local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,260,0,300)
frame.AnchorPoint = Vector2.new(1,0)
frame.Position = UDim2.new(1, -10, 0, 8)
frame.BackgroundTransparency = 0.15
frame.BackgroundColor3 = Color3.fromRGB(18,18,20)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,32)
title.BackgroundTransparency = 1
title.Text = "Dev Test Panel"
title.TextColor3 = Color3.fromRGB(220,220,220)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local y = 34

local rows = {}
-- create compact rows on the right UI
for i=1,3 do
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(1,-12,0,36)
    rowFrame.Position = UDim2.new(0,6,0,y)
    rowFrame.BackgroundTransparency = 1
    rowFrame.Parent = frame

    local skillBox = Instance.new("TextBox")
    skillBox.Size = UDim2.new(0.6, -6, 1, 0)
    skillBox.Position = UDim2.new(0,0,0,0)
    skillBox.PlaceholderText = (i==1 and "Slash" or (i==2 and "Heavy" or "PowerStrike"))
    skillBox.Text = ""
    skillBox.Font = Enum.Font.SourceSans
    skillBox.TextSize = 14
    skillBox.Parent = rowFrame

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.2, -6, 1, 0)
    keyBox.Position = UDim2.new(0.62, 6, 0, 0)
    keyBox.PlaceholderText = tostring(i)
    keyBox.Text = ""
    keyBox.Font = Enum.Font.SourceSans
    keyBox.TextSize = 14
    keyBox.Parent = rowFrame

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.18, 0, 1, 0)
    testBtn.Position = UDim2.new(0.84, 6, 0, 0)
    testBtn.Text = "Fire"
    testBtn.Font = Enum.Font.SourceSans
    testBtn.TextSize = 14
    testBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    testBtn.Parent = rowFrame

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
    overlay.Parent = rowFrame

    rows[i] = {
        skillBox = skillBox,
        keyBox = keyBox,
        testBtn = testBtn,
        overlay = overlay,
    }

    y = y + 40
end

local shiftLock = false
local shiftBtn = Instance.new("TextButton")
shiftBtn.Size = UDim2.new(0.44, -6, 0, 32)
shiftBtn.Position = UDim2.new(0.04, 0, 1, -48)
shiftBtn.Text = "ShiftLock: Off"
shiftBtn.Font = Enum.Font.Gotham
shiftBtn.TextSize = 15
shiftBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
shiftBtn.TextColor3 = Color3.fromRGB(240,240,240)
shiftBtn.BorderSizePixel = 0
shiftBtn.Parent = frame
-- (initial simple toggle removed; full behavior implemented below)

-- Implement ShiftLock camera behavior for testing: lock mouse center when enabled
-- Implement ShiftLock camera behavior for testing: lock mouse center when enabled
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local shiftConn = nil
local function applyShiftLock(state)
    if state then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

-- full toggle: locks mouse and orients character to camera while ShiftLock is enabled
shiftBtn.MouseButton1Click:Connect(function()
    shiftLock = not shiftLock
    shiftBtn.Text = "ShiftLock: " .. (shiftLock and "On" or "Off")
    pcall(function() applyShiftLock(shiftLock) end)

    if shiftLock then
        -- disable AutoRotate and start aligning HRP to camera each frame
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum.AutoRotate = false end)
        end
        shiftConn = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local look = cam.CFrame.LookVector
                local dir = Vector3.new(look.X, 0, look.Z)
                if dir.Magnitude > 0.001 then
                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
                end
            end
        end)
    else
        -- restore AutoRotate and stop aligning
        if shiftConn then
            pcall(function() shiftConn:Disconnect() end)
            shiftConn = nil
        end
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum.AutoRotate = true end)
            end
        end
        pcall(function() applyShiftLock(false) end)
    end
end)

-- Stats label
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(0.92, 0, 0, 40)
statsLabel.Position = UDim2.new(0.04, 0, 0, 64)
statsLabel.BackgroundTransparency = 0
statsLabel.BackgroundColor3 = Color3.fromRGB(14,14,14)
statsLabel.TextColor3 = Color3.fromRGB(220,220,220)
statsLabel.Text = "Stats: (click)"
statsLabel.TextWrapped = true
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextSize = 14
statsLabel.Parent = frame
statsLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if getStats and getStats:IsA("RemoteFunction") then
            local ok, result = pcall(function()
                return getStats:InvokeServer()
            end)
            if ok and type(result) == "table" then
                statsLabel.Text = string.format("STR:%s AGI:%s VIT:%s", tostring(result.STR or "-"), tostring(result.AGI or "-"), tostring(result.VIT or "-"))
            else
                statsLabel.Text = "Stats: (error)"
            end
        else
            statsLabel.Text = "GetStatsSnapshot remote missing"
        end
    end
end)

-- cooldown tracking and helper
local cooldowns = {}
local function triggerSkill(id)
    if not id or id == "" then return end
    -- for testing: no client cooldowns; server may still control damage timing
    if useSkill then
        pcall(function() useSkill:FireServer(id) end)
    end
    -- visual feedback: briefly flash overlay
    for _, r in ipairs(rows) do

    -- Dev tools quick actions (Spawn, Teleport, ToggleAI, Damage/Heal, SmokeReport)
    local devActionsY = 140
    local function mkButton(text, posY, width)
        width = width or 0.46
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(width, -6, 0, 32)
        b.Position = UDim2.new(0.02, 0, 0, posY)
        b.Text = text
        b.Font = Enum.Font.Gotham
        b.TextSize = 15
        b.BackgroundColor3 = Color3.fromRGB(65,65,65)
        b.TextColor3 = Color3.fromRGB(245,245,245)
        b.BorderSizePixel = 0
        b.Parent = frame
        return b
    end

    local spawnBtn = mkButton("Spawn NPC", 120)
    local teleportBtn = mkButton("Teleport To NPC", 160)
    local toggleAIBtn = mkButton("Toggle AI", 200)
    local dmgBtn = mkButton("Damage 10", 240, 0.22)
    local healBtn = mkButton("Heal 10", 240, 0.22)

    -- place heal to the right
    healBtn.Position = UDim2.new(0.5, 6, 0, 236)

    local smokeLabel = Instance.new("TextLabel")
    smokeLabel.Size = UDim2.new(0.96, 0, 0, 56)
    smokeLabel.Position = UDim2.new(0.02, 0, 0, 64)
    smokeLabel.BackgroundTransparency = 0
    smokeLabel.BackgroundColor3 = Color3.fromRGB(10,10,10)
    smokeLabel.TextColor3 = Color3.fromRGB(200,200,200)
    smokeLabel.Text = "SmokeReport: (refresh)"
    smokeLabel.TextWrapped = true
    smokeLabel.RichText = true
    smokeLabel.Font = Enum.Font.Gotham
    smokeLabel.TextSize = 12
    smokeLabel.Parent = frame

    local function refreshSmoke()
        local sv = ReplicatedStorage:FindFirstChild("SmokeReport")
        if sv and sv:IsA("StringValue") then
            smokeLabel.Text = "SmokeReport: " .. (sv.Value or "(empty)")
        else
            smokeLabel.Text = "SmokeReport: (not present)"
        end
    end

    spawnBtn.MouseButton1Click:Connect(function()
        if devRemote and devRemote:IsA("RemoteEvent") then
            pcall(function() devRemote:FireServer("SpawnNPC") end)
        end
    end)

    teleportBtn.MouseButton1Click:Connect(function()
        if devRemote and devRemote:IsA("RemoteEvent") then
            pcall(function() devRemote:FireServer("TeleportToNPC") end)
        end
    end)

    toggleAIBtn.MouseButton1Click:Connect(function()
        if devRemote and devRemote:IsA("RemoteEvent") then
            pcall(function() devRemote:FireServer("ToggleAI") end)
        end
    end)

    dmgBtn.MouseButton1Click:Connect(function()
        if devRemote and devRemote:IsA("RemoteEvent") then
            pcall(function() devRemote:FireServer("DamageSelf", 10) end)
        end
    end)

    healBtn.MouseButton1Click:Connect(function()
        if devRemote and devRemote:IsA("RemoteEvent") then
            pcall(function() devRemote:FireServer("HealSelf", 10) end)
        end
    end)

    -- allow clicking the smoke label to refresh
    smokeLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            refreshSmoke()
        end
    end)

    -- Attempt initial refresh
    task.spawn(function() wait(1) refreshSmoke() end)
        local sid = r.skillBox.Text ~= "" and r.skillBox.Text or r.skillBox.PlaceholderText
        if sid == id then
            r.overlay.Visible = true
            r.overlay.Text = "!"
            r.testBtn.BackgroundColor3 = Color3.fromRGB(90,90,90)
            delay(0.3, function()
                r.overlay.Visible = false
                r.testBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
            end)
        end
    end
end

-- connect test buttons
for _, r in ipairs(rows) do
    r.testBtn.MouseButton1Click:Connect(function()
        local sid = r.skillBox.Text ~= "" and r.skillBox.Text or r.skillBox.PlaceholderText
        triggerSkill(sid)
    end)
end

-- key input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local keyName = input.KeyCode.Name
    -- check explicit mappings from rows
    for _, r in ipairs(rows) do
        local desired = normalizeKeyText(r.keyBox.Text ~= "" and r.keyBox.Text or r.keyBox.PlaceholderText)
        if desired ~= "" then
            if desired == "Shift" then
                if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
                    local sid = r.skillBox.Text ~= "" and r.skillBox.Text or r.skillBox.PlaceholderText
                    triggerSkill(sid)
                    return
                end
            else
                if keyName:lower():sub(1,1) == desired:lower():sub(1,1) or keyName:lower() == desired:lower() then
                    local sid = r.skillBox.Text ~= "" and r.skillBox.Text or r.skillBox.PlaceholderText
                    triggerSkill(sid)
                    return
                end
            end
        end
    end

    -- shift lock fallback: trigger first row skill when shift is pressed
    if shiftLock and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
        local r = rows[1]
        local sid = r.skillBox.Text ~= "" and r.skillBox.Text or r.skillBox.PlaceholderText
        triggerSkill(sid)
    end
end)
-- no heartbeat cooldown updater in dev panel (server handles damage timing)

