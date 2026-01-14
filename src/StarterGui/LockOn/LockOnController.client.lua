local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local LOCK_RANGE = 20

local function getHRP()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function findNearestEnemy(maxDist)
	local hrp = getHRP()
	if not hrp then return nil end

	local enemies = Workspace:FindFirstChild("Enemies")
	if not enemies then return nil end

	local best, bestD = nil, maxDist
	for _, m in ipairs(enemies:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("IsEnemy") == true then
			local hum = m:FindFirstChildOfClass("Humanoid")
			local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
			if hum and root and hum.Health > 0 then
				local d = (root.Position - hrp.Position).Magnitude
				if d < bestD then
					bestD = d
					best = m
				end
			end
		end
	end
	return best
end

local locked = false
local target = nil

local function setTarget(newTarget)
	target = newTarget
	_G.__LOCKON_TARGET = target -- exposed for UI
end

local function toggle()
	locked = not locked
	if not locked then
		setTarget(nil)
	else
		setTarget(findNearestEnemy(LOCK_RANGE))
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Q then
		toggle()
	end
end)

-- keep target valid / reacquire if dead or too far
RunService.RenderStepped:Connect(function()
	if not locked then return end
	if not target or not target.Parent then
		setTarget(findNearestEnemy(LOCK_RANGE))
		return
	end
	local hum = target:FindFirstChildOfClass("Humanoid")
	local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
	local hrp = getHRP()
	if not hum or hum.Health <= 0 or not root or not hrp then
		setTarget(findNearestEnemy(LOCK_RANGE))
		return
	end
	if (root.Position - hrp.Position).Magnitude > LOCK_RANGE then
		setTarget(findNearestEnemy(LOCK_RANGE))
	end
end)
