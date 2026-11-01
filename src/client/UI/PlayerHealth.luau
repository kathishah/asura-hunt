--!strict
-- The player's own health: a bar with the numbers on it ("85 / 100"), bottom centre above the E and
-- Q boxes. It replaces Roblox's built-in health bar, which has no numbers. The server owns health;
-- this only reads the Humanoid and draws.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Effects = require(Shared.Config.Effects)
local PlayerHealth = require(Shared.PlayerHealth)

local LOOK = Effects.PLAYER_HEALTH
local BAR = Effects.HEALTH_BAR

local UIPlayerHealth = {}

-- SetCoreGuiEnabled can fail while Roblox is still starting up, so try a few times.
local function hideDefaultHealthBar()
	task.spawn(function()
		for _ = 1, 10 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
			end)
			if ok then
				return
			end
			task.wait(1)
		end
		warn("[PlayerHealth] could not hide the default health bar")
	end)
end

function UIPlayerHealth.start(screen: ScreenGui)
	local player = Players.LocalPlayer

	local back = Instance.new("Frame")
	back.Name = "PlayerHealth"
	back.AnchorPoint = Vector2.new(0.5, 1)
	back.Position = UDim2.new(0.5, 0, 1, -LOOK.bottomOffset)
	back.Size = UDim2.fromOffset(LOOK.width, LOOK.height)
	back.BackgroundColor3 = BAR.back
	back.BackgroundTransparency = 0.2
	back.ClipsDescendants = true
	back.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local label = Instance.new("TextLabel")
	label.Name = "Numbers"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = LOOK.textSize
	label.Parent = back

	local connections: { RBXScriptConnection } = {}

	local function show(health: number, maxHealth: number)
		local fraction = PlayerHealth.fraction(health, maxHealth)
		fill.Size = UDim2.fromScale(fraction, 1)
		fill.BackgroundColor3 = PlayerHealth.colorFor(fraction, BAR.colors)
		label.Text = PlayerHealth.text(health, maxHealth)
	end

	-- A new character (after respawn) has a new Humanoid, so drop the old listeners first.
	local function watch(character: Model)
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)

		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid or not humanoid:IsA("Humanoid") then
			return
		end
		local function update()
			show(humanoid.Health, humanoid.MaxHealth)
		end
		table.insert(connections, humanoid.HealthChanged:Connect(update))
		table.insert(connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update))
		update()
	end

	show(0, 0)
	player.CharacterAdded:Connect(watch)
	if player.Character then
		task.spawn(watch, player.Character)
	end

	hideDefaultHealthBar()
end

return UIPlayerHealth
