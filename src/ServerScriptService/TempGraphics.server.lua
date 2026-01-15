-- TempGraphics.server.lua
-- Server-side minimal styling for Workspace.Enemies to improve readability in Studio/playtests.
-- NOTE: Temporary visual adjustments only. Do NOT couple gameplay to these changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:FindFirstChild("Shared")
local Visuals = nil
if shared then
    pcall(function() Visuals = require(shared:FindFirstChild("VisualsConfig")) end)
end
Visuals = Visuals or { envStoneColor = Color3.fromRGB(80,85,90), envStoneMaterial = Enum.Material.Slate }

local function styleModel(m)
    if not m or not m:IsA("Model") then return end
    if m:GetAttribute("_TempStyledServer") then return end
    m:SetAttribute("_TempStyledServer", true)
    for _, part in ipairs(m:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Material = Visuals.envStoneMaterial or Enum.Material.Slate
                if part.Name:lower():find("eye") or part.Name:lower():find("glow") then
                    -- small override for obvious enemy eyes
                    part.BrickColor = BrickColor.new("Bright yellow")
                    part.Material = Enum.Material.Neon
                else
                    part.Color = Visuals.envStoneColor or Color3.fromRGB(80,85,90)
                end
                part.CastShadow = true
            end)
        end
    end
end

-- Style existing enemies folder children
local enemies = Workspace:FindFirstChild("Enemies")
if enemies then
    for _, v in ipairs(enemies:GetChildren()) do
        styleModel(v)
    end
    enemies.ChildAdded:Connect(function(ch)
        styleModel(ch)
    end)
end

-- Also style Bosses folder if present
local bosses = Workspace:FindFirstChild("Bosses")
if bosses then
    for _, v in ipairs(bosses:GetChildren()) do
        styleModel(v)
    end
    bosses.ChildAdded:Connect(function(ch)
        styleModel(ch)
    end)
end

print("[TempGraphics] Server-side styling initialized (temporary visuals).")
