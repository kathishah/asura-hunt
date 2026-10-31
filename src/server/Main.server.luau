--!strict
-- Server entry point. Wires the services together; keep game logic inside the services.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes) -- creates the RemoteEvents, so require it first

local Services = script.Parent.Services
local CombatService = require(Services.CombatService)
local DataService = require(Services.DataService)
local EnemyService = require(Services.EnemyService)
local ShopService = require(Services.ShopService)

local statsChanged = Remotes.get("StatsChanged")

-- Whenever a player's data loads or changes: tell their client and refresh their health stats.
DataService.onChanged(function(player, data)
	statsChanged:FireClient(player, data)
	CombatService.applyCharacterStats(player, data)
end)

-- Re-apply stats each time the character respawns.
local function watchCharacter(player: Player)
	player.CharacterAdded:Connect(function()
		local data = DataService.get(player)
		if data then
			CombatService.applyCharacterStats(player, data)
		end
	end)
end
Players.PlayerAdded:Connect(watchCharacter)
for _, player in Players:GetPlayers() do
	watchCharacter(player)
end

-- A client announces it is ready, so it can receive the current data it may have missed.
Remotes.get("ClientReady").OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if data then
		statsChanged:FireClient(player, data)
	end
end)

-- Never trust remote arguments: check their types before using them.
Remotes.get("ChoosePath").OnServerEvent:Connect(function(player, path)
	if typeof(path) == "string" then
		DataService.setPath(player, path)
	end
end)

Remotes.get("SpendStat").OnServerEvent:Connect(function(player, stat)
	if typeof(stat) == "string" then
		DataService.spendStatPoint(player, stat)
	end
end)

DataService.start()
EnemyService.start()
CombatService.start()
ShopService.start()
