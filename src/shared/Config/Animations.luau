--!strict
-- How enemies move. Numbers only: change them here instead of in the services.
-- Every animation tilts or shifts the whole body around its feet (see BodyBuilder and
-- EnemyAnimator). "Lean" is in degrees, positive leaning forward and negative leaning backward.
-- "Sink" and "height fraction" are fractions of the enemy's own height, so big and small enemies
-- both look right.

local Animations = {
	-- How a hurt enemy stands. The first step whose `upTo` is at or above its health fraction is used,
	-- so keep the steps from lowest to highest. Healthy (the last step) stands straight.
	POSTURE = {
		steps = {
			{ upTo = 0.3, leanDegrees = 28, sinkFraction = 0.1 }, -- barely standing
			{ upTo = 0.6, leanDegrees = 13, sinkFraction = 0.04 }, -- hunched and hurt
			{ upTo = 1, leanDegrees = 0, sinkFraction = 0 }, -- healthy
		},
		-- Bosses stay more upright, so the big fight still looks threatening.
		bossScale = 0.6,
		changeSeconds = 0.35,
	},
	-- A quick recoil when an enemy is hit.
	FLINCH = {
		leanDegrees = -10,
		pushBackStuds = 0.7,
		outSeconds = 0.05,
		backSeconds = 0.22,
	},
	-- Leaning back to gather strength while the red glow shows.
	WINDUP = {
		leanBackDegrees = 16,
		pullBackStuds = 0.6,
		-- Reaches the pose after this fraction of the windup, then holds it.
		reachFraction = 0.8,
	},
	-- The lunge when the attack lands.
	STRIKE = {
		leanDegrees = 20,
		lungeStuds = 1.6,
		outSeconds = 0.07,
		backSeconds = 0.3,
	},
	-- Falling over after the last hit, lying there for a moment, then sinking out of sight.
	DEATH = {
		fallDegrees = 88,
		fallSeconds = 0.55,
		settleSeconds = 0.18,
		lieSeconds = 1,
		sinkSeconds = 0.7,
		-- Lying down, the body rests a little into the ground; then it sinks by this much more.
		restSinkFraction = 0.04,
		sinkHeightFraction = 0.6,
	},
}

return Animations
