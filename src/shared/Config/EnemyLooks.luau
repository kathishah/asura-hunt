--!strict
-- What each enemy looks like, as a list of small parts welded around its invisible hitbox
-- (the HumanoidRootPart, sized by `size` in Enemies.luau). Edit the numbers to reshape a demon.
-- Offsets are studs from the hitbox centre. Enemies face -Z, so negative Z is their front.
-- Rotations are degrees. Anything ending in "Pair" is written for the +X side and mirrored.
--
-- Everything is built from rounded blobs ("Ellipsoid"), limbs that join two points, and curved
-- strands (horns, tusks, ears, hair) so the silhouettes are organic, not boxy.
-- Folklore creatures only: no gods, third eyes, tridents, skull garlands or holy marks.

local Types = require(script.Parent.Parent.Types)

type BodyPart = Types.BodyPart

-- A curved, tapering strand: `segments` pieces of length `step`, thickness going from `from` to
-- `to`, turning `bend` degrees per piece towards a direction.
type Strand = { segments: number, step: number, from: number, to: number, bend: number }

local v = Vector3.new
local NEON = Enum.Material.Neon
local CLOTH = Enum.Material.Fabric
local BONE = Color3.fromRGB(232, 224, 196)

local function flip(point: Vector3): Vector3
	return v(-point.X, point.Y, point.Z)
end

local function add(
	list: { BodyPart },
	shape: Types.PartShape,
	name: string,
	color: Color3,
	size: Vector3,
	offset: Vector3,
	rotation: Vector3?,
	material: Enum.Material?
)
	table.insert(list, {
		name = name,
		shape = shape,
		color = color,
		size = size,
		offset = offset,
		rotation = rotation,
		material = material,
	})
end

-- A rounded blob.
local function blob(
	list: { BodyPart },
	name: string,
	color: Color3,
	size: Vector3,
	offset: Vector3,
	rotation: Vector3?,
	material: Enum.Material?
)
	add(list, "Ellipsoid", name, color, size, offset, rotation, material)
end

local function blobPair(
	list: { BodyPart },
	name: string,
	color: Color3,
	size: Vector3,
	offset: Vector3,
	rotation: Vector3?,
	material: Enum.Material?
)
	blob(list, name .. "R", color, size, offset, rotation, material)
	local mirrored = if rotation then v(rotation.X, -rotation.Y, -rotation.Z) else nil
	blob(list, name .. "L", color, size, flip(offset), mirrored, material)
end

-- Degrees (X, Y, Z) that turn a part's own Y axis to point along `direction`.
local function pointY(direction: Vector3): Vector3
	local up = if math.abs(direction.Unit.Y) > 0.99 then v(0, 0, 1) else v(0, 1, 0)
	local turned = CFrame.lookAt(Vector3.zero, direction, up) * CFrame.Angles(-math.pi / 2, 0, 0)
	local rx, ry, rz = turned:ToEulerAnglesXYZ()
	return v(math.deg(rx), math.deg(ry), math.deg(rz))
end

-- A rounded limb joining two points (an arm bone, a thigh, a claw, a rag).
local function limb(
	list: { BodyPart },
	name: string,
	color: Color3,
	from: Vector3,
	to: Vector3,
	thickness: number,
	material: Enum.Material?
)
	local delta = to - from
	local length = delta.Magnitude + thickness * 0.5 -- rounded ends overlap into the joints
	local size = v(thickness, length, thickness)
	blob(list, name, color, size, (from + to) / 2, pointY(delta), material)
end

local function limbPair(
	list: { BodyPart },
	name: string,
	color: Color3,
	from: Vector3,
	to: Vector3,
	thickness: number,
	material: Enum.Material?
)
	limb(list, name .. "R", color, from, to, thickness, material)
	limb(list, name .. "L", color, flip(from), flip(to), thickness, material)
end

-- Armor pieces (plates, straps, blades): flattened rounded blobs, so armor looks hammered and worn
-- instead of boxy. Square blocks made the demons look like robots.
local function plate(
	list: { BodyPart },
	name: string,
	color: Color3,
	size: Vector3,
	offset: Vector3,
	rotation: Vector3?,
	material: Enum.Material?
)
	add(list, "Ellipsoid", name, color, size, offset, rotation, material)
end

local function platePair(
	list: { BodyPart },
	name: string,
	color: Color3,
	size: Vector3,
	offset: Vector3,
	rotation: Vector3?,
	material: Enum.Material?
)
	plate(list, name .. "R", color, size, offset, rotation, material)
	local mirrored = if rotation then v(rotation.X, -rotation.Y, -rotation.Z) else nil
	plate(list, name .. "L", color, size, flip(offset), mirrored, material)
end

-- A flat bar joining two points (a bracer, a strap, a spike).
local function bar(
	list: { BodyPart },
	name: string,
	color: Color3,
	from: Vector3,
	to: Vector3,
	thickness: number,
	material: Enum.Material?
)
	local delta = to - from
	local size = v(thickness, delta.Magnitude, thickness)
	plate(list, name, color, size, (from + to) / 2, pointY(delta), material)
end

local function barPair(
	list: { BodyPart },
	name: string,
	color: Color3,
	from: Vector3,
	to: Vector3,
	thickness: number,
	material: Enum.Material?
)
	bar(list, name .. "R", color, from, to, thickness, material)
	bar(list, name .. "L", color, flip(from), flip(to), thickness, material)
end

