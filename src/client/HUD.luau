--!strict
-- Minimal placeholder HUD built entirely in code: stats panel, path buttons, stat-point buttons
-- and floating damage numbers. Replace with proper UI designed in Studio when you're ready.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Paths = require(Shared.Config.Paths)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)

local HUD = {}

local function newLabel(parent: Instance, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.Text = ""
	label.Parent = parent
	return label
end

local function newButton(
	parent: Instance,
	order: number,
	text: string,
	onClick: () -> ()
): TextButton
	local button = Instance.new("TextButton")
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, 28)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Text = text
	button.Activated:Connect(onClick)
	button.Parent = parent
	return button
end

local function showDamageNumber(position: Vector3, amount: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position + Vector3.new(0, 3, 0)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(80, 30)
	gui.AlwaysOnTop = true
	gui.Adornee = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = tostring(amount)
	label.TextColor3 = Color3.fromRGB(255, 220, 90)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 22
	label.Parent = gui

	gui.Parent = anchor
	anchor.Parent = workspace

	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = anchor.Position + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

function HUD.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "AsuraHuntHUD"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Position = UDim2.fromOffset(10, 10)
	panel.Size = UDim2.fromOffset(240, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.new(0, 0, 0)
	panel.BackgroundTransparency = 0.45
	panel.Parent = screen

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = panel

	local levelLabel = newLabel(panel, 1)
	local goldLabel = newLabel(panel, 2)
	local pathLabel = newLabel(panel, 3)
	local statsLabel = newLabel(panel, 4)

	local strengthButton = newButton(panel, 5, "+ Strength", function()
		Remotes.get("SpendStat"):FireServer("strength")
	end)
	local vitalityButton = newButton(panel, 6, "+ Vitality", function()
		Remotes.get("SpendStat"):FireServer("vitality")
	end)
	newButton(panel, 7, "Path: Yodha (warrior)", function()
		Remotes.get("ChoosePath"):FireServer("Yodha")
	end)
	newButton(panel, 8, "Path: Rishi (caster)", function()
		Remotes.get("ChoosePath"):FireServer("Rishi")
	end)

	local function render(data: Types.PlayerData)
		local path = Paths[data.path]
		levelLabel.Text =
			`Lv {data.level}   XP {math.floor(data.xp)}/{GameConfig.xpToNextLevel(data.level)}`
		goldLabel.Text = `Gold {data.gold}`
		pathLabel.Text = `{path.displayName}: {path.skill.name} [E]`
		statsLabel.Text =
			`STR {data.stats.strength}  VIT {data.stats.vitality}  Points {data.statPoints}`
		strengthButton.Visible = data.statPoints > 0
		vitalityButton.Visible = data.statPoints > 0
	end

	Remotes.get("StatsChanged").OnClientEvent:Connect(render)

	Remotes.get("DamageNumber").OnClientEvent:Connect(function(position: Vector3, amount: number)
		showDamageNumber(position, amount)
	end)
end

return HUD
