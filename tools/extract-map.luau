-- Copies the map out of a Studio place file into `map/`, so the map lives in git.
--
-- How to use:
--   1. In Studio choose File > Download a Copy and save the .rbxl somewhere (Downloads is fine).
--   2. In this folder run:  lune run tools/extract-map ~/Downloads/YourPlace.rbxl
--   3. Check `git status`, then commit the changed files in `map/`.
--
-- Rojo can only load one top-level instance per model file, so each map piece gets its own file.
-- `default.project.json` maps the files in `map/` into Workspace. Once they are mapped, Rojo puts
-- them into Studio whenever you connect, so a hand edit in Studio is lost unless you run this again
-- and commit the result.
-- Not part of the game: it must not live in `src/`.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

-- Children of Workspace to keep. Add a name here when you add another map piece.
local MAP_PIECES = { "Zone1", "Baseplate", "SpawnLocation" }
local OUTPUT_FOLDER = "map"

local placePath = process.args[1]
if placePath == nil then
	print("Usage: lune run tools/extract-map <path to a .rbxl file>")
	process.exit(1)
end

local place = roblox.deserializePlace(fs.readFile(placePath))
local workspace = place:GetService("Workspace")

if not fs.isDir(OUTPUT_FOLDER) then
	fs.writeDir(OUTPUT_FOLDER)
end

local missing = {}
for _, name in MAP_PIECES do
	local piece = workspace:FindFirstChild(name)
	if piece == nil then
		table.insert(missing, name)
		continue
	end
	local path = `{OUTPUT_FOLDER}/{name}.rbxm`
	fs.writeFile(path, roblox.serializeModel({ piece }))
	local tagged = 0
	for _, descendant in piece:GetDescendants() do
		if #descendant:GetTags() > 0 then
			tagged += 1
		end
	end
	print(`wrote {path}: {#piece:GetDescendants()} descendants, {tagged} with tags`)
end

if #missing > 0 then
	print(`Not found in Workspace: {table.concat(missing, ", ")}`)
	process.exit(1)
end
