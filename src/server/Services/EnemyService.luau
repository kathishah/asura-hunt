--!strict
-- Spawns enemies, runs their simple chase-and-attack AI, and handles their death and respawn.
--
-- Spawn points: tag a Part with "EnemySpawn" (CollectionService) and give it a string attribute
-- "EnemyId" (e.g. "Vetala"). If no tagged parts exist, DEFAULT_SPAWNS below is used instead.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BodyBuilder = require(Shared.BodyBuilder)
local Animations = require(Shared.Config.Animations)
local Effects = require(Shared.Config.Effects)
local Enemies = require(Shared.Config.Enemies)
local EnemyLooks = require(Shared.Config.EnemyLooks)
local Posture = require(Shared.Posture)
local Types = require(Shared.Types)
local AttackTiming = require(script.Parent.AttackTiming)
local EnemyAnimator = require(script.Parent.EnemyAnimator)
local HealthBar = require(script.Parent.HealthBar)
local EnemyBehaviors = require(script.Parent.EnemyBehaviors)
local Sfx = require(script.Parent.Sfx)

local SPAWN_TAG = "EnemySpawn"
local AI_TICK_SECONDS = 0.25
local LEASH_DISTANCE = 120
local HOME_RADIUS = 6
-- A telegraphed attack still lands if the target is just outside normal reach when it ends.
local WINDUP_REACH = 1.15

export type EnemyState = {
	def: Types.EnemyDef,
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	spawnPosition: Vector3,
	nextAttackAt: number,
	windupEndsAt: number?,
	lastAttacker: Player?,
	dead: boolean,
	-- Nil for an enemy built from a custom model, which has no BodyPivot to animate.
	animator: EnemyAnimator.EnemyAnimator?,
}

-- Placed to match the nested courtyards built by tools/build-zone1.luau: easy fights in the outer
-- corridors, harder ones further in, the boss in the inner court.
local DEFAULT_SPAWNS = {
	{ id = "Pishacha", position = Vector3.new(-60, 4, -24) },
	{ id = "Pishacha", position = Vector3.new(60, 4, -24) },
	{ id = "Pishacha", position = Vector3.new(100, 4, -52) },
	{ id = "Chudail", position = Vector3.new(-100, 4, -90) },
	{ id = "Chudail", position = Vector3.new(-100, 4, -150) },
	{ id = "Vetala", position = Vector3.new(97, 4, -115) },
	{ id = "Vetala", position = Vector3.new(97, 4, -165) },
	{ id = "Daayan", position = Vector3.new(-60, 4, -196) },
	{ id = "Daayan", position = Vector3.new(60, 4, -196) },
	{ id = "Rakshasa", position = Vector3.new(0, 4, -54) },
	{ id = "Rakshasa", position = Vector3.new(0, 4, -166) },
	{ id = "Krodha", position = Vector3.new(0, 8, -132) },
}

local EnemyService = {}

local active: { [Model]: EnemyState } = {}
local enemiesFolder: Folder
local killHandler: ((Player, Types.EnemyDef) -> ())? = nil

-- Called when a player lands the killing blow.
function EnemyService.setKillHandler(handler: (Player, Types.EnemyDef) -> ())
	killHandler = handler
end

