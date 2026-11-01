-- Zone 1 starter: a ruined fortress-city at dusk, built as nested walled courtyards.
--
-- The plan is inspired by the layout of the great South Indian temple cities: rectangle inside
-- rectangle, each with a tall gate tower in the middle of every side, joined by a straight road
-- from the outer gate to the centre. It is an original place: no shrine, idols or sacred symbols.
--
-- How to use (no Play needed):
--   1. Run `rojo serve` and Connect in Studio.
--   2. Open the command bar (View > Command Bar), paste this whole file and press Run.
--      Studio warns "Dangerous Command" because the script deletes its own old Zone1 folder:
--      press Continue.
--   3. Everything is built from plain Parts inside Workspace > Zone1, grouped into Models
--      (OuterWall, GateTowers, PillarHall, Court ...). Move, resize, recolour or delete by hand.
--   4. Running it again replaces Zone1, so copy anything you want to keep out of that folder first.
--
-- Enemy spawns are the positions in EnemyService (DEFAULT_SPAWNS), placed to match these rings.
-- Not part of the game: Rojo does not sync this folder. The map lives in git as `map/*.rbxm`. After
-- running this or editing by hand, File > Download a Copy and run `lune run tools/extract-map`.
--
-- Plan (top of the sketch is far, negative Z). Centre of the compound is (0, -110):
--   outer wall   x -120..120, z -210..-10    gate towers N, S, E, W
--   middle wall  x  -84..84,  z -182..-38    smaller gate towers
--   inner wall   x  -50..50,  z -150..-70    small gate towers, the court with the water tank
--   the player starts at (0, 0), outside the south gate, and walks straight in.

local C = Color3.fromRGB
local M = Enum.Material
local V = Vector3.new
local rng = Random.new(7)

local STONE = C(140, 128, 114)
local STONE_DARK = C(104, 96, 88)
local PAINT = C(158, 74, 56)
local OCHRE = C(196, 160, 96)
local WOOD = C(70, 52, 40)
local WARM = C(255, 176, 80)
-- The pillar hall is a calm beige and grey, lit by pale dim lanterns, so it does not glow orange.
local HALL_PILLAR = C(176, 168, 152)
local HALL_STONE = C(132, 128, 120)
local HALL_ROOF = C(116, 114, 108)
local HALL_BAND = C(150, 142, 126)
local HALL_LIGHT = C(255, 238, 205)
local CZ = -110

local old = workspace:FindFirstChild("Zone1")
if old then
	old:Destroy()
end
local zone = Instance.new("Folder")
zone.Name = "Zone1"

-- Where enemies spawn (x, z), so scenery leaves room around them.
local SPAWNS = {
	{ -60, -24 },
	{ 60, -24 },
	{ 100, -52 },
	{ -100, -90 },
	{ -100, -150 },
	{ 97, -115 },
	{ 97, -165 },
	{ -60, -196 },
	{ 60, -196 },
	{ 0, -54 },
	{ 0, -166 },
	{ 0, -132 },
}
local function nearSpawn(x, z, radius)
	for _, spawn in SPAWNS do
		if (x - spawn[1]) ^ 2 + (z - spawn[2]) ^ 2 < radius * radius then
			return true
		end
	end
	return false
end
local function insideCompound(x, z)
	return math.abs(x) < 135 and z < 24 and z > -228
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
	local size = V(height, diameter, diameter)
	return part(parent, name, size, cf, color, material, Enum.PartType.Cylinder)
end

local function ball(parent, name, diameter, pos, color, material)
	local size = V(diameter, diameter, diameter)
	return part(parent, name, size, CFrame.new(pos), color, material, Enum.PartType.Ball)
end

