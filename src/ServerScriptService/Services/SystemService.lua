-- ServerScriptService/Services/SystemService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SystemService = {}
SystemService.__index = SystemService

-- System metrics
SystemService.Metrics = {
	totalPlayers = 0,
	totalMatches = 0,
	totalGatesCompleted = 0,
	totalBossesDefeated = 0,
	systemUptime = tick()
}

function SystemService:GetSystemStatus()
	local Players = game:GetService("Players")
	local currentPlayers = #Players:GetPlayers()
	
	return {
		status = "Online",
		uptime = tick() - self.Metrics.systemUptime,
		playersOnline = currentPlayers,
		totalPlayed = self.Metrics.totalPlayers,
		timestamp = tick()
	}
end

function SystemService:LogEvent(eventType, player, data)
	local timestamp = tick()
	
	-- Structure event data
	local eventData = {
		type = eventType,
		player = player and player.Name or "System",
		userId = player and player.UserId or 0,
		data = data or {},
		timestamp = timestamp
	}
	
	-- Save to DataStore for analytics
	local ds = game:GetService("DataStoreService"):GetDataStore("SystemEvents_V1")
	pcall(function()
		ds:UpdateAsync("Events_" .. math.floor(timestamp), function(oldValue)
			return oldValue or {}
		end)
	end)
	
	return true
end

function SystemService:RecordGameAction(player, action, details)
	local eventData = {
		action = action,
		details = details,
		timestamp = tick()
	}
	
	self:LogEvent("GameAction", player, eventData)
end

function SystemService:HealthCheck()
	local Players = game:GetService("Players")
	local playersOnline = #Players:GetPlayers()
	
	return {
		running = true,
		playerCount = playersOnline,
		timestamp = tick(),
		version = "1.0"
	}
end

function SystemService:GetPerformanceMetrics()
	return {
		uptime = tick() - self.Metrics.systemUptime,
		totalPlayers = self.Metrics.totalPlayers,
		totalMatches = self.Metrics.totalMatches,
		totalGatesCompleted = self.Metrics.totalGatesCompleted,
		totalBossesDefeated = self.Metrics.totalBossesDefeated
	}
end

return SystemService