local function addNameplate(model: Model, root: BasePart, def: Types.EnemyDef, humanoid: Humanoid)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Adornee = root
	local barConfig = Effects.HEALTH_BAR
	local barSize = if def.isBoss then barConfig.boss else barConfig
	gui.Size = UDim2.fromOffset(200, 58)
	-- Sit above the tallest part (horns, flames), not just the hitbox.
	local boxCFrame, boxSize = model:GetBoundingBox()
	local top = math.max(def.size.Y / 2, boxCFrame.Position.Y + boxSize.Y / 2 - root.Position.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, top + 2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.TextColor3 = if def.isBoss then Color3.fromRGB(255, 190, 80) else Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = gui

	-- The health bar sits between the name and the folklore name.
	local back = Instance.new("Frame")
	back.Name = "HealthBack"
	back.AnchorPoint = Vector2.new(0.5, 0)
	back.Position = UDim2.new(0.5, 0, 0, 22)
	back.Size = UDim2.fromOffset(barSize.width, barSize.height)
	back.BackgroundColor3 = barConfig.back
	back.BorderSizePixel = 0
	back.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "HealthFill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = back

	-- The folklore name, small and quiet, so players pick it up over time.
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 16)
	subtitle.Position = UDim2.fromOffset(0, 22 + barSize.height + 2)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = def.folkloreName
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 210)
	subtitle.TextStrokeTransparency = 0.5
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 11
	subtitle.Parent = gui

	local function refresh()
		label.Text =
			`{def.displayName}  {math.ceil(humanoid.Health)}/{math.ceil(humanoid.MaxHealth)}`
		local fraction = HealthBar.fraction(humanoid.Health, humanoid.MaxHealth)
		fill.BackgroundColor3 = HealthBar.colorFor(fraction, barConfig.colors)
		TweenService:Create(
			fill,
			TweenInfo.new(barConfig.smoothSeconds),
			{ Size = UDim2.fromScale(fraction, 1) }
		):Play()
	end
	refresh()
	humanoid.HealthChanged:Connect(refresh)

	gui.Parent = model
end

-- Returns the model and, for a model built from EnemyLooks, the weld that moves its whole body.
local function buildModel(def: Types.EnemyDef, position: Vector3): (Model?, Weld?)
	local enemyModels = ServerStorage:FindFirstChild("EnemyModels")
	local template = if enemyModels then enemyModels:FindFirstChild(def.id) else nil
	if template and template:IsA("Model") then
		local clone = template:Clone()
		clone:PivotTo(CFrame.new(position))
		return clone, nil
	end

	-- Built from EnemyLooks: an invisible hitbox driven by a Humanoid, wearing welded parts.
	-- An enemy with no look listed falls back to a plain coloured block.
	local model = Instance.new("Model")
	model.Name = def.displayName

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = def.size
	root.Color = def.color
	root.Material = Enum.Material.SmoothPlastic
	root.CFrame = CFrame.new(position)
	root.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 0
	humanoid.Parent = model

	model.PrimaryPart = root

	local bodyParts = EnemyLooks[def.id]
	local pivotWeld: Weld? = nil
	if bodyParts then
		root.Transparency = 1
		pivotWeld = BodyBuilder.addParts(model, root, bodyParts)
	end
	return model, pivotWeld
end

local function setupDeath(state: EnemyState)
	state.humanoid.Died:Connect(function()
		if state.dead then
			return
		end
		state.dead = true
		active[state.model] = nil

		local killer = state.lastAttacker
		if killer and killer.Parent == Players and killHandler then
			killHandler(killer, state.def)
		end

		-- Stop where it fell: no more chasing, blocking, glowing or floating name.
		state.windupEndsAt = nil
		state.root.Anchored = true
		state.root.CanCollide = false
		local glow = state.model:FindFirstChild("Telegraph")
		if glow then
			glow:Destroy()
		end
		local nameplate = state.model:FindFirstChild("Nameplate")
		if nameplate and nameplate:IsA("BillboardGui") then
			nameplate.Enabled = false
		end

		-- Fall over, lie there, sink out of sight, then remove the body. A model with no animator
		-- (a custom model) is just removed after a short delay, as before.
		local animator = state.animator
		local removeAfter = 2
		if animator then
			animator:collapse()
			removeAfter = Posture.deathSeconds(Animations.DEATH) + 0.3
		end
		-- The thud is timed for when the body reaches the ground.
		task.delay(if animator then Animations.DEATH.fallSeconds else 0, function()
			Sfx.play("death", state.root)
		end)
		task.delay(removeAfter, function()
			state.model:Destroy()
		end)
		task.delay(state.def.respawnSeconds, function()
			EnemyService.spawn(state.def.id, state.spawnPosition)
		end)
	end)
end

