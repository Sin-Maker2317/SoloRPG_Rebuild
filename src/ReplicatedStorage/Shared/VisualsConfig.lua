-- VisualsConfig.lua (Temporary graphics pass)
-- Purpose: centralize simple, replaceable visual choices for testing only.
-- NOTE: Temporary. Replace with final art pipeline later.

local Visuals = {}

Visuals.enemyBodyColor = Color3.fromRGB(120, 50, 50) -- muted enemy tone
Visuals.enemyOutline = Color3.fromRGB(200, 100, 100)
Visuals.enemyFillTransparency = 0.6

Visuals.envStoneColor = Color3.fromRGB(80,85,90)
Visuals.envStoneMaterial = Enum.Material.Slate

Visuals.uiAccent = Color3.fromRGB(200,200,200)
Visuals.uiBG = Color3.fromRGB(18,18,18)

function Visuals:GetGateColor(grade)
    -- subtle temperature shifts by grade (string or number ok)
    grade = tostring(grade or "1")
    if grade == "1" then return Color3.fromRGB(100,120,140) end
    if grade == "2" then return Color3.fromRGB(110,100,120) end
    if grade == "3" then return Color3.fromRGB(120,90,100) end
    return Color3.fromRGB(100,110,120)
end

return Visuals
