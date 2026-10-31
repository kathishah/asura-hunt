-- Checks that old saved records upgrade safely. No Play and no DataStore needed.
-- Paste into Studio's command bar (edit mode, Rojo connected) and press Run.
--
-- Expected output:
--   MIG v1 -> 2 7 55 Rishi 3 true true true      (old record keeps its values, gains empty new fields)
--   MIG v2 2 nil sword nil true nil               (junk items, non-string slots and bad zones dropped)
--   MIG bad 1 2 true                              (garbage input gives a fresh level 1 record)

local D = require(game.ServerScriptService.Server.Services.DataService)

local v1 = D.reconcile({
	version = 1,
	level = 7,
	xp = 120,
	gold = 55,
	statPoints = 2,
	path = "Rishi",
	stats = { strength = 3, vitality = 1 },
})
print(
	"MIG v1 ->",
	v1.version,
	v1.level,
	v1.gold,
	v1.path,
	v1.stats.strength,
	next(v1.inventory) == nil,
	next(v1.equipped) == nil,
	v1.unlockedZones.Zone1
)

local v2 = D.reconcile({
	version = 2,
	level = 3,
	inventory = { sword = 2, junk = -5, [1] = 9 },
	equipped = { weapon = "sword", armor = 7 },
	unlockedZones = { Zone1 = true, Zone2 = true, Bad = "yes" },
})
print(
	"MIG v2",
	v2.inventory.sword,
	v2.inventory.junk,
	v2.equipped.weapon,
	v2.equipped.armor,
	v2.unlockedZones.Zone2,
	v2.unlockedZones.Bad
)

local bad = D.reconcile("garbage")
print("MIG bad", bad.level, bad.version, bad.unlockedZones.Zone1)
