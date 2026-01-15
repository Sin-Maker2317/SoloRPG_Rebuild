-- ServerScriptService/Services/DebugService.lua

local RunService = game:GetService("RunService")

local DebugService = {}
DebugService.__index = DebugService

DebugService.Enabled = RunService:IsStudio()

function DebugService:Log(...)
	if self.Enabled then
		print("[DEBUG]", ...)
	end
end

function DebugService:Warn(...)
	if self.Enabled then
		warn("[DEBUG]", ...)
	end
end

return DebugService

