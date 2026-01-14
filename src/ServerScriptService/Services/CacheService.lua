-- ServerScriptService/Services/CacheService.lua
local CacheService = {}
CacheService.__index = CacheService

CacheService.TTL = 300 -- Cache time to live: 5 minutes
CacheService.cache = {} -- { [key] = { value, expireTime } }

function CacheService:Set(key, value, ttl)
	ttl = ttl or self.TTL
	self.cache[key] = {
		value = value,
		expireTime = tick() + ttl
	}
	return true
end

function CacheService:Get(key)
	local entry = self.cache[key]
	if not entry then return nil end
	
	-- Check if expired
	if tick() >= entry.expireTime then
		self.cache[key] = nil
		return nil
	end
	
	return entry.value
end

function CacheService:Exists(key)
	return self:Get(key) ~= nil
end

function CacheService:Delete(key)
	self.cache[key] = nil
	return true
end

function CacheService:Clear()
	self.cache = {}
	return true
end

function CacheService:GetStats()
	local count = 0
	for _ in pairs(self.cache) do
		count = count + 1
	end
	
	return {
		entries = count,
		memoryUsage = "~" .. (count * 256) .. " bytes"
	}
end

-- Periodic cleanup of expired entries
local RunService = game:GetService("RunService")
if RunService:IsServer() then
	spawn(function()
		while true do
			task.wait(60) -- Cleanup every minute
			
			local now = tick()
			for key, entry in pairs(CacheService.cache) do
				if now >= entry.expireTime then
					CacheService.cache[key] = nil
				end
			end
		end
	end)
end

return CacheService
