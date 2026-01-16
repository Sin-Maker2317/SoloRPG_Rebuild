-- VisualsClient.client.lua (LocalScript)
-- Temporary, easily-removable visual polish for Test Phase.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local CombatEvent = remotes and remotes:FindFirstChild("CombatEvent")

-- CONFIG: small, non-heavy effects
local POPUP_LIFETIME = 0.9
local FLASH_ALPHA = 0.5

-- Create HUD overlay for hit flash and popups
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VisualsClient"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Name = "HitFlash"
flash.Size = UDim2.new(1,0,1,0)
flash.Position = UDim2.new(0,0,0,0)
flash.BackgroundColor3 = Color3.fromRGB(255,0,0)
flash.BackgroundTransparency = 1
flash.ZIndex = 50
flash.Parent = screenGui

local centerPopup = Instance.new("TextLabel")
centerPopup.Name = "CenterPopup"
centerPopup.AnchorPoint = Vector2.new(0.5,0.5)
centerPopup.Position = UDim2.new(0.5,0.35,0,0)
centerPopup.Size = UDim2.new(0,220,0,60)
centerPopup.BackgroundTransparency = 1
centerPopup.TextScaled = true
centerPopup.TextColor3 = Color3.new(1,1,1)
centerPopup.Font = Enum.Font.SourceSansBold
centerPopup.Text = ""
centerPopup.ZIndex = 51
centerPopup.Parent = screenGui

local function showFlash(color, duration)
    flash.BackgroundColor3 = color
    flash.BackgroundTransparency = 1 - FLASH_ALPHA
    local tween = TweenService:Create(flash, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
    tween:Play()
end

local function showCenterPopup(text, color)
    centerPopup.Text = text
    centerPopup.TextColor3 = color or Color3.new(1,1,1)
    centerPopup.TextTransparency = 0
    centerPopup.TextStrokeTransparency = 0.6
    centerPopup.TextSize = 36
    centerPopup.TextTransparency = 0
    centerPopup.BackgroundTransparency = 1
    centerPopup.Visible = true
    centerPopup.TextStrokeColor3 = Color3.new(0,0,0)
    -- scale/tween
    centerPopup.Size = UDim2.new(0,220,0,60)
    local tween = TweenService:Create(centerPopup, TweenInfo.new(POPUP_LIFETIME, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5,0,0.25,0), TextTransparency = 1})
    tween:Play()
    task.delay(POPUP_LIFETIME, function()
        centerPopup.Text = ""
        centerPopup.Position = UDim2.new(0.5,0,0.35,0)
    end)
end

local function createWorldPopup(text, worldPos)
    if not worldPos then return end
    local part = Instance.new("Part")
    part.Name = "PopupPart"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(1,1,1)
    part.CFrame = CFrame.new(worldPos)
    part.Parent = Workspace

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0,120,0,40)
    gui.StudsOffset = Vector3.new(0,2,0)
    gui.AlwaysOnTop = true
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.Parent = gui

    -- animate upward + fade
    local goal = {StudsOffset = gui.StudsOffset + Vector3.new(0,2,0)}
    local t = TweenService:Create(gui, TweenInfo.new(POPUP_LIFETIME, Enum.EasingStyle.Quad), goal)
    t:Play()
    task.delay(POPUP_LIFETIME, function()
        if part then part:Destroy() end
    end)
end

-- Enemy highlights: add simple red highlight on enemy models
local function addHighlightToEnemy(model)
    if not model or not model:IsA("Model") then return end
    if model:FindFirstChild("_VisualHighlight") then return end
    local ok, _ = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "_VisualHighlight"
        highlight.Adornee = model
        highlight.FillColor = Color3.fromRGB(200,60,60)
        highlight.OutlineColor = Color3.fromRGB(255,40,40)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0.2
        highlight.Parent = model
    end)
    return ok
end

