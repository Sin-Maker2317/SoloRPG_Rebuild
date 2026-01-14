local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TargetFrame"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.28, 0.10)
frame.Position = UDim2.fromScale(0.02, 0.06)
frame.BackgroundTransparency = 0.18
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Transparency = 0.60
stroke.Parent = frame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.fromScale(1, 0.45)
nameLabel.BackgroundTransparency = 1
nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextStrokeTransparency = 0.85
nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
nameLabel.Text = "Target"
nameLabel.Parent = frame

local hpBg = Instance.new("Frame")
hpBg.Size = UDim2.fromScale(0.94, 0.30)
hpBg.Position = UDim2.fromScale(0.03, 0.58)
hpBg.BackgroundTransparency = 0.45
hpBg.BorderSizePixel = 0
hpBg.Parent = frame

local hpCorner = Instance.new("UICorner")
hpCorner.CornerRadius = UDim.new(0, 8)
hpCorner.Parent = hpBg

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.fromScale(1, 1)
hpBar.BorderSizePixel = 0
hpBar.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
hpBar.Parent = hpBg

local hpCorner2 = Instance.new("UICorner")
hpCorner2.CornerRadius = UDim.new(0, 8)
hpCorner2.Parent = hpBar

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.fromScale(1, 0.55)
hpText.Position = UDim2.fromScale(0, 0.18)
hpText.BackgroundTransparency = 1
hpText.TextScaled = true
hpText.Font = Enum.Font.Gotham
hpText.TextStrokeTransparency = 0.85
hpText.TextColor3 = Color3.fromRGB(235,235,235)
hpText.Text = "HP: 0/0"
hpText.Parent = frame

RunService.RenderStepped:Connect(function()
	local t = _G.__LOCKON_TARGET
	if not t or not t.Parent then
		frame.Visible = false
		return
	end

	local hum = t:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		frame.Visible = false
		return
	end

	frame.Visible = true
	nameLabel.Text = tostring(t.Name)

	local hp = hum.Health
	local mx = hum.MaxHealth
	local pct = (mx > 0) and math.clamp(hp / mx, 0, 1) or 0
	hpBar.Size = UDim2.fromScale(pct, 1)
	hpText.Text = ("HP: %d/%d"):format(math.max(0, math.floor(hp+0.5)), math.floor(mx+0.5))
end)
