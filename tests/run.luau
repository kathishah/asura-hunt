-- Headless checks for logic that does not need Roblox: saved-data upgrades, the data-loading
-- safety rules, enemy config and enemy attack behaviours. Run with:  lune run tests/run
-- It runs the real files from src/ against the fake Roblox in harness.luau.
-- It does NOT replace a Studio playtest: nothing here draws, moves or collides.

local process = require("@lune/process")
local task = require("@lune/task")
local harness = require("./harness")

local passed, failed = 0, 0
local function check(name: string, condition: boolean, detail: any?)
	if condition then
		passed += 1
		print(`  ok    {name}`)
	else
		failed += 1
		print(`  FAIL  {name}{if detail ~= nil then ` ({detail})` else ""}`)
	end
end
local function section(title: string)
	print(`\n{title}`)
end

-- DataService.reconcile: the migration and sanitising ---------------------------------------
section("Saved data: reconcile")
do
	local world = harness.newWorld({
		services = {
			Players = {},
			DataStoreService = {
				GetDataStore = function()
					error("no store")
				end,
			},
		},
	})
	local DataService = world.load("server/Services/DataService")
	local GameConfig = world.load("shared/Config/GameConfig")

	local v1 = DataService.reconcile({
		version = 1,
		level = 7,
		xp = 120,
		gold = 55,
		statPoints = 2,
		path = "Rishi",
		stats = { strength = 3, vitality = 1 },
	})
	check("v1 record keeps its values", v1.level == 7 and v1.gold == 55 and v1.path == "Rishi")
	check("v1 record keeps its stats", v1.stats.strength == 3 and v1.stats.vitality == 1)
	check("v1 record is upgraded to the current version", v1.version == GameConfig.DATA_VERSION)
	check(
		"v1 record gets empty inventory and equipment",
		next(v1.inventory) == nil and next(v1.equipped) == nil
	)
	check("v1 record starts with the first zone unlocked", v1.unlockedZones[GameConfig.FIRST_ZONE])

	local v2 = DataService.reconcile({
		version = 2,
		level = 3,
		inventory = { sword = 2, junk = -5, huge = 99999, [1] = 9 },
		equipped = { weapon = "sword", armor = 7 },
		unlockedZones = { Zone1 = true, Zone2 = true, Bad = "yes" },
	})
	check("inventory keeps good counts", v2.inventory.sword == 2)
	check(
		"inventory drops negative counts and numeric keys",
		v2.inventory.junk == nil and v2.inventory[1] == nil
	)
	check("inventory caps huge counts", v2.inventory.huge == 999, v2.inventory.huge)
	check("equipped keeps string slots", v2.equipped.weapon == "sword")
	check("equipped drops non-string items", v2.equipped.armor == nil)
	check("unlocked zones keep real unlocks", v2.unlockedZones.Zone2 == true)
	check("unlocked zones drop non-true values", v2.unlockedZones.Bad == nil)

	local bad = DataService.reconcile("garbage")
	check("garbage input gives a fresh level 1 record", bad.level == 1 and bad.gold == 0)

	local clamped = DataService.reconcile({ level = 9999, gold = -50, xp = -1, statPoints = -3 })
	check("level is clamped to the maximum", clamped.level == GameConfig.MAX_LEVEL)
	check(
		"negative gold, xp and points are clamped to 0",
		clamped.gold == 0 and clamped.xp == 0 and clamped.statPoints == 0
	)

	local sloppy = DataService.reconcile({ path = "Pirate", stats = "no" })
	check("an unknown path falls back to Yodha", sloppy.path == "Yodha")
end

-- DataService loading and saving with a fake DataStore --------------------------------------
local function fakePlayer(name: string, userId: number)
	return { Name = name, UserId = userId, Parent = true }
end

