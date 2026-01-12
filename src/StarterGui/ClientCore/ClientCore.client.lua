local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[ClientCore] loaded")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
print("[ClientCore] Remotes ready")

local Attack = Remotes:WaitForChild("Attack")
local ClientLog = Remotes:WaitForChild("ClientLog")

ClientLog:FireServer("ClientCore loaded OK (StarterGui)")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		ClientLog:FireServer("F pressed -> Attack:FireServer()")
		Attack:FireServer()
	end
end)
