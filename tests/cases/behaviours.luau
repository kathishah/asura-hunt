-- Enemy attack behaviours.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness, task = t.check, t.section, t.harness, t.task

	-- Enemy attack behaviours --------------------------------------------------------------------
	section("Enemy behaviours")
	do
		local world = harness.newWorld()
		local Enemies = world.load("shared/Config/Enemies")
		local EnemyBehaviors = world.load("server/Services/EnemyBehaviors")

		local function target(invulnerable: boolean)
			local taken = {}
			local humanoid = {
				Health = 100,
				TakeDamage = function(_, amount)
					table.insert(taken, amount)
				end,
			}
			local player = {
				GetAttribute = function(_, name)
					return if name == "Invulnerable" then invulnerable else nil
				end,
			}
			return { player = player, humanoid = humanoid, root = {} }, taken
		end

		local melee = EnemyBehaviors.forDef(Enemies.Pishacha)
		local projectile = EnemyBehaviors.forDef(Enemies.Daayan)
		check("melee enemies use the melee behaviour", melee ~= projectile)
		check(
			"every enemy resolves to a behaviour",
			(function()
				for _, def in Enemies do
					if type(EnemyBehaviors.forDef(def)) ~= "function" then
						return false
					end
				end
				return true
			end)()
		)
		check(
			"an enemy with a projectile uses the projectile behaviour",
			EnemyBehaviors.forDef(Enemies.Daayan) == projectile
		)

		local hit, taken = target(false)
		melee({ def = Enemies.Pishacha, root = {} }, hit, {})
		check("melee deals the enemy's damage", taken[1] == Enemies.Pishacha.damage, taken[1])

		local dodging, dodgeTaken = target(true)
		melee({ def = Enemies.Pishacha, root = {} }, dodging, {})
		check("melee does nothing while the player is dodging", #dodgeTaken == 0)

		local custom = table.clone(Enemies.Pishacha)
		custom.behavior = "does-not-exist"
		check(
			"an unknown behaviour name falls back to melee",
			EnemyBehaviors.forDef(custom) == melee
		)
		custom.behavior = "projectile"
		check(
			"an explicit behaviour name is respected",
			EnemyBehaviors.forDef(custom) == projectile
		)
	end
end
