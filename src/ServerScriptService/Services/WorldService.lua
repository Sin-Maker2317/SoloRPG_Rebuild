-- ServerScriptService/Services/WorldService.lua
local Workspace = game:GetService("Workspace")

local WorldService = {}
WorldService.__index = WorldService

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then return f end
	if f then f:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ensurePart(parent, name, position)
	local p = parent:FindFirstChild(name)
	if p and p:IsA("Part") then return p end
	if p then p:Destroy() end
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(4, 1, 4)
	part.Position = position
	part.Parent = parent
	return part
end

local function ensurePlatform(parent, name, position, size)
	local p = parent:FindFirstChild(name)
	if p and p:IsA("Part") then return p end
	if p then p:Destroy() end
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = 0
	part.Size = size
	part.Position = position
	part.Parent = parent
	return part
end

local function ensureVisiblePart(parent, name, position, size)
	local p = parent:FindFirstChild(name)
	if p and p:IsA("Part") then return p end
	if p then p:Destroy() end
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = 0
	part.Size = size
	part.Position = position
	part.Parent = parent
	return part
end

function WorldService:Init()
	local world = ensureFolder(Workspace, "World")
	local platforms = ensureFolder(world, "Platforms")
	local spawns = ensureFolder(world, "Spawns")
	local awakening = ensureFolder(world, "Awakening")

	-- HUB / TOWN
	ensurePlatform(platforms, "Platform_Town", Vector3.new(0, 0, 0), Vector3.new(200, 1, 200))
	ensurePart(spawns, "Spawn_Town", Vector3.new(0, 5, 0))

	-- SOLO GATES (2)
	ensurePlatform(platforms, "Platform_SoloGate", Vector3.new(0, 0, -250), Vector3.new(120, 1, 120))
	ensurePart(spawns, "Spawn_SoloGate", Vector3.new(0, 5, -250))

	ensurePlatform(platforms, "Platform_SoloGate2", Vector3.new(-250, 0, 0), Vector3.new(120, 1, 120))
	ensurePart(spawns, "Spawn_SoloGate2", Vector3.new(-250, 5, 0))

	-- GUILD HOME
	ensurePlatform(platforms, "Platform_GuildHome", Vector3.new(250, 0, 0), Vector3.new(120, 1, 120))
	ensurePart(spawns, "Spawn_GuildHome", Vector3.new(250, 5, 0))

	-- AWAKENING DUNGEON
	ensurePlatform(platforms, "Platform_AwakeningDungeon", Vector3.new(0, -50, -500), Vector3.new(220, 1, 220))
	ensurePart(spawns, "Spawn_AwakeningDungeon", Vector3.new(0, -45, -500))

	-- SIMPLE PUZZLE: 3 pressure plates + exit trigger (visible for now)
	local plates = ensureFolder(awakening, "Plates")
	local exit = ensureFolder(awakening, "Exit")

	ensureVisiblePart(plates, "Plate1", Vector3.new(-20, -49, -520), Vector3.new(10, 1, 10))
	ensureVisiblePart(plates, "Plate2", Vector3.new(0, -49, -520), Vector3.new(10, 1, 10))
	ensureVisiblePart(plates, "Plate3", Vector3.new(20, -49, -520), Vector3.new(10, 1, 10))

	local exitTrigger = ensureVisiblePart(exit, "ExitTrigger", Vector3.new(0, -49, -470), Vector3.new(12, 6, 12))
	exitTrigger.CanCollide = false

	-- TERMINALS
	local terminals = ensureFolder(world, "Terminals")
	ensureVisiblePart(terminals, "GateTerminal_SoloE", Vector3.new(30, 1, 10), Vector3.new(6, 4, 6))
	ensureVisiblePart(terminals, "GateTerminal_SoloE2", Vector3.new(45, 1, 10), Vector3.new(6, 4, 6))

	print("[WorldService] World + Spawns creati/validati.")
end

function WorldService:GetSpawnCFrame(spawnName)
	local world = Workspace:FindFirstChild("World")
	if not world then return nil end
	local spawns = world:FindFirstChild("Spawns")
	if not spawns then return nil end
	local spawnPart = spawns:FindFirstChild(spawnName)
	if not spawnPart or not spawnPart:IsA("BasePart") then return nil end
	return spawnPart.CFrame
end

return WorldService
