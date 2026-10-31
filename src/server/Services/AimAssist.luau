--!strict
-- Decides whether a swing should turn the player toward an enemy first. Clicking does not turn the
-- character, so without this a swing misses whenever you happen to face the wrong way.
-- It works on plain numbers so it can be tested without Roblox.

local AimAssist = {}

-- `offsets` are where enemies stand relative to the player, flat (x, z), nearest first.
-- `lookX`, `lookZ` is the player's flat facing. `coneDot` is the swing's cone (see Types.SkillDef).
-- Returns the (x, z) to turn toward, or nil when nobody is near, or someone is already in the cone.
function AimAssist.turnTarget(
	offsets: { { x: number, z: number } },
	lookX: number,
	lookZ: number,
	coneDot: number
): (number?, number?)
	local nearest = offsets[1]
	if not nearest then
		return nil, nil
	end

	local lookLength = math.sqrt(lookX * lookX + lookZ * lookZ)
	if lookLength < 0.01 then
		return nearest.x, nearest.z
	end

	for _, offset in offsets do
		local length = math.sqrt(offset.x * offset.x + offset.z * offset.z)
		-- Standing right on top of the player counts as in front.
		if length < 0.01 then
			return nil, nil
		end
		local dot = (offset.x * lookX + offset.z * lookZ) / (length * lookLength)
		if dot >= coneDot then
			return nil, nil
		end
	end

	-- Nobody is in the cone: turn toward the nearest. Skip a pointless turn when it is on top of us.
	if nearest.x * nearest.x + nearest.z * nearest.z < 0.01 then
		return nil, nil
	end
	return nearest.x, nearest.z
end

return AimAssist
