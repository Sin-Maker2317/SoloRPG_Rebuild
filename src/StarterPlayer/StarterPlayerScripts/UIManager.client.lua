-- UIManager.client.lua
-- Centralize UI visibility for playtests: hide dev/debug screens for non-devs
-- and ensure TutorialHUD is prominent and readable.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local ALLOWED_DEVS = {
    ["Azathiell"] = true,
    ["Marietto_Crg"] = true,
}

local function isDebugName(name)
    if not name then return false end
    name = name:lower()
    local patterns = {"dev", "debug", "test", "devui", "devpanel", "devtools", "overlay"}
    for _, p in ipairs(patterns) do
        if name:find(p) then return true end
    end
    return false
end

local function tidyPlayerGui()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return end

    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") then
            if not ALLOWED_DEVS[player.Name] and isDebugName(gui.Name) then
                -- hide dev/debug GUIs for non-dev players
                pcall(function() gui.Enabled = false end)
            else
                -- ensure core HUDs are visible and have high ZIndex
                pcall(function() gui.ResetOnSpawn = false end)
            end
        end
    end

    -- Promote TutorialHUD if present
    local tut = pg:FindFirstChild("TutorialHUD")
    if tut and tut:IsA("ScreenGui") then
        pcall(function()
            tut.DisplayOrder = 100
            -- ensure the main frame is compact and top-left
            local f = tut:FindFirstChildWhichIsA("Frame", true)
            if f then
                f.Position = UDim2.new(0.01,0,0.01,0)
                f.Size = UDim2.new(0,300,0,120)
                f.AnchorPoint = Vector2.new(0,0)
            end
        end)
    end
end

-- Run once when PlayerGui ready, and again after character spawn
player.CharacterAdded:Connect(function()
    task.wait(0.6)
    tidyPlayerGui()
end)

-- Also tidy on PlayerGui added
player:GetPropertyChangedSignal("PlayerGui"):Connect(function()
    task.wait(0.2)
    tidyPlayerGui()
end)

-- initial run when script starts
task.spawn(function()
    for i=1,6 do
        tidyPlayerGui()
        task.wait(0.25)
    end
end)

print("[UIManager] Initialized. Dev UIs hidden for non-dev players.")