local function runLoad(record: any, loadError: boolean?)
	local store = { saved = {}, updates = 0 }
	if record ~= nil then
		store.saved["Player_1"] = record
	end
	function store.GetAsync(_, key)
		if loadError then
			error("datastore is down")
		end
		return store.saved[key]
	end
	function store.UpdateAsync(_, key, transform)
		store.updates += 1
		store.saved[key] = transform(store.saved[key])
	end

	local player = fakePlayer("Tester", 1)
	local removing: { (any) -> () } = {}
	local players = {
		GetPlayers = function()
			return { player }
		end,
		PlayerAdded = { Connect = function() end },
		PlayerRemoving = {
			Connect = function(_, handler)
				table.insert(removing, handler)
			end,
		},
	}
	local world = harness.newWorld({
		services = {
			Players = players,
			DataStoreService = {
				GetDataStore = function()
					return store
				end,
			},
		},
	})
	local DataService = world.load("server/Services/DataService")
	DataService.start()
	task.wait(0.2)
	local data = DataService.get(player)
	for _, handler in removing do
		handler(player) -- the player leaves: this saves, unless loading failed
	end
	return data, store, world
end

section("Saved data: loading and saving")
do
	local data, store, world = runLoad({ version = 1, level = 4, gold = 20 })
	local GameConfig = world.load("shared/Config/GameConfig")
	check(
		"a v1 record loads and upgrades",
		data ~= nil and data.level == 4 and data.version == GameConfig.DATA_VERSION
	)
	check("a normal record is saved when the player leaves", store.updates == 1, store.updates)
	check(
		"the saved record is the current version",
		store.saved["Player_1"].version == GameConfig.DATA_VERSION
	)
	check("the saved record keeps the new fields", store.saved["Player_1"].unlockedZones ~= nil)

	local newer, newerStore = runLoad({ version = 99, level = 12, futureField = "keep me" })
	check("a record from a newer version still lets you play", newer ~= nil)
	check(
		"a record from a newer version is NOT overwritten",
		newerStore.updates == 0,
		newerStore.updates
	)
	check(
		"the newer record is left exactly as it was",
		newerStore.saved["Player_1"].futureField == "keep me"
	)

	local _, failedStore = runLoad(nil, true)
	check(
		"if loading fails, nothing is saved over the real record",
		failedStore.updates == 0,
		failedStore.updates
	)

	local fresh, freshStore = runLoad(nil)
	check("a new player starts with defaults", fresh ~= nil and fresh.level == 1)
	check("a new player is saved on leaving", freshStore.updates == 1)
end

-- Game config and enemy definitions ---------------------------------------------------------
section("Config")
do
	local world = harness.newWorld()
	local GameConfig = world.load("shared/Config/GameConfig")
	check("XP for level 1 is 50", GameConfig.xpToNextLevel(1) == 50)
	check("XP for level 4 is 400", GameConfig.xpToNextLevel(4) == 400)
	check(
		"XP for level 10 is 1581",
		GameConfig.xpToNextLevel(10) == 1581,
		GameConfig.xpToNextLevel(10)
	)

	local Enemies = world.load("shared/Config/Enemies")
	local count = 0
	for key, def in Enemies do
		count += 1
		check(`{key}: id matches its key`, def.id == key)
		check(
			`{key}: has names`,
			type(def.displayName) == "string" and type(def.folkloreName) == "string"
		)
		check(
			`{key}: numbers are positive`,
			def.maxHealth > 0
				and def.damage > 0
				and def.walkSpeed > 0
				and def.attackRange > 0
				and def.attackCooldown > 0
		)
		if def.projectile then
			check(
				`{key}: projectile has speed, size and hit radius`,
				def.projectile.speed > 0
					and def.projectile.size > 0
					and def.projectile.hitRadius > 0
			)
		end
	end
	check("all six enemies are defined", count == 6, count)
	local names = {}
	local unique = true
	for _, def in Enemies do
		if names[def.displayName] then
			unique = false
		end
		names[def.displayName] = true
	end
	check("display names are unique", unique)
end

