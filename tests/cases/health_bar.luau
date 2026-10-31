-- Enemy health bar: how full it is and what colour it shows.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness = t.check, t.section, t.harness

	section("Health bar")
	do
		local world = harness.newWorld()
		local HealthBar = world.load("server/Services/HealthBar")
		local Effects = world.load("shared/Config/Effects")
		local colors = Effects.HEALTH_BAR.colors

		check("full health is a full bar", HealthBar.fraction(60, 60) == 1)
		check("half health is half a bar", HealthBar.fraction(30, 60) == 0.5)
		check("no health is an empty bar", HealthBar.fraction(0, 60) == 0)
		check("negative health does not go below empty", HealthBar.fraction(-5, 60) == 0)
		check("overheal does not go past full", HealthBar.fraction(90, 60) == 1)
		check("a zero max health does not divide by zero", HealthBar.fraction(10, 0) == 0)

		check("full health is green", HealthBar.colorFor(1, colors) == colors[3].color)
		check("just over half is green", HealthBar.colorFor(0.51, colors) == colors[3].color)
		check("half health is yellow", HealthBar.colorFor(0.5, colors) == colors[2].color)
		check("a quarter health is red", HealthBar.colorFor(0.25, colors) == colors[1].color)
		check("almost dead is red", HealthBar.colorFor(0.01, colors) == colors[1].color)

		local ordered = true
		for i = 2, #colors do
			if colors[i].upTo <= colors[i - 1].upTo then
				ordered = false
			end
		end
		check("colour steps are listed from lowest to highest", ordered)
		check("the last colour step covers a full bar", colors[#colors].upTo >= 1)
		check(
			"bar sizes are positive",
			Effects.HEALTH_BAR.width > 0
				and Effects.HEALTH_BAR.height > 0
				and Effects.HEALTH_BAR.boss.width > Effects.HEALTH_BAR.width
		)
	end
end
