-- Shared/Util.lua
local Util = {}

function Util.Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function Util.FormatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", minutes, secs)
end

function Util.DeepCopy(original)
	local copy
	if type(original) == "table" then
		copy = {}
		for key, value in pairs(original) do
			copy[key] = Util.DeepCopy(value)
		end
		setmetatable(copy, getmetatable(original))
	else
		copy = original
	end
	return copy
end

return Util
