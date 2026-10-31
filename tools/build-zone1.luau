-- Zone 1 starter: a haunted village at dusk, with an old fort for the boss.
--
-- How to use (no Play needed):
--   1. Run `rojo serve` and Connect in Studio.
--   2. Open the command bar (View > Command Bar), paste this whole file and press Run.
--      Studio warns "Dangerous Command" because the script deletes its own old Zone1 folder:
--      press Continue.
--   3. Everything is built from plain Parts inside Workspace > Zone1, grouped into Models
--      (Huts, Wells, Banyan, Fort ...). Move, resize, recolour or delete anything by hand.
--   4. Running it again replaces Zone1, so copy anything you want to keep out of that folder first.
--
-- It does not touch enemy spawns: they still use the positions in EnemyService, and the landmarks
-- are placed around those positions. Not part of the game: Rojo does not sync this folder.
-- The map itself lives in your Studio place, so Publish or Save to File to keep it.

local C = Color3.fromRGB
local M = Enum.Material
local rng = Random.new(7)

local old = workspace:FindFirstChild("Zone1")
if old then
	old:Destroy()
end
local zone = Instance.new("Folder")
zone.Name = "Zone1"

-- Where enemies spawn (x, z), so scenery leaves room around them.
local SPAWNS = {
	{ 40, 0 },
	{ -40, 0 },
	{ 0, 40 },
	{ -60, -50 },
	{ 30, -100 },
	{ 0, -60 },
	{ 60, 60 },
	{ -70, 50 },
	{ 90, -40 },
	{ -90, 90 },
	{ 0, -150 },
}
local function nearSpawn(x, z, radius)
	for _, spawn in SPAWNS do
		if (x - spawn[1]) ^ 2 + (z - spawn[2]) ^ 2 < radius * radius then
			return true
		end
	end
	return false
end
local function onPath(x, z)
	return math.abs(x) < 8 and z < 22 and z > -150
end

local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

-- A standing cylinder. Roblox cylinders lie along X, so turn them upright.
local function cyl(parent, name, height, diameter, pos, color, material, tilt)
	local cf = CFrame.new(pos) * (tilt or CFrame.identity) * CFrame.Angles(0, 0, math.pi / 2)
	local size = Vector3.new(height, diameter, diameter)
	return part(parent, name, size, cf, color, material, Enum.PartType.Cylinder)
end

local function ball(parent, name, diameter, pos, color, material)
	local size = Vector3.new(diameter, diameter, diameter)
	return part(parent, name, size, CFrame.new(pos), color, material, Enum.PartType.Ball)
end

