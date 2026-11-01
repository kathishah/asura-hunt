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

	-- `opts.beforeLeave(store)` runs after loading, to change what is stored (as another server
	-- would). `opts.leaves` fires the leave handler that many times at once, and `opts.storeDelay`
	-- makes each store call take that long, so saves overlap. `opts.config` overrides GameConfig
	-- values (such as short retry waits) and `opts.setup(store)` runs just before the service starts.
	local function runLoad(record: any, loadError: boolean?, opts: any?)
		local store = { saved = {}, updates = 0, writes = 0, active = 0, maxActive = 0 }
		if record ~= nil then
			store.saved["Player_1"] = record
		end
		function store.UpdateAsync(_, key, transform)
			store.updates += 1
			if loadError then
				error("datastore is down")
			end
			store.active += 1
			store.maxActive = math.max(store.maxActive, store.active)
			if opts and opts.storeDelay then
				task.wait(opts.storeDelay)
			end
			local result = transform(store.saved[key])
			-- Like Roblox, returning nil cancels the update and leaves the record alone.
			if result ~= nil then
				store.writes += 1
				store.saved[key] = result
			end
			store.active -= 1
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
		local GameConfig = world.load("shared/Config/GameConfig")
		for key, value in (opts and opts.config) or {} do
			GameConfig[key] = value
		end
		if opts and opts.setup then
			opts.setup(store)
		end
		local DataService = world.load("server/Services/DataService")
		DataService.start()
		task.wait(0.2)
		local data = DataService.get(player)
		if opts and opts.beforeLeave then
			opts.beforeLeave(store)
		end
		for _, handler in removing do
			-- the player leaves: this saves, unless loading failed
			for _ = 1, (opts and opts.leaves) or 1 do
				if opts and opts.leaves then
					task.spawn(handler, player)
				else
					handler(player)
				end
			end
		end
		if opts and opts.leaves then
			task.wait(0.6)
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
		check(
			"a normal record is claimed on load and saved on leaving",
			store.writes == 2,
			store.writes
		)
		check("leaving gives up the claim", store.saved["Player_1"].session == nil)
		check(
			"the saved record is the current version",
			store.saved["Player_1"].version == GameConfig.DATA_VERSION
		)
		check("the saved record keeps the new fields", store.saved["Player_1"].unlockedZones ~= nil)

		local newer, newerStore = runLoad({ version = 99, level = 12, futureField = "keep me" })
		check("a record from a newer version still lets you play", newer ~= nil)
		check(
			"a record from a newer version is NOT overwritten",
			newerStore.writes == 0,
			newerStore.writes
		)
		check(
			"the newer record is left exactly as it was",
			newerStore.saved["Player_1"].futureField == "keep me"
		)

		local _, failedStore = runLoad(nil, true)
		check(
			"if loading fails, nothing is saved over the real record",
			failedStore.writes == 0,
			failedStore.writes
		)

		-- Another server saved newer data after we loaded: our save must not overwrite it.
		local _, racedStore = runLoad({ version = 2, level = 4 }, false, {
			beforeLeave = function(store)
				store.saved["Player_1"] = { version = 99, level = 30 }
			end,
		})
		check(
			"a save never overwrites data from a newer build",
			racedStore.writes == 1, -- only the claim at load
			racedStore.writes
		)
		check("the newer record is still there", racedStore.saved["Player_1"].level == 30)

		-- An autosave and the exit save fire together: they take turns instead of overlapping.
		local _, busyStore = runLoad(
			{ version = 2, level = 4 },
			false,
			{ leaves = 2, storeDelay = 0.1 }
		)
		check("two saves at once never overlap", busyStore.maxActive == 1, busyStore.maxActive)
		check(
			"the second save sees the player is gone",
			busyStore.writes == 2, -- the claim at load, then one exit save
			busyStore.writes
		)

		local fresh, freshStore = runLoad(nil)
		check("a new player starts with defaults", fresh ~= nil and fresh.level == 1)
		check("a new player is saved on leaving", freshStore.writes == 2, freshStore.writes)

		-- The session lock: one server at a time owns a player's record.
		local fastRetries = { LOCK_RETRY_SECONDS = 0.01, LOCK_RETRIES = 2 }
		local now = os.time()

		local heldWhileIn = false
		runLoad({ version = 3, level = 4 }, false, {
			beforeLeave = function(store)
				local lock = store.saved["Player_1"].session
				heldWhileIn = type(lock) == "table" and type(lock.jobId) == "string"
			end,
		})
		check("the record is claimed while the player is in the game", heldWhileIn)

		local locked, lockedStore = runLoad(
			{ version = 3, level = 9, session = { jobId = "other-server", at = now } },
			false,
			{ config = fastRetries }
		)
		check("a record held by another server is not loaded", locked ~= nil and locked.level == 1)
		check(
			"the other server's claim is waited on, then given up",
			lockedStore.updates == 3,
			lockedStore.updates
		)
		check(
			"a record held by another server is never written",
			lockedStore.writes == 0 and lockedStore.saved["Player_1"].level == 9,
			lockedStore.writes
		)

		local stale = runLoad(
			{ version = 3, level = 9, session = { jobId = "crashed", at = now - 100000 } },
			false,
			{ config = fastRetries }
		)
		check("a claim from a crashed server is taken over", stale ~= nil and stale.level == 9)

		local released = runLoad(
			{ version = 3, level = 9, session = { jobId = "leaving", at = now } },
			false,
			{
				config = { LOCK_RETRY_SECONDS = 0.05, LOCK_RETRIES = 5 },
				setup = function(store)
					task.delay(0.08, function()
						store.saved["Player_1"].session = nil -- the other server finished saving
					end)
				end,
			}
		)
		check(
			"a quick rejoin waits for the other server to let go",
			released ~= nil and released.level == 9
		)

		local _, takenStore = runLoad({ version = 3, level = 4 }, false, {
			beforeLeave = function(store)
				store.saved["Player_1"].session = { jobId = "other-server", at = os.time() }
				store.saved["Player_1"].level = 20
			end,
		})
		check(
			"a save is refused once another server has claimed the record",
			takenStore.writes == 1 and takenStore.saved["Player_1"].level == 20,
			takenStore.writes
		)
	end
end
