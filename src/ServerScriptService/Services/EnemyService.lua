-- ServerScriptService/Services/EnemyService.lua
local Workspace = game:GetService("Workspace")

local EnemyService = {}
EnemyService.__index = EnemyService

-- Spawna un dummy e chiama onDied() quando muore
function EnemyService:SpawnDummyEnemy(position: Vector3, onDied: (() -> ())?)
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

	humanoid.Died:Connect(function()
		if onDied then
			onDied()
		end
		task.delay(1, function()
			if model then
				model:Destroy()
			end
		end)
	end)

	return model
end

return EnemyService
