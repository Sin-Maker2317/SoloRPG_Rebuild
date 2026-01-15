-- BossService_Gate1Harness.lua
-- Deterministic harness for Gate1 boss ability rotation.
-- Non-destructive: this is a harness that can be used by tests or swapped into BossService.

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Gate1Harness = {}
Gate1Harness.__index = Gate1Harness

-- Example ability timeline (seconds)
local ABILITIES = {
    { id = "TelegraphSlam", telegraph = 1.5, cast = 0.5, cooldown = 5 },
    { id = "SwipeCombo", telegraph = 0.8, cast = 0.3, cooldown = 3 },
    { id = "GroundShock", telegraph = 2.0, cast = 0.7, cooldown = 8 }
}

function Gate1Harness.new(bossModel)
    local self = setmetatable({}, Gate1Harness)
    self.boss = bossModel
    self.index = 1
    self.running = false
    self.nextAvailable = 0
    self.telemetry = nil
    pcall(function()
        self.telemetry = require(script.Parent:WaitForChild("TelemetryService"))
    end)
    return self
end

function Gate1Harness:Start()
    if self.running then return end
    self.running = true
    self._conn = RunService.Heartbeat:Connect(function(dt)
        self:_update(dt)
    end)
    if self.telemetry then self.telemetry:Emit("BossHarnessStart", { boss = tostring(self.boss and self.boss.Name) }) end
end

function Gate1Harness:Stop()
    if not self.running then return end
    self.running = false
    if self._conn then self._conn:Disconnect() end
    if self.telemetry then self.telemetry:Emit("BossHarnessStop", { boss = tostring(self.boss and self.boss.Name) }) end
end

function Gate1Harness:_update(dt)
    if not self.boss then return end
    local now = tick()
    if now < self.nextAvailable then return end

    local ability = ABILITIES[self.index]
    if not ability then
        self.index = 1
        ability = ABILITIES[self.index]
    end

    -- Telegraphed cast sequence
    if self.telemetry then self.telemetry:Emit("BossAbilityTelegraph", { ability = ability.id }) end
    -- Wait telegraph (synchronous sleep ok on server for harness)
    task.wait(ability.telegraph)

    if self.telemetry then self.telemetry:Emit("BossAbilityCast", { ability = ability.id }) end
    -- Apply ability effect placeholder (non-destructive)
    -- e.g., we could damage players within range here in production harness.
    task.wait(ability.cast)

    if self.telemetry then self.telemetry:Emit("BossAbilityUsed", { ability = ability.id }) end

    -- schedule next ability
    self.nextAvailable = tick() + ability.cooldown
    self.index = (self.index % #ABILITIES) + 1
end

return Gate1Harness
