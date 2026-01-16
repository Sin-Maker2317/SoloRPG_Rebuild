local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("DebugService"))

local PlayerStateService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerStateService"))

local WorldService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("WorldService"))

local CombatService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("CombatService"))

local ProfileMemoryService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("ProfileMemoryService"))

local RewardService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("RewardService"))
local AwakeningDeathService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("AwakeningDeathService"))
local AwakeningPuzzleService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("AwakeningPuzzleService"))
local ProgressService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("ProgressService"))
local QuestService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("QuestService"))
local InventoryService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("InventoryService"))

local CharacterStats =
	require(script.Parent:WaitForChild("Services"):WaitForChild("CharacterStats"))

local DodgeService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("DodgeService"))

local StaminaService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("StaminaService"))

local SkillService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("SkillService"))

local StunService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("StunService"))

local GuardService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("GuardService"))

local GuildService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("GuildService"))

local EquipmentService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("EquipmentService"))

local BossService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("BossService"))

local AbilityService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("AbilityService"))

local WorldGatesService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("WorldGatesService"))
local MobService = require(script.Parent:WaitForChild("Services"):WaitForChild("MobService"))
local RespawnService = require(script.Parent:WaitForChild("Services"):WaitForChild("RespawnService"))

local ArenaService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("ArenaService"))

local LeaderboardService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("LeaderboardService"))

local SystemService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("SystemService"))

local NotificationService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("NotificationService"))

local CacheService =
	require(script.Parent:WaitForChild("Services"):WaitForChild("CacheService"))
local RemoteGuardService = require(script.Parent:WaitForChild("Services"):WaitForChild("RemoteGuardService"))

DebugService:Log("[ServerBootstrap] STARTING...")

WorldService:Init()
AwakeningDeathService:Init()
RespawnService:Init()

-- === REMOTES SETUP ===
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = ReplicatedStorage
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local rf = RemotesFolder:FindFirstChild(name)
	if rf and rf:IsA("RemoteFunction") then return rf end
	if rf then rf:Destroy() end

	rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = RemotesFolder
	return rf
end

local function ensureRemoteEvent(name: string): RemoteEvent
	local re = RemotesFolder:FindFirstChild(name)
	if re and re:IsA("RemoteEvent") then return re end
	if re then re:Destroy() end

	re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = RemotesFolder
	return re
end

local GetPlayerState = ensureRemoteFunction("GetPlayerState")
local GetRewards = ensureRemoteFunction("GetRewards")
local GetProgress = ensureRemoteFunction("GetProgress")
local GetQuests = ensureRemoteFunction("GetQuests")
local GetInventory = ensureRemoteFunction("GetInventory")
local GetCombatStats = ensureRemoteFunction("GetCombatStats")
local ChoosePath = ensureRemoteEvent("ChoosePath")
local Attack = ensureRemoteEvent("Attack")
local ClientLog = ensureRemoteEvent("ClientLog")
	local CombatEvent = ensureRemoteEvent("CombatEvent")
local RequestDodge = ensureRemoteEvent("RequestDodge")
local GateMessage = ensureRemoteEvent("GateMessage")
local AllocateStatPoint = ensureRemoteEvent("AllocateStatPoint")
local StateChanged = ensureRemoteEvent("StateChanged")
local SetGuildFaction = ensureRemoteEvent("SetGuildFaction")
local CompleteTutorial = ensureRemoteEvent("CompleteTutorial")
local UseTerminal = ensureRemoteEvent("UseTerminal")
local ClaimQuest = ensureRemoteEvent("ClaimQuest")
local Notification = ensureRemoteEvent("Notification")

ClientLog.OnServerEvent:Connect(function(player, msg)
	DebugService:Log("[ClientLog]", player.Name, msg)
end)

-- dodgeCooldowns managed by improved RequestDodge handler below; simple early handler removed to avoid duplicate listeners
local dodgeCooldowns = {}

-- === REMOTES LOGIC ===
GetPlayerState.OnServerInvoke = function(player)
	return PlayerStateService:Get(player)
end

GetRewards.OnServerInvoke = function(player)
	local r = RewardService:Get(player)
	return { xp = r.xp, coins = r.coins }
end

GetProgress.OnServerInvoke = function(player)
	local p = ProgressService:Get(player)
	return { awakened = p.awakened, pathChoice = p.pathChoice, faction = p.faction }
end

