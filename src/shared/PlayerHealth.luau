--!strict
-- What the player's own health display shows. It has no Roblox objects in it, so it can be tested
-- without Studio. UI/PlayerHealth draws the bar from these values.

local PlayerHealth = {}

-- "85 / 100". Health rounds up so a living player never reads 0; only death shows 0.
function PlayerHealth.text(health: number, maxHealth: number): string
	local max = math.max(math.floor(maxHealth + 0.5), 0)
	local current = math.clamp(math.ceil(health), 0, max)
	return `{current} / {max}`
end

-- How full the bar is, from 0 to 1.
function PlayerHealth.fraction(health: number, maxHealth: number): number
	if maxHealth <= 0 then
		return 0
	end
	return math.clamp(health / maxHealth, 0, 1)
end

-- `colors` is the HEALTH_BAR.colors list from Config/Effects, lowest `upTo` first.
function PlayerHealth.colorFor<T>(fraction: number, colors: { { upTo: number, color: T } }): T
	for _, step in colors do
		if fraction <= step.upTo then
			return step.color
		end
	end
	return colors[#colors].color
end

return PlayerHealth
