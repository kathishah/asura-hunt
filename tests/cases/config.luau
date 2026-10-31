-- Game config and enemy definitions.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness, task = t.check, t.section, t.harness, t.task

	-- Game config and enemy definitions ---------------------------------------------------------
	section("Config")
	do
		local world = harness.newWorld()
		local GameConfig = world.load("shared/Config/GameConfig")
		check("XP for level 1 is 50", GameConfig.xpToNextLevel(1) == 50)
		check("XP for level 4 is 400", GameConfig.xpToNextLevel(4) == 400)
		check(
			"XP for level 10 is 1581",
			GameConfig.xpToNextLevel(10) == 1581,
			GameConfig.xpToNextLevel(10)
		)

		local Enemies = world.load("shared/Config/Enemies")
		local count = 0
		for key, def in Enemies do
			count += 1
			check(`{key}: id matches its key`, def.id == key)
			check(
				`{key}: has names`,
				type(def.displayName) == "string" and type(def.folkloreName) == "string"
			)
			check(
				`{key}: numbers are positive`,
				def.maxHealth > 0
					and def.damage > 0
					and def.walkSpeed > 0
					and def.attackRange > 0
					and def.attackCooldown > 0
			)
			if def.projectile then
				check(
					`{key}: projectile has speed, size and hit radius`,
					def.projectile.speed > 0
						and def.projectile.size > 0
						and def.projectile.hitRadius > 0
				)
			end
		end
		check("all six enemies are defined", count == 6, count)
		local names = {}
		local unique = true
		for _, def in Enemies do
			if names[def.displayName] then
				unique = false
			end
			names[def.displayName] = true
		end
		check("display names are unique", unique)
	end
end
