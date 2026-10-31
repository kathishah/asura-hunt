--!strict
-- Global tuning values. Change numbers here instead of hunting through scripts.

local GameConfig = {
	DATASTORE_NAME = "AsuraHuntPlayerData_v1",
	DATA_VERSION = 1,
	AUTOSAVE_SECONDS = 60,

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
