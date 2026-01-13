-- ServerScriptService/Services/InventoryService.lua
local InventoryService = {}
InventoryService.__index = InventoryService

local inv = {} -- [player] = { items = {string,...} }

function InventoryService:Get(player)
	local p = inv[player]
	if not p then
		p = { items = {} }
		inv[player] = p
	end
	return p
end

function InventoryService:AddItem(player, itemId)
	local p = self:Get(player)
	table.insert(p.items, itemId)
	return p
end

function InventoryService:List(player)
	return self:Get(player).items
end

function InventoryService:Clear(player)
	inv[player] = nil
end

return InventoryService