-- A curved strand starting at `start`, heading along `direction` and bending towards `toward`.
local function strand(
	list: { BodyPart },
	name: string,
	color: Color3,
	start: Vector3,
	direction: Vector3,
	toward: Vector3,
	spec: Strand,
	material: Enum.Material?
)
	local heading = direction.Unit
	local point = start
	local bend = math.tan(math.rad(spec.bend))
	for index = 1, spec.segments do
		local progress = if spec.segments > 1 then (index - 1) / (spec.segments - 1) else 0
		local thickness = spec.from + (spec.to - spec.from) * progress
		local nextPoint = point + heading * spec.step
		limb(list, `{name}{index}`, color, point, nextPoint, thickness, material)
		point = nextPoint
		heading = (heading + toward.Unit * bend).Unit
	end
end

local function strandPair(
	list: { BodyPart },
	name: string,
	color: Color3,
	start: Vector3,
	direction: Vector3,
	toward: Vector3,
	spec: Strand,
	material: Enum.Material?
)
	strand(list, name .. "R", color, start, direction, toward, spec, material)
	strand(list, name .. "L", color, flip(start), flip(direction), flip(toward), spec, material)
end

local function scaled(parts: { BodyPart }, factor: number): { BodyPart }
	local result: { BodyPart } = {}
	for _, part in parts do
		add(
			result,
			part.shape,
			part.name,
			part.color,
			part.size * factor,
			part.offset * factor,
			part.rotation,
			part.material
		)
	end
	return result
end

-- Pishacha: a starving flesh-eating ghoul. Hunched, ribs showing, pot belly, bulging red eyes,
-- a gaping toothy mouth, matted hair and long claws.
local function pishacha(): { BodyPart }
	local skin = Color3.fromRGB(104, 118, 108)
	local skinDark = Color3.fromRGB(66, 76, 72)
	local belly = Color3.fromRGB(128, 138, 120)
	local hair = Color3.fromRGB(26, 22, 24)
	local rag = Color3.fromRGB(96, 70, 50)
	local eye = Color3.fromRGB(255, 70, 40)

	local parts: { BodyPart } = {}
	-- Body
	blob(parts, "Pelvis", skinDark, v(1.4, 1.1, 1), v(0, -0.9, 0.1))
	blob(parts, "Belly", belly, v(1.7, 1.7, 1.5), v(0, -0.1, -0.25))
	blob(parts, "Chest", skin, v(1.5, 1.4, 1.1), v(0, 1, -0.45), v(-20, 0, 0))
	blob(parts, "Hump", skin, v(0.9, 1.2, 0.7), v(0, 1.4, 0.3), v(-15, 0, 0))
	for rib = 1, 3 do
		blob(
			parts,
			`Rib{rib}`,
			skinDark,
			v(1.2, 0.1, 0.2),
			v(0, 0.4 + 0.3 * rib, -0.93 - 0.04 * rib)
		)
	end
	for ragIndex = 1, 3 do
		local x = (ragIndex - 2) * 0.55
		blob(parts, `Rag{ragIndex}`, rag, v(0.5, 0.9, 0.15), v(x, -1.45, -0.55), nil, CLOTH)
	end
	-- Head, hanging forward
	limb(parts, "Neck", skin, v(0, 1.7, -0.5), v(0, 2.1, -0.8), 0.5)
	blob(parts, "Head", skin, v(1.3, 1.5, 1.3), v(0, 2.3, -0.85))
	blobPair(parts, "Brow", skinDark, v(0.65, 0.2, 0.35), v(0.38, 2.7, -1.4), v(0, 0, 15))
	blobPair(parts, "Eye", eye, v(0.42, 0.42, 0.42), v(0.38, 2.45, -1.42), nil, NEON)
	blobPair(parts, "Pupil", skinDark, v(0.12, 0.2, 0.1), v(0.38, 2.45, -1.62))
	blob(parts, "Nose", skinDark, v(0.25, 0.35, 0.3), v(0, 2.2, -1.55))
	blob(parts, "Mouth", skinDark, v(0.85, 0.35, 0.5), v(0, 1.9, -1.35))
	blob(parts, "Jaw", skin, v(0.9, 0.45, 0.9), v(0, 1.65, -1.1))
	for tooth = -2, 2 do
		blob(parts, `Tooth{tooth}`, BONE, v(0.1, 0.28, 0.1), v(tooth * 0.16, 2, -1.55))
	end
	limbPair(parts, "Fang", BONE, v(0.28, 1.8, -1.55), v(0.28, 1.4, -1.62), 0.12)
	strandPair(parts, "Ear", skin, v(0.6, 2.4, -0.85), v(1, 0.5, 0.1), v(0, 1, 0), {
		segments = 3,
		step = 0.35,
		from = 0.28,
		to = 0.07,
		bend = 20,
	})
	-- Matted hair rising from the skull and drooping
	local hairStrands = {
		{ -0.5, -0.3, -0.6, 0.3 },
		{ -0.25, -0.5, -0.2, 0.2 },
		{ 0, -0.6, 0, 0.3 },
		{ 0.25, -0.5, 0.2, 0.2 },
		{ 0.5, -0.3, 0.6, 0.3 },
		{ -0.35, 0, -0.4, 0.8 },
		{ 0.35, 0, 0.4, 0.8 },
	}
	for index, s in hairStrands do
		strand(
			parts,
			`Hair{index}`,
			hair,
			v(s[1], 3, -0.85 + s[2]),
			v(s[3], 1, s[4]),
			v(0, -1, 0.2),
			{ segments = 4, step = 0.5, from = 0.2, to = 0.05, bend = 28 }
		)
	end
	-- Long thin arms with claws
	blobPair(parts, "Shoulder", skin, v(0.6, 0.6, 0.6), v(0.85, 1.5, -0.4))
	limbPair(parts, "UpperArm", skin, v(0.85, 1.5, -0.4), v(1, 0.5, -0.75), 0.4)
	limbPair(parts, "Forearm", skin, v(1, 0.5, -0.75), v(0.95, -0.6, -1.3), 0.3)
	blobPair(parts, "Hand", skinDark, v(0.4, 0.5, 0.35), v(0.95, -0.85, -1.38))
	for claw = 1, 3 do
		local spread = (claw - 2) * 0.14
		local from = v(0.95 + spread, -1.05, -1.4)
		limbPair(parts, `Claw{claw}`, BONE, from, v(0.95 + spread * 1.6, -1.7, -1.6), 0.08)
	end
	-- Bent legs
	limbPair(parts, "Thigh", skin, v(0.5, -0.9, 0.1), v(0.6, -1.7, -0.4), 0.5)
	limbPair(parts, "Shin", skin, v(0.6, -1.7, -0.4), v(0.55, -2.35, 0.05), 0.35)
	blobPair(parts, "Foot", skinDark, v(0.5, 0.25, 0.9), v(0.55, -2.4, -0.25))
	return parts
