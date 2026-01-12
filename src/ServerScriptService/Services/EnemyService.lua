-- ServerScriptService/Services/EnemyService.lua

local Workspace = game:GetService("Workspace")

local EnemyService = {}
EnemyService.__index = EnemyService

function EnemyService:SpawnDummyEnemy(position: Vector3)
	local model = Instance.new("Model")
	model.Name = "DummyEnemy"

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = false
	root.Position = position
	root.Parent = model

	model.PrimaryPart = root
	model.Parent = Workspace

	return model
end

return EnemyService