function EnemyService.spawn(enemyId: string, position: Vector3)
	local def = Enemies[enemyId]
	if not def then
		warn(`[EnemyService] Unknown enemy id: {enemyId}`)
		return
	end

	local model, pivotWeld = buildModel(def, position)
	if not model then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		warn(`[EnemyService] Model for {enemyId} needs a Humanoid and a HumanoidRootPart`)
		model:Destroy()
		return
	end

	-- Keep the body together when it dies, so it can fall over instead of coming apart.
	humanoid.BreakJointsOnDeath = false
	humanoid.MaxHealth = def.maxHealth
	humanoid.Health = def.maxHealth
	humanoid.WalkSpeed = def.walkSpeed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	model:SetAttribute("EnemyId", def.id)
	addNameplate(model, root, def, humanoid)
	model.Parent = enemiesFolder

	if not root.Anchored then
		root:SetNetworkOwner(nil) -- the server simulates enemies, not a nearby player
	end

	local state: EnemyState = {
		def = def,
		model = model,
		humanoid = humanoid,
		root = root,
		spawnPosition = position,
		nextAttackAt = 0,
		windupEndsAt = nil,
		lastAttacker = nil,
		dead = false,
		animator = if pivotWeld
			then EnemyAnimator.new(pivotWeld, root.Size.Y, def.isBoss == true)
			else nil,
	}
	active[model] = state
	setupDeath(state)

	-- The more hurt it is, the lower it stands. Healing back up (when it gives up the chase)
	-- straightens it again.
	local animator = state.animator
	if animator then
		humanoid.HealthChanged:Connect(function(health)
			if health > 0 then
				animator:setHealth(health / humanoid.MaxHealth)
			end
		end)
	end
end

-- Enemies in front of `origin`, nearest first.
function EnemyService.getEnemiesInCone(
	origin: Vector3,
	look: Vector3,
	range: number,
	coneDot: number
): { EnemyState }
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then
		return {}
	end
	flatLook = flatLook.Unit

	local found: { { state: EnemyState, distance: number } } = {}
	for _, state in active do
		local offset = state.root.Position - origin
		local flat = Vector3.new(offset.X, 0, offset.Z)
		local distance = flat.Magnitude - state.def.size.X / 2
		if distance <= range then
			local inCone = flat.Magnitude < 0.01 or flatLook:Dot(flat.Unit) >= coneDot
			if inCone then
				table.insert(found, { state = state, distance = distance })
			end
		end
	end

	table.sort(found, function(a, b)
		return a.distance < b.distance
	end)

	local result: { EnemyState } = {}
	for _, entry in found do
		table.insert(result, entry.state)
	end
	return result
end

-- A quick white flash so you can see that a hit landed.
local function flashHit(state: EnemyState)
	if state.model:FindFirstChild("HitFlash") then
		return
	end
	local config = Effects.HIT_FLASH
	local flash = Instance.new("Highlight")
	flash.Name = "HitFlash"
	flash.FillColor = config.color
	flash.FillTransparency = 0.25
	flash.OutlineTransparency = 1
	flash.Parent = state.model
	task.delay(config.seconds, function()
		flash:Destroy()
	end)
end

-- Returns false if the hit was refused because the enemy is already dead.
function EnemyService.damage(state: EnemyState, amount: number, attacker: Player): boolean
	-- `dead` is only set when the Died handler runs, which is deferred. Until then a second hit on
	-- the same frame would pass that check and steal the kill, so health decides too.
	if state.dead or state.humanoid.Health <= 0 then
		return false
	end
	state.lastAttacker = attacker
	state.humanoid:TakeDamage(amount)
	flashHit(state)
	Sfx.play("hit", state.root)
	-- Recoil from the hit, but not while winding up, so the red glow pose stays readable.
	if state.animator and not state.windupEndsAt and state.humanoid.Health > 0 then
		state.animator:flinch()
	end
	return true
end

