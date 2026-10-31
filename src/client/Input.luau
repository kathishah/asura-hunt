--!strict
-- Keyboard, mouse, touch and gamepad input. ContextActionService also creates the on-screen
-- touch buttons for mobile players automatically.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Remotes = require(Shared.Remotes)

local COMBAT = GameConfig.COMBAT
local localPlayer = Players.LocalPlayer

local Input = {}

local nextDodgeAt = 0

-- Visual dash. The server separately grants the invulnerability frames.
local function dash()
	local character = localPlayer.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end

	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector
	end
	local flat = Vector3.new(direction.X, 0, direction.Z).Unit

	local elapsed = 0
	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= COMBAT.dodgeDashSeconds or not root.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity =
			Vector3.new(flat.X * COMBAT.dodgeDashSpeed, velocity.Y, flat.Z * COMBAT.dodgeDashSpeed)
	end)
end

function Input.start()
	local attack = Remotes.get("Attack")
	local useSkill = Remotes.get("UseSkill")
	local dodge = Remotes.get("Dodge")

	ContextActionService:BindAction("Attack", function(_name, state)
		if state == Enum.UserInputState.Begin then
			attack:FireServer()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	ContextActionService:BindAction("Skill", function(_name, state)
		if state == Enum.UserInputState.Begin then
			useSkill:FireServer()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

	ContextActionService:BindAction("Dodge", function(_name, state)
		if state == Enum.UserInputState.Begin and os.clock() >= nextDodgeAt then
			nextDodgeAt = os.clock() + COMBAT.dodgeCooldown
			dodge:FireServer()
			dash()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)

	ContextActionService:SetTitle("Attack", "Slash")
	ContextActionService:SetTitle("Skill", "Skill")
	ContextActionService:SetTitle("Dodge", "Dodge")
end

return Input
