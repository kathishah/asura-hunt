--!strict
-- Two small boxes at the bottom of the screen, one for the skill (E) and one for the dodge (Q).
-- Each fills up from the bottom while it recharges, shows the seconds left, and lights up when it
-- is ready. The server decides the cooldowns; it publishes them as player attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cooldown = require(Shared.Cooldown)

local BOX_SIZE = 56
local READY_COLOR = Color3.fromRGB(120, 220, 140)
local CHARGING_COLOR = Color3.fromRGB(90, 90, 110)
local FILL_COLOR = Color3.fromRGB(70, 140, 200)

type Box = {
	name: string, -- attribute prefix, e.g. "Skill" reads SkillReadyAt and SkillCooldown
	key: string,
	fill: Frame,
	stroke: UIStroke,
	label: TextLabel,
}

local Cooldowns = {}

local function makeBox(
	parent: Instance,
	order: number,
	name: string,
	key: string,
	title: string
): Box
	local box = Instance.new("Frame")
	box.Name = `{name}Box`
	box.LayoutOrder = order
	box.Size = UDim2.fromOffset(BOX_SIZE, BOX_SIZE)
	box.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	box.BackgroundTransparency = 0.2
	box.ClipsDescendants = true
	box.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = box

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = READY_COLOR
	stroke.Parent = box

	-- Grows upward from the bottom as the ability recharges.
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = FILL_COLOR
	fill.BackgroundTransparency = 0.35
	fill.BorderSizePixel = 0
	fill.Parent = box

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, 0, 0, 26)
	keyLabel.Position = UDim2.fromOffset(0, 4)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = key
	keyLabel.TextColor3 = Color3.new(1, 1, 1)
	keyLabel.Font = Enum.Font.GothamBlack
	keyLabel.TextSize = 24
	keyLabel.Parent = box

	local nameLabel = Instance.new("TextLabel")
	nameLabel.AnchorPoint = Vector2.new(0, 1)
	nameLabel.Size = UDim2.new(1, 0, 0, 14)
	nameLabel.Position = UDim2.fromScale(0, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = title
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextSize = 11
	nameLabel.Parent = box

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Position = UDim2.fromOffset(0, 28)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.Parent = box

	return { name = name, key = key, fill = fill, stroke = stroke, label = label }
end

function Cooldowns.start(screen: ScreenGui)
	local player = Players.LocalPlayer

	local row = Instance.new("Frame")
	row.Name = "Cooldowns"
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -16)
	row.Size = UDim2.fromOffset(BOX_SIZE * 2 + 10, BOX_SIZE)
	row.BackgroundTransparency = 1
	row.Parent = screen

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local boxes = {
		makeBox(row, 1, "Skill", "E", "Skill"),
		makeBox(row, 2, "Dodge", "Q", "Dodge"),
	}

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		for _, box in boxes do
			local readyAt = player:GetAttribute(`{box.name}ReadyAt`)
			local duration = player:GetAttribute(`{box.name}Cooldown`)
			local readyAtNumber = if typeof(readyAt) == "number" then readyAt else nil
			local durationNumber = if typeof(duration) == "number" then duration else nil

			local progress = Cooldown.progress(readyAtNumber, durationNumber, now)
			local ready = progress >= 1
			box.fill.Size = UDim2.fromScale(1, progress)
			box.stroke.Color = if ready then READY_COLOR else CHARGING_COLOR
			box.label.Text = Cooldown.label(Cooldown.remaining(readyAtNumber, now))
		end
	end)
end

return Cooldowns
