--!strict
-- Things you can buy and equip. Everything is data: add an item here and it appears in the shop.
-- Weapons raise the damage you deal; armour raises your max health. Prices are in gold (a Hungry
-- Ghoul drops 5, a Tusked Brute 30, the Rage King 400), so tune them while you play.

local Types = require(script.Parent.Parent.Types)

local Items: { [string]: Types.ItemDef } = {
	IronSword = {
		id = "IronSword",
		displayName = "Iron Sword",
		description = "A plain, sturdy blade.",
		slot = "weapon",
		price = 40,
		damageMultiplier = 1.15,
		paths = { "Yodha" },
	},
	SteelSword = {
		id = "SteelSword",
		displayName = "Steel Sword",
		description = "Sharper, lighter, and much more expensive.",
		slot = "weapon",
		price = 150,
		damageMultiplier = 1.4,
		paths = { "Yodha" },
	},
	AshStaff = {
		id = "AshStaff",
		displayName = "Ash Staff",
		description = "A smooth staff to focus your mantras.",
		slot = "weapon",
		price = 40,
		damageMultiplier = 1.15,
		paths = { "Rishi" },
	},
	SilverStaff = {
		id = "SilverStaff",
		displayName = "Silver Staff",
		description = "Strengthens every mantra you speak.",
		slot = "weapon",
		price = 150,
		damageMultiplier = 1.4,
		paths = { "Rishi" },
	},
	LeatherVest = {
		id = "LeatherVest",
		displayName = "Leather Vest",
		description = "Light armour that takes the edge off a hit.",
		slot = "armor",
		price = 50,
		healthBonus = 30,
	},
	BronzeMail = {
		id = "BronzeMail",
		displayName = "Bronze Mail",
		description = "Heavy armour for the long fights.",
		slot = "armor",
		price = 160,
		healthBonus = 80,
	},
}

return Items
