--!strict
-- The top-left panel: level, XP, gold, stats, and the path and stat-point buttons.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Paths = require(Shared.Config.Paths)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)
local Widgets = require(script.Parent.Parent.Widgets)

local StatsPanel = {}

function StatsPanel.start(screen: ScreenGui)
	local panel = Instance.new("Frame")
	panel.Name = "StatsPanel"
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

	local levelLabel = Widgets.newLabel(panel, 1)
	local goldLabel = Widgets.newLabel(panel, 2)
	local pathLabel = Widgets.newLabel(panel, 3)
	local statsLabel = Widgets.newLabel(panel, 4)

	local strengthButton = Widgets.newButton(panel, 5, "+ Strength", function()
		Remotes.get("SpendStat"):FireServer("strength")
	end)
	local vitalityButton = Widgets.newButton(panel, 6, "+ Vitality", function()
		Remotes.get("SpendStat"):FireServer("vitality")
	end)
	Widgets.newButton(panel, 7, "Path: Yodha (warrior)", function()
		Remotes.get("ChoosePath"):FireServer("Yodha")
	end)
	Widgets.newButton(panel, 8, "Path: Rishi (caster)", function()
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
end

return StatsPanel
