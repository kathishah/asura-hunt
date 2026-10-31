-- Enemy gallery: shows every enemy on its own pedestal so you can look at each one up close.
--
-- How to use (no Play needed):
--   1. Run `rojo serve` and Connect in Studio, so the latest looks are synced.
--   2. Open the command bar (View > Command Bar), paste this whole file and press Run.
--      Studio warns "Dangerous Command" because the script deletes its own old gallery: press
--      Continue ("Always Continue" stops the warning for every command bar script).
--   3. Orbit with right-click drag, zoom with the scroll wheel, move with W A S D (Shift = slower).
--   4. Click any piece in the 3D view and look in Explorer: its name (like "HairL3" or "Horn2R")
--      is what you tell me when you want that piece changed.
--   5. Set FOCUS below to one id (for example "Chudail") to show only that enemy, bigger.
--   6. Edit EnemyLooks.luau (or ask me), save, and paste this again. It rebuilds from scratch.
--   7. Delete the gallery with:  workspace.EnemyGallery:Destroy()
--
-- Not part of the game: Rojo does not sync this folder.

local FOCUS = nil -- nil = everyone, or an id: "Pishacha", "Vetala", "Chudail", "Daayan", "Rakshasa", "Krodha"
local SPACING = 24 -- studs between enemies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Enemies = require(Shared.Config.Enemies)
local BodyBuilder = require(Shared.BodyBuilder)

-- A fresh copy of EnemyLooks each time, because the command bar remembers modules it already
-- loaded and would show the old shapes after you edit them.
local looksModule = Shared.Config.EnemyLooks:Clone()
looksModule.Parent = Shared.Config
local EnemyLooks = require(looksModule)
looksModule:Destroy()

local old = workspace:FindFirstChild("EnemyGallery")
if old then
	old:Destroy()
end
local gallery = Instance.new("Folder")
gallery.Name = "EnemyGallery"

local ids = {}
for id in Enemies do
	if EnemyLooks[id] and (FOCUS == nil or id == FOCUS) then
		table.insert(ids, id)
	end
end
table.sort(ids, function(a, b)
	return Enemies[a].maxHealth < Enemies[b].maxHealth
end)
if #ids == 0 then
	error(`No enemy with a look called "{FOCUS}"`)
end

local tallest = 0
for index, id in ids do
	local def = Enemies[id]
	local parts = EnemyLooks[id]
	local x = (index - (#ids + 1) / 2) * SPACING

	local model = Instance.new("Model")
	model.Name = `{def.displayName} ({id})`

	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Anchored = true
	pedestal.Size = Vector3.new(math.max(10, def.size.X + 6), 1, math.max(10, def.size.Z + 6))
	pedestal.Color = Color3.fromRGB(70, 70, 78)
	pedestal.Material = Enum.Material.Slate
	pedestal.CFrame = CFrame.new(x, 0.5, 0)
	pedestal.Parent = model

	-- Same invisible hitbox the game uses. Enemies face -Z, so the camera sits at negative Z.
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Transparency = 1
	root.Size = def.size
	root.CFrame = CFrame.new(x, 1 + def.size.Y / 2, 0)
	root.Parent = model
	model.PrimaryPart = root

	BodyBuilder.addParts(model, root, parts)

	local boxCFrame, boxSize = model:GetBoundingBox()
	local top = boxCFrame.Position.Y + boxSize.Y / 2
	tallest = math.max(tallest, top)

	local label = Instance.new("BillboardGui")
	label.Adornee = root
	label.Size = UDim2.fromOffset(240, 64)
	label.StudsOffsetWorldSpace = Vector3.new(0, top - root.Position.Y + 2, 0)
	label.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.3
	text.Font = Enum.Font.GothamBold
	text.TextSize = 16
	text.Text = `{def.displayName}\n{id}  ({#parts} pieces)`
	text.Parent = label
	label.Parent = model

	model.Parent = gallery
end
gallery.Parent = workspace

local width = #ids * SPACING
local distance = math.max(tallest * 2.5, width * 0.5)
local camera = workspace.CurrentCamera
camera.CFrame =
	CFrame.lookAt(Vector3.new(0, tallest * 0.55 + 2, -distance), Vector3.new(0, tallest * 0.45, 0))
print(`[EnemyGallery] {#ids} enemies built. Click a piece and read its name in Explorer.`)
