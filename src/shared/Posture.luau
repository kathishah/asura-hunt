--!strict
-- The numbers behind how a hurt enemy stands and how long its death takes. It has no Roblox
-- objects in it, so it can be tested without Studio. EnemyAnimator turns these numbers into moves.

local Posture = {}

type Step = { upTo: number, leanDegrees: number, sinkFraction: number }

-- Which step of `steps` applies at this health fraction (1 is the last, healthy one).
function Posture.stage(fraction: number, steps: { Step }): number
	local clamped = math.clamp(fraction, 0, 1)
	for index, step in steps do
		if clamped <= step.upTo then
			return index
		end
	end
	return #steps
end

-- The lean (degrees) and sink (fraction of height) for this health. `scale` softens the pose, for
-- example for bosses.
function Posture.forHealth(fraction: number, steps: { Step }, scale: number): (number, number)
	local step = steps[Posture.stage(fraction, steps)]
	return step.leanDegrees * scale, step.sinkFraction * scale
end

-- How long the whole death takes, from the first fall to the end of the sink.
function Posture.deathSeconds(death: {
	fallSeconds: number,
	settleSeconds: number,
	lieSeconds: number,
	sinkSeconds: number,
}): number
	return death.fallSeconds + death.settleSeconds + death.lieSeconds + death.sinkSeconds
end

return Posture
