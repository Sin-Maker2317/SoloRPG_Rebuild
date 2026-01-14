local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local useSkill = remotes:WaitForChild("UseSkill")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkillBarGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 56)
frame.Position = UDim2.new(0.5, -120, 0.88, 0)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.BackgroundTransparency = 0.2
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.Parent = screenGui

local buttons = {}
local skillIds = { "Slash", "Heavy", "PowerStrike" }

for i, id in ipairs(skillIds) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 72, 0, 48)
    btn.Position = UDim2.new(0, (i-1)*76 + 8, 0, 4)
    btn.Text = id
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.fromRGB(230,230,230)
    btn.Parent = frame

    local cooldownOverlay = Instance.new("Frame")
    cooldownOverlay.Size = UDim2.new(1,0,1,0)
    cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    cooldownOverlay.BackgroundTransparency = 0.5
    cooldownOverlay.Visible = false
    cooldownOverlay.Parent = btn

    btn.MouseButton1Click:Connect(function()
        useSkill:FireServer(id)
        cooldownOverlay.Visible = true
        task.delay(0.5, function() cooldownOverlay.Visible = false end)
    end)

    buttons[id] = { btn = btn, overlay = cooldownOverlay }
end

-- Listen for server feedback (basic)
local useSkillClient = remotes:FindFirstChild("UseSkill")
if useSkillClient and useSkillClient:IsA("RemoteEvent") then
    useSkillClient.OnClientEvent:Connect(function(res)
        -- optional: show result in console for now
        if res and res.success then
            print("Skill used: ", res)
        else
            print("Skill failed: ", res)
        end
    end)
end
