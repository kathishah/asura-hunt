-- Cooldown display maths: how charged an ability is and what the countdown says.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness = t.check, t.section, t.harness

	section("Cooldown display")
	do
		local world = harness.newWorld()
		local Cooldown = world.load("shared/Cooldown")

		check("never used: ready", Cooldown.progress(nil, nil, 100) == 1)
		check("never used: no time left", Cooldown.remaining(nil, 100) == 0)
		check("just used: empty", Cooldown.progress(106, 6, 100) == 0)
		check("halfway: half charged", Cooldown.progress(106, 6, 103) == 0.5)
		check("past the ready time: full", Cooldown.progress(106, 6, 120) == 1)
		check("past the ready time: nothing remaining", Cooldown.remaining(106, 120) == 0)
		check(
			"clock a little behind: still empty, not negative",
			Cooldown.progress(106, 6, 99) == 0
		)
		check("a zero duration is always ready", Cooldown.progress(106, 0, 100) == 1)
		check("remaining counts down", Cooldown.remaining(106, 101) == 5)

		check("ready shows no text", Cooldown.label(0) == "")
		check(
			"under ten seconds shows a decimal",
			Cooldown.label(5.25) == "5.2" or Cooldown.label(5.25) == "5.3"
		)
		check("short time shows a decimal", Cooldown.label(0.4) == "0.4")
		check("ten or more shows whole seconds", Cooldown.label(12.2) == "13")
	end
end
