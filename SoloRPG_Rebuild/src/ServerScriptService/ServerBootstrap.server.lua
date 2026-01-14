local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Ensure Remotes folder exists (EnsureRemotes already handles runtime, but create for build-time clarity)
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

local remoteDefinitions = {
    GetPlayerState = "Function",
    GetRewards = "Function",
    GetProgress = "Function",
    GetQuests = "Function",
    GetInventory = "Function",
    GetCombatStats = "Function",
    GetStatsSnapshot = "Function",
    GetEquipmentSnapshot = "Function",
    ChoosePath = "Event",
    Attack = "Event",
    UseSkill = "Event",
    ClientLog = "Event",
    CombatEvent = "Event",
    RequestDodge = "Event",
    GateMessage = "Event",
    AllocateStatPoint = "Event",
    StateChanged = "Event",
    SetGuildFaction = "Event",
    CompleteTutorial = "Event",
    UseTerminal = "Event",
    ClaimQuest = "Event",
}

local function ensureRemote(name, kind)
    if remotes:FindFirstChild(name) then return remotes:FindFirstChild(name) end
    if kind == "Function" then
        local rf = Instance.new("RemoteFunction")
        rf.Name = name
        rf.Parent = remotes
        return rf
    else
        local re = Instance.new("RemoteEvent")
        re.Name = name
        re.Parent = remotes
        return re
    end
end

for name, kind in pairs(remoteDefinitions) do
    ensureRemote(name, kind)
end

-- Require core services silently if present
local function safeRequire(name)
    local ok, mod = pcall(function()
        local s = script.Parent:FindFirstChild(name) or script.Parent:FindFirstChild("Services") and script.Parent.Services:FindFirstChild(name)
        if s then return require(s) end
        return nil
    end)
    return ok and mod or nil
end

local StatsService = safeRequire("StatsService") or safeRequire("PlayerStatsService")
local CombatResolve = safeRequire("CombatResolveService")
local EnemyAI = safeRequire("EnemyAIService")
local EnemyService = safeRequire("EnemyService")

-- Wire GetCombatStats
local getCombatStatsRF = remotes:FindFirstChild("GetCombatStats")
if getCombatStatsRF and getCombatStatsRF:IsA("RemoteFunction") then
    if StatsService and type(StatsService.GetStats) == "function" then
        getCombatStatsRF.OnServerInvoke = function(player)
            return StatsService:GetStats(player)
        end
    else
        getCombatStatsRF.OnServerInvoke = function() return {} end
    end
end

-- Wire GetPlayerState fallback
local getPlayerState = remotes:FindFirstChild("GetPlayerState")
if getPlayerState and getPlayerState:IsA("RemoteFunction") then
    getPlayerState.OnServerInvoke = function(player)
        return { state = "Town" }
    end
end

-- Attack event: basic server-side resolution if CombatResolveService exists
local attackEvent = remotes:FindFirstChild("Attack")
if attackEvent and attackEvent:IsA("RemoteEvent") then
    attackEvent.OnServerEvent:Connect(function(player, target, attackData)
        if CombatResolve and type(CombatResolve.ResolvePlayerAttack) == "function" then
            local res = CombatResolve.ResolvePlayerAttack(player, target, attackData)
            if res and res.damage and target and target.FindFirstChild then
                local hum = target:FindFirstChildWhichIsA("Humanoid") or (target.Parent and target.Parent:FindFirstChildWhichIsA("Humanoid"))
                if hum and res.damage > 0 then
                    hum:TakeDamage(res.damage)
                end
            end
        end
    end)
end

print("[ServerBootstrap] remotes ensured and core services wired")
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

AllocateStatPoint.OnServerEvent:Connect(function(player, field)
	if type(field) ~= "string" then return end
	local PlayerStatsService = require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerStatsService"))
	pcall(function()
		PlayerStatsService:AllocatePoint(player, field)
	end)
end)

-- === REMOTES LOGIC ===
GetPlayerState.OnServerInvoke = function(player)
	return PlayerStateService:Get(player)
end

-- RewardService already required above; avoid duplicate require

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
	PlayerStateService:OnPlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	RewardService:Save(player)
	PlayerStateService:OnPlayerRemoving(player)
	AwakeningPuzzleService:OnPlayerRemoving(player)
end)

DebugService:Log("[ServerBootstrap] Server started, remotes ready.")
DebugService:Log("[ServerBootstrap] Remotes children:", table.concat((function()
	local t = {}
	for _, c in ipairs(RemotesFolder:GetChildren()) do
		table.insert(t, c.Name .. ":" .. c.ClassName)
	end
	return t
end)(), ", "))