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
	-- The bar under an enemy's name that shrinks as it loses health.
	HEALTH_BAR = {
		width = 120, -- pixels
		height = 9,
		boss = { width = 180, height = 12 },
		back = Color3.fromRGB(25, 20, 28),
		-- The fill takes the first colour whose `upTo` fraction it is at or below, so it goes from
		-- green to yellow to red as health drops.
		colors = {
			{ upTo = 0.25, color = Color3.fromRGB(220, 60, 50) },
			{ upTo = 0.5, color = Color3.fromRGB(235, 190, 60) },
			{ upTo = 1, color = Color3.fromRGB(90, 200, 90) },
		},
		smoothSeconds = 0.15, -- how quickly the bar slides to its new length
	},
}

return Effects
