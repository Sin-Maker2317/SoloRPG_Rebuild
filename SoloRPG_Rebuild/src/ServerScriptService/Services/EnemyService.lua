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

	-- Ensure there is an Enemies folder under Workspace and parent the model there
	local enemiesFolder = Workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "Enemies"
		enemiesFolder.Parent = Workspace
	end

	model.Parent = enemiesFolder

	-- Mark model as an enemy for client lock-on detection
	model:SetAttribute("IsEnemy", true)

	-- Create a simple server-side nameplate (BillboardGui) showing HP above the enemy
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Nameplate"
	billboard.Adornee = root
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 120, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.Parent = model

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 200, 120)
	label.Text = ("HP: %d/%d"):format(humanoid.Health, humanoid.MaxHealth)
	label.Parent = billboard

	humanoid.HealthChanged:Connect(function(h)
		if label then
			label.Text = ("HP: %d/%d"):format(math.max(0, math.floor(h + 0.5)), humanoid.MaxHealth)
		end
	end)

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