local function model(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = zone
	return m
end

local function lantern(parent, x, y, z, color)
	local lamp = part(parent, "Lantern", Vector3.new(1, 1.4, 1), CFrame.new(x, y, z), color, M.Neon)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 1.2
	light.Range = 24
	light.Parent = lamp
end

local function lanternPost(parent, x, z, color)
	part(parent, "Pole", Vector3.new(0.4, 7, 0.4), CFrame.new(x, 3.5, z), C(70, 52, 40), M.Wood)
	lantern(parent, x, 7.4, z, color)
end

local function rocks(parent, x, z, count, minR, maxR, minSize, maxSize)
	for i = 1, count do
		local angle = rng:NextNumber(0, 2 * math.pi)
		local radius = rng:NextNumber(minR, maxR)
		local size = rng:NextNumber(minSize, maxSize)
		local cf = CFrame.new(
			x + math.cos(angle) * radius,
			size * 0.3,
			z + math.sin(angle) * radius
		) * CFrame.Angles(
			rng:NextNumber(-0.4, 0.4),
			rng:NextNumber(0, 6),
			rng:NextNumber(-0.4, 0.4)
		)
		local grey = rng:NextInteger(86, 112)
		local dims =
			Vector3.new(size, size * rng:NextNumber(0.6, 1), size * rng:NextNumber(0.8, 1.2))
		part(parent, `Rock{i}`, dims, cf, C(grey, grey, grey + 8), M.Slate)
	end
end

-- Ground and path ---------------------------------------------------------------------------
local base = workspace:FindFirstChild("Baseplate")
if base then
	base.Material = M.Ground
	base.Color = C(92, 76, 58)
end

local ground = model("Ground")
for i = 1, 36 do
	local x, z = rng:NextNumber(-220, 220), rng:NextNumber(-220, 220)
	local size = Vector3.new(rng:NextNumber(24, 50), 0.1 + i * 0.002, rng:NextNumber(24, 50))
	part(
		ground,
		`GrassPatch{i}`,
		size,
		CFrame.new(x, 0.05, z) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
		C(70 + rng:NextInteger(0, 14), 82 + rng:NextInteger(0, 12), 50),
		M.Grass
	)
end
local path = model("Path")
local pathIndex = 0
for z = 14, -150, -12 do
	pathIndex += 1
	local jitter = math.sin(z * 0.05) * 3
	local tone = rng:NextInteger(0, 12)
	part(
		path,
		`Path{pathIndex}`,
		Vector3.new(8 + rng:NextNumber(0, 2), 0.2, 13),
		CFrame.new(jitter, 0.12, z) * CFrame.Angles(0, math.sin(z * 0.05) * 0.1, 0),
		C(150 + tone, 120 + tone, 84 + tone),
		M.Sand
	)
end

-- Round mud huts with stepped thatch roofs ---------------------------------------------------
local huts = model("Huts")
local function hut(name, x, z, yaw, ruined)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = huts
	local origin = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	local mud = C(126, 108, 90)
	local height = if ruined then 2.6 else 6
	cyl(m, "Wall", height, 9, Vector3.new(x, height / 2, z), mud, M.Concrete)
	part(
		m,
		"Door",
		Vector3.new(2.6, 4, 0.5),
		origin * CFrame.new(0, 2, -4.4),
		C(34, 24, 20),
		M.Wood
	)
	if ruined then
		rocks(m, x, z, 6, 4, 7, 1.6, 3)
		return
	end
	for tier = 0, 5 do
		local tone = (tier % 2) * 14
		cyl(
			m,
			`Roof{tier}`,
			1.3,
			12.4 - tier * 2.2,
			Vector3.new(x, 6.5 + tier * 1.1, z),
			C(112 + tone, 96 + tone, 62),
			M.Fabric
		)
	end
	local at = origin * CFrame.new(3, 0, -6)
	lanternPost(m, at.X, at.Z, C(255, 176, 80))
end
hut("HutA", -26, -20, 0.6, false)
hut("HutB", -28, 18, 2.4, false)
hut("HutC", 26, -24, -0.5, false)
hut("HutD", 28, 20, 3.4, false)
hut("HutE", -58, -18, 1.2, false)
hut("HutF", 58, -12, -1.2, false)
hut("RuinedHutA", 68, 68, 0.3, true)
hut("RuinedHutB", 100, -50, 2, true)
hut("RuinedHutC", 18, -112, 1, true)

-- A well with a little roof -------------------------------------------------------------------
local function well(x, z)
	local m = model("Well")
	cyl(m, "Ring", 3, 7, Vector3.new(x, 1.5, z), C(120, 116, 108), M.Cobblestone)
	cyl(m, "Water", 0.2, 5, Vector3.new(x, 3.02, z), C(14, 16, 24), M.SmoothPlastic)
	for _, side in { -3, 3 } do
		part(m, "Post", Vector3.new(0.5, 6, 0.5), CFrame.new(x + side, 6, z), C(70, 52, 40), M.Wood)
	end
	part(m, "Beam", Vector3.new(7, 0.5, 0.5), CFrame.new(x, 9, z), C(70, 52, 40), M.Wood)
end
well(14, -14)
well(6, -66)

-- The great banyan tree, with the Backfoot Hag's spot underneath ----------------------------
local function banyan(x, z)
	local m = model("Banyan")
	local bark = C(78, 60, 48)
	cyl(m, "Trunk", 16, 4.5, Vector3.new(x, 8, z), bark, M.Wood)
	for i = 1, 3 do
		local a = i * 2.1
		cyl(
			m,
			`SideTrunk{i}`,
			14,
			1.8,
			Vector3.new(x + math.cos(a) * 5, 7, z + math.sin(a) * 5),
			bark,
			M.Wood
		)
	end
	for i = 1, 9 do
		local a, r, s = rng:NextNumber(0, 6.3), rng:NextNumber(0, 9), rng:NextNumber(12, 19)
		local green = C(36 + rng:NextInteger(0, 14), 66 + rng:NextInteger(0, 16), 38)
		ball(
			m,
			`Leaves{i}`,
			s,
			Vector3.new(x + math.cos(a) * r, rng:NextNumber(17, 23), z + math.sin(a) * r),
			green,
			M.Grass
		)
	end
	for i = 1, 16 do
		local a, r, len = rng:NextNumber(0, 6.3), rng:NextNumber(5, 14), rng:NextNumber(9, 16)
		cyl(
			m,
			`Root{i}`,
			len,
			0.5,
			Vector3.new(x + math.cos(a) * r, 16 - len / 2, z + math.sin(a) * r),
			bark,
			M.Wood
		)
	end
end
banyan(-68, -58)

-- Dead trees, scarecrow, rocks -----------------------------------------------------------------
local dead = model("DeadTrees")
local function deadTree(x, z)
	local height = rng:NextNumber(8, 12)
	local wood = C(60, 50, 44)
	local lean = CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12))
	cyl(dead, "Trunk", height, 1.2, Vector3.new(x, height / 2, z), wood, M.Wood, lean)
	for i = 1, 3 do
		local tilt = CFrame.Angles(rng:NextNumber(-0.9, 0.9), 0, rng:NextNumber(-0.9, 0.9))
		local top = Vector3.new(
			x + rng:NextNumber(-1, 1),
			height * rng:NextNumber(0.6, 0.9),
			z + rng:NextNumber(-1, 1)
		)
		cyl(dead, `Branch{i}`, rng:NextNumber(3, 5), 0.5, top, wood, M.Wood, tilt)
	end
