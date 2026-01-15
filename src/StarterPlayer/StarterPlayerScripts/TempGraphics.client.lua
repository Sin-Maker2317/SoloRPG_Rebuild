-- TempGraphics.client.lua
-- Temporary, low-cost visuals to improve combat readability during playtests.
-- Listens for `CombatEvent` and highlights enemies in Workspace.Enemies.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

local shared = ReplicatedStorage:WaitForChild("Shared")
local Visuals = nil
pcall(function() Visuals = require(shared:WaitForChild("VisualsConfig")) end)
Visuals = Visuals or { enemyBodyColor = Color3.fromRGB(120,50,50), enemyOutline = Color3.fromRGB(200,100,100), enemyFillTransparency = 0.6 }

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local combatRemote = remotes and remotes:FindFirstChild("CombatEvent")

-- HUD flash frame for HitConfirm
local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "TempGraphicsHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local flash = Instance.new("Frame")
flash.Size = UDim2.new(1,0,1,0)
flash.Position = UDim2.new(0,0,0,0)
flash.BackgroundColor3 = Color3.fromRGB(255,240,200)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

local function cameraFlash()
    local t1 = TweenService:Create(flash, TweenInfo.new(0.08), {BackgroundTransparency = 0.6})
    local t2 = TweenService:Create(flash, TweenInfo.new(0.18), {BackgroundTransparency = 1})
    t1:Play()
    t1.Completed:Wait()
    t2:Play()
end

-- Simple on-screen popup for dodge/guard feedback
local function showFloatingText(text, duration)
    duration = duration or 0.9
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.2,0,0,30)
    lbl.Position = UDim2.new(0.5, -100, 0.2, 0)
    lbl.AnchorPoint = Vector2.new(0,0)
    lbl.BackgroundTransparency = 0.6
    lbl.BackgroundColor3 = Visuals.uiBG
    lbl.TextColor3 = Visuals.uiAccent
    lbl.Text = text
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 20
    lbl.Parent = gui
    task.delay(duration, function() pcall(function() lbl:Destroy() end) end)
end

-- Style enemies with a Highlight on the client
local function styleEnemy(model)
    if not model or not model:IsA("Model") then return end
    if model:GetAttribute("_TempStyled") then return end
    model:SetAttribute("_TempStyled", true)

    local hl = Instance.new("Highlight")
    hl.Name = "TempHighlight"
    hl.FillColor = Visuals.enemyBodyColor
    hl.OutlineColor = Visuals.enemyOutline
    hl.FillTransparency = Visuals.enemyFillTransparency or 0.6
    hl.OutlineTransparency = 0
    hl.Parent = model
end

local function styleAllExisting()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end
    for _, child in ipairs(enemies:GetChildren()) do
        styleEnemy(child)
    end
end

-- react to workspace changes
local enemiesFolder = Workspace:WaitForChild("Enemies", 5)
if enemiesFolder then
    styleAllExisting()
    enemiesFolder.ChildAdded:Connect(function(ch)
        styleEnemy(ch)
    end)
end

-- Handle CombatEvent remote payloads
if combatRemote and combatRemote:IsA("RemoteEvent") then
    combatRemote.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" or not payload.type then return end
        local typ = payload.type
        if typ == "HitConfirm" then
            cameraFlash()
            -- small burst at position
            if payload.position then
                local p = Instance.new("Part")
                p.Anchored = true
                p.CanCollide = false
                p.Size = Vector3.new(0.4,0.4,0.4)
                p.Shape = Enum.PartType.Ball
                p.Material = Enum.Material.Neon
                p.Color = Color3.fromRGB(255,220,160)
                p.CFrame = CFrame.new(payload.position)
                p.Parent = workspace
                local goal = {Size = Vector3.new(1.6,1.6,1.6), Transparency = 1}
                local tw = TweenService:Create(p, TweenInfo.new(0.25), goal)
                tw:Play()
                tw.Completed:Connect(function() p:Destroy() end)
            end
        elseif typ == "DodgeSuccess" then
            showFloatingText("DODGE!", 0.8)
        elseif typ == "DodgeFail" then
            showFloatingText("Missed Dodge", 0.8)
        elseif typ == "Windup" then
            -- optionally flash the target model (if modelName provided)
            if payload.targetModelName then
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    local m = enemies:FindFirstChild(payload.targetModelName)
                    if m then
                        local prev = m:GetAttribute("_TempStyled")
                        -- quick pulsing outline
                        local hl = m:FindFirstChild("TempHighlight")
                        if hl then
                            local orig = hl.FillTransparency
                            hl.FillTransparency = math.max(0.2, orig - 0.4)
                            task.delay(0.45, function() if hl then hl.FillTransparency = orig end end)
                        end
                    end
                end
            end
        end
    end)
end