GetQuests.OnServerInvoke = function(player)
	return QuestService:Snapshot(player)
end

GetInventory.OnServerInvoke = function(player)
	return InventoryService:List(player)
end

-- NEW: GetCombatStats returns character stats + stamina
local GetStatsSnapshot = ensureRemoteFunction("GetStatsSnapshot")
GetStatsSnapshot.OnServerInvoke = function(player)
	local stats = CharacterStats:GetSnapshot(player)
	local stamina = StaminaService:Snapshot(player)
	return {
		character = stats,
		stamina = stamina
	}
end

-- NEW: Stamina remote sync
local GetStamina = ensureRemoteFunction("GetStamina")
GetStamina.OnServerInvoke = function(player)
	return StaminaService:Snapshot(player)
end

-- IMPROVED: RequestDodge with server-side validation
RequestDodge.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	local okGuard, guardReason = RemoteGuardService:CanInvoke(player, "RequestDodge")
	if not okGuard then
		CombatEvent:FireClient(player, { type = "DodgeFailed", reason = guardReason or "RateLimited" })
		return
	end

	local stamina = StaminaService:Get(player)
	if not DodgeService:CanDodge(player, stamina) then
		CombatEvent:FireClient(player, { type = "DodgeFailed", reason = "No stamina or on cooldown" })
		return
	end
	
	local dodgeSuccess, staminaCost = DodgeService:StartDodge(player, function() return StaminaService:Get(player) end)
	if dodgeSuccess then
		StaminaService:Use(player, staminaCost)
		CombatEvent:FireClient(player, { type = "DodgeStarted", duration = DodgeService:GetDodgeDuration() })
		DebugService:Log("[RequestDodge] Player", player.Name, "dodged; stamina now:", StaminaService:Get(player))
	end
end)

-- HELPER: Find nearest enemy to player (MUST BE BEFORE UseSkill)
local function findNearestEnemy(playerHRP, range)
	range = range or 40
	local nearest = nil
	local minDist = range
	
	local enemies = game:GetService("Workspace"):FindFirstChild("Enemies")
	if not enemies then return nil end
	
	for _, enemy in ipairs(enemies:GetChildren()) do
		local eHRP = enemy:FindFirstChild("HumanoidRootPart")
		local eHum = enemy:FindFirstChildOfClass("Humanoid")
		if eHRP and eHum and eHum.Health > 0 then
			local dist = (eHRP.Position - playerHRP.Position).Magnitude
			if dist < minDist then
				minDist = dist
				nearest = enemy
			end
		end
	end
	
	return nearest
end

-- IMPROVED: Allocate stat point using CharacterStats
AllocateStatPoint.OnServerEvent:Connect(function(player, field)
	if type(field) ~= "string" or not player or not player.Parent then return end
	local ok = CharacterStats:AllocatePoint(player, field)
	if ok then
		CombatEvent:FireClient(player, { type = "StatAllocated", field = field })
		DebugService:Log("[AllocateStatPoint] Player", player.Name, "allocated", field)
	end
end)

-- NEW: SetGuildFaction remote handler
local SetGuildFaction = ensureRemoteEvent("SetGuildFaction")
SetGuildFaction.OnServerEvent:Connect(function(player, guildId)
	if type(guildId) ~= "string" or not player or not player.Parent then return end
	local ok, guildDef = GuildService:SetGuild(player, guildId)
	if ok then
		CombatEvent:FireClient(player, { type = "GuildSet", guildId = guildId, guildName = guildDef.name })
		DebugService:Log("[SetGuildFaction] Player", player.Name, "chose", guildDef.name)
	end
end)

-- NEW: EquipItem remote handler (for equipment panel)
local EquipItem = ensureRemoteEvent("EquipItem")
EquipItem.OnServerEvent:Connect(function(player, itemId)
	if type(itemId) ~= "string" or not player or not player.Parent then return end
	local ok, item = EquipmentService:Equip(player, itemId)
	if ok then
		CombatEvent:FireClient(player, { type = "ItemEquipped", itemId = itemId, itemName = item.name })
		DebugService:Log("[EquipItem] Player", player.Name, "equipped", item.name)
	end
end)

