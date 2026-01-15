-- TelemetryService.lua
-- Minimal in-memory telemetry emitter for development and testing.

local TelemetryService = {}
TelemetryService.__index = TelemetryService

local counters = {}

function TelemetryService:Emit(eventName, payload)
    if type(eventName) ~= "string" then return end
    counters[eventName] = (counters[eventName] or 0) + 1
    -- Simple logging for now
    local ok, json = pcall(function()
        return game:GetService("HttpService"):JSONEncode({ event = eventName, payload = payload or {}, ts = os.time() })
    end)
    if ok then
        print("[Telemetry] ", json)
    else
        print("[Telemetry] event:", eventName)
    end
end

function TelemetryService:GetCount(eventName)
    return counters[eventName] or 0
end

function TelemetryService:Snapshot()
    local copy = {}
    for k, v in pairs(counters) do copy[k] = v end
    return copy
end

return TelemetryService
