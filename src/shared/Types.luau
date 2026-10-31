--!strict
-- Shared type definitions. This module only exports types; it has no runtime content.

export type PathId = "Yodha" | "Rishi"

export type SkillDef = {
	name: string,
	damageMultiplier: number,
	range: number,
	-- Cosine of the half-angle of the hit cone. 1 = laser-thin, 0 = 180 degrees, -1 = full circle.
	coneDot: number,
	cooldown: number,
}

export type PathDef = {
	displayName: string,
	description: string,
	damageMultiplier: number,
	attackRange: number,
	attackConeDot: number,
	skill: SkillDef,
}

export type Stats = {
	strength: number,
	vitality: number,
}

export type PlayerData = {
	version: number,
	level: number,
	xp: number,
	gold: number,
	statPoints: number,
	path: PathId,
	stats: Stats,
}

export type EnemyDef = {
	id: string,
	displayName: string,
	maxHealth: number,
	damage: number,
	walkSpeed: number,
	aggroRange: number,
	attackRange: number,
	attackCooldown: number,
	xp: number,
	gold: number,
	respawnSeconds: number,
	size: Vector3,
	color: Color3,
	isBoss: boolean?,
}

return {}
