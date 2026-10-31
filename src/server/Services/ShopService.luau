--!strict
-- Buying, equipping and unequipping items. The client only asks; every rule is checked here, using
-- the shared rules in Equipment, and gold and items only ever change on the server.
-- For now the shop works from anywhere. Later it can require standing near a shopkeeper.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Equipment = require(Shared.Equipment)
local Items = require(Shared.Config.Items)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local ShopService = {}

-- Returns whether it worked, and why not if it did not.
function ShopService.buy(player: Player, itemId: string): (boolean, string?)
	local reason: string? = "no data"
	local changed = DataService.update(player, function(data)
		local allowed, why = Equipment.checkBuy(data, itemId)
		if not allowed then
			reason = why
			return false
		end
		data.gold -= Items[itemId].price
		data.inventory[itemId] = 1
		return true
	end)
	return changed, if changed then nil else reason
end

function ShopService.equip(player: Player, itemId: string): (boolean, string?)
	local reason: string? = "no data"
	local changed = DataService.update(player, function(data)
		local allowed, why = Equipment.checkEquip(data, itemId)
		if not allowed then
			reason = why
			return false
		end
		data.equipped[Items[itemId].slot] = itemId
		return true
	end)
	return changed, if changed then nil else reason
end

function ShopService.unequip(player: Player, slot: string): (boolean, string?)
	if not Equipment.isSlot(slot) then
		return false, "unknown slot"
	end
	local changed = DataService.update(player, function(data)
		if data.equipped[slot] == nil then
			return false
		end
		data.equipped[slot] = nil
		return true
	end)
	return changed, if changed then nil else "nothing equipped"
end

function ShopService.start()
	-- Never trust remote arguments: check their types before using them.
	Remotes.get("BuyItem").OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) == "string" then
			ShopService.buy(player, itemId)
		end
	end)
	Remotes.get("EquipItem").OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) == "string" then
			ShopService.equip(player, itemId)
		end
	end)
	Remotes.get("UnequipSlot").OnServerEvent:Connect(function(player, slot)
		if typeof(slot) == "string" then
			ShopService.unequip(player, slot)
		end
	end)
end

return ShopService
