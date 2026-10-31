--!strict
-- Spawns enemies, runs their simple chase-and-attack AI, and handles their death and respawn.
--
-- Spawn points: tag a Part with "EnemySpawn" (CollectionService) and give it a string attribute
-- "EnemyId" (e.g. "Vetala"). If no tagged parts exist, DEFAULT_SPAWNS below is used instead.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared.Config.Enemies)
local EnemyLooks = require(Shared.Config.EnemyLooks)
local Types = require(Shared.Types)

local SPAWN_TAG = "EnemySpawn"
local AI_TICK_SECONDS = 0.25
local LEASH_DISTANCE = 120
local HOME_RADIUS = 6

export type EnemyState = {
	def: Types.EnemyDef,
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	spawnPosition: Vector3,
	nextAttackAt: number,
	lastAttacker: Player?,
	dead: boolean,
}

local DEFAULT_SPAWNS = {
	{ id = "Pishacha", position = Vector3.new(40, 4, 0) },
	{ id = "Pishacha", position = Vector3.new(-40, 4, 0) },
	{ id = "Pishacha", position = Vector3.new(0, 4, 40) },
	{ id = "Vetala", position = Vector3.new(0, 4, -60) },
	{ id = "Vetala", position = Vector3.new(60, 4, 60) },
	{ id = "Chudail", position = Vector3.new(-60, 4, -50) },
	{ id = "Chudail", position = Vector3.new(30, 4, -100) },
	{ id = "Rakshasa", position = Vector3.new(-90, 4, 90) },
	{ id = "Krodha", position = Vector3.new(0, 8, -150) },
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
	gui.Size = UDim2.fromOffset(200, 42)
	-- Sit above the tallest part (horns, flames), not just the hitbox.
	local boxCFrame, boxSize = model:GetBoundingBox()
	local top = math.max(def.size.Y / 2, boxCFrame.Position.Y + boxSize.Y / 2 - root.Position.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, top + 2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.6)
	label.BackgroundTransparency = 1
	label.TextColor3 = if def.isBoss then Color3.fromRGB(255, 190, 80) else Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = gui

	-- The folklore name, small and quiet, so players pick it up over time.
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.fromScale(1, 0.4)
	subtitle.Position = UDim2.fromScale(0, 0.6)
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
	end
	refresh()
	humanoid.HealthChanged:Connect(refresh)

	gui.Parent = model
end

-- Welds the enemy's decorative parts to its hitbox. They never collide or block attacks.
local function addBodyParts(model: Model, root: BasePart, bodyParts: { Types.BodyPart })
	for _, def in bodyParts do
		local part = Instance.new("Part")
		part.Name = def.name
		if def.shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif def.shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		elseif def.shape == "Ellipsoid" then
			-- A sphere mesh stretches with the part's size into a rounded blob.
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
		end
		part.Size = def.size
		part.Color = def.color
		part.Material = def.material or Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true

		local rotation = def.rotation or Vector3.zero
		local relative = CFrame.new(def.offset)
			* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		part.CFrame = root.CFrame * relative

		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = part
		weld.C0 = relative
		weld.Parent = part

		part.Parent = model
	end
end

local function buildModel(def: Types.EnemyDef, position: Vector3): Model?
	local enemyModels = ServerStorage:FindFirstChild("EnemyModels")
	local template = if enemyModels then enemyModels:FindFirstChild(def.id) else nil
	if template and template:IsA("Model") then
		local clone = template:Clone()
		clone:PivotTo(CFrame.new(position))
		return clone
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
	if bodyParts then
		root.Transparency = 1
		addBodyParts(model, root, bodyParts)
	end
	return model
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

		task.delay(2, function()
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

	local model = buildModel(def, position)
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
		lastAttacker = nil,
		dead = false,
	}
	active[model] = state
	setupDeath(state)
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

function EnemyService.damage(state: EnemyState, amount: number, attacker: Player)
	if state.dead then
		return
	end
	state.lastAttacker = attacker
	state.humanoid:TakeDamage(amount)
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

local function updateEnemy(state: EnemyState)
	if state.dead or state.humanoid.Health <= 0 then
		return
	end

	local player, targetHumanoid, targetRoot = findTarget(state)
	if not player or not targetHumanoid or not targetRoot then
		-- No target: walk home and recover.
		local homeDistance = (state.root.Position - state.spawnPosition).Magnitude
		if homeDistance > HOME_RADIUS then
			state.humanoid:MoveTo(state.spawnPosition)
		elseif state.humanoid.Health < state.humanoid.MaxHealth then
			state.humanoid.Health = state.humanoid.MaxHealth
		end
		return
	end

	local distance = (targetRoot.Position - state.root.Position).Magnitude
	if distance > state.def.attackRange then
		state.humanoid:MoveTo(targetRoot.Position)
		return
	end

	local now = os.clock()
	if now >= state.nextAttackAt then
		state.nextAttackAt = now + state.def.attackCooldown
		-- Dodge i-frames: CombatService sets this attribute on the player.
		if not player:GetAttribute("Invulnerable") then
			targetHumanoid:TakeDamage(state.def.damage)
		end
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