end

-- Vetala: a corpse-spirit of the cremation ground. Thin and ashen in a tattered white shroud,
-- with a hollow face, a wide grin, wild upright hair, glowing eyes and long grasping fingers.
local function vetala(): { BodyPart }
	local skin = Color3.fromRGB(150, 158, 170)
	local skinDark = Color3.fromRGB(96, 104, 120)
	local rib = Color3.fromRGB(190, 196, 208)
	local shroud = Color3.fromRGB(214, 208, 192)
	local shroudDark = Color3.fromRGB(160, 154, 140)
	local hair = Color3.fromRGB(24, 20, 30)
	local hollow = Color3.fromRGB(26, 20, 32)
	local eye = Color3.fromRGB(150, 255, 200)

	local parts: { BodyPart } = {}
	-- Bony torso
	blob(parts, "Chest", skin, v(1.5, 2.2, 0.9), v(0, 0.8, -0.1), v(-10, 0, 0))
	for index = 1, 4 do
		blob(parts, `Rib{index}`, rib, v(1.25, 0.1, 0.25), v(0, 0.2 + 0.3 * index, -0.55))
	end
	blob(parts, "Pelvis", skinDark, v(1.1, 0.8, 0.7), v(0, -0.8, 0))
	-- Shroud: a cape over the shoulders, a ragged skirt and strips hanging behind
	blob(parts, "Cape", shroud, v(2.2, 0.6, 1.5), v(0, 1.75, -0.1), nil, CLOTH)
	blob(parts, "Back", shroudDark, v(1.9, 3.4, 0.2), v(0, 0.1, 0.55), nil, CLOTH)
	local lengths = { 1.8, 2.4, 2, 2.5, 1.7 }
	for index, length in lengths do
		local x = (index - 3) * 0.42
		local tilt = v(0, 0, (index - 3) * 4)
		blob(
			parts,
			`Skirt{index}`,
			shroud,
			v(0.38, length, 0.1),
			v(x, -0.4 - length / 2, -0.6),
			tilt,
			CLOTH
		)
	end
	for index = 1, 3 do
		local x = (index - 2) * 0.6
		blob(parts, `Tail{index}`, shroudDark, v(0.5, 2, 0.1), v(x, -1.9, 0.55), nil, CLOTH)
	end
	-- Skull-like head with a hollow face
	limb(parts, "Neck", skin, v(0, 1.9, -0.2), v(0, 2.5, -0.55), 0.4)
	blob(parts, "Head", skin, v(1.1, 1.5, 1.1), v(0, 3.1, -0.6))
	blob(parts, "Chin", skin, v(0.5, 0.4, 0.5), v(0, 2.4, -0.95))
	blobPair(parts, "Cheek", skinDark, v(0.35, 0.5, 0.2), v(0.4, 2.85, -1.05))
	blobPair(parts, "Socket", hollow, v(0.42, 0.36, 0.25), v(0.28, 3.2, -1.08))
	blobPair(parts, "Eye", eye, v(0.2, 0.2, 0.2), v(0.28, 3.2, -1.16), nil, NEON)
	blob(parts, "Nose", hollow, v(0.2, 0.32, 0.12), v(0, 2.95, -1.13))
	blob(parts, "Mouth", hollow, v(0.75, 0.22, 0.15), v(0, 2.6, -1.08))
	for tooth = -2, 2 do
		blob(parts, `Tooth{tooth}`, BONE, v(0.07, 0.22, 0.07), v(tooth * 0.14, 2.62, -1.15))
	end
	-- Wild hair standing up and falling over
	for index = -3, 3 do
		strand(
			parts,
			`Hair{index}`,
			hair,
			v(index * 0.13, 3.8, -0.6 + (index % 2) * 0.2),
			v(index * 0.2, 1, -0.1),
			v(0, -1, 0),
			{ segments = 4, step = 0.5, from = 0.16, to = 0.04, bend = 24 }
		)
	end
	-- Very long arms and fingers
	blobPair(parts, "Shoulder", skinDark, v(0.55, 0.55, 0.55), v(0.85, 1.7, -0.15))
	limbPair(parts, "UpperArm", skin, v(0.85, 1.7, -0.15), v(1.2, 0.2, -0.45), 0.3)
	limbPair(parts, "Forearm", skin, v(1.2, 0.2, -0.45), v(1.1, -1.3, -0.9), 0.24)
	blobPair(parts, "Hand", skin, v(0.35, 0.5, 0.25), v(1.1, -1.55, -0.95))
	for finger = 1, 4 do
		local spread = (finger - 2.5) * 0.1
		local from = v(1.1 + spread, -1.75, -0.95)
		limbPair(parts, `Finger{finger}`, skinDark, from, v(1.1 + spread * 2, -2.55, -1.1), 0.07)
	end
	-- Bony legs and feet showing under the shroud
	limbPair(parts, "Shin", skin, v(0.3, -1.2, 0), v(0.35, -2.7, -0.1), 0.25)
	blobPair(parts, "Foot", skinDark, v(0.3, 0.15, 0.7), v(0.35, -2.9, -0.3))
	return parts
