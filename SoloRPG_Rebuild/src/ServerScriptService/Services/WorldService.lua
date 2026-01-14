local Workspace = game:GetService("Workspace")
local EnemyService = require(script.Parent:FindFirstChild("EnemyService"))

local WorldService = {}

local function ensureFolder(name)
    local f = Workspace:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = Workspace
    end
    return f
end

function WorldService:CreatePlatform(pos, size)
    local part = Instance.new("Part")
    part.Name = "Platform"
    part.Size = size or Vector3.new(10, 1, 10)
    part.Anchored = true
    part.Position = pos or Vector3.new(0, 0, 0)
    part.Parent = Workspace
    return part
end

function WorldService:Init()
    -- ensure folders
    ensureFolder("Enemies")
    ensureFolder("Gates")

    -- Create a few simple platforms for visual debugging
    if not Workspace:FindFirstChild("DebugPlatform1") then
        local p1 = Instance.new("Part")
        p1.Name = "DebugPlatform1"
        p1.Size = Vector3.new(40, 1, 40)
        p1.Anchored = true
        p1.Position = Vector3.new(0, 0, 0)
        p1.Parent = Workspace
    end
    if not Workspace:FindFirstChild("DebugPlatform2") then
        local p2 = Instance.new("Part")
        p2.Name = "DebugPlatform2"
        p2.Size = Vector3.new(12, 1, 12)
        p2.Anchored = true
        p2.Position = Vector3.new(0, 0, -30)
        p2.Parent = Workspace
    end

    -- Spawn a sample enemy for testing
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies and #enemies:GetChildren() == 0 then
        EnemyService:SpawnEnemy({ name = "Grunt", maxHealth = 60, size = Vector3.new(2,3,1) }, Vector3.new(5, 3, 0))
    end
end

return WorldService
