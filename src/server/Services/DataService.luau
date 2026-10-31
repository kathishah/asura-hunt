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

local store = DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)

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
	}
end

-- Fills in anything missing and clamps values so old or odd records never break the game.
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

	return data
end

local function notify(player: Player)
	local data = sessions[player]
	if not data then
		return
	end
	for _, listener in listeners do
		listener(player, data)
	end
end

local function loadPlayer(player: Player)
	local success = false
	local result: any = nil

	for attempt = 1, MAX_ATTEMPTS do
		success, result = pcall(function()
			return store:GetAsync(keyFor(player))
		end)
		if success then
			break
		end
		warn(`[DataService] Load attempt {attempt} failed for {player.Name}: {result}`)
		task.wait(attempt * 2)
	end

	if not player.Parent then
		return -- left while we were loading
	end

	if success then
		sessions[player] = reconcile(result)
	else
		loadFailed[player] = true
		sessions[player] = defaultData()
		warn(`[DataService] Could not load data for {player.Name}. Progress will not be saved.`)
	end

	notify(player)
end

local function savePlayer(player: Player)
	local data = sessions[player]
	if not data or loadFailed[player] then
		return
	end

	for attempt = 1, MAX_ATTEMPTS do
		local success, err = pcall(function()
			store:UpdateAsync(keyFor(player), function()
				return data
			end)
		end)
		if success then
			return
		end
		warn(`[DataService] Save attempt {attempt} failed for {player.Name}: {err}`)
		task.wait(attempt * 2)
	end
end

function DataService.get(player: Player): Types.PlayerData?
	return sessions[player]
end

-- Called whenever a player's data is loaded or changes.
function DataService.onChanged(listener: (Player, Types.PlayerData) -> ())
	table.insert(listeners, listener)
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
		savePlayer(player)
		sessions[player] = nil
		loadFailed[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.AUTOSAVE_SECONDS)
			for _, player in Players:GetPlayers() do
				task.spawn(savePlayer, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				savePlayer(player)
				pending -= 1
			end)
		end
		while pending > 0 do
			task.wait()
		end
	end)
end

return DataService