-- NEW: StartGate remote handler for boss encounters
local StartGate = ensureRemoteEvent("StartGate")
StartGate.OnServerEvent:Connect(function(player, gateId)
	if type(gateId) ~= "string" or not player or not player.Parent then return end
	local ok, gateDef = WorldGatesService:StartGate(gateId, player)
	if ok then
		CombatEvent:FireClient(player, { type = "GateStarted", gateId = gateId, gateName = gateDef.name })
		DebugService:Log("[StartGate] Player", player.Name, "entered", gateDef.name)
	else
		CombatEvent:FireClient(player, { type = "GateFailed", reason = "Cannot start gate" })
	end
end)

-- Minimal EnterGate flow for Test Phase: spawn 2 simple mobs, reward, teleport back
local EnterGate = ensureRemoteEvent("EnterGate")
local playerGateSessions = {}

local function teleportPlayerToCFrame(player, cframe)
	if not player or not player.Parent or not cframe then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = cframe + Vector3.new(0,3,0)
	end
end

EnterGate.OnServerEvent:Connect(function(player, gateId)
	if not player or not player.Parent then return end
	if playerGateSessions[player] then
		CombatEvent:FireClient(player, { type = "GateFailed", reason = "AlreadyInGate" })
		return
	end

	-- validate gate
	gateId = gateId or "Gate1"
	local gateDef = WorldGatesService.Gates[gateId] or WorldGatesService.Gates.Gate1

	-- teleport player to gate spawn
	local spawnCF = WorldService:GetSpawnCFrame("Spawn_SoloGate") or WorldService:GetSpawnCFrame("Spawn_Town")
	teleportPlayerToCFrame(player, spawnCF)

	-- create session
	local session = { player = player, enemies = {}, remaining = 2, gateId = gateId }
	playerGateSessions[player] = session

	-- safety: on player death inside gate, teleport back and cleanup
	local function onDied()
		-- use central respawn to handle gate deaths
		RespawnService:RespawnPlayer(player, "GateDeath")
		playerGateSessions[player] = nil
	end
	if player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Died:Connect(onDied) end
	end

	-- spawn two simple mobs in front of player
	for i = 1, 2 do
		local pos = spawnCF.Position + Vector3.new((i-1)*4 - 2, 0, -8)
		MobService:SpawnRandom(pos, function(mobKey, cfg, model)
			-- on mob death
			if not player or not player.Parent then return end
			-- simple session reward per mob
			local xp = (gateDef and gateDef.reward_xp and math.floor(gateDef.reward_xp / 2)) or 100
			local coins = (gateDef and gateDef.reward_coins and math.floor(gateDef.reward_coins / 2)) or 50
			RewardService:Add(player, xp, coins)
			GateMessage:FireClient(player, "Enemy defeated: +" .. tostring(xp) .. " XP +" .. tostring(coins) .. " COINS")

			session.remaining = session.remaining - 1
			if session.remaining <= 0 then
				-- gate cleared
				GateMessage:FireClient(player, "Gate Cleared")
				DebugService:Log("[EnterGate] Player", player.Name, "cleared gate", gateId)
				-- teleport back to town
				local townCF = WorldService:GetSpawnCFrame("Spawn_Town")
				teleportPlayerToCFrame(player, townCF)
				playerGateSessions[player] = nil
			end
		end)
	end

	CombatEvent:FireClient(player, { type = "GateStarted", gateId = gateId, gateName = gateDef.name })
	DebugService:Log("[EnterGate] Player", player.Name, "entered test gate", gateId)
end)

-- NEW: CreateMatch remote handler for PvP arenas
local CreateMatch = ensureRemoteEvent("CreateMatch")
CreateMatch.OnServerEvent:Connect(function(player, arenaId, opponentIds)
	if type(arenaId) ~= "string" or not player or not player.Parent then return end
	
	local opponents = {}
	if opponentIds and type(opponentIds) == "table" then
		for _, id in ipairs(opponentIds) do
			local opponent = game:GetService("Players"):FindFirstChild(id) or game:GetService("Players"):FindFirstChildWhichIsA("Player", true)
			if opponent and opponent.UserId == tonumber(id) then
				table.insert(opponents, opponent)
			end
		end
	end
	
	local ok, result = ArenaService:CreateMatch(arenaId, player, opponents)
	if ok then
		local matchId = result.matchId
		CombatEvent:FireClient(player, { type = "MatchCreated", matchId = matchId, arena = result.arena.name })
		DebugService:Log("[CreateMatch] Player", player.Name, "created match:", matchId)
	else
		CombatEvent:FireClient(player, { type = "MatchFailed", reason = result })
	end
end)

