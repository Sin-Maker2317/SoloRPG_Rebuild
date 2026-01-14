-- ServerScriptService/Services/EnemyAIService.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local DebugService = require(script.Parent:WaitForChild("DebugService"))

local EnemyAIService = {}
EnemyAIService.__index = EnemyAIService

-- AI States
local AIState = {
	Idle = "Idle",
	Chase = "Chase",
	Attack = "Attack",
	Cooldown = "Cooldown"
}

-- Enemy AI data: [model] = { state, target, attackCooldownEnd, stateStartTime, isElite }
local enemyData = {}

-- Configuration
local DETECTION_RANGE = 30
local ATTACK_RANGE = 6
local CHASE_RANGE = 50
local ATTACK_COOLDOWN = 2.0
local ATTACK_WINDUP = 0.5
local IDLE_WANDER_RANGE = 5

function EnemyAIService:Init()
	-- Ensure Enemies folder exists
	local enemiesFolder = Workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "Enemies"
		enemiesFolder.Parent = Workspace
	end

	-- Run AI update loop
	RunService.Heartbeat:Connect(function(deltaTime)
		self:UpdateAI(deltaTime)
	end)

	DebugService:Log("[EnemyAI] Initialized")
end

function EnemyAIService:RegisterEnemy(model, isElite)
	if not model or not model.Parent then return end
	
	-- Set IsEnemy attribute for lock-on system
	model:SetAttribute("IsEnemy", true)
	
	-- Move to Enemies folder if not already there
	local enemiesFolder = Workspace:FindFirstChild("Enemies")
	if enemiesFolder and model.Parent ~= enemiesFolder then
		model.Parent = enemiesFolder
	end
	
	-- Initialize AI data
	enemyData[model] = {
		state = AIState.Idle,
		target = nil,
		attackCooldownEnd = 0,
		stateStartTime = tick(),
		isElite = isElite or false
	}
	
	-- Clean up on death
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			enemyData[model] = nil
		end)
	end
	
	DebugService:Log("[EnemyAI] Registered enemy:", model.Name, isElite and "(Elite)" or "")
end

function EnemyAIService:FindNearestPlayer(enemyRoot)
	local nearestPlayer = nil
	local nearestDist = DETECTION_RANGE
	
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then goto continue end
		
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then goto continue end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then goto continue end
		
		local dist = (hrp.Position - enemyRoot.Position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearestPlayer = player
		end
		::continue::
	end
	
	return nearestPlayer, nearestDist
end

function EnemyAIService:UpdateAI(deltaTime)
	local currentTime = tick()
	
	for model, data in pairs(enemyData) do
		if not model.Parent then
			enemyData[model] = nil
			goto continue
		end
		
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		
		if not humanoid or not root or humanoid.Health <= 0 then
			enemyData[model] = nil
			goto continue
		end
		
		-- Find nearest player
		local targetPlayer, distToTarget = self:FindNearestPlayer(root)
		
		-- State machine
		if data.state == AIState.Idle then
			-- Look for targets
			if targetPlayer then
				data.state = AIState.Chase
				data.target = targetPlayer
				data.stateStartTime = currentTime
				humanoid.WalkSpeed = 8
			end
			
		elseif data.state == AIState.Chase then
			if not targetPlayer or distToTarget > CHASE_RANGE then
				-- Lost target
				data.state = AIState.Idle
				data.target = nil
				humanoid.WalkSpeed = 4
			elseif distToTarget <= ATTACK_RANGE and currentTime >= data.attackCooldownEnd then
				-- In attack range, start attack
				data.state = AIState.Attack
				data.stateStartTime = currentTime
				humanoid.WalkSpeed = 0
			else
				-- Continue chasing
				if targetPlayer.Character then
					local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
					if targetHrp then
						humanoid:MoveTo(targetHrp.Position)
					end
				end
			end
			
			goto continue
			
		elseif data.state == AIState.Attack then
			local timeInState = currentTime - data.stateStartTime
			
			if timeInState >= ATTACK_WINDUP then
				-- Execute attack
				if targetPlayer and targetPlayer.Character then
					self:ExecuteAttack(model, targetPlayer, data.isElite)
				end
				
				-- Enter cooldown
				data.state = AIState.Cooldown
				data.attackCooldownEnd = currentTime + ATTACK_COOLDOWN
				data.stateStartTime = currentTime
			end
			
		elseif data.state == AIState.Cooldown then
			if currentTime >= data.attackCooldownEnd then
				-- Cooldown finished
				if targetPlayer and distToTarget <= ATTACK_RANGE then
					data.state = AIState.Attack
					data.stateStartTime = currentTime
					humanoid.WalkSpeed = 0
				else
					data.state = AIState.Chase
					data.stateStartTime = currentTime
					humanoid.WalkSpeed = 8
				end
			end
		end
		
		::continue::
	end
end

function EnemyAIService:ExecuteAttack(enemyModel, targetPlayer, isElite)
	-- This will be handled by CombatService
	-- EnemyAIService just triggers it
	DebugService:Log("[EnemyAI] Attack executed:", enemyModel.Name, "->", targetPlayer.Name)
	
	-- Fire attack event (will be handled by CombatService)
	local CombatService = require(script.Parent:WaitForChild("CombatService"))
	CombatService:EnemyAttack(enemyModel, targetPlayer, isElite)
end

function EnemyAIService:UnregisterEnemy(model)
	enemyData[model] = nil
end

return EnemyAIService
