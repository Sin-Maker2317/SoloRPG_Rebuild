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

-- NEW: Equip remote handler
local Equip = ensureRemoteEvent("Equip")
Equip.OnServerEvent:Connect(function(player, itemId)
	if type(itemId) ~= "string" or not player or not player.Parent then return end
	local ok, item = EquipmentService:Equip(player, itemId)
	if ok then
		CombatEvent:FireClient(player, { type = "ItemEquipped", itemId = itemId, itemName = item.name })
		DebugService:Log("[Equip] Player", player.Name, "equipped", item.name)
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

-- NEW: UseSkill remote handler
local UseSkill = ensureRemoteEvent("UseSkill")
UseSkill.OnServerEvent:Connect(function(player, skillId, targetEnemy)
	if not player or not player.Parent or type(skillId) ~= "string" then return end
	
	local stamina = StaminaService:Get(player)
	local ok, skillDef = SkillService:UseSkill(player, skillId)
	
	if ok then
		StaminaService:Use(player, skillDef.staminaCost)
		
		-- Apply skill effects if there's a target
		if targetEnemy and skillDef.damage > 0 then
			CombatService:PlayerSkillAttack(player, targetEnemy, skillDef)
		end
		
		-- Handle Guard mechanic activation
		if skillId == "Guard" then
			GuardService:StartGuard(player)
		end
		
		CombatEvent:FireClient(player, { 
			type = "SkillUsed", 
			skillId = skillId, 
			damage = skillDef.damage,
			cooldown = skillDef.cooldown
		})
		DebugService:Log("[UseSkill] Player", player.Name, "used", skillId)
	else
		CombatEvent:FireClient(player, { type = "SkillFailed", reason = skillDef })
	end
end)

-- IMPROVED: Attack remote - server-side validation
Attack.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	
	-- Check if player is in dodge window (server-side dodge protection)
	if DodgeService:IsInDodgeWindow(player) then
		-- Player in opponent's dodge window? Damage negated handled on damage calc
		DebugService:Log("[Attack] Target would be in dodge window")
	end
	
	-- Try to find target (lock-on target or nearest)
	-- For now, just apply base damage to any nearby enemy
	-- TODO: implement proper target validation
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local enemies = game:GetService("Workspace"):FindFirstChild("Enemies")
			if enemies then
				local nearest = nil
				local minDist = 15 -- attack range
				for _, enemy in ipairs(enemies:GetChildren()) do
					local eHRP = enemy:FindFirstChild("HumanoidRootPart")
					if eHRP then
						local dist = (eHRP.Position - hrp.Position).Magnitude
						if dist < minDist then
							minDist = dist
							nearest = enemy
						end
					end
				end
				
				if nearest then
					local humanoid = nearest:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then
						CombatService:DealDamage(humanoid)
						CombatEvent:FireClient(player, { type = "HitConfirm", damage = CombatService.BASE_DAMAGE })
						DebugService:Log("[Attack] Hit enemy:", nearest.Name)
					end
				end
			end
		end
	end
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