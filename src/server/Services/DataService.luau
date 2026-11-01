--!strict
-- Loads, caches and saves player data. The in-memory copy is the source of truth during a session.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Types = require(Shared.Types)

local DEFAULT_PATH: Types.PathId = "Yodha"
local MAX_ATTEMPTS = 3
local MAX_ITEM_COUNT = 999

-- GetDataStore throws in an unpublished place, so guard it: the game must still run, just unsaved.
local storeOk, storeResult = pcall(function()
	return DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)
end)
local store: DataStore? = if storeOk then storeResult else nil
if not store then
	warn(`[DataService] DataStore unavailable (publish the place to enable saving): {storeResult}`)
end

-- Identifies this server in a record's session lock. JobId is empty in Studio, so make one up.
local serverId = if type(game.JobId) == "string" and game.JobId ~= ""
	then game.JobId
	else `studio-{os.time()}-{math.random(1, 1000000000)}`

local sessions: { [Player]: Types.PlayerData } = {}
-- If loading failed we play with temporary data and must NOT save it over the real record.
local loadFailed: { [Player]: boolean } = {}
local listeners: { (Player, Types.PlayerData) -> () } = {}

local DataService = {}

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

local function defaultData(): Types.PlayerData
	return {
		version = GameConfig.DATA_VERSION,
		level = 1,
		xp = 0,
		gold = 0,
		statPoints = 0,
		path = DEFAULT_PATH,
		stats = { strength = 0, vitality = 0 },
		inventory = {},
		equipped = {},
		unlockedZones = { [GameConfig.FIRST_ZONE] = true },
	}
end

-- Fills in anything missing and clamps values so old or odd records never break the game.
-- This is also the migration: a version 1 record has no inventory, equipped or unlockedZones, so
-- those start at their defaults and the record is saved as the current version.
local function reconcile(saved: any): Types.PlayerData
	local data = defaultData()
	if type(saved) ~= "table" then
		return data
	end

	data.level = math.clamp(math.floor(tonumber(saved.level) or 1), 1, GameConfig.MAX_LEVEL)
	data.xp = math.max(0, tonumber(saved.xp) or 0)
	data.gold = math.max(0, tonumber(saved.gold) or 0)
	data.statPoints = math.max(0, math.floor(tonumber(saved.statPoints) or 0))

	if saved.path == "Yodha" then
		data.path = "Yodha"
	elseif saved.path == "Rishi" then
		data.path = "Rishi"
	end

	if type(saved.stats) == "table" then
		data.stats.strength = math.max(0, math.floor(tonumber(saved.stats.strength) or 0))
		data.stats.vitality = math.max(0, math.floor(tonumber(saved.stats.vitality) or 0))
	end

	if type(saved.inventory) == "table" then
		for itemId, count in saved.inventory do
			local amount = math.clamp(math.floor(tonumber(count) or 0), 0, MAX_ITEM_COUNT)
			if type(itemId) == "string" and amount > 0 then
				data.inventory[itemId] = amount
			end
		end
	end

	if type(saved.equipped) == "table" then
		for slot, itemId in saved.equipped do
			if type(slot) == "string" and type(itemId) == "string" then
				data.equipped[slot] = itemId
			end
		end
	end

	if type(saved.unlockedZones) == "table" then
		for zoneId, unlocked in saved.unlockedZones do
			if type(zoneId) == "string" and unlocked == true then
				data.unlockedZones[zoneId] = true
			end
		end
	end

	return data
end

-- Exposed so a saved record can be checked from the Studio command bar without a DataStore.
DataService.reconcile = reconcile

local function notify(player: Player)
	local data = sessions[player]
	if not data then
		return
	end
	for _, listener in listeners do
		listener(player, data)
	end
end

-- One save at a time per player, so an autosave and the exit save cannot race each other.
local saving: { [Player]: boolean } = {}

-- `skipIfBusy` is for autosave: if a save is already running, the next autosave will cover it.
-- `release` gives up this server's claim on the record, for when the player is leaving.
local function savePlayer(player: Player, skipIfBusy: boolean?, release: boolean?)
	if saving[player] then
		if skipIfBusy then
			return
		end
		while saving[player] do
			task.wait(0.1)
		end
	end

	local data = sessions[player]
	local dataStore = store
	if not data or not dataStore or loadFailed[player] then
		return
	end

	saving[player] = true
	for attempt = 1, MAX_ATTEMPTS do
		local refusal: string? = nil
		local success, err = pcall(function()
			dataStore:UpdateAsync(keyFor(player), function(stored: any)
				if type(stored) == "table" then
					-- Another server running newer code has saved since we loaded: never overwrite it.
					local storedVersion = tonumber(stored.version)
					if storedVersion and storedVersion > GameConfig.DATA_VERSION then
						refusal = "newer"
						return nil -- cancels the update
					end
					-- Another server has claimed the record, so it owns the player now.
					local lock = stored.session
					if type(lock) == "table" and lock.jobId ~= serverId then
						refusal = "claimed by another server"
						return nil
					end
				end
				local record = table.clone(data)
				record.session = if release then nil else { jobId = serverId, at = os.time() }
				return record
			end)
		end)
		if success then
			if refusal then
				loadFailed[player] = true -- stop saving for the rest of the session
				warn(`[DataService] Not saving {player.Name}: the stored data is {refusal}.`)
			end
			break
		end
		warn(`[DataService] Save attempt {attempt} failed for {player.Name}: {err}`)
		task.wait(attempt * 2)
	end
	saving[player] = nil