local function scanEnemies()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return end
    for _,m in ipairs(enemiesFolder:GetChildren()) do
        addHighlightToEnemy(m)
    end
    enemiesFolder.ChildAdded:Connect(function(child)
        task.defer(function() addHighlightToEnemy(child) end)
    end)
end

-- Gate portal visuals (local only): attach simple particle emitter and dark rim
local function setupGateVisuals()
    local world = Workspace:FindFirstChild("World")
    if not world then return end
    local terminals = world:FindFirstChild("Terminals")
    if not terminals then return end
    for _,term in ipairs(terminals:GetChildren()) do
        if term:IsA("BasePart") and term.Name:match("GateTerminal") then
            -- avoid double-creating
            if term:FindFirstChild("_PortalLocal") then continue end
            local container = Instance.new("Folder")
            container.Name = "_PortalLocal"
            container.Parent = term

            local glow = Instance.new("ParticleEmitter")
            glow.Rate = 6
            glow.Speed = NumberRange.new(0.2, 0.6)
            glow.Lifetime = NumberRange.new(0.8,1.6)
            glow.Size = NumberSequence.new(0.5)
            glow.Color = ColorSequence.new(Color3.fromRGB(30,30,40), Color3.fromRGB(80,80,120))
            glow.LightEmission = 0.6
            glow.Parent = term

            -- subtle dark rim: local transparent part
            local rim = Instance.new("Part")
            rim.Name = "_PortalRim"
            rim.Anchored = true
            rim.CanCollide = false
            rim.Size = Vector3.new(term.Size.X * 1.2, 4, term.Size.Z * 1.2)
            rim.CFrame = term.CFrame * CFrame.new(0,1,0)
            rim.Transparency = 0.5
            rim.Color = Color3.fromRGB(10,10,20)
            rim.Material = Enum.Material.SmoothPlastic
            rim.Parent = term
            -- keep rim follow terminal
            task.spawn(function()
                while rim and rim.Parent do
                    rim.CFrame = term.CFrame * CFrame.new(0,1,0)
                    task.wait(0.2)
                end
            end)
        end
    end
end

-- Mild local lighting to make scene readable
local function applyLocalLighting()
    -- non-destructive: adjust a few properties locally
    local ok, err = pcall(function()
        Lighting.Brightness = Lighting.Brightness + 0.6
        Lighting.OutdoorAmbient = Color3.fromRGB(120,120,130)
        Lighting.FogEnd = math.max(500, Lighting.FogEnd)
    end)
end

-- Hook CombatEvent for hit feedback
if CombatEvent and CombatEvent.IsA and CombatEvent:IsA("RemoteEvent") then
    CombatEvent.OnClientEvent:Connect(function(payload)
        if not payload or type(payload) ~= "table" then return end
        local t = payload.type
        if t == "HitConfirm" then
            showFlash(Color3.fromRGB(255,60,60), 0.25)
            showCenterPopup("HIT", Color3.fromRGB(255,220,180))
            if payload.position then createWorldPopup("HIT", payload.position) end
        elseif t == "Block" or t == "Parry" then
            showFlash(Color3.fromRGB(120,180,255), 0.18)
            showCenterPopup(t == "Block" and "BLOCK" or "PARRY", Color3.fromRGB(180,220,255))
            if payload.position then createWorldPopup(t == "Block" and "BLOCK" or "PARRY", payload.position) end
        elseif t == "DodgeFailed" then
            showCenterPopup("DODGE FAILED", Color3.fromRGB(240,140,140))
        elseif t == "GateStarted" then
            showCenterPopup("Gate Started", Color3.fromRGB(200,200,255))
        end
    end)
end

-- Initialize
scanEnemies()
setupGateVisuals()
applyLocalLighting()

-- re-scan if world changes
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "World" then
        task.delay(0.2, function() setupGateVisuals() end)
    end
end)

-- ensure enemies folder exists handler
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Enemies" then
        task.delay(0.1, scanEnemies)
    end
end)

print("[VisualsClient] Initialized temporary visuals")
