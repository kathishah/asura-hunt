-- Enemy animation tuning: the wounded posture steps and the death timing.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness = t.check, t.section, t.harness

	section("Animations")
	do
		local world = harness.newWorld()
		local Animations = world.load("shared/Config/Animations")
		local Posture = world.load("shared/Posture")
		local steps = Animations.POSTURE.steps

		-- The steps must be ordered, end at full health, and get worse as health drops.
		local ordered, worse = true, true
		for i = 2, #steps do
			if steps[i].upTo <= steps[i - 1].upTo then
				ordered = false
			end
			if steps[i].leanDegrees > steps[i - 1].leanDegrees then
				worse = false
			end
		end
		check("posture steps are listed from lowest to highest health", ordered)
		check("the last step covers full health", steps[#steps].upTo >= 1)
		check("a healthier step never leans more than a hurt one", worse)
		check(
			"healthy enemies stand straight",
			steps[#steps].leanDegrees == 0 and steps[#steps].sinkFraction == 0
		)

		check("full health is the last step", Posture.stage(1, steps) == #steps)
		check("half health is a middle step", Posture.stage(0.5, steps) == 2)
		check("nearly dead is the first step", Posture.stage(0.1, steps) == 1)
		check("no health is the first step", Posture.stage(0, steps) == 1)
		check("negative health is clamped to the first step", Posture.stage(-3, steps) == 1)
		check("overheal is clamped to the last step", Posture.stage(5, steps) == #steps)
		check("exactly on a threshold uses the hurt side", Posture.stage(0.6, steps) == 2)

		local healthyLean = Posture.forHealth(1, steps, 1)
		local hurtLean = Posture.forHealth(0.5, steps, 1)
		local deadLean = Posture.forHealth(0.1, steps, 1)
		check("a hurt enemy leans more than a healthy one", hurtLean > healthyLean)
		check("a nearly dead enemy leans most", deadLean > hurtLean)
		local bossLean = Posture.forHealth(0.1, steps, Animations.POSTURE.bossScale)
		check("a boss stands straighter than a normal enemy", bossLean < deadLean)
		check(
			"the boss scale is between 0 and 1",
			Animations.POSTURE.bossScale > 0 and Animations.POSTURE.bossScale <= 1
		)

		local death = Animations.DEATH
		check(
			"every death time is positive",
			death.fallSeconds > 0
				and death.settleSeconds > 0
				and death.lieSeconds > 0
				and death.sinkSeconds > 0
		)
		check(
			"the fall ends close to lying flat",
			death.fallDegrees >= 80 and death.fallDegrees <= 95
		)
		check(
			"the death total is the sum of its parts",
			math.abs(
				Posture.deathSeconds(death)
					- (
						death.fallSeconds
						+ death.settleSeconds
						+ death.lieSeconds
						+ death.sinkSeconds
					)
			) < 1e-9
		)

		-- The respawn delay of every enemy should outlast its own death animation.
		local Enemies = world.load("shared/Config/Enemies")
		for key, def in Enemies do
			check(
				`{key}: respawns after its death animation`,
				def.respawnSeconds > Posture.deathSeconds(death)
			)
		end

		for name, pose in { FLINCH = Animations.FLINCH, STRIKE = Animations.STRIKE } do
			check(`{name}: times are positive`, pose.outSeconds > 0 and pose.backSeconds > 0)
		end
		check(
			"the windup reach fraction is between 0 and 1",
			Animations.WINDUP.reachFraction > 0 and Animations.WINDUP.reachFraction <= 1
		)
	end
end
