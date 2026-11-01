-- The player's health display: the "85 / 100" text, the bar length and the bar colour.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness = t.check, t.section, t.harness

	section("Player health display")
	do
		local world = harness.newWorld()
		local PlayerHealth = world.load("shared/PlayerHealth")
		local Effects = world.load("shared/Config/Effects")

		check("full health", PlayerHealth.text(100, 100) == "100 / 100")
		check("part health", PlayerHealth.text(85, 100) == "85 / 100")
		check(
			"fractions round up so a living player never reads 0",
			PlayerHealth.text(0.3, 100) == "1 / 100"
		)
		check("dead reads 0", PlayerHealth.text(0, 100) == "0 / 100")
		check("below zero reads 0", PlayerHealth.text(-5, 100) == "0 / 100")
		check("over the max is held at the max", PlayerHealth.text(120, 100) == "100 / 100")
		check("armour raises the max shown", PlayerHealth.text(130, 130) == "130 / 130")
		check("no character yet", PlayerHealth.text(0, 0) == "0 / 0")

		check("bar is full at full health", PlayerHealth.fraction(100, 100) == 1)
		check("bar is half at half health", PlayerHealth.fraction(50, 100) == 0.5)
		check("bar is empty with no max", PlayerHealth.fraction(10, 0) == 0)
		check("bar never goes negative", PlayerHealth.fraction(-4, 100) == 0)

		local colors = Effects.HEALTH_BAR.colors
		check(
			"low health is the first (red) step",
			PlayerHealth.colorFor(0.1, colors) == colors[1].color
		)
		check(
			"middle health is the second (yellow) step",
			PlayerHealth.colorFor(0.4, colors) == colors[2].color
		)
		check(
			"full health is the last (green) step",
			PlayerHealth.colorFor(1, colors) == colors[3].color
		)
	end
end