local function model(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = zone
	return m
end

local function lantern(parent, x, y, z, color, brightness, range)
	local lamp = part(parent, "Lantern", V(1, 1.4, 1), CFrame.new(x, y, z), color, M.Neon)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 1.2
	light.Range = range or 24
	light.Parent = lamp
end

local function lanternPost(parent, x, z, color)
	part(parent, "Pole", V(0.4, 7, 0.4), CFrame.new(x, 3.5, z), WOOD, M.Wood)
	lantern(parent, x, 7.4, z, color)
end

local function rocks(parent, x, z, count, minR, maxR, minSize, maxSize)
	for i = 1, count do
		local angle = rng:NextNumber(0, 2 * math.pi)
		local radius = rng:NextNumber(minR, maxR)
		local size = rng:NextNumber(minSize, maxSize)
		local at = V(x + math.cos(angle) * radius, size * 0.3, z + math.sin(angle) * radius)
		local cf = CFrame.new(at)
			* CFrame.Angles(
				rng:NextNumber(-0.4, 0.4),
				rng:NextNumber(0, 6),
				rng:NextNumber(-0.4, 0.4)
			)
		local grey = rng:NextInteger(86, 112)
		local dims = V(size, size * rng:NextNumber(0.6, 1), size * rng:NextNumber(0.8, 1.2))
		part(parent, `Rock{i}`, dims, cf, C(grey, grey, grey + 8), M.Slate)
	end
end

-- Ground, paving and the road in --------------------------------------------------------------
local base = workspace:FindFirstChild("Baseplate")
if base then
	base.Material = M.Ground
	base.Color = C(92, 76, 58)
end

local ground = model("Ground")
for i = 1, 40 do
	local x, z = rng:NextNumber(-230, 230), rng:NextNumber(-240, 240)
	if not insideCompound(x, z) then
		local size = V(rng:NextNumber(24, 50), 0.1 + i * 0.002, rng:NextNumber(24, 50))
		local cf = CFrame.new(x, 0.05, z) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		local color = C(70 + rng:NextInteger(0, 14), 82 + rng:NextInteger(0, 12), 50)
		part(ground, `GrassPatch{i}`, size, cf, color, M.Grass)
	end
end
part(ground, "Paving", V(244, 0.5, 204), CFrame.new(0, 0.25, CZ), C(122, 110, 96), M.Cobblestone)
part(ground, "CourtFloor", V(104, 0.6, 84), CFrame.new(0, 0.3, CZ), C(98, 90, 82), M.Cobblestone)
local road = model("Road")
for z = 14, -8, -11 do
	part(road, "Dirt", V(9, 0.3, 12), CFrame.new(0, 0.15, z), C(150, 120, 84), M.Sand)
end
-- The axis: a paved road through every gate, straight to the centre
part(road, "Axis", V(10, 0.7, 100), CFrame.new(0, 0.35, -60), C(136, 122, 104), M.Slate)

-- Walls with gaps for the gates ---------------------------------------------------------------
local function wallRing(name, hx, hz, height, thick, gap)
	local m = model(name)
	-- One side of the ring, in two halves either side of the gate. `alongX` says which way it runs.
	local function side(label, length, centre, alongX, fixed)
		local function at(along, y)
			if alongX then
				return CFrame.new(along, y, fixed)
			end
			return CFrame.new(fixed, y, along)
		end
		local function dims(len, h, depth)
			if alongX then
				return V(len, h, depth)
			end
			return V(depth, h, len)
		end
		for _, dir in { -1, 1 } do
			local start = gap / 2
			local len = length - start + thick / 2
			local mid = centre + dir * (start + len / 2)
			part(m, label, dims(len, height, thick), at(mid, height / 2), STONE, M.Brick)
			local cap = dims(len + 0.4, 1.2, thick + 1.2)
			part(m, label .. "Cap", cap, at(mid, height + 0.6), STONE_DARK, M.Cobblestone)
			local k = start + 3
			while k < start + len - 2 do
				local finial = at(centre + dir * k, height + 2.3)
				part(m, label .. "Finial", V(2, 2.2, 2), finial, STONE, M.Brick)
				k += 8
			end
		end
	end
	for _, s in { -1, 1 } do
		side("WallEW", hx, 0, true, CZ + s * hz)
		side("WallNS", hz, CZ, false, s * hx)
	end
end
wallRing("OuterWall", 120, 100, 18, 5, 16)
wallRing("MiddleWall", 84, 72, 14, 4.5, 14)
wallRing("InnerWall", 50, 40, 10, 4, 12)

-- Tall gate towers: a stone gateway with stepped, banded tiers and a barrel roof ---------------
local towers = model("GateTowers")
local function gateTower(name, x, z, yaw, width, depth, baseH, tiers, gap)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = towers
	local origin = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	local function put(label, size, offset, color, material)
		return part(m, label, size, origin * CFrame.new(offset), color, material)
	end
	local pier = (width - gap) / 2
	for _, s in { -1, 1 } do
		local offset = V(s * (gap / 2 + pier / 2), baseH / 2, 0)
		put("Pier", V(pier, baseH, depth), offset, STONE, M.Brick)
	end
	put("Lintel", V(width, 3, depth), V(0, baseH + 1.5, 0), STONE_DARK, M.Cobblestone)
	local y = baseH + 3
	local w, d = width, depth
	for tier = 1, tiers do
		w -= 3.5
		d -= 2
		local h = 5.5
		put(`Tier{tier}`, V(w, h, d), V(0, y + h / 2, 0), STONE, M.Brick)
		local band = if tier % 2 == 0 then PAINT else OCHRE
		put(`Band{tier}`, V(w + 0.8, 1.1, d + 0.8), V(0, y + 0.55, 0), band, M.Concrete)
		for _, face in { -1, 1 } do
			for _, slot in { -1, 1 } do
				local at = V(slot * w * 0.22, y + h * 0.6, face * (d / 2 + 0.05))
				put("Window", V(1.2, 2.4, 0.4), at, C(30, 24, 28), M.SmoothPlastic)
			end
		end
		y += h
	end
	-- A barrel roof lying along the tower's width
	local roofCf = origin * CFrame.new(0, y + d * 0.45, 0)
	local roofSize = V(w, d, d)
	part(m, "BarrelRoof", roofSize, roofCf, STONE_DARK, M.Cobblestone, Enum.PartType.Cylinder)
	for slot = -1, 1 do
		local at = V(slot * w * 0.35, y + d * 0.95 + 1.2, 0)
		put("Finial", V(1.2, 2.4, 1.2), at, OCHRE, M.Concrete)
	end
end
local function gatesFor(label, hx, hz, width, depth, baseH, tiers, gap)
	gateTower(label .. "North", 0, CZ - hz, 0, width, depth, baseH, tiers, gap)
	gateTower(label .. "South", 0, CZ + hz, 0, width, depth, baseH, tiers, gap)
	gateTower(label .. "East", hx, CZ, math.pi / 2, width, depth, baseH, tiers, gap)
	gateTower(label .. "West", -hx, CZ, math.pi / 2, width, depth, baseH, tiers, gap)
end
gatesFor("Outer", 120, 100, 34, 16, 14, 5, 16)
gatesFor("Middle", 84, 72, 26, 14, 11, 3, 14)
gatesFor("Inner", 50, 40, 20, 12, 8, 2, 12)

-- A pillared hall in the east corridor ---------------------------------------------------------
local hall = model("PillarHall")
local function pillarHall(x0, z0, cols, rows, dx, dz, height)
	for c = 0, cols - 1 do
		for r = 0, rows - 1 do
			local x, z = x0 + c * dx, z0 + r * dz
			cyl(hall, "Pillar", height, 2.2, V(x, height / 2, z), HALL_PILLAR, M.Concrete)
			part(hall, "Foot", V(3.4, 0.8, 3.4), CFrame.new(x, 0.9, z), HALL_STONE, M.Cobblestone)
			local cap = CFrame.new(x, height + 0.6, z)
			part(hall, "Cap", V(3.6, 1.2, 3.6), cap, HALL_STONE, M.Cobblestone)
			if (c + r) % 4 == 0 then
				lantern(hall, x + 1.7, 5, z, HALL_LIGHT, 0.45, 14)
			end
		end
	end
	local width, length = (cols - 1) * dx + 6, (rows - 1) * dz + 6
	local centre = V(x0 + (cols - 1) * dx / 2, height + 1.9, z0 + (rows - 1) * dz / 2)
	part(hall, "Roof", V(width, 1.4, length), CFrame.new(centre), HALL_ROOF, M.Cobblestone)
	local band = CFrame.new(centre.X, height + 2.9, centre.Z)
	part(hall, "RoofBand", V(width + 0.8, 0.6, length + 0.8), band, HALL_BAND, M.Concrete)
end
pillarHall(92, -170, 3, 12, 10, 10, 12)

-- West corridor: a ruined market and the great banyan tree --------------------------------------
local market = model("Market")
local function stall(x, z, color)
	for _, dx in { -2.2, 2.2 } do
		for _, dz in { -1.6, 1.6 } do
			part(market, "Post", V(0.4, 5, 0.4), CFrame.new(x + dx, 2.5, z + dz), WOOD, M.Wood)
		end
	end
	local canopy = CFrame.new(x, 5.2, z) * CFrame.Angles(0, 0, 0.1)
	part(market, "Canopy", V(6, 0.4, 4.4), canopy, color, M.Fabric)
	part(market, "Counter", V(4.4, 1.6, 1.4), CFrame.new(x, 0.8, z), WOOD, M.WoodPlanks)
end
for index, z in { -48, -62, -76 } do
	stall(-108, z, if index % 2 == 0 then PAINT else OCHRE)
end
for index, z in { -172, -186 } do
	stall(-108, z, if index % 2 == 0 then OCHRE else PAINT)
end
local function banyan(x, z)
	local m = model("Banyan")
	local bark = C(78, 60, 48)
	cyl(m, "Trunk", 16, 4.5, V(x, 8, z), bark, M.Wood)
	for i = 1, 3 do
		local a = i * 2.1
		local at = V(x + math.cos(a) * 5, 7, z + math.sin(a) * 5)
		cyl(m, `SideTrunk{i}`, 14, 1.8, at, bark, M.Wood)
	end
	for i = 1, 9 do
		local a, r, s = rng:NextNumber(0, 6.3), rng:NextNumber(0, 8), rng:NextNumber(12, 18)
		local green = C(36 + rng:NextInteger(0, 14), 66 + rng:NextInteger(0, 16), 38)
		local at = V(x + math.cos(a) * r, rng:NextNumber(17, 23), z + math.sin(a) * r)
		ball(m, `Leaves{i}`, s, at, green, M.Grass)
	end
	for i = 1, 14 do
		local a, r, len = rng:NextNumber(0, 6.3), rng:NextNumber(5, 12), rng:NextNumber(9, 16)
		local at = V(x + math.cos(a) * r, 16 - len / 2, z + math.sin(a) * r)
		cyl(m, `Root{i}`, len, 0.5, at, bark, M.Wood)
	end
end
banyan(-108, -120)

-- North corridor: round huts and purple lanterns for the Night Witches --------------------------
local huts = model("Huts")
local function hut(name, x, z, yaw)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = huts
	local origin = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	cyl(m, "Wall", 6, 9, V(x, 3, z), C(126, 108, 90), M.Concrete)
	part(m, "Door", V(2.6, 4, 0.5), origin * CFrame.new(0, 2, -4.4), C(34, 24, 20), M.Wood)
	for tier = 0, 5 do
		local tone = (tier % 2) * 14
		local color = C(112 + tone, 96 + tone, 62)
		cyl(m, `Roof{tier}`, 1.3, 12.4 - tier * 2.2, V(x, 6.5 + tier * 1.1, z), color, M.Fabric)
	end
end
hut("HutWest", -88, -198, 0.4)
hut("HutEast", 88, -198, 2.6)
local witch = model("WitchLanterns")
for _, spot in { { -40, -200 }, { -78, -190 }, { 40, -200 }, { 78, -190 } } do
	lantern(witch, spot[1], 8.4, spot[2], C(170, 90, 255))
	part(witch, "Pole", V(0.4, 8, 0.4), CFrame.new(spot[1], 4, spot[2]), WOOD, M.Wood)
end

-- South corridor: wells and lanterns by the entrance ----------------------------------------------
local function well(x, z)
	local m = model("Well")
	cyl(m, "Ring", 3, 7, V(x, 1.5, z), C(120, 116, 108), M.Cobblestone)
	cyl(m, "Water", 0.2, 5, V(x, 3.02, z), C(14, 16, 24), M.SmoothPlastic)
	for _, s in { -3, 3 } do
		part(m, "Post", V(0.5, 6, 0.5), CFrame.new(x + s, 6, z), WOOD, M.Wood)
	end
	part(m, "Beam", V(7, 0.5, 0.5), CFrame.new(x, 9, z), WOOD, M.Wood)
end
well(-30, -26)
well(30, -26)
local entry = model("EntryLanterns")
for z = 8, -30, -19 do
	lanternPost(entry, -9, z, WARM)
	lanternPost(entry, 9, z - 9, WARM)
end

-- Inner corridors: rubble and braziers --------------------------------------------------------------
local rubble = model("Rubble")
for _, spot in
	{ { -68, -100 }, { 68, -100 }, { -68, -130 }, { 68, -130 }, { -24, -50 }, { 24, -170 } }
do
	rocks(rubble, spot[1], spot[2], 5, 2, 7, 2, 5)
end
for _, spot in { { -30, -52 }, { 30, -52 }, { -30, -168 }, { 30, -168 } } do
	lanternPost(rubble, spot[1], spot[2], C(255, 120, 60))
end

-- The inner court: a raised water tank, with the arena north of it ----------------------------------
local court = model("Court")
local function tank(x, z, w, d)
	part(court, "TankStep1", V(w + 10, 0.8, d + 10), CFrame.new(x, 0.9, z), STONE, M.Slate)
	part(court, "TankStep2", V(w + 6, 0.8, d + 6), CFrame.new(x, 1.7, z), STONE_DARK, M.Slate)
	part(court, "TankStep3", V(w + 2.4, 0.8, d + 2.4), CFrame.new(x, 2.5, z), STONE, M.Slate)
	local water = part(court, "Water", V(w, 0.4, d), CFrame.new(x, 2.8, z), C(28, 66, 84), M.Glass)
	water.Transparency = 0.25
	for i = 1, 12 do
		local px = x + rng:NextNumber(-w / 2 + 1.5, w / 2 - 1.5)
		local pz = z + rng:NextNumber(-d / 2 + 1.5, d / 2 - 1.5)
		local size = rng:NextNumber(1.4, 2.4)
		cyl(court, `Pad{i}`, 0.12, size, V(px, 3.05, pz), C(50, 100, 56), M.Grass)
	end
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local lx, lz = x + corner[1] * (w / 2 + 6), z + corner[2] * (d / 2 + 6)
		lanternPost(court, lx, lz, WARM)
	end
end
tank(0, -98, 26, 14)
for _, s in { -1, 1 } do
	for _, z in { -78, -142 } do
		cyl(court, "CourtPillar", 10, 2.4, V(s * 36, 5, z), STONE, M.Brick)
		local cap = CFrame.new(s * 36, 10.6, z)
		part(court, "CourtCap", V(3.8, 1.2, 3.8), cap, STONE_DARK, M.Cobblestone)
	end
end

-- Dead trees and rocks outside and between ----------------------------------------------------------
local dead = model("DeadTrees")
local function deadTree(x, z)
	local height = rng:NextNumber(8, 12)
	local wood = C(60, 50, 44)
	local lean = CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12))
	cyl(dead, "Trunk", height, 1.2, V(x, height / 2, z), wood, M.Wood, lean)
	for i = 1, 3 do
		local tilt = CFrame.Angles(rng:NextNumber(-0.9, 0.9), 0, rng:NextNumber(-0.9, 0.9))
		local jitter =
			V(rng:NextNumber(-1, 1), height * rng:NextNumber(0.6, 0.9), rng:NextNumber(-1, 1))
		cyl(dead, `Branch{i}`, rng:NextNumber(3, 5), 0.5, V(x, 0, z) + jitter, wood, M.Wood, tilt)
	end
end
local placed = 0
for _ = 1, 600 do
	if placed >= 26 then
		break
	end
	local x, z = rng:NextNumber(-240, 240), rng:NextNumber(-245, 40)
	if not insideCompound(x, z) and not nearSpawn(x, z, 14) then
		deadTree(x, z)
		placed += 1
	end
end
-- A few inside the corridors, where the walls have been neglected
for _, spot in { { -40, -30 }, { 40, -30 }, { -100, -40 }, { 40, -176 }, { -40, -176 } } do
	deadTree(spot[1], spot[2])
end
local scatter = model("Rocks")
for _ = 1, 40 do
	local x, z = rng:NextNumber(-240, 240), rng:NextNumber(-245, 40)
	if not insideCompound(x, z) then
		rocks(scatter, x, z, 1, 0, 0, 1.5, 4.5)
	end
end

zone.Parent = workspace
print(`[Zone1] built {#zone:GetDescendants()} pieces. Edit them by hand in Workspace > Zone1.`)