-- NEW: GetLeaderboard remote function for rankings
local GetLeaderboard = ensureRemoteFunction("GetLeaderboard")
function GetLeaderboard.OnServerInvoke(player, leaderboardType, limit)
	if type(leaderboardType) ~= "string" then return {} end
	
	return LeaderboardService:GetTopPlayers(leaderboardType, limit or 10)
end

-- NEW: GetSystemStatus remote function for monitoring
local GetSystemStatus = ensureRemoteFunction("GetSystemStatus")
function GetSystemStatus.OnServerInvoke(player)
	return SystemService:GetSystemStatus()
end

-- NEW: GetEquipmentSnapshot remote function for equipment panel
local GetEquipmentSnapshot = ensureRemoteFunction("GetEquipmentSnapshot")
function GetEquipmentSnapshot.OnServerInvoke(player)
	local equipped = EquipmentService:GetEquipped(player)
	local bonuses = EquipmentService:CalculateTotalBonuses(player)
	return { equipped = equipped, bonuses = bonuses }
end

-- NEW: UseSkill remote handler with auto-targeting
local UseSkill = ensureRemoteEvent("UseSkill")
UseSkill.OnServerEvent:Connect(function(player, skillId)
	if not player or not player.Parent or type(skillId) ~= "string" then return end

	local okGuard, guardReason = RemoteGuardService:CanInvoke(player, "UseSkill")
	if not okGuard then
		CombatEvent:FireClient(player, { type = "SkillFailed", reason = guardReason or "RateLimited" })
		return
	end
	
	-- Check stamina and cooldown
	local ok, skillDef = SkillService:UseSkill(player, skillId)
	if not ok then
		CombatEvent:FireClient(player, { type = "SkillFailed", reason = "Cooldown or invalid skill" })
		return
	end
	
	-- Check stamina cost
	local currentStamina = StaminaService:Get(player)
	if currentStamina < skillDef.staminaCost then
		CombatEvent:FireClient(player, { type = "SkillFailed", reason = "Insufficient stamina" })
		return
	end
	
	-- Deduct stamina
	StaminaService:Use(player, skillDef.staminaCost)
	
	-- Apply skill effects
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp and skillDef.damage > 0 then
			-- Find target
			local target = findNearestEnemy(hrp, 50)
			if target then
				local stats = CharacterStats:GetSnapshot(player)
				local damage = CombatService:CalculatePlayerDamage(stats, skillDef.damage)
				
				-- Handle special skill effects
				if skillId == "GuardBreak" then
					if GuardService:IsGuarding(target) then
						local targetHum = target:FindFirstChildOfClass("Humanoid")
						if targetHum then
							StunService:Stun(targetHum, 1.0)
							GuardService:StopGuard(target)
							damage = damage * 1.5
						end
					end
				end
				
				local targetHum = target:FindFirstChildOfClass("Humanoid")
				if targetHum then
					targetHum:TakeDamage(damage)
					CombatEvent:FireClient(player, { type = "SkillHit", skillId = skillId, damage = damage, target = target.Name })
				end
			end
		end
	end
	
	CombatEvent:FireClient(player, { 
		type = "SkillUsed", 
		skillId = skillId, 
		damage = skillDef.damage,
		cooldown = skillDef.cooldown
	})
	DebugService:Log("[UseSkill]", player.Name, "used", skillId, "| Stamina remaining:", StaminaService:Get(player))
end)

-- Attack handling consolidated later in this file (keeps single authoritative handler)

GetCombatStats.OnServerInvoke = function(player)
	local PlayerStatsService = require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerStatsService"))
	local p = PlayerStatsService:Get(player)
	return { defense = p.def or 0, points = p.points or 0 }
end

ChoosePath.OnServerEvent:Connect(function(player, choice)
	DebugService:Log("[ChoosePath] from", player.Name, "choice:", choice)

	-- Only accept valid path choices
	if choice ~= "Solo" and choice ~= "Guild" then
		return
	end

	ProgressService:SetPathChoice(player, choice)
	ProgressService:Save(player)

	if choice == "Solo" then
		PlayerStateService:Set(player, "SoloGateTutorial")
	elseif choice == "Guild" then
		PlayerStateService:Set(player, "GuildGateTutorial")
	end
end)