-- Enemy attack behaviours --------------------------------------------------------------------
section("Enemy behaviours")
do
	local world = harness.newWorld()
	local Enemies = world.load("shared/Config/Enemies")
	local EnemyBehaviors = world.load("server/Services/EnemyBehaviors")

	local function target(invulnerable: boolean)
		local taken = {}
		local humanoid = {
			Health = 100,
			TakeDamage = function(_, amount)
				table.insert(taken, amount)
			end,
		}
		local player = {
			GetAttribute = function(_, name)
				return if name == "Invulnerable" then invulnerable else nil
			end,
		}
		return { player = player, humanoid = humanoid, root = {} }, taken
	end

	local melee = EnemyBehaviors.forDef(Enemies.Pishacha)
	local projectile = EnemyBehaviors.forDef(Enemies.Daayan)
	check("melee enemies use the melee behaviour", melee ~= projectile)
	check(
		"every enemy resolves to a behaviour",
		(function()
			for _, def in Enemies do
				if type(EnemyBehaviors.forDef(def)) ~= "function" then
					return false
				end
			end
			return true
		end)()
	)
	check(
		"an enemy with a projectile uses the projectile behaviour",
		EnemyBehaviors.forDef(Enemies.Daayan) == projectile
	)

	local hit, taken = target(false)
	melee({ def = Enemies.Pishacha, root = {} }, hit, {})
	check("melee deals the enemy's damage", taken[1] == Enemies.Pishacha.damage, taken[1])

	local dodging, dodgeTaken = target(true)
	melee({ def = Enemies.Pishacha, root = {} }, dodging, {})
	check("melee does nothing while the player is dodging", #dodgeTaken == 0)

	local custom = table.clone(Enemies.Pishacha)
	custom.behavior = "does-not-exist"
	check("an unknown behaviour name falls back to melee", EnemyBehaviors.forDef(custom) == melee)
	custom.behavior = "projectile"
	check("an explicit behaviour name is respected", EnemyBehaviors.forDef(custom) == projectile)
end

-- M4: items, equipment rules and the shop ----------------------------------------------------
section("Items and equipment")
do
	local world = harness.newWorld()
	local Items = world.load("shared/Config/Items")
	local count = 0
	for key, item in Items do
		count += 1
		check(`{key}: id matches its key and it has a price`, item.id == key and item.price > 0)
		if item.slot == "weapon" then
			check(`{key}: a weapon raises damage`, (item.damageMultiplier or 0) > 1)
		else
			check(`{key}: armour adds health`, item.slot == "armor" and (item.healthBonus or 0) > 0)
		end
	end
	check("the shop has items", count >= 4, count)

	local Equipment = world.load("shared/Equipment")
	local function dataWith(fields: any)
		local data = { gold = 0, path = "Yodha", inventory = {}, equipped = {} }
		for key, value in fields do
			data[key] = value
		end
		return data
	end

	check(
		"buying checks the item exists",
		select(2, Equipment.checkBuy(dataWith({ gold = 999 }), "Nope")) == "unknown item"
	)
	check(
		"buying needs enough gold",
		select(2, Equipment.checkBuy(dataWith({ gold = 5 }), "IronSword")) == "not enough gold"
	)
	check("buying works with enough gold", Equipment.checkBuy(dataWith({ gold = 40 }), "IronSword"))
	check(
		"you cannot buy something twice",
		select(
			2,
			Equipment.checkBuy(dataWith({ gold = 999, inventory = { IronSword = 1 } }), "IronSword")
		) == "already owned"
	)
	check(
		"you cannot equip what you do not own",
		select(2, Equipment.checkEquip(dataWith({}), "IronSword")) == "not owned"
	)
	check(
		"you cannot equip a weapon for the wrong path",
		select(
			2,
			Equipment.checkEquip(
				dataWith({ path = "Rishi", inventory = { IronSword = 1 } }),
				"IronSword"
			)
		) == "wrong path"
	)

	local armed = dataWith({ inventory = { IronSword = 1 }, equipped = { weapon = "IronSword" } })
	check("an equipped weapon raises damage", Equipment.damageMultiplier(armed) == 1.15)
	armed.path = "Rishi"
	check("a weapon for another path does nothing", Equipment.damageMultiplier(armed) == 1)
	check(
		"an equipped item you no longer own does nothing",
		Equipment.damageMultiplier(dataWith({ equipped = { weapon = "IronSword" } })) == 1
	)
	check(
		"an item in the wrong slot does nothing",
		Equipment.healthBonus(
			dataWith({ inventory = { IronSword = 1 }, equipped = { armor = "IronSword" } })
		) == 0
	)
	check(
		"armour adds health",
		Equipment.healthBonus(
			dataWith({ inventory = { LeatherVest = 1 }, equipped = { armor = "LeatherVest" } })
		) == 30
	)
end

section("Shop service")
do
	-- Starts the real DataService and ShopService against a fake DataStore with one player.
	local function startShop(record: any)
		local store = { saved = { Player_1 = record } }
		function store.GetAsync(_, key)
			return store.saved[key]
		end
		function store.UpdateAsync(_, key, transform)
			store.saved[key] = transform(store.saved[key])
		end
		local player = { Name = "Shopper", UserId = 1, Parent = true }
		local world = harness.newWorld({
			services = {
				Players = {
					GetPlayers = function()
						return { player }
					end,
					PlayerAdded = { Connect = function() end },
					PlayerRemoving = { Connect = function() end },
				},
				DataStoreService = {
					GetDataStore = function()
						return store
					end,
				},
			},
		})
		local DataService = world.load("server/Services/DataService")
		local ShopService = world.load("server/Services/ShopService")
		local Remotes = world.load("shared/Remotes")
		DataService.start()
		ShopService.start()
		task.wait(0.2)
		return {
			player = player,
			data = DataService.get(player),
			shop = ShopService,
			remote = function(name: string)
				return Remotes.get(name)
			end,
		}
	end

	local game1 = startShop({ version = 2, level = 1, gold = 100 })
	local data = game1.data
	check("the shopper has 100 gold to start", data.gold == 100)

	local ok = game1.shop.buy(game1.player, "IronSword")
	check("buying an item works", ok and data.inventory.IronSword == 1)
	check("buying takes the gold", data.gold == 60, data.gold)

	local again, reason = game1.shop.buy(game1.player, "IronSword")
	check("buying twice is refused", not again and reason == "already owned")
	check("a refused purchase takes no gold", data.gold == 60)

	local poor, poorReason = game1.shop.buy(game1.player, "SteelSword")
	check("buying without enough gold is refused", not poor and poorReason == "not enough gold")
	check("a refused purchase keeps the gold", data.gold == 60)

	local unknown = game1.shop.buy(game1.player, "FreeMoney")
	check("buying an unknown item is refused", not unknown)

	local equipped = game1.shop.equip(game1.player, "IronSword")
	check("equipping an owned weapon works", equipped and data.equipped.weapon == "IronSword")
	check(
		"equipping something you do not own is refused",
		not game1.shop.equip(game1.player, "SteelSword")
	)

	local dropped = game1.shop.unequip(game1.player, "weapon")
	check("unequipping works", dropped and data.equipped.weapon == nil)
	check("unequipping an empty slot is refused", not game1.shop.unequip(game1.player, "weapon"))
	check("unequipping an unknown slot is refused", not game1.shop.unequip(game1.player, "helmet"))

	-- The remote handlers must survive anything a client sends.
	local before = data.gold
	for _, junk in { 123, true, {}, "", "x" } do
		game1.remote("BuyItem").__fireServer(game1.player, junk)
		game1.remote("EquipItem").__fireServer(game1.player, junk)
		game1.remote("UnequipSlot").__fireServer(game1.player, junk)
	end
	game1.remote("BuyItem").__fireServer(game1.player)
	check(
		"junk remote arguments change nothing",
		data.gold == before and data.equipped.weapon == nil
	)

	game1.remote("BuyItem").__fireServer(game1.player, "LeatherVest")
	check(
		"a valid remote purchase works",
		data.inventory.LeatherVest == 1 and data.gold == before - 50
	)
	game1.remote("EquipItem").__fireServer(game1.player, "LeatherVest")
	check("a valid remote equip works", data.equipped.armor == "LeatherVest")
	game1.remote("UnequipSlot").__fireServer(game1.player, "armor")
	check("a valid remote unequip works", data.equipped.armor == nil)
end

print(`\n{passed} passed, {failed} failed`)
process.exit(if failed == 0 then 0 else 1)
