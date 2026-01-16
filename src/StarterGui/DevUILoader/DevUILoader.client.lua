--[[
    DevUILoader - Auto-loads the Dev Test Panel in DEV_MODE
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- DEV MODE FLAG - set to false to disable dev UI
-- DEV MODE FLAG - default to false to prevent auto-showing dev UI
local DEV_MODE = false

if not DEV_MODE then
    return
end

local player = Players.LocalPlayer
if not player then return end

task.wait(0.5) -- Wait for PlayerGui to be ready

-- Load DevTestPanel if it exists
local devTestPanelTemplate = StarterGui:FindFirstChild("DevTestPanel")
if devTestPanelTemplate then
    -- Clone the DevTestPanel into StarterGui folder so UIRoot can manage it
    local devPanel = devTestPanelTemplate:Clone()
    devPanel.Parent = script.Parent
    print("[DevUILoader] DevTestPanel loaded")
else
    print("[DevUILoader] Warning: DevTestPanel not found in StarterGui")
end

-- Load EnemyHealthBar display
local enemyUITemplate = StarterGui:FindFirstChild("EnemyUI")
if enemyUITemplate then
    local enemyUI = enemyUITemplate:Clone()
    enemyUI.Parent = script.Parent
    print("[DevUILoader] EnemyUI loaded")
end
