--!strict
-- The two playable paths. Everything here is data: tweak freely, or add a new path
-- (also add its id to PathId in Types.luau and to the checks in DataService).

local Types = require(script.Parent.Parent.Types)

local Paths: { [Types.PathId]: Types.PathDef } = {
	Yodha = {
		displayName = "Yodha",
		description = "Warrior. Fast melee combos and a wide, powerful slash.",
		damageMultiplier = 1.0,
		attackRange = 8,
		attackConeDot = 0.3,
		skill = {
			name = "Jwala Slash",
			damageMultiplier = 3.0,
			range = 12,
			coneDot = -0.2,
			cooldown = 6,
		},
	},
	Rishi = {
		displayName = "Rishi",
		description = "Mantra-caster. Weaker hits, but strikes from a distance.",
		damageMultiplier = 0.8,
		attackRange = 22,
		attackConeDot = 0.85,
		skill = {
			name = "Mantra Bolt",
			damageMultiplier = 3.5,
			range = 45,
			coneDot = 0.92,
			cooldown = 7,
		},
	},
}

return Paths
