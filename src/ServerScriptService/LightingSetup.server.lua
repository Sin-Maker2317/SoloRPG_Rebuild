-- LightingSetup.server.lua
-- Temporary lighting and environment setup for playtests.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Apply readable, neutral lighting suitable for testing
pcall(function()
    Lighting.TimeOfDay = "12:00:00"
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(100,100,110)
    Lighting.OutdoorAmbient = Color3.fromRGB(70,70,80)
    Lighting.FogEnd = 1000
    Lighting.GlobalShadows = true
end)

-- Add a simple sky if missing
if not Lighting:FindFirstChildOfClass("Sky") then
    local sky = Instance.new("Sky")
    sky.SkyboxBk = ""
    sky.SkyboxDn = ""
    sky.SkyboxFt = ""
    sky.SkyboxLf = ""
    sky.SkyboxRt = ""
    sky.SkyboxUp = ""
    sky.Name = "_TempSky"
    sky.Parent = Lighting
end

-- Create a simple ground part if Workspace lacks large Terrain or ground
local function ensureGround()
    local existing = Workspace:FindFirstChild("_TempGround")
    if existing then return end
    local ground = Instance.new("Part")
    ground.Name = "_TempGround"
    ground.Size = Vector3.new(2000, 1, 2000)
    ground.Position = Vector3.new(0, 0.5, 0)
    ground.Anchored = true
    ground.Material = Enum.Material.Slate
    ground.Color = Color3.fromRGB(80,85,90)
    ground.Parent = Workspace
end

ensureGround()

print("[LightingSetup] Temporary lighting and ground applied.")
