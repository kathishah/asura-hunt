-- Checks that a built place file is complete enough to publish. It is the last gate before the
-- publish workflow uploads it, because an upload replaces the whole live place: a build that lost the
-- map, a script folder or the lighting settings must stop here, not reach players.
--
--   rojo build -o build/AsuraHunt.rbxl
--   lune run tools/check-place build/AsuraHunt.rbxl
--
-- Not part of the game: it must not live in `src/`.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

-- Zone1 has about 1100 parts. A lower count means the map was cut down or went missing.
local MIN_ZONE1_DESCENDANTS = 1000

local path = process.args[1]
if path == nil then
	print("Usage: lune run tools/check-place <path to a .rbxl file>")
	process.exit(1)
end

local place = roblox.deserializePlace(fs.readFile(path))
local problems: { string } = {}

local function expect(ok: boolean, message: string)
	if not ok then
		table.insert(problems, message)
	end
end

local function find(root: any, ...: string): any
	local node = root
	for _, name in { ... } do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local workspace = place:GetService("Workspace")
local zone = workspace:FindFirstChild("Zone1")
expect(zone ~= nil, "Workspace.Zone1 is missing")
if zone then
	expect(
		#zone:GetDescendants() >= MIN_ZONE1_DESCENDANTS,
		`Workspace.Zone1 has only {#zone:GetDescendants()} descendants (expected at least {MIN_ZONE1_DESCENDANTS})`
	)
end
expect(workspace:FindFirstChild("Baseplate") ~= nil, "Workspace.Baseplate is missing")
expect(workspace:FindFirstChild("SpawnLocation") ~= nil, "Workspace.SpawnLocation is missing")

-- The game's scripts, as Rojo maps them.
local serverScripts = place:GetService("ServerScriptService")
local starterPlayer = place:GetService("StarterPlayer")
local replicated = place:GetService("ReplicatedStorage")
expect(find(serverScripts, "Server", "Main") ~= nil, "ServerScriptService.Server.Main is missing")
expect(
	find(serverScripts, "Server", "Services", "CombatService") ~= nil,
	"ServerScriptService.Server.Services.CombatService is missing"
)
expect(
	find(starterPlayer, "StarterPlayerScripts", "Client", "Main") ~= nil,
	"StarterPlayerScripts.Client.Main is missing"
)
expect(
	find(starterPlayer, "StarterPlayerScripts", "Client", "UI", "PlayerHealth") ~= nil,
	"StarterPlayerScripts.Client.UI.PlayerHealth is missing"
)
expect(find(replicated, "Shared", "Remotes") ~= nil, "ReplicatedStorage.Shared.Remotes is missing")

-- Place settings the game was playtested with. A default build flips these back.
local lighting = place:GetService("Lighting")
expect(find(lighting, "Sky") ~= nil, "Lighting.Sky is missing")
expect(tostring(lighting.Technology) == "Enum.Technology.ShadowMap", "Lighting.Technology changed")
expect(workspace.StreamingEnabled == true, "Workspace.StreamingEnabled is off")
expect(
	tostring(workspace.SignalBehavior) == "Enum.SignalBehavior.Deferred",
	"Workspace.SignalBehavior is not Deferred"
)

if #problems > 0 then
	print(`{path} is NOT safe to publish:`)
	for _, problem in problems do
		print(`  - {problem}`)
	end
	process.exit(1)
end
print(`{path} looks complete: map, scripts and place settings are present.`)
