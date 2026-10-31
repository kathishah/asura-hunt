-- Saved data: upgrades, sanitising, loading and saving.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness, task = t.check, t.section, t.harness, t.task

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
		check(
			"v1 record starts with the first zone unlocked",
			v1.unlockedZones[GameConfig.FIRST_ZONE]
		)

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

		local clamped =
			DataService.reconcile({ level = 9999, gold = -50, xp = -1, statPoints = -3 })
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
end
