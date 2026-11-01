--!strict
-- Turns an EnemyLooks part list into real Parts welded to a hitbox. Shared by EnemyService (the
-- game) and tools/enemy-gallery.luau (the Studio viewer) so both always draw the same thing.
--
-- Every body part is welded to one small invisible "BodyPivot" at the enemy's feet, and the pivot
-- is welded to the hitbox. Moving that single weld (`PivotWeld`) tilts or shifts the whole body
-- around its feet, which is how EnemyAnimator makes enemies lean, recoil and fall over.

local Types = require(script.Parent.Types)

local BodyBuilder = {}

-- The decorative parts never collide or block attacks. Returns the weld that moves the whole body.
function BodyBuilder.addParts(model: Model, root: BasePart, bodyParts: { Types.BodyPart }): Weld
	local feet = CFrame.new(0, -root.Size.Y / 2, 0)

	local pivot = Instance.new("Part")
	pivot.Name = "BodyPivot"
	pivot.Size = Vector3.one * 0.2
	pivot.Transparency = 1
	pivot.CanCollide = false
	pivot.CanTouch = false
	pivot.CanQuery = false
	pivot.Massless = true
	pivot.CFrame = root.CFrame * feet

	local pivotWeld = Instance.new("Weld")
	pivotWeld.Name = "PivotWeld"
	pivotWeld.Part0 = root
	pivotWeld.Part1 = pivot
	pivotWeld.C0 = feet
	pivotWeld.Parent = pivot
	pivot.Parent = model

	for _, def in bodyParts do
		local part = Instance.new("Part")
		part.Name = def.name
		if def.shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif def.shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		elseif def.shape == "Ellipsoid" then
			-- A sphere mesh stretches with the part's size into a rounded blob.
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
		end
		part.Size = def.size
		part.Color = def.color
		part.Material = def.material or Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true

		local rotation = def.rotation or Vector3.zero
		local relative = CFrame.new(def.offset)
			* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		part.CFrame = root.CFrame * relative

		-- Relative to the pivot at the feet, so the part stays exactly where `relative` puts it.
		local weld = Instance.new("Weld")
		weld.Part0 = pivot
		weld.Part1 = part
		weld.C0 = feet:Inverse() * relative
		weld.Parent = part

		part.Parent = model
	end

	return pivotWeld
end

return BodyBuilder