local function findTarget(state: EnemyState): (Player?, Humanoid?, BasePart?)
	local fromSpawn = (state.root.Position - state.spawnPosition).Magnitude
	if fromSpawn > LEASH_DISTANCE then
		return nil, nil, nil
	end

	local bestPlayer: Player? = nil
	local bestHumanoid: Humanoid? = nil
	local bestRoot: BasePart? = nil
	local bestDistance = state.def.aggroRange

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
				local distance = (root.Position - state.root.Position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					bestPlayer = player
					bestHumanoid = humanoid
					bestRoot = root
				end
			end
		end
	end

	return bestPlayer, bestHumanoid, bestRoot
end

-- A red glow on an enemy that is winding up to strike, so the player can see it coming.
-- Uses Roblox's Highlight; check https://create.roblox.com/docs/reference/engine/classes/Highlight
local function setTelegraph(state: EnemyState, on: boolean)
	local existing = state.model:FindFirstChild("Telegraph")
	if on and not existing then
		local glow = Instance.new("Highlight")
		glow.Name = "Telegraph"
		glow.FillColor = Color3.fromRGB(255, 60, 40)
		glow.FillTransparency = 0.35
		glow.OutlineColor = Color3.fromRGB(255, 200, 80)
		glow.Parent = state.model
	elseif not on and existing then
		existing:Destroy()
	end
end

local function updateEnemy(state: EnemyState)
	if state.dead or state.humanoid.Health <= 0 then
		return
	end

	local player, targetHumanoid, targetRoot = findTarget(state)
	if not player or not targetHumanoid or not targetRoot then
		-- No target: drop any half-finished attack, then walk home and recover.
		if state.windupEndsAt then
			state.windupEndsAt = nil
			setTelegraph(state, false)
		end
		local homeDistance = (state.root.Position - state.spawnPosition).Magnitude
		if homeDistance > HOME_RADIUS then
			state.humanoid:MoveTo(state.spawnPosition)
		elseif state.humanoid.Health < state.humanoid.MaxHealth then
			state.humanoid.Health = state.humanoid.MaxHealth
		end
		return
	end

	local distance = (targetRoot.Position - state.root.Position).Magnitude
	local winding = state.windupEndsAt ~= nil
	local reach = state.def.attackRange * (if winding then WINDUP_REACH else 1)
	local inReach = distance <= reach
	if not inReach and not winding then
		state.humanoid:MoveTo(targetRoot.Position)
		return
	end

	local action = AttackTiming.update(
		state,
		os.clock(),
		inReach,
		state.def.attackWindup,
		state.def.attackCooldown
	)
	if action == "windup" then
		state.humanoid:MoveTo(state.root.Position) -- stand still while telegraphing
		setTelegraph(state, true)
		Sfx.play("windup", state.root)
		if state.animator then
			state.animator:windup(state.def.attackWindup or 0.5)
		end
	elseif action == "cancel" then
		setTelegraph(state, false)
		if state.animator then
			state.animator:recover()
		end
	elseif action == "strike" then
		setTelegraph(state, false)
		if state.animator then
			state.animator:strike()
		end
		local target: EnemyBehaviors.Target = {
			player = player,
			humanoid = targetHumanoid,
			root = targetRoot,
		}
		EnemyBehaviors.forDef(state.def)(state, target, enemiesFolder)
	end
end

local function collectSpawns(): { { id: string, position: Vector3 } }
	local spawns = {}
	for _, instance in CollectionService:GetTagged(SPAWN_TAG) do
		local enemyId = instance:GetAttribute("EnemyId")
		if instance:IsA("BasePart") and type(enemyId) == "string" then
			local def = Enemies[enemyId]
			if def then
				table.insert(spawns, {
					id = enemyId,
					position = instance.Position + Vector3.new(0, def.size.Y / 2 + 2, 0),
				})
			else
				warn(
					`[EnemyService] Spawn {instance:GetFullName()} has unknown EnemyId "{enemyId}"`
				)
			end
		end
	end

	if #spawns == 0 then
		return DEFAULT_SPAWNS
	end
	return spawns
end

function EnemyService.start()
	enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "Enemies"
	enemiesFolder.Parent = workspace

	for _, spawnInfo in collectSpawns() do
		EnemyService.spawn(spawnInfo.id, spawnInfo.position)
	end

	task.spawn(function()
		while true do
			task.wait(AI_TICK_SECONDS)
			for _, state in active do
				updateEnemy(state)
			end
		end
	end)
end

return EnemyService