SetGuildFaction.OnServerEvent:Connect(function(player, factionId: string)
	DebugService:Log("[SetGuildFaction] from", player.Name, "faction:", factionId)

	if type(factionId) ~= "string" then
		return
	end

	if factionId ~= "Hunters" and factionId ~= "WhiteTiger" and factionId ~= "ChoiAssoc" then
		return
	end

	ProfileMemoryService:SetGuildFaction(player, factionId)
	ProgressService:SetFaction(player, factionId)
	ProgressService:Save(player)
end)

CompleteTutorial.OnServerEvent:Connect(function(player)
	PlayerStateService:Set(player, "HospitalChoice")
end)

UseTerminal.OnServerEvent:Connect(function(player, terminalName)
	if type(terminalName) ~= "string" then
		return
	end

	if terminalName == "GateTerminal_SoloE" then
		PlayerStateService:Set(player, "SoloGateTutorial")
		DebugService:Log("[UseTerminal]", player.Name, "used", terminalName)
	elseif terminalName == "GateTerminal_SoloE2" then
		PlayerStateService:Set(player, "SoloGateTutorial")
		DebugService:Log("[UseTerminal]", player.Name, "used", terminalName)
	end
end)

ClaimQuest.OnServerEvent:Connect(function(player, questId)
	local ok, msg = QuestService:TryClaim(player, questId)
	GateMessage:FireClient(player, msg)
end)

Attack.OnServerEvent:Connect(function(player)
	local okGuard, guardReason = RemoteGuardService:CanInvoke(player, "Attack")
	if not okGuard then
		CombatEvent:FireClient(player, { type = "HitFailed", reason = guardReason or "RateLimited" })
		return
	end

	DebugService:Log("[Attack] received from", player.Name)

	local character = player.Character
	if not character then
		DebugService:Log("[Attack] no character")
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		DebugService:Log("[Attack] no HRP")
		return
	end

	-- find nearest enemy within melee range (6 studs)
	local target = findNearestEnemy(hrp, 6)
	if not target then
		DebugService:Log("[Attack] no enemy in melee range")
		CombatEvent:FireClient(player, { type = "HitFailed", reason = "NoTarget" })
		return
	end

	local targetHum = target:FindFirstChildOfClass("Humanoid")
	if not targetHum or targetHum.Health <= 0 then
		DebugService:Log("[Attack] invalid target")
		CombatEvent:FireClient(player, { type = "HitFailed", reason = "InvalidTarget" })
		return
	end

	-- Deal damage via CombatService with dealerPlayer for correct dodge/scale handling
	local damage = CombatService:DealDamage(targetHum, player)
	if damage and type(damage) == "number" and damage > 0 then
		CombatEvent:FireClient(player, { type = "HitConfirm", damage = damage, target = target.Name })
		DebugService:Log("[Attack] damage applied", damage, "to", target.Name, "HP now:", targetHum.Health)
	else
		CombatEvent:FireClient(player, { type = "HitFailed", reason = "DodgedOrBlocked" })
		DebugService:Log("[Attack] damage not applied (dodged/blocked)")
	end
end)

-- === PLAYER LIFECYCLE ===
PlayerStateService:Init()
AwakeningPuzzleService:Init(
	function(player) return PlayerStateService:Get(player) end,
	function(player, state) PlayerStateService:Set(player, state) end
)

Players.PlayerAdded:Connect(function(player)
	RewardService:Load(player)
	CharacterStats:Load(player)
	StaminaService:Load(player)
	GuildService:LoadGuild(player)
	EquipmentService:LoadEquipment(player)
	PlayerStateService:OnPlayerAdded(player)
	DebugService:Log("[PlayerAdded]", player.Name, "loaded all services")
end)

Players.PlayerRemoving:Connect(function(player)
	RewardService:Save(player)
	CharacterStats:Save(player)
	StaminaService:Clear(player)
	GuildService:Clear(player)
	EquipmentService:Clear(player)
	PlayerStateService:OnPlayerRemoving(player)
	AwakeningPuzzleService:OnPlayerRemoving(player)
	DodgeService:Clear(player)
	DebugService:Log("[PlayerRemoving]", player.Name, "saved and cleared")
end)

DebugService:Log("[ServerBootstrap] Server started, remotes ready.")
DebugService:Log("[ServerBootstrap] Remotes children:", table.concat((function()
	local t = {}
	for _, c in ipairs(RemotesFolder:GetChildren()) do
		table.insert(t, c.Name .. ":" .. c.ClassName)
	end
	return t
end)(), ", "))