end

-- Chudail: the restless ghost of a woman, from village folk tales. Pale and thin in a tattered
-- gown, with long black hair, amber eyes, fangs, long claws and feet that point backwards.
local function chudail(): { BodyPart }
	local skin = Color3.fromRGB(176, 182, 196)
	local skinDark = Color3.fromRGB(120, 126, 144)
	local gown = Color3.fromRGB(104, 36, 58)
	local gownDark = Color3.fromRGB(66, 24, 42)
	local hair = Color3.fromRGB(14, 12, 18)
	local hollow = Color3.fromRGB(24, 16, 26)
	local eye = Color3.fromRGB(255, 170, 40)

	local parts: { BodyPart } = {}
	-- Gown: fitted top, a skirt that flares out, and torn strips at the hem
	blob(parts, "Bodice", gown, v(1.8, 2.3, 1.1), v(0, 0.8, 0), v(-6, 0, 0), CLOTH)
	blob(parts, "Skirt", gownDark, v(2.3, 2.6, 1.6), v(0, -0.8, 0), nil, CLOTH)
	blob(parts, "Flare", gown, v(2.7, 1.3, 1.9), v(0, -1.65, 0), nil, CLOTH)
	local hem = { 0.5, 0.35, 0.45, 0.3, 0.5 }
	for index, length in hem do
		local x = (index - 3) * 0.42
		local tilt = v(0, 0, (index - 3) * 5)
		blob(
			parts,
			`Strip{index}`,
			gownDark,
			v(0.34, length, 0.1),
			v(x, -2.25 - length / 2, -0.7),
			tilt,
			CLOTH
		)
		blob(
			parts,
			`StripBack{index}`,
			gownDark,
			v(0.34, length, 0.1),
			v(x, -2.25 - length / 2, 0.7),
			tilt,
			CLOTH
		)
	end
	-- Head: a gaunt face with sunken glowing eyes and fangs
	limb(parts, "Neck", skin, v(0, 1.8, -0.1), v(0, 2.2, -0.25), 0.38)
	blob(parts, "Head", skin, v(1.15, 1.4, 1.1), v(0, 2.7, -0.3))
	blob(parts, "Chin", skin, v(0.5, 0.4, 0.5), v(0, 2.05, -0.6))
	blobPair(parts, "Cheek", skinDark, v(0.3, 0.5, 0.15), v(0.42, 2.5, -0.7))
	blobPair(parts, "Socket", hollow, v(0.42, 0.3, 0.2), v(0.27, 2.8, -0.8))
	blobPair(parts, "Eye", eye, v(0.22, 0.2, 0.15), v(0.27, 2.8, -0.88), nil, NEON)
	blob(parts, "Nose", skinDark, v(0.18, 0.35, 0.2), v(0, 2.55, -0.88))
	blob(parts, "Mouth", hollow, v(0.7, 0.2, 0.15), v(0, 2.35, -0.84))
	limbPair(parts, "Fang", BONE, v(0.17, 2.4, -0.88), v(0.17, 2.05, -0.9), 0.09)
	-- Long black hair down the back, with locks framing the face
	blob(parts, "HairBack", hair, v(1.5, 1.9, 0.7), v(0, 2.65, 0.25))
	for index = -3, 3 do
		strand(
			parts,
			`Hair{index}`,
			hair,
			v(index * 0.17, 3.15, 0.2),
			v(index * 0.05, -0.15, 0.5),
			v(0, -1, -0.1),
			{ segments = 8, step = 0.55, from = 0.28, to = 0.06, bend = 15 }
		)
	end
	strandPair(parts, "Lock", hair, v(0.55, 3.2, -0.35), v(0.2, -0.3, -0.1), v(0, -1, 0.1), {
		segments = 5,
		step = 0.5,
		from = 0.2,
		to = 0.05,
		bend = 35,
	})
	-- Thin arms reaching forward, ending in claws
	blobPair(parts, "Shoulder", skin, v(0.45, 0.45, 0.45), v(0.75, 1.7, 0))
	limbPair(parts, "UpperArm", skin, v(0.75, 1.7, 0), v(1.15, 0.8, -0.4), 0.26)
	limbPair(parts, "Forearm", skin, v(1.15, 0.8, -0.4), v(0.9, 0.6, -1.4), 0.2)
	blobPair(parts, "Hand", skinDark, v(0.3, 0.4, 0.3), v(0.9, 0.5, -1.5))
	for claw = 1, 4 do
		local spread = (claw - 2.5) * 0.1
		local from = v(0.9 + spread, 0.4, -1.55)
		limbPair(parts, `Claw{claw}`, BONE, from, v(0.9 + spread * 1.7, 0.1, -2.15), 0.06)
	end
	-- Feet turned backwards: heels at the front, toes pointing behind her
	limbPair(parts, "Shin", skin, v(0.4, -2.2, 0.1), v(0.4, -2.75, 0.15), 0.22)
	blobPair(parts, "Heel", skinDark, v(0.35, 0.35, 0.35), v(0.4, -2.8, -0.15))
	blobPair(parts, "Foot", skinDark, v(0.45, 0.22, 0.95), v(0.4, -2.85, 0.35))
	for toe = -1, 1 do
		local x = 0.4 + toe * 0.13
		limbPair(parts, `Toe{toe}`, BONE, v(x, -2.88, 0.75), v(x, -2.88, 1.05), 0.1)
	end
	return parts
