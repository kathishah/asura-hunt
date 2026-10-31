-- M1: enemy attack timing and telegraph config.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness, task = t.check, t.section, t.harness, t.task

	-- M1: enemy telegraphs ------------------------------------------------------------------------
	section("Attack timing")
	do
		local world = harness.newWorld()
		local AttackTiming = world.load("server/Services/AttackTiming")

		-- With no windup an enemy strikes as soon as the cooldown allows.
		local plain = { nextAttackAt = 0 }
		check(
			"no windup: strikes at once",
			AttackTiming.update(plain, 10, true, nil, 2) == "strike"
		)
		check(
			"no windup: then waits out the cooldown",
			AttackTiming.update(plain, 11, true, nil, 2) == "none"
		)
		check(
			"no windup: strikes again after the cooldown",
			AttackTiming.update(plain, 12.1, true, nil, 2) == "strike"
		)
		check(
			"a zero windup counts as no windup",
			AttackTiming.update({ nextAttackAt = 0 }, 1, true, 0, 2) == "strike"
		)

		-- With a windup: telegraph first, strike when it ends.
		local timer = { nextAttackAt = 0 }
		check(
			"windup: starts telegraphing",
			AttackTiming.update(timer, 10, true, 0.5, 2) == "windup"
		)
		check(
			"windup: does not strike early",
			AttackTiming.update(timer, 10.25, true, 0.5, 2) == "none"
		)
		check(
			"windup: strikes when it ends",
			AttackTiming.update(timer, 10.5, true, 0.5, 2) == "strike"
		)
		check(
			"windup: the cooldown starts at the strike",
			timer.nextAttackAt == 12.5,
			timer.nextAttackAt
		)
		check(
			"windup: no new windup during the cooldown",
			AttackTiming.update(timer, 11, true, 0.5, 2) == "none"
		)
		check(
			"windup: telegraphs again after the cooldown",
			AttackTiming.update(timer, 12.6, true, 0.5, 2) == "windup"
		)

		-- Stepping out of reach during the windup avoids the attack.
		local dodged = { nextAttackAt = 0 }
		AttackTiming.update(dodged, 20, true, 0.5, 2)
		check(
			"a target that steps away cancels the attack",
			AttackTiming.update(dodged, 20.25, false, 0.5, 2) == "cancel"
		)
		check("a cancelled windup is cleared", dodged.windupEndsAt == nil)
		check(
			"a cancelled attack is not an instant retry",
			AttackTiming.update(dodged, 20.3, true, 0.5, 2) == "none"
		)
		check(
			"a cancelled attack can try again after a short pause",
			AttackTiming.update(dodged, 21.5, true, 0.5, 2) == "windup"
		)

		check(
			"out of reach with no windup does nothing",
			AttackTiming.update({ nextAttackAt = 0 }, 5, false, 0.5, 2) == "none"
		)

		local Enemies = world.load("shared/Config/Enemies")
		local allHaveWindup = true
		for _, def in Enemies do
			if
				not def.attackWindup
				or def.attackWindup <= 0
				or def.attackWindup >= def.attackCooldown
			then
				allHaveWindup = false
			end
		end
		check("every enemy has a windup shorter than its cooldown", allHaveWindup)
		check(
			"the boss telegraphs longer than the grunt",
			Enemies.Krodha.attackWindup > Enemies.Pishacha.attackWindup
		)
	end
end