end
local placed = 0
for _ = 1, 400 do
	if placed >= 22 then
		break
	end
	local x, z = rng:NextNumber(-210, 210), rng:NextNumber(-210, 210)
	if not nearSpawn(x, z, 14) and not onPath(x, z) and (x * x + z * z) > 45 * 45 then
		deadTree(x, z)
		placed += 1
	end
end
-- A tight grove for the second Backfoot Hag
for _, spot in { { 38, -108 }, { 24, -94 }, { 40, -92 }, { 22, -110 } } do
	deadTree(spot[1], spot[2])
end

local scarecrow = model("Scarecrow")
local sx, sz = -10, -64
part(scarecrow, "Post", Vector3.new(0.4, 7, 0.4), CFrame.new(sx, 3.5, sz), C(70, 52, 40), M.Wood)
part(scarecrow, "Arms", Vector3.new(5, 0.4, 0.4), CFrame.new(sx, 5.2, sz), C(70, 52, 40), M.Wood)
part(
	scarecrow,
	"Sack",
	Vector3.new(1.8, 2.6, 1),
	CFrame.new(sx, 4.4, sz),
	C(150, 120, 80),
	M.Fabric
)
ball(scarecrow, "Head", 1.6, Vector3.new(sx, 6.6, sz), C(190, 160, 100), M.Fabric)

local scatter = model("Rocks")
for _ = 1, 40 do
	local x, z = rng:NextNumber(-220, 220), rng:NextNumber(-220, 220)
	if not nearSpawn(x, z, 10) and not onPath(x, z) then
		rocks(scatter, x, z, 1, 0, 0, 1.5, 4.5)
	end
