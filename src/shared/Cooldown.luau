--!strict
-- Small helpers for showing a cooldown. The server decides when an ability is ready and publishes
-- that moment; the client only reads it and draws. Times are server times (Workspace's
-- GetServerTimeNow), so both sides agree.

local Cooldown = {}

-- Seconds left until `readyAt`, never below 0. A missing `readyAt` means ready now.
function Cooldown.remaining(readyAt: number?, now: number): number
	if readyAt == nil then
		return 0
	end
	return math.max(readyAt - now, 0)
end

-- How charged the ability is, from 0 (just used) to 1 (ready).
function Cooldown.progress(readyAt: number?, duration: number?, now: number): number
	if readyAt == nil or duration == nil or duration <= 0 then
		return 1
	end
	return math.clamp(1 - Cooldown.remaining(readyAt, now) / duration, 0, 1)
end

-- Text for the countdown: one decimal under 10 seconds, whole seconds above, nothing when ready.
function Cooldown.label(remaining: number): string
	if remaining <= 0 then
		return ""
	end
	if remaining < 10 then
		return string.format("%.1f", remaining)
	end
	return tostring(math.ceil(remaining))
end

return Cooldown
