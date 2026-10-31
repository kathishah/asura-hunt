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

-- Ellipsoids are rounded blobs that can be stretched to any size, so they make soft, organic
-- bodies. Cylinders lie along the X axis, so rotate them 90 degrees on Z to stand upright.
-- Balls must have equal X, Y and Z sizes.
export type PartShape = "Block" | "Ball" | "Cylinder" | "Ellipsoid"

-- One decorative piece of an enemy's body, welded to its hitbox.
export type BodyPart = {
	name: string,
	shape: PartShape,
	color: Color3,
	size: Vector3,
	-- Studs from the hitbox centre. Enemies face -Z, so negative Z is their front.
	offset: Vector3,
	-- Degrees around X, Y and Z.
	rotation: Vector3?,
	material: Enum.Material?,
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