end

-- Daayan: a witch from village folk tales. Hunched and gaunt in a ragged purple shawl, with wild
-- grey hair, a hooked nose, glowing violet eyes and a gnarled staff topped with a curse-orb.
-- Her free hand is raised, casting.
local function daayan(): { BodyPart }
	local skin = Color3.fromRGB(150, 128, 112)
	local skinDark = Color3.fromRGB(104, 86, 78)
	local shawl = Color3.fromRGB(78, 44, 100)
	local shawlDark = Color3.fromRGB(46, 28, 64)
	local hair = Color3.fromRGB(196, 196, 204)
	local hollow = Color3.fromRGB(28, 18, 34)
	local wood = Color3.fromRGB(82, 58, 40)
	local glow = Color3.fromRGB(170, 90, 255)
	local eye = Color3.fromRGB(200, 130, 255)

	local parts: { BodyPart } = {}
	-- Robe and shawl, hunched forward
	blob(parts, "Skirt", shawlDark, v(2.4, 3.4, 2), v(0, -1.2, 0.05), nil, CLOTH)
	blob(parts, "Flare", shawl, v(2.8, 1.2, 2.2), v(0, -2.2, 0.05), nil, CLOTH)
	blob(parts, "Torso", shawl, v(1.8, 2.2, 1.3), v(0, 0.9, 0.1), v(-12, 0, 0), CLOTH)
	blob(parts, "Hump", shawlDark, v(1.3, 1.3, 1.1), v(0, 1.7, 0.5), v(-20, 0, 0), CLOTH)
	blob(parts, "Shawl", shawl, v(2.5, 0.7, 1.7), v(0, 1.95, 0), nil, CLOTH)
	blob(parts, "ShawlTail", shawlDark, v(1.4, 2.6, 0.15), v(0, 0.4, 0.95), nil, CLOTH)
	blobPair(parts, "Foot", skinDark, v(0.5, 0.2, 0.9), v(0.6, -2.85, -0.3))
	-- Head: hooked nose, glowing eyes and a crooked grin
	limb(parts, "Neck", skin, v(0, 2, 0), v(0, 2.45, -0.5), 0.35)
	blob(parts, "HairBack", hair, v(1.5, 1.9, 0.7), v(0, 2.8, -0.2))
	blob(parts, "Head", skin, v(1.1, 1.35, 1.15), v(0, 2.85, -0.65))
	blob(parts, "Chin", skin, v(0.45, 0.55, 0.5), v(0, 2.3, -1))
	blobPair(parts, "Brow", skinDark, v(0.5, 0.15, 0.25), v(0.28, 3.15, -1.15), v(0, 0, 15))
	blobPair(parts, "Socket", hollow, v(0.38, 0.28, 0.2), v(0.27, 2.95, -1.18))
	blobPair(parts, "Eye", eye, v(0.22, 0.22, 0.16), v(0.27, 2.95, -1.25), nil, NEON)
	strand(parts, "Nose", skin, v(0, 2.8, -1.2), v(0, -0.2, -1), v(0, -1, 0), {
		segments = 3,
		step = 0.22,
		from = 0.24,
		to = 0.1,
		bend = 30,
	})
	blob(parts, "Mouth", hollow, v(0.6, 0.15, 0.15), v(0, 2.5, -1.2))
	blobPair(parts, "Tooth", BONE, v(0.08, 0.2, 0.08), v(0.12, 2.43, -1.27))
	blobPair(parts, "Wart", skinDark, v(0.1, 0.1, 0.1), v(0.4, 2.65, -1.1))
	-- Long grey hair hanging down her back, with locks framing the face
	for index = -3, 3 do
		strand(
			parts,
			`Hair{index}`,
			hair,
			v(index * 0.17, 3.4, -0.4),
			v(index * 0.05, -0.15, 0.5),
			v(0, -1, -0.1),
			{ segments = 8, step = 0.55, from = 0.28, to = 0.06, bend = 15 }
		)
	end
	strandPair(parts, "Lock", hair, v(0.55, 3.3, -0.75), v(0.2, -0.3, -0.1), v(0, -1, 0.1), {
		segments = 5,
		step = 0.5,
		from = 0.2,
		to = 0.05,
		bend = 35,
	})
	blobPair(parts, "Shoulder", shawl, v(0.6, 0.6, 0.6), v(0.95, 1.8, 0.1))
	-- Right arm holds the staff
	limb(parts, "UpperArmR", skin, v(0.95, 1.8, 0.1), v(1.35, 0.8, -0.3), 0.28)
	limb(parts, "ForearmR", skin, v(1.35, 0.8, -0.3), v(1.5, 0.85, -0.95), 0.22)
	blob(parts, "HandR", skinDark, v(0.4, 0.4, 0.4), v(1.5, 0.9, -1))
	limb(parts, "Staff", wood, v(1.5, -2.85, -0.95), v(1.6, 3.7, -1.1), 0.24)
	blob(parts, "StaffKnot", wood, v(0.42, 0.42, 0.42), v(1.55, 1.9, -1.05))
	local top = v(1.6, 3.6, -1.1)
	local sides = { v(1, 0, 0), v(-1, 0, 0), v(0, 0, 1), v(0, 0, -1) }
	for index, side in sides do
		local spec = { segments = 3, step = 0.3, from = 0.13, to = 0.07, bend = 30 }
		strand(parts, `Prong{index}`, wood, top, v(side.X * 0.6, 1, side.Z * 0.6), -side, spec)
	end
	blob(parts, "Orb", glow, v(0.9, 0.9, 0.9), v(1.6, 4.3, -1.1), nil, NEON)
	-- Left hand raised, a curse gathering above the fingers
	limb(parts, "UpperArmL", skin, v(-0.95, 1.8, 0.1), v(-1.5, 1.4, -0.5), 0.26)
	limb(parts, "ForearmL", skin, v(-1.5, 1.4, -0.5), v(-1.3, 2.3, -1.2), 0.2)
	blob(parts, "HandL", skinDark, v(0.4, 0.45, 0.3), v(-1.3, 2.5, -1.3))
	for finger = 1, 4 do
		local spread = (finger - 2.5) * 0.12
		local from = v(-1.3 + spread, 2.7, -1.3)
		limb(parts, `Finger{finger}`, skinDark, from, v(-1.3 + spread * 1.8, 3.3, -1.5), 0.07)
	end
	blob(parts, "CastGlow", glow, v(0.5, 0.5, 0.5), v(-1.3, 3, -1.8), nil, NEON)
	return parts
