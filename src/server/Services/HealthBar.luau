--!strict
-- The numbers behind an enemy's health bar. It has no Roblox objects in it, so it can be tested
-- without Studio. EnemyService draws the bar from these values.

local HealthBar = {}

-- How full the bar is, from 0 to 1.
function HealthBar.fraction(health: number, maxHealth: number): number
	if maxHealth <= 0 then
		return 0
	end
	return math.clamp(health / maxHealth, 0, 1)
end

-- `colors` is the HEALTH_BAR.colors list from Config/Effects, lowest `upTo` first.
function HealthBar.colorFor<T>(fraction: number, colors: { { upTo: number, color: T } }): T
	for _, step in colors do
		if fraction <= step.upTo then
			return step.color
		end
	end
	return colors[#colors].color
end

return HealthBar
