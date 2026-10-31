--!strict
-- How combat looks. Numbers only: change them here instead of in the services.

local Effects = {
	-- The glowing arc that sweeps out when you swing or use a skill.
	SWING = {
		segments = 7, -- pieces in the arc; more is smoother
		sweepSeconds = 0.1, -- time for the arc to sweep from one side to the other
		fadeSeconds = 0.18, -- how long each piece takes to fade out
		reachFraction = 0.85, -- how far out the arc sits, as a fraction of the swing's range
		thickness = 0.4, -- attack arc thickness in studs
		skillThickness = 0.9,
		attackColor = Color3.fromRGB(255, 244, 214),
		skillColors = {
			Yodha = Color3.fromRGB(255, 140, 40),
			Rishi = Color3.fromRGB(150, 120, 255),
		} :: { [string]: Color3 },
	},
	-- A quick white flash on an enemy when it is hit.
	HIT_FLASH = {
		seconds = 0.12,
		color = Color3.fromRGB(255, 255, 255),
	},
}

return Effects