end

type OgrePalette = {
	skin: Color3,
	dark: Color3,
	cloth: Color3, -- waist cloth
	armor: Color3, -- main armor plates
	trim: Color3, -- armor edges and jewellery
	metal: Color3, -- blades and spikes
	wood: Color3,
	hair: Color3,
	glow: Color3, -- eyes
}

local LEATHER = Enum.Material.Leather
local METAL = Enum.Material.Metal

-- The body shared by the Tusked Brute and the Rage King: a huge, fierce demon with a heavy brow,
-- glowing eyes, boar-like tusks and a thick moustache. Each wears different armor on top.
local function ogre(p: OgrePalette, withHair: boolean, withHorns: boolean): { BodyPart }
	local parts: { BodyPart } = {}
	-- Torso: broad shoulders tapering to the waist (armor covers most of it)
	blob(parts, "Chest", p.skin, v(3.2, 2.6, 1.8), v(0, 1.3, 0), v(-6, 0, 0))
	blob(parts, "Belly", p.dark, v(1.9, 1.6, 1.2), v(0, -0.4, -0.2))
	blob(parts, "Hips", p.dark, v(2.2, 1.1, 1.5), v(0, -1.4, 0))
	-- Arms
	blobPair(parts, "Shoulder", p.skin, v(1.3, 1.3, 1.3), v(2, 2.3, 0))
	limbPair(parts, "UpperArm", p.skin, v(2, 2.2, 0), v(2.5, 0.6, -0.25), 1.15)
	limbPair(parts, "Forearm", p.skin, v(2.5, 0.6, -0.25), v(2.45, -0.9, -0.6), 0.95)
	blobPair(parts, "Fist", p.dark, v(1, 1, 1), v(2.45, -1.3, -0.65))
	-- Head and face
	blob(parts, "Neck", p.skin, v(1.3, 0.9, 1.2), v(0, 2.9, -0.1))
	blob(parts, "Head", p.skin, v(1.8, 1.7, 1.6), v(0, 3.6, -0.25))
	blob(parts, "Jaw", p.dark, v(1.6, 0.8, 1.4), v(0, 3.05, -0.35))
	blobPair(parts, "Brow", p.dark, v(0.95, 0.35, 0.55), v(0.5, 3.95, -0.95), v(0, 0, 22))
	blobPair(parts, "Eye", p.glow, v(0.42, 0.24, 0.2), v(0.5, 3.75, -1), v(0, 0, 10), NEON)
	blob(parts, "Nose", p.skin, v(0.6, 0.7, 0.5), v(0, 3.5, -1.1))
	blob(parts, "Mouth", p.dark, v(1.1, 0.25, 0.3), v(0, 3, -1))
	strandPair(parts, "Tusk", BONE, v(0.5, 2.95, -0.95), v(0.1, 1, -0.35), v(1, 0.3, 0), {
		segments = 3,
		step = 0.4,
		from = 0.3,
		to = 0.08,
		bend = 20,
	})
	strandPair(parts, "Moustache", p.hair, v(0.2, 3.2, -1.1), v(1, -0.3, -0.3), v(0, -1, 0), {
		segments = 3,
		step = 0.35,
		from = 0.18,
		to = 0.06,
		bend = 25,
	})
	strandPair(parts, "Ear", p.skin, v(0.9, 3.75, -0.2), v(1, 0.4, 0), v(0, 1, 0), {
		segments = 3,
		step = 0.3,
		from = 0.32,
		to = 0.08,
		bend = 20,
	})
	blobPair(parts, "Earring", p.trim, v(0.18, 0.45, 0.1), v(1.1, 3.4, -0.2))
	if withHorns then
		strandPair(parts, "Horn", BONE, v(0.65, 4.3, -0.25), v(0.3, 1, -0.15), v(-1, 0.3, 0), {
			segments = 5,
			step = 0.45,
			from = 0.4,
			to = 0.07,
			bend = 22,
		})
	end
	if withHair then
		-- Hair swept back from the crown
		for index = -3, 3 do
			strand(
				parts,
				`Hair{index}`,
				p.hair,
				v(index * 0.22, 4.35, -0.1),
				v(index * 0.08, 0.5, 1),
				v(0, -1, 0),
				{ segments = 4, step = 0.5, from = 0.24, to = 0.06, bend = 30 }
			)
		end
	end
	-- Waist cloth and legs
	blob(parts, "Cloth", p.cloth, v(2.5, 1.3, 1.8), v(0, -2, 0), nil, CLOTH)
	blob(parts, "ClothFront", p.cloth, v(1.5, 1.8, 0.2), v(0, -2.7, -0.9), nil, CLOTH)
	plate(parts, "ClothTrim", p.trim, v(1.5, 0.15, 0.25), v(0, -3.6, -0.9))
	limbPair(parts, "Thigh", p.skin, v(0.9, -1.8, 0), v(1, -3, -0.3), 1.3)
	limbPair(parts, "Shin", p.skin, v(1, -3, -0.3), v(1, -3.8, 0), 1.05)
	blobPair(parts, "Foot", p.dark, v(1.2, 0.5, 2), v(1, -3.75, -0.4))
	for toe = -1, 1 do
		local from = v(1 + toe * 0.35, -3.8, -1.2)
		limbPair(parts, `Toe{toe}`, p.dark, from, v(1 + toe * 0.35, -3.8, -1.75), 0.3)
	end
	return parts
