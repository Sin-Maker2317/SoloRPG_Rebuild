-- ServerScriptService/Services/NotificationService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationService = {}
NotificationService.__index = NotificationService

-- Notification types
NotificationService.Types = {
	INFO = "info",
	SUCCESS = "success",
	WARNING = "warning",
	ERROR = "error",
	QUEST = "quest",
	REWARD = "reward",
	SYSTEM = "system"
}

function NotificationService:Send(player, message, notificationType, duration)
	notificationType = notificationType or self.Types.INFO
	duration = duration or 5
	
	if not player or not player.Parent then return false end
	
	-- Fire client notification event
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local notifyEvent = remotes:FindFirstChild("Notification")
		if notifyEvent then
			notifyEvent:FireClient(player, {
				message = message,
				type = notificationType,
				duration = duration,
				timestamp = tick()
			})
		end
	end
	
	return true
end

function NotificationService:Broadcast(message, notificationType)
	notificationType = notificationType or self.Types.SYSTEM
	
	local Players = game:GetService("Players")
	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, message, notificationType, 8)
	end
end

function NotificationService:SendReward(player, amount, rewardType)
	rewardType = rewardType or "xp"
	
	local message = "+" .. amount .. " " .. string.upper(rewardType)
	self:Send(player, message, self.Types.REWARD, 3)
end

function NotificationService:SendQuestUpdate(player, questName, stage)
	local message = questName .. " - " .. stage
	self:Send(player, message, self.Types.QUEST, 4)
end

function NotificationService:SendSystemAlert(player, message)
	self:Send(player, message, self.Types.SYSTEM, 6)
end

return NotificationService
