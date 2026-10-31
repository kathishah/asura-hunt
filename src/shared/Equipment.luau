--!strict
-- The rules for items: who can buy and equip what, and what equipped items do. Pure functions of
-- the player's data and Config/Items, so the server and the shop screen agree, and tests can
-- check them without Roblox. The server (ShopService) is the one that actually changes data.

local Items = require(script.Parent.Config.Items)
local Types = require(script.Parent.Types)

local Equipment = {}

function Equipment.usableOnPath(item: Types.ItemDef, path: Types.PathId): boolean
	local allowed = item.paths
	if not allowed then
		return true
	end
	for _, candidate in allowed do
		if candidate == path then
			return true
		end
	end
	return false
end

local function owns(data: Types.PlayerData, itemId: string): boolean
	return (data.inventory[itemId] or 0) >= 1
end

-- The item in a slot, only if it is a real item, belongs in that slot and is still owned.
function Equipment.equippedItem(data: Types.PlayerData, slot: Types.ItemSlot): Types.ItemDef?
	local itemId = data.equipped[slot]
	local item = if itemId then Items[itemId] else nil
	if item and item.slot == slot and owns(data, item.id) then
		return item
	end
	return nil
end

-- Multiplier on all damage you deal. A weapon that does not suit your current path does nothing.
function Equipment.damageMultiplier(data: Types.PlayerData): number
	local weapon = Equipment.equippedItem(data, "weapon")
	if weapon and Equipment.usableOnPath(weapon, data.path) then
		return weapon.damageMultiplier or 1
	end
	return 1
end

-- Extra max health from armour.
function Equipment.healthBonus(data: Types.PlayerData): number
	local armor = Equipment.equippedItem(data, "armor")
	return if armor then armor.healthBonus or 0 else 0
end

-- Each check answers (allowed, reason when not allowed).
function Equipment.checkBuy(data: Types.PlayerData, itemId: string): (boolean, string?)
	local item = Items[itemId]
	if not item then
		return false, "unknown item"
	end
	if owns(data, itemId) then
		return false, "already owned"
	end
	if data.gold < item.price then
		return false, "not enough gold"
	end
	return true, nil
end

function Equipment.checkEquip(data: Types.PlayerData, itemId: string): (boolean, string?)
	local item = Items[itemId]
	if not item then
		return false, "unknown item"
	end
	if not owns(data, itemId) then
		return false, "not owned"
	end
	if not Equipment.usableOnPath(item, data.path) then
		return false, "wrong path"
	end
	return true, nil
end

function Equipment.isSlot(slot: any): boolean
	return slot == "weapon" or slot == "armor"
end

return Equipment
