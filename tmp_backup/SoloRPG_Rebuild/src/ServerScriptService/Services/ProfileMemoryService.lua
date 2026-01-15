-- ServerScriptService/Services/ProfileMemoryService.lua
-- TEMP DISABLED: this module was causing recursive require errors.
-- We'll reintroduce it later cleanly.

local ProfileMemoryService = {}
ProfileMemoryService.__index = ProfileMemoryService

function ProfileMemoryService:Get(player)
	return { xp = 0, coins = 0, pathChoice = nil, faction = nil }
end

function ProfileMemoryService:Clear(player)
end

return ProfileMemoryService

