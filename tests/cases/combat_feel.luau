-- M1: swing aim assist, effects config and the Brute's reach.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness = t.check, t.section, t.harness

	section("Aim assist")
	do
		local world = harness.newWorld()
		local AimAssist = world.load("server/Services/AimAssist")
		-- Facing -Z, like a Roblox character at the default rotation.
		local lookX, lookZ = 0, -1
		local cone = 0.3

		local x, z = AimAssist.turnTarget({}, lookX, lookZ, cone)
		check("nobody near: no turn", x == nil and z == nil)

		x, z = AimAssist.turnTarget({ { x = 0, z = -5 } }, lookX, lookZ, cone)
		check("enemy in front: no turn", x == nil and z == nil)

		x, z = AimAssist.turnTarget({ { x = 0, z = 5 } }, lookX, lookZ, cone)
		check("enemy behind: turns toward it", x == 0 and z == 5, `{x}, {z}`)

		x, z = AimAssist.turnTarget({ { x = 4, z = 0 } }, lookX, lookZ, cone)
		check("enemy to the side, outside the cone: turns", x == 4 and z == 0)

		-- The nearest is behind but a farther one is in front: the swing already hits someone.
		x, z = AimAssist.turnTarget({ { x = 0, z = 3 }, { x = 0, z = -6 } }, lookX, lookZ, cone)
		check("someone else in front: no turn", x == nil and z == nil)

		x, z = AimAssist.turnTarget({ { x = 0, z = 3 }, { x = 5, z = 5 } }, lookX, lookZ, cone)
		check("all behind: turns toward the nearest", x == 0 and z == 3)

		x, z = AimAssist.turnTarget({ { x = 0, z = 0 } }, lookX, lookZ, cone)
		check("enemy on top of the player: no turn", x == nil and z == nil)

		x, z = AimAssist.turnTarget({ { x = 3, z = 0 } }, 0, 0, cone)
		check("no facing direction: turns toward the enemy", x == 3 and z == 0)

		-- A full-circle skill cone (like Yodha's, -0.2) is satisfied by almost everything.
		x, z = AimAssist.turnTarget({ { x = 4, z = 0 } }, lookX, lookZ, -0.2)
		check("wide cone: side enemy already counts", x == nil and z == nil)
	end

	section("Effects and combat tuning")
	do
		local world = harness.newWorld()
		local Effects = world.load("shared/Config/Effects")
		local GameConfig = world.load("shared/Config/GameConfig")
		local Paths = world.load("shared/Config/Paths")
		local Enemies = world.load("shared/Config/Enemies")

		local swing = Effects.SWING
		check("swing has several pieces", swing.segments >= 3)
		check("swing times are positive", swing.sweepSeconds > 0 and swing.fadeSeconds > 0)
		check(
			"swing reach is a fraction of range",
			swing.reachFraction > 0 and swing.reachFraction <= 1
		)
		check("swing thickness is positive", swing.thickness > 0 and swing.skillThickness > 0)
		for pathId in Paths do
			check(`{pathId} has a skill swing colour`, swing.skillColors[pathId] ~= nil)
		end
		check(
			"hit flash is brief",
			Effects.HIT_FLASH.seconds > 0 and Effects.HIT_FLASH.seconds < 0.5
		)
		check("aim assist range is set", GameConfig.COMBAT.aimAssistRange > 0)

		-- The player starts at the origin; the south-gate Brute stands at (0, -54).
		check(
			"the Brute does not notice a player at the start",
			Enemies.Rakshasa.aggroRange < 54,
			Enemies.Rakshasa.aggroRange
		)
	end
end
