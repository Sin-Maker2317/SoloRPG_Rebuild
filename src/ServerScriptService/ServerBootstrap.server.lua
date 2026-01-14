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

DebugService:Log("[ServerBootstrap] STARTING...")

WorldService:Init()
AwakeningDeathService:Init()

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

-- Simple dodge request handling (server-side validation + cooldown)
local dodgeCooldowns = {}
RequestDodge.OnServerEvent:Connect(function(player)
	local last = dodgeCooldowns[player]
	local now = os.clock()
	if last and now - last < 0.5 then
		-- too fast, ignore
		return
	end
	dodgeCooldowns[player] = now

	-- Approve dodge by notifying client via CombatEvent
	pcall(function()
		CombatEvent:FireClient(player, { type = "DodgeApproved" })
	end)
end)

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

-- HELPER: Find nearest enemy to player
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

-- IMPROVED: Attack remote - server-side validation with proper damage
Attack.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local nearest = findNearestEnemy(hrp, 40)
	if not nearest then return end
	
	local humanoid = nearest:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Calculate damage with proper scaling
	local stats = CharacterStats:GetSnapshot(player)
	local damage = CombatService:CalculatePlayerDamage(stats, CombatService.BASE_DAMAGE)
	
	-- Apply damage
	humanoid:TakeDamage(damage)
	
	-- Notify client of hit
	CombatEvent:FireClient(player, { type = "HitConfirm", damage = damage, targetName = nearest.Name })
	DebugService:Log("[Attack]", player.Name, "hit", nearest.Name, "for", damage, "damage")
end)

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

	local closestHumanoid = nil
	local closestDist = 999

	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") then
			local h = m:FindFirstChildOfClass("Humanoid")
			local rp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
			if h and rp and h.Health > 0 then
				local d = (rp.Position - hrp.Position).Magnitude
				if d < closestDist then
					closestDist = d
					closestHumanoid = h
				end
			end
		end
	end

	DebugService:Log("[Attack] closestDist:", closestDist, "found:", closestHumanoid ~= nil)

	if closestHumanoid and closestDist <= 30 then
		CombatService:DealDamage(closestHumanoid)
		DebugService:Log("[Attack] damage applied, target HP now:", closestHumanoid.Health)
	else
		DebugService:Log("[Attack] no target in range")
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