--!strict
-- Turns an EnemyLooks part list into real Parts welded to a hitbox. Shared by EnemyService (the
-- game) and tools/enemy-gallery.luau (the Studio viewer) so both always draw the same thing.

local Types = require(script.Parent.Types)

local BodyBuilder = {}

-- The decorative parts never collide or block attacks.
function BodyBuilder.addParts(model: Model, root: BasePart, bodyParts: { Types.BodyPart })
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

		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = part
		weld.C0 = relative
		weld.Parent = part

		part.Parent = model
	end
end

return BodyBuilder
