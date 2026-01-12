-- ServerScriptService/Services/WorldService.lua
local Workspace = game:GetService("Workspace")

local WorldService = {}
WorldService.__index = WorldService

local function ensureFolder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then
		return f
	end
	if f then f:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ensurePart(parent: Instance, name: string, position: Vector3): Part
	local p = parent:FindFirstChild(name)
	if p and p:IsA("Part") then
		return p
	end
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

local function ensurePlatform(parent: Instance, name: string, position: Vector3, size: Vector3): Part
	local p = parent:FindFirstChild(name)
	if p and p:IsA("Part") then
		return p
	end
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

	ensurePlatform(platforms, "Platform_Town", Vector3.new(0, 0, 0), Vector3.new(200, 1, 200))
	ensurePlatform(platforms, "Platform_SoloGate", Vector3.new(0, 0, -250), Vector3.new(120, 1, 120))
	ensurePlatform(platforms, "Platform_GuildHome", Vector3.new(250, 0, 0), Vector3.new(120, 1, 120))

	ensurePart(spawns, "Spawn_Town", Vector3.new(0, 5, 0))
	ensurePart(spawns, "Spawn_SoloGate", Vector3.new(0, 5, -250))
	ensurePart(spawns, "Spawn_GuildHome", Vector3.new(250, 5, 0))

	print("[WorldService] World + Spawns creati/validati.")
end

function WorldService:GetSpawnCFrame(spawnName: string): CFrame?
	local world = Workspace:FindFirstChild("World")
	if not world then return nil end

	local spawns = world:FindFirstChild("Spawns")
	if not spawns then return nil end

	local spawnPart = spawns:FindFirstChild(spawnName)
	if not spawnPart or not spawnPart:IsA("BasePart") then
		return nil
	end

	return spawnPart.CFrame
end

return WorldService