end

-- Tusked Brute: blue-skinned, in layered leather and bronze, carrying a spiked club.
local function rakshasa(): { BodyPart }
	local p: OgrePalette = {
		skin = Color3.fromRGB(64, 84, 142),
		dark = Color3.fromRGB(42, 54, 100),
		cloth = Color3.fromRGB(104, 62, 44),
		armor = Color3.fromRGB(132, 92, 58),
		trim = Color3.fromRGB(190, 134, 62),
		metal = Color3.fromRGB(120, 120, 132),
		wood = Color3.fromRGB(98, 68, 42),
		hair = Color3.fromRGB(20, 18, 30),
		glow = Color3.fromRGB(255, 205, 70),
	}
	local parts = ogre(p, true, true)
	local tilt = v(-6, 0, 0)
	-- Chest guard: overlapping leather bands that follow the curve of the chest
	for band = 1, 5 do
		local y = 0.5 + (band - 1) * 0.45
		local around = math.sqrt(1 - ((y - 1.3) / 1.3) ^ 2)
		local width = 2 * 1.6 * around * 0.95
		local z = -0.9 * around - 0.1
		plate(parts, `ChestBand{band}`, p.armor, v(width, 0.5, 0.22), v(0, y, z), tilt, LEATHER)
		plate(
			parts,
			`ChestEdge{band}`,
			p.trim,
			v(width, 0.07, 0.26),
			v(0, y - 0.24, z),
			tilt,
			METAL
		)
	end
	bar(parts, "ChestStrap", p.cloth, v(-1.4, 2.7, -0.7), v(1.2, 0.4, -0.95), 0.3, LEATHER)
	-- Layered bronze shoulder guards with a spike, and bronze bracers
	for tier = 1, 3 do
		local size = v(2.2 - 0.3 * tier, 0.22, 2 - 0.25 * tier)
		local at = v(2 + 0.25 * tier, 2.85 - 0.3 * tier, 0)
		local color = if tier % 2 == 1 then p.trim else p.armor
		platePair(parts, `Pauldron{tier}`, color, size, at, v(0, 0, -(10 + 6 * tier)), METAL)
	end
	strandPair(parts, "ShoulderSpike", p.metal, v(2.3, 3, 0), v(0.3, 1, 0), v(-1, 0, 0), {
		segments = 2,
		step = 0.45,
		from = 0.3,
		to = 0.08,
		bend = 15,
	})
	barPair(parts, "Bracer", p.trim, v(2.49, 0.2, -0.35), v(2.46, -0.4, -0.5), 1.05, METAL)
	-- Studded belt
	plate(parts, "Belt", p.cloth, v(2.5, 0.45, 1.7), v(0, -1.35, 0), nil, LEATHER)
	plate(parts, "Buckle", p.trim, v(0.7, 0.6, 0.12), v(0, -1.35, -0.88), nil, METAL)
	-- Spiked wooden club in the right hand, getting thicker towards the top
	strand(parts, "Club", p.wood, v(2.5, -1.4, -0.65), v(0.15, 1, -0.12), v(0, 0, 1), {
		segments = 5,
		step = 0.95,
		from = 0.3,
		to = 0.85,
		bend = 0,
	})
	local head = v(3.12, 2.72, -1.16)
	local studs = { v(1, 0, 0), v(-1, 0, 0), v(0, 0, 1), v(0, 0, -1), v(0, 1, 0) }
	for index, direction in studs do
		local from = head + direction * 0.55
		limb(parts, `ClubSpike{index}`, p.metal, from, head + direction * 1.15, 0.22, METAL)
	end
	return parts
end