end

-- Tries to claim a player's stored record for this server in one atomic update. Returns how it
-- went and the record: "claimed" (ours now), "locked" (another server holds it), "newer" (saved by
-- newer code, so left alone), or "error" if the store failed.
local function claimRecord(dataStore: DataStore, player: Player): (string, any)
	local outcome = "error"
	local record: any = nil
	local success, err = pcall(function()
		dataStore:UpdateAsync(keyFor(player), function(stored: any)
			if type(stored) ~= "table" then
				outcome = "claimed"
				record = nil
				return {
					version = GameConfig.DATA_VERSION,
					session = { jobId = serverId, at = os.time() },
				}
			end
			local storedVersion = tonumber(stored.version)
			if storedVersion and storedVersion > GameConfig.DATA_VERSION then
				outcome = "newer"
				record = stored
				return nil
			end
			local lock = stored.session
			if
				type(lock) == "table"
				and lock.jobId ~= serverId
				and os.time() - (tonumber(lock.at) or 0) < GameConfig.SESSION_LOCK_SECONDS
			then
				outcome = "locked"
				return nil
			end
			stored.session = { jobId = serverId, at = os.time() }
			outcome = "claimed"
			record = stored
			return stored
		end)
	end)
	if not success then
		return "error", err
	end
	return outcome, record
end

local function loadPlayer(player: Player)
	local outcome = "error"
	local result: any = nil
	local dataStore = store
	-- No store means retrying cannot help, so skip straight to the load-failed path.
	local errors = if dataStore then 0 else MAX_ATTEMPTS
	local lockWaits = 0

	while dataStore and errors < MAX_ATTEMPTS do
		outcome, result = claimRecord(dataStore, player)
		if outcome == "error" then
			errors += 1
			warn(`[DataService] Load attempt {errors} failed for {player.Name}: {result}`)
			task.wait(errors * 2)
		elseif outcome == "locked" and lockWaits < GameConfig.LOCK_RETRIES then
			-- The server they just left is probably still saving; give it a moment to let go.
			lockWaits += 1
			task.wait(GameConfig.LOCK_RETRY_SECONDS)
		else
			break
		end
	end

	if outcome == "claimed" then
		sessions[player] = reconcile(result)
		if not player.Parent then
			-- Left while we were loading: write the record back to give up the claim.
			savePlayer(player, false, true)
			sessions[player] = nil
			return
		end
	else
		if not player.Parent then
			return
		end
		loadFailed[player] = true
		sessions[player] = defaultData()
		if outcome == "newer" then
			warn(
				`[DataService] {player.Name}'s data was saved by newer code than this build `
					.. `({GameConfig.DATA_VERSION}). Progress will not be saved.`
			)
		elseif outcome == "locked" then
			warn(
				`[DataService] {player.Name}'s data is in use on another server. `
					.. "Progress will not be saved."
			)
		else
			warn(`[DataService] Could not load data for {player.Name}. Progress will not be saved.`)
		end
	end

	notify(player)
end

function DataService.get(player: Player): Types.PlayerData?
	return sessions[player]
end

-- Called whenever a player's data is loaded or changes.
function DataService.onChanged(listener: (Player, Types.PlayerData) -> ())
	table.insert(listeners, listener)
end

-- Runs `change` on the player's data. If it returns true the change is kept and the client and
-- listeners are told; return false (after checking, before changing anything) to refuse.
function DataService.update(player: Player, change: (Types.PlayerData) -> boolean): boolean
	local data = sessions[player]
	if not data then
		return false
	end
	if change(data) then
		notify(player)
		return true
	end
	return false
end

function DataService.addRewards(player: Player, xp: number, gold: number)
	local data = sessions[player]
	if not data then
		return
	end

	data.gold += gold
	data.xp += xp

	while data.level < GameConfig.MAX_LEVEL and data.xp >= GameConfig.xpToNextLevel(data.level) do
		data.xp -= GameConfig.xpToNextLevel(data.level)
		data.level += 1
		data.statPoints += GameConfig.STAT_POINTS_PER_LEVEL
	end

	notify(player)
end

function DataService.spendStatPoint(player: Player, stat: string): boolean
	local data = sessions[player]
	if not data or data.statPoints < 1 then
		return false
	end

	if stat == "strength" then
		data.stats.strength += 1
	elseif stat == "vitality" then
		data.stats.vitality += 1
	else
		return false
	end

	data.statPoints -= 1
	notify(player)
	return true
end

function DataService.setPath(player: Player, path: string): boolean
	local data = sessions[player]
	if not data then
		return false
	end

	if path == "Yodha" then
		data.path = "Yodha"
	elseif path == "Rishi" then
		data.path = "Rishi"
	else
		return false
	end

	notify(player)
	return true
end

function DataService.start()
	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		savePlayer(player, false, true)
		sessions[player] = nil
		loadFailed[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.AUTOSAVE_SECONDS)
			for _, player in Players:GetPlayers() do
				task.spawn(savePlayer, player, true)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				savePlayer(player, false, true)
				pending -= 1
			end)
		end
		while pending > 0 do
			task.wait()
		end
	end)
end

return DataService
