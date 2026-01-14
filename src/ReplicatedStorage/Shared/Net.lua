-- Shared/Net.lua
local Net = {}

-- Remote function names
Net.GetPlayerState = "GetPlayerState"
Net.GetRewards = "GetRewards"
Net.GetProgress = "GetProgress"
Net.GetQuests = "GetQuests"
Net.GetInventory = "GetInventory"
Net.GetStatsSnapshot = "GetStatsSnapshot"
Net.GetCombatStats = "GetCombatStats"
Net.GetEquipmentSnapshot = "GetEquipmentSnapshot"
Net.GetAvailableGates = "GetAvailableGates"
Net.GetGuildSnapshot = "GetGuildSnapshot"
Net.GetReputationSnapshot = "GetReputationSnapshot"
Net.GetStorySnapshot = "GetStorySnapshot"

-- Remote event names
Net.ChoosePath = "ChoosePath"
Net.Attack = "Attack"
Net.ClientLog = "ClientLog"
Net.GateMessage = "GateMessage"
Net.StateChanged = "StateChanged"
Net.SetGuildFaction = "SetGuildFaction"
Net.CompleteTutorial = "CompleteTutorial"
Net.UseTerminal = "UseTerminal"
Net.ClaimQuest = "ClaimQuest"
Net.CombatEvent = "CombatEvent"
Net.RequestDodge = "RequestDodge"
Net.AllocateStatPoint = "AllocateStatPoint"
Net.UseSkill = "UseSkill"
Net.EquipItem = "EquipItem"
Net.EnterGate = "EnterGate"
Net.ReserveGate = "ReserveGate"
Net.BuyGuildItem = "BuyGuildItem"
Net.SpawnGuildHelper = "SpawnGuildHelper"
Net.AdvanceStory = "AdvanceStory"

return Net
