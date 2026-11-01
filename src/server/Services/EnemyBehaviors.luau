--!strict
-- What an enemy does when a target is in range and its attack is ready.
-- EnemyService decides when to attack; each behaviour here decides how. To add a new way of
-- fighting (a boss pattern, a charge), add a function below and register it in `behaviors`,
-- then set `behavior = "name"` on the enemy in Config/Enemies.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local LineOfSight = require(script.Parent.LineOfSight)

export type Attacker = { def: Types.EnemyDef, root: BasePart }
export type Target = { player: Player, humanoid: Humanoid, root: BasePart }
-- `container` is where any projectile or effect parts are placed.
export type Behavior = (attacker: Attacker, target: Target, container: Instance) -> ()

local EnemyBehaviors = {}

-- Dodge i-frames: CombatService sets the "Invulnerable" attribute on the player.
local function hurt(target: Target, amount: number)
	if not target.player:GetAttribute("Invulnerable") then
		target.humanoid:TakeDamage(amount)
	end
end

-- A direct hit on whoever is in reach.
local function melee(attacker: Attacker, target: Target, _container: Instance)
	hurt(target, attacker.def.damage)
end

-- Fires a glowing bolt at where the target is now. Damage lands on arrival, so the player can
-- dodge by moving or by using the dodge roll's invulnerability.
local function projectile(attacker: Attacker, target: Target, container: Instance)
	local config = attacker.def.projectile
	if not config then
		return
	end

	local root = attacker.root
	local origin = root.Position + Vector3.new(0, attacker.def.size.Y * 0.2, 0)
	local direction = (target.root.Position - origin).Unit
	-- Enemies face -Z, so look at the target before casting.
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude > 0.01 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
	end

	local bolt = Instance.new("Part")
	bolt.Name = "CurseBolt"
	bolt.Shape = Enum.PartType.Ball
	bolt.Size = Vector3.one * config.size
	bolt.Color = config.color
	bolt.Material = Enum.Material.Neon
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanTouch = false
	bolt.CanQuery = false
	bolt.CFrame = CFrame.new(origin)
	bolt.Parent = container

	task.spawn(function()
		local maxTravel = attacker.def.attackRange * 1.5
		local travelled = 0
		while travelled < maxTravel do
			local step = config.speed * RunService.Heartbeat:Wait()
			travelled += step
			local before = bolt.Position
			bolt.Position += direction * step
			-- A wall stops the bolt.
			if not LineOfSight.clear(before, bolt.Position) then
				break
			end
			local closeEnough = (target.root.Position - bolt.Position).Magnitude <= config.hitRadius
			if closeEnough and target.humanoid.Health > 0 then
				hurt(target, attacker.def.damage)
				break
			end
		end
		bolt:Destroy()
	end)
end

local behaviors: { [string]: Behavior } = {
	melee = melee,
	projectile = projectile,
}

-- An enemy's behaviour: its `behavior` field if set, otherwise "projectile" for enemies that have a
-- projectile and "melee" for everyone else.
function EnemyBehaviors.forDef(def: Types.EnemyDef): Behavior
	local name = def.behavior or (if def.projectile then "projectile" else "melee")
	local behavior = behaviors[name]
	if not behavior then
		warn(`[EnemyBehaviors] Unknown behavior "{name}" on {def.id}; using melee`)
		return melee
	end
	return behavior
end

return EnemyBehaviors
