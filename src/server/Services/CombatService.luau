--!strict
-- Server-authoritative player combat. Clients only say "I pressed attack / dodge / skill";
-- the server decides cooldowns, hit detection, damage and rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Paths = require(Shared.Config.Paths)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)

local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)

local COMBAT = GameConfig.COMBAT

type CombatState = {
	comboIndex: number,
	lastAttackAt: number,
	nextAttackAt: number,
	nextDodgeAt: number,
	nextSkillAt: number,
}

local states: { [Player]: CombatState } = {}

local CombatService = {}

local function getState(player: Player): CombatState
	local state = states[player]
	if not state then
		state = {
			comboIndex = 0,
			lastAttackAt = 0,
			nextAttackAt = 0,
			nextDodgeAt = 0,
			nextSkillAt = 0,
		}
		states[player] = state
	end
	return state
end

-- Returns the player's root part only if they are alive.
local function getLivingRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function computeDamage(data: Types.PlayerData, multiplier: number): number
	local path = Paths[data.path]
	local scaling = GameConfig.STAT_SCALING
	local strengthBonus = 1 + data.stats.strength * scaling.strengthDamagePerPoint
	local levelBonus = 1 + (data.level - 1) * scaling.damagePerLevel
	return COMBAT.baseDamage * path.damageMultiplier * strengthBonus * levelBonus * multiplier
end

local function strike(
	player: Player,
	root: BasePart,
	range: number,
	coneDot: number,
	damage: number
)
	local damageRemote = Remotes.get("DamageNumber")
	local targets =
		EnemyService.getEnemiesInCone(root.Position, root.CFrame.LookVector, range, coneDot)

	for index, enemy in targets do
		if index > COMBAT.maxTargetsPerHit then
			break
		end
		EnemyService.damage(enemy, damage, player)
		damageRemote:FireClient(player, enemy.root.Position, math.floor(damage + 0.5))
	end
end

local function onAttack(player: Player)
	local data = DataService.get(player)
	local root = getLivingRoot(player)
	if not data or not root then
		return
	end

	local state = getState(player)
	local now = os.clock()
	if now < state.nextAttackAt - COMBAT.cooldownTolerance then
		return
	end
	state.nextAttackAt = now + COMBAT.attackCooldown

	if now - state.lastAttackAt > COMBAT.comboResetSeconds then
		state.comboIndex = 0
	end
	state.comboIndex += 1
	state.lastAttackAt = now

	local multiplier = 1
	if state.comboIndex >= COMBAT.comboLength then
		multiplier = COMBAT.finisherMultiplier
		state.comboIndex = 0
	end

	local path = Paths[data.path]
	strike(player, root, path.attackRange, path.attackConeDot, computeDamage(data, multiplier))
end

local function onSkill(player: Player)
	local data = DataService.get(player)
	local root = getLivingRoot(player)
	if not data or not root then
		return
	end

	local state = getState(player)
	local now = os.clock()
	if now < state.nextSkillAt - COMBAT.cooldownTolerance then
		return
	end

	local skill = Paths[data.path].skill
	state.nextSkillAt = now + skill.cooldown
	strike(player, root, skill.range, skill.coneDot, computeDamage(data, skill.damageMultiplier))
end

local function onDodge(player: Player)
	if not getLivingRoot(player) then
		return
	end

	local state = getState(player)
	local now = os.clock()
	if now < state.nextDodgeAt - COMBAT.cooldownTolerance then
		return
	end
	state.nextDodgeAt = now + COMBAT.dodgeCooldown

	-- The dash itself is played on the client; the server only grants the i-frames.
	player:SetAttribute("Invulnerable", true)
	task.delay(COMBAT.dodgeInvulnerableSeconds, function()
		player:SetAttribute("Invulnerable", nil)
	end)
end

-- Applies level and Vitality bonuses to the character's health.
function CombatService.applyCharacterStats(player: Player, data: Types.PlayerData)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		return
	end

	local newMax = GameConfig.BASE_HEALTH
		+ data.stats.vitality * GameConfig.STAT_SCALING.vitalityHealthPerPoint
	if humanoid.MaxHealth ~= newMax then
		local ratio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 1
		humanoid.MaxHealth = newMax
		humanoid.Health = newMax * ratio
	end
end

-- Pays out XP and gold when a player kills an enemy.
local function onEnemyKilled(player: Player, def: Types.EnemyDef)
	DataService.addRewards(player, def.xp, def.gold)
end

function CombatService.start()
	EnemyService.setKillHandler(onEnemyKilled)

	Remotes.get("Attack").OnServerEvent:Connect(onAttack)
	Remotes.get("UseSkill").OnServerEvent:Connect(onSkill)
	Remotes.get("Dodge").OnServerEvent:Connect(onDodge)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return CombatService