-- The Rage King: red-skinned and crowned, in black iron with gold trim and a mane of flame.
-- It is the Brute's body, made bigger, with a great axe in place of the club.
local function krodha(): { BodyPart }
	local p: OgrePalette = {
		skin = Color3.fromRGB(150, 30, 34),
		dark = Color3.fromRGB(96, 20, 26),
		cloth = Color3.fromRGB(46, 24, 30),
		armor = Color3.fromRGB(38, 36, 46),
		trim = Color3.fromRGB(236, 186, 70),
		metal = Color3.fromRGB(168, 172, 186),
		wood = Color3.fromRGB(60, 40, 30),
		hair = Color3.fromRGB(30, 12, 12),
		glow = Color3.fromRGB(255, 235, 120),
	}
	local parts = ogre(p, false, false)
	local tilt = v(-6, 0, 0)
	-- One big breastplate with a gold border and chevron, and a gold collar
	plate(parts, "BreastBorder", p.trim, v(2.6, 1.9, 0.3), v(0, 1.5, -0.74), tilt, METAL)
	plate(parts, "Breastplate", p.armor, v(2.4, 1.7, 0.4), v(0, 1.5, -0.8), tilt, METAL)
	barPair(parts, "Chevron", p.trim, v(1.05, 2.1, -1.02), v(0, 0.9, -1.04), 0.13, METAL)
	plate(parts, "Collar", p.trim, v(2.1, 0.3, 1.7), v(0, 2.75, -0.05), nil, METAL)
	-- Domed shoulder guards with gold rims and spikes, and gold armlets
	platePair(parts, "Pauldron", p.armor, v(2.4, 1, 2.3), v(2.15, 2.85, 0), v(0, 0, -26), METAL)
	platePair(parts, "PauldronRim", p.trim, v(2.5, 0.16, 2.4), v(2.35, 2.4, 0), v(0, 0, -26), METAL)
	for index, z in { -0.55, 0.55 } do
		local spec = { segments = 2, step = 0.5, from = 0.35, to = 0.08, bend = 12 }
		local at = v(2.6, 3.15, z)
		strandPair(parts, `ShoulderSpike{index}`, p.metal, at, v(0.3, 1, 0), v(-1, 0, 0), spec)
	end
	platePair(parts, "Armlet", p.trim, v(1.5, 0.28, 1.5), v(2.3, 1.5, -0.1), v(0, 0, -12), METAL)
	-- Black bracer sleeves, gauntlets and greaves, with gold rings at the wrists
	limbPair(parts, "Bracer", p.armor, v(2.5, 0.45, -0.3), v(2.45, -0.7, -0.58), 1.1, METAL)
	platePair(parts, "BracerRing", p.trim, v(1.2, 0.2, 1.2), v(2.46, -0.78, -0.6), nil, METAL)
	platePair(parts, "Knuckle", p.armor, v(0.95, 1.15, 1), v(2.45, -1.3, -0.65), nil, METAL)
	limbPair(parts, "Greave", p.armor, v(1, -2.7, -0.3), v(1, -3.5, -0.05), 1.2, METAL)
	-- Belt and a skirt of overlapping hanging plates, edged in gold
	plate(parts, "Belt", p.armor, v(2.6, 0.5, 1.8), v(0, -1.35, 0), nil, METAL)
	plate(parts, "Buckle", p.trim, v(0.7, 0.7, 0.15), v(0, -1.35, -0.93), v(0, 0, 45), METAL)
	for index = 1, 5 do
		local x = (index - 3) * 0.55
		local swing = v(8, 0, (3 - index) * 4)
		plate(parts, `Fauld{index}`, p.armor, v(0.75, 1.4, 0.14), v(x, -2.4, -0.98), swing, METAL)
	end
	plate(parts, "FauldEdge", p.trim, v(2.9, 0.1, 0.18), v(0, -3.05, -1.1), nil, METAL)
	-- Spiked gold crown between big swept-forward horns, and a mane of flame
	plate(parts, "CrownBand", p.trim, v(1.8, 0.28, 1.55), v(0, 4.18, -0.25), nil, METAL)
	for index = -1, 1 do
		local spec = { segments = 2, step = 0.3, from = 0.18, to = 0.06, bend = 0 }
		local at = v(index * 0.4, 4.3, -0.55)
		strand(parts, `CrownSpike{index}`, p.trim, at, v(0, 1, 0), v(0, 0, 1), spec, METAL)
	end
	strandPair(parts, "BigHorn", BONE, v(0.86, 4.1, -0.26), v(0.9, 0.9, -0.1), v(-0.6, 0.5, 0), {
		segments = 5,
		step = 0.4,
		from = 0.34,
		to = 0.06,
		bend = 25,
	})
	for index = -4, 4 do
		local orange = Color3.fromRGB(255, 110, 30)
		local yellow = Color3.fromRGB(255, 190, 50)
		local spec = { segments = 4, step = 0.46, from = 0.4, to = 0.07, bend = 15 }
		local at = v(index * 0.34, 3.8, 0.6)
		local color = if index % 2 == 0 then orange else yellow
		strand(parts, `Flame{index}`, color, at, v(index * 0.25, 1, 0.5), v(0, 0, 1), spec, NEON)
	end
	-- Great axe in the right hand: a long shaft and a curved double blade
	limb(parts, "AxeShaft", p.wood, v(2.45, -1.5, -0.65), v(3, 3.4, -1), 0.28)
	plate(parts, "AxeSocket", p.armor, v(0.6, 1, 0.5), v(3.05, 2.6, -1), nil, METAL)
	plate(parts, "AxeBlade", p.metal, v(1.5, 2.5, 0.16), v(3.95, 2.6, -1), nil, METAL)
	plate(parts, "AxeBevel", p.armor, v(0.9, 1.7, 0.2), v(3.75, 2.6, -1), nil, METAL)
	bar(parts, "AxeSpike", p.metal, v(3, 2.6, -1), v(2.2, 2.6, -1), 0.22, METAL)
	return scaled(parts, 1.75)
end

local EnemyLooks: { [string]: { BodyPart } } = {
	Pishacha = pishacha(),
	Vetala = vetala(),
	Chudail = chudail(),
	Daayan = daayan(),
	Rakshasa = rakshasa(),
	Krodha = krodha(),
}

return EnemyLooks
