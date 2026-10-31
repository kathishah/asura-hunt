--!strict
-- Enemy definitions, inspired by creatures from Indian folklore.
-- Placeholder bodies are generated from `size` and `color`. To use a real model later, put a
-- Model (with a Humanoid and HumanoidRootPart) named exactly like the enemy id into
-- ServerStorage/EnemyModels and EnemyService will clone it instead.

local Types = require(script.Parent.Parent.Types)

local Enemies: { [string]: Types.EnemyDef } = {
	Pishacha = {
		id = "Pishacha",
		displayName = "Hungry Ghoul",
		folkloreName = "Pishacha",
		maxHealth = 60,
		damage = 6,
		walkSpeed = 12,
		aggroRange = 40,
		attackRange = 5,
		attackCooldown = 1.5,
		xp = 10,
		gold = 5,
		respawnSeconds = 8,
		size = Vector3.new(2, 5, 1.5),
		color = Color3.fromRGB(86, 105, 86),
	},
	Vetala = {
		id = "Vetala",
		displayName = "Shroud Walker",
		folkloreName = "Vetala",
		maxHealth = 140,
		damage = 12,
		walkSpeed = 14,
		aggroRange = 50,
		attackRange = 5.5,
		attackCooldown = 1.4,
		xp = 28,
		gold = 12,
		respawnSeconds = 12,
		size = Vector3.new(3, 6, 2),
		color = Color3.fromRGB(96, 78, 120),
	},
	Rakshasa = {
		id = "Rakshasa",
		displayName = "Tusked Brute",
		folkloreName = "Rakshasa",
		maxHealth = 320,
		damage = 22,
		walkSpeed = 15,
		aggroRange = 55,
		attackRange = 6,
		attackCooldown = 1.3,
		xp = 70,
		gold = 30,
		respawnSeconds = 20,
		size = Vector3.new(4, 8, 3),
		color = Color3.fromRGB(140, 40, 40),
	},
	Krodha = {
		id = "Krodha",
		displayName = "The Rage King",
		folkloreName = "Krodha",
		maxHealth = 2500,
		damage = 45,
		walkSpeed = 16,
		aggroRange = 70,
		attackRange = 8,
		attackCooldown = 1.8,
		xp = 800,
		gold = 400,
		respawnSeconds = 300,
		size = Vector3.new(8, 14, 6),
		color = Color3.fromRGB(170, 70, 20),
		isBoss = true,
	},
}

return Enemies
