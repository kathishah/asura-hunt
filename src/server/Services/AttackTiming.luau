--!strict
-- The timing of one enemy's attack: wait for the cooldown, telegraph (wind up), then strike.
-- It only decides what happens next. EnemyService draws the telegraph and applies the damage, and
-- tests can check the timing without Roblox.
--
-- A telegraphed attack that finds its target out of reach when the windup ends is cancelled, so
-- stepping back or dodging out of range really does avoid it.

export type Timer = {
	nextAttackAt: number,
	windupEndsAt: number?,
}

export type Action = "none" | "windup" | "strike" | "cancel"

local AttackTiming = {}

-- Call every AI tick with whether the target is in reach. `windup` is seconds (nil or 0 for none).
function AttackTiming.update(
	timer: Timer,
	now: number,
	inReach: boolean,
	windup: number?,
	cooldown: number
): Action
	local endsAt = timer.windupEndsAt
	if endsAt then
		if not inReach then
			timer.windupEndsAt = nil
			timer.nextAttackAt = now + cooldown * 0.5 -- it whiffed; a short pause before trying again
			return "cancel"
		end
		if now >= endsAt then
			timer.windupEndsAt = nil
			timer.nextAttackAt = now + cooldown
			return "strike"
		end
		return "none"
	end

	if not inReach or now < timer.nextAttackAt then
		return "none"
	end

	if windup and windup > 0 then
		timer.windupEndsAt = now + windup
		return "windup"
	end
	timer.nextAttackAt = now + cooldown
	return "strike"
end

return AttackTiming
