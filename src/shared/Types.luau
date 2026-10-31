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
	-- Added in data version 2. Items, equipment and zones are filled in by later milestones.
	inventory: { [string]: number }, -- item id -> how many
	equipped: { [string]: string }, -- slot ("weapon", "armor") -> item id
	unlockedZones: { [string]: boolean }, -- zone id -> true
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

-- A ranged enemy casts a glowing bolt instead of striking in melee. It flies straight at where the
-- target stood when cast, so a moving or dodging player can avoid it.
export type ProjectileDef = {
	speed: number, -- studs per second
	size: number, -- visual diameter in studs
	hitRadius: number, -- how close to the target's centre counts as a hit
	color: Color3,
}

export type ItemSlot = "weapon" | "armor"

export type ItemDef = {
	id: string,
	displayName: string,
	description: string,
	slot: ItemSlot,
	price: number,
	damageMultiplier: number?, -- weapons: multiplies all damage you deal (1 = no change)
	healthBonus: number?, -- armour: extra max health
	paths: { PathId }?, -- weapons only work for these paths; left out means any path
}

export type EnemyDef = {
	id: string,
	-- Easy English name shown to players, with the folklore name as a small subtitle.
	displayName: string,
	folkloreName: string,
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
	projectile: ProjectileDef?,
	-- Which attack behaviour to use (see EnemyBehaviors). Left out, it is "projectile" when the
	-- enemy has a projectile and "melee" otherwise.
	behavior: string?,
}

return {}
