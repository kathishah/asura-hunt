-- The sound list: every sound has what it needs, and every sound the code plays exists.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness = t.check, t.section, t.harness

	section("Sounds")
	do
		local world = harness.newWorld()
		local Sounds = world.load("shared/Config/Sounds")

		check("the hearing distance is positive", Sounds.MAX_DISTANCE > 0)

		local count = 0
		for name, def in Sounds.SOUNDS do
			count += 1
			check(`{name}: has an id (empty means off)`, type(def.id) == "string")
			check(
				`{name}: a set id looks like an asset`,
				def.id == ""
					or def.id:find("^rbxasset://") ~= nil
					or def.id:find("^rbxassetid://") ~= nil,
				def.id
			)
			check(`{name}: volume is between 0 and 2`, def.volume >= 0 and def.volume <= 2)
			check(
				`{name}: pitch jitter keeps speed positive`,
				def.pitchJitter >= 0 and def.pitchJitter < 1
			)
		end
		check("there are sounds", count > 0)

		-- Every sound name the services play. Add a name here when the code starts using a new one.
		for _, name in { "swing", "skill", "dodge", "hurt", "hit", "windup", "death" } do
			check(`the game uses "{name}", so it must exist`, Sounds.SOUNDS[name] ~= nil)
		end
	end
end
