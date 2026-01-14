-- ServerScriptService/Services/StunService.lua
local StunService = {}
local stunEndTimes = {}

function StunService:Stun(humanoid, duration)
	if not humanoid then return false end
	
	-- Mark as stunned
	stunEndTimes[humanoid] = tick() + duration
	
	-- Disable movement during stun
	local humanoidRootPart = humanoid.Parent:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CanCollide = true
	end
	
	-- Visual feedback: white tint flash
	local character = humanoid.Parent
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color = Color3.fromRGB(255, 255, 255)
			end
		end
		
		-- Restore color after brief flash
		task.wait(0.15)
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color = Color3.new(0.5, 0.5, 0.5)
			end
		end
	end
	
	return true
end

function StunService:IsStunned(humanoid)
	if not humanoid then return false end
	
	local stunEndTime = stunEndTimes[humanoid]
	if not stunEndTime then return false end
	
	if tick() >= stunEndTime then
		stunEndTimes[humanoid] = nil
		return false
	end
	
	return true
end

function StunService:GetRemainingStunTime(humanoid)
	if not humanoid then return 0 end
	
	local stunEndTime = stunEndTimes[humanoid]
	if not stunEndTime then return 0 end
	
	local remaining = stunEndTime - tick()
	if remaining <= 0 then
		stunEndTimes[humanoid] = nil
		return 0
	end
	
	return remaining
end

function StunService:ClearStun(humanoid)
	if humanoid then
		stunEndTimes[humanoid] = nil
	end
end

return StunService