end

-- The Night Witch's corner: a leaning hut, purple lanterns and herb poles ---------------------
local witch = model("WitchCorner")
hut("WitchHut", -84, 62, 0.8, false)
for i, spot in { { -62, 66 }, { -80, 38 }, { -58, 40 } } do
	part(
		witch,
		`HerbPole{i}`,
		Vector3.new(0.4, 8, 0.4),
		CFrame.new(spot[1], 4, spot[2]),
		C(70, 52, 40),
		M.Wood
	)
	lantern(witch, spot[1], 8.4, spot[2], C(170, 90, 255))
end

-- The Tusked Brute's stony hollow ----------------------------------------------------------------
rocks(model("BruteRocks"), -90, 90, 14, 13, 22, 5, 11)

-- Lanterns along the road ----------------------------------------------------------------------------
local road = model("RoadLanterns")
for z = 6, -140, -26 do
	lanternPost(road, -6.5, z, C(255, 176, 80))
	lanternPost(road, 6.5, z - 13, C(255, 176, 80))
end

-- The old fort for the Rage King -----------------------------------------------------------------
local fort = model("Fort")
local stone = C(112, 108, 102)
local darkStone = C(84, 80, 78)
cyl(fort, "ArenaFloor", 0.4, 64, Vector3.new(0, 0.2, -150), darkStone, M.Cobblestone)
local function wall(name, size, pos)
	part(fort, name, size, CFrame.new(pos), stone, M.Cobblestone)
	local length = math.max(size.X, size.Z)
	for i = 0, math.floor(length / 5) - 1 do
		local offset = -length / 2 + 2.5 + i * 5
		local at = if size.X > size.Z
			then Vector3.new(pos.X + offset, size.Y + 1, pos.Z)
			else Vector3.new(pos.X, size.Y + 1, pos.Z + offset)
		part(fort, `{name}Top{i}`, Vector3.new(2.6, 2.4, 2.6), CFrame.new(at), stone, M.Cobblestone)
	end
end
wall("WallNorthL", Vector3.new(56, 16, 5), Vector3.new(-42, 8, -175))
wall("WallNorthR", Vector3.new(56, 16, 5), Vector3.new(42, 8, -175))
wall("WallWest", Vector3.new(5, 14, 50), Vector3.new(-70, 7, -150))
wall("WallEast", Vector3.new(5, 14, 50), Vector3.new(70, 7, -150))
for _, side in { -1, 1 } do
	cyl(fort, "Tower", 26, 14, Vector3.new(side * 70, 13, -175), stone, M.Cobblestone)
	cyl(fort, "TowerTop", 1.4, 16, Vector3.new(side * 70, 26.7, -175), darkStone, M.Cobblestone)
	part(
		fort,
		"Pillar",
		Vector3.new(6, 22, 6),
		CFrame.new(side * 12, 11, -175),
		stone,
		M.Cobblestone
	)
end
-- A broken lintel over the gate
part(
	fort,
	"LintelL",
	Vector3.new(14, 4, 6),
	CFrame.new(-6, 23.5, -175) * CFrame.Angles(0, 0, 0.12),
	stone,
	M.Cobblestone
)
part(
	fort,
	"LintelR",
	Vector3.new(9, 4, 6),
	CFrame.new(8, 22.6, -175) * CFrame.Angles(0, 0, -0.2),
	stone,
	M.Cobblestone
)
rocks(fort, 0, -172, 8, 4, 10, 2, 4)
lanternPost(fort, -20, -128, C(255, 120, 60))
lanternPost(fort, 20, -128, C(255, 120, 60))

zone.Parent = workspace
print(`[Zone1] built {#zone:GetDescendants()} pieces. Edit them by hand in Workspace > Zone1.`)
