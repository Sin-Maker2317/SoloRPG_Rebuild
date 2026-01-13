-- ServerScriptService/Services/EnemyService.lua
local Workspace = game:GetService("Workspace")

local EnemyService = {}
EnemyService.__index = EnemyService

-- Generic spawn
function EnemyService:SpawnEnemy(config, position, onDied)
	-- config: { name=string, maxHealth=number, size=Vector3 }
	config = config or {}
	local name = config.name or "Enemy"
	local maxHealth = config.maxHealth or 100
	local size = config.size or Vector3.new(2, 2, 1)

	local model = Instance.new("Model")
	model.Name = name

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	humanoid.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = size
	root.Anchored = false
	root.Position = position
	root.Parent = model

	model.PrimaryPart = root
	model.Parent = Workspace

	humanoid.Died:Connect(function()
		if onDied then
			onDied(model)
		end
		task.delay(1, function()
			if model then model:Destroy() end
		end)
	end)

	return model
end

-- Backward compatibility
function EnemyService:SpawnDummyEnemy(position, onDied)
	return self:SpawnEnemy({
		name = "DummyEnemy",
		maxHealth = 100,
		size = Vector3.new(2, 2, 1)
	}, position, onDied)
end

return EnemyService
