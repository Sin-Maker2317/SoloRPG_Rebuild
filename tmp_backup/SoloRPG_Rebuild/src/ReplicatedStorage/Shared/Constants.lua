-- Shared/Constants.lua
local Constants = {}

Constants.REMOTES_FOLDER_NAME = "Remotes"

-- Combat tuning
Constants.STAMINA_COST_DODGE = 20
Constants.STAMINA_COST_GUARD = 5
Constants.STAMINA_COST_SKILL = 30
Constants.DODGE_IFRAME_DURATION = 0.3
Constants.GUARD_DAMAGE_REDUCTION = 0.5
Constants.GUARD_BREAK_THRESHOLD = 100

-- Cooldowns (seconds)
Constants.COOLDOWN_GATE = 30
Constants.COOLDOWN_SKILL_BASE = 5

-- Gate grades
Constants.GATE_GRADES = { "E", "D", "C", "B", "A", "S" }
Constants.GATE_TYPES = { "Clear", "Survival", "Boss", "Puzzle" }

-- Stats
Constants.BASE_STAT_POINTS_PER_LEVEL = 3
Constants.MAX_LEVEL = 100

-- XP curve (simplified: level * 100)
Constants.XP_BASE_PER_LEVEL = 100

-- World events
Constants.WORLD_EVENT_INTERVAL = 1800 -- 30 minutes in seconds (Studio: 180 = 3 minutes)
Constants.STUDIO_EVENT_INTERVAL = 180 -- 3 minutes for Studio

-- Reputation
Constants.REPUTATION_GATE_STEAL_PENALTY = -10
Constants.REPUTATION_GUILD_HELP_BONUS = 5

-- Keys
Constants.DAILY_KEY_GRANT = 5

return Constants
