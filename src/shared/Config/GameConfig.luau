--!strict
-- Global tuning values. Change numbers here instead of hunting through scripts.

local GameConfig = {
	DATASTORE_NAME = "AsuraHuntPlayerData_v1",
	-- Bump this whenever the saved shape changes, and handle the old shape in DataService.reconcile.
	-- 2: added inventory, equipped and unlockedZones.
	-- 3: a stored record carries a `session` lock (which server owns it). Older builds see the
	--    higher version and refuse to save over it, so they cannot bypass the lock.
	DATA_VERSION = 3,
	FIRST_ZONE = "Zone1",
	AUTOSAVE_SECONDS = 60,
	-- A server claims a player's record while they are in it, and autosave keeps the claim fresh.
	-- A claim older than this is from a crashed server and can be taken over.
	SESSION_LOCK_SECONDS = 180,
	-- Joining a second server while the first still holds the claim: wait this long, this many times.
	LOCK_RETRY_SECONDS = 3,
	LOCK_RETRIES = 5,

	MAX_LEVEL = 50,
	STAT_POINTS_PER_LEVEL = 3,
	BASE_HEALTH = 100,

	STAT_SCALING = {
		strengthDamagePerPoint = 0.05, -- +5% damage per Strength point
		vitalityHealthPerPoint = 10, -- +10 max health per Vitality point
		damagePerLevel = 0.03, -- +3% damage per level above 1
	},

	COMBAT = {
		comboLength = 3,
		comboResetSeconds = 1.2,
		attackCooldown = 0.35,
		baseDamage = 10,
		finisherMultiplier = 1.8, -- last hit of the combo
		maxTargetsPerHit = 5,
		-- A swing turns you toward the nearest enemy within this many studs if nobody is in front.
		aimAssistRange = 16,
		dodgeCooldown = 1.5,
		dodgeInvulnerableSeconds = 0.35,
		dodgeDashSpeed = 70,
		dodgeDashSeconds = 0.2,
		-- Small allowance so network jitter never rejects a legitimate input.
		cooldownTolerance = 0.05,
	},
}

-- XP needed to go from `level` to `level + 1`.
function GameConfig.xpToNextLevel(level: number): number
	return math.floor(50 * level ^ 1.5)
end

return GameConfig
