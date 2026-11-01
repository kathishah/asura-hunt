--!strict
-- Whether a straight line between two points is free of walls and other solid map pieces.
-- Players and enemies never block it, and neither does anything with CanCollide off, so effects
-- and decorations that you can walk through do not either.

local Players = game:GetService("Players")

local LineOfSight = {}

-- Made on first use, so loading this module needs no Roblox (the headless tests load it).
local params: RaycastParams? = nil

-- Rebuilt on every call because characters come and go. Cheap: a hit is checked per target.
local function ignoreList(): { Instance }
	local ignore: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		table.insert(ignore, enemies)
	end
	return ignore
end

function LineOfSight.clear(from: Vector3, to: Vector3): boolean
	local offset = to - from
	if offset.Magnitude < 0.01 then
		return true
	end
	local raycastParams = params
	if not raycastParams then
		raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.RespectCanCollide = true
		params = raycastParams
	end
	raycastParams.FilterDescendantsInstances = ignoreList()
	return workspace:Raycast(from, offset, raycastParams) == nil
end

return LineOfSight
