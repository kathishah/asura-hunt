--!strict
-- A short "How to play" panel at the right of the screen. Each line is ticked off the first time
-- the player really does it (the server accepted the action), and the panel fades away once every
-- line is done. The close button hides it earlier. The words live in Config/Tutorial.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TutorialConfig = require(Shared.Config.Tutorial)
local TutorialProgress = require(Shared.TutorialProgress)

local DONE_COLOR = Color3.fromRGB(110, 210, 130)
local TODO_COLOR = Color3.fromRGB(255, 255, 255)

local Tutorial = {}

type Row = { label: TextLabel, key: TextLabel, dot: Frame }

local function makeRow(parent: Instance, order: number, key: string, text: string): Row
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local chip = Instance.new("TextLabel")
	chip.Name = "Key"
	chip.Size = UDim2.fromOffset(58, 28)
	chip.Position = UDim2.fromOffset(0, 6)
	chip.BackgroundColor3 = Color3.fromRGB(55, 55, 78)
	chip.TextColor3 = Color3.new(1, 1, 1)
	chip.Font = Enum.Font.GothamBlack
	chip.TextSize = 15
	chip.Text = key
	chip.Parent = row
	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0, 6)
	chipCorner.Parent = chip

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Position = UDim2.fromOffset(66, 0)
	label.Size = UDim2.new(1, -92, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = TODO_COLOR
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.Text = text
	label.Parent = row

	-- A hollow circle that turns into a filled green one when the step is done.
	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.AnchorPoint = Vector2.new(1, 0.5)
	dot.Position = UDim2.fromScale(1, 0.5)
	dot.Size = UDim2.fromOffset(16, 16)
	dot.BackgroundColor3 = DONE_COLOR
	dot.BackgroundTransparency = 1
	dot.Parent = row
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot
	local dotStroke = Instance.new("UIStroke")
	dotStroke.Color = Color3.fromRGB(150, 150, 170)
	dotStroke.Thickness = 2
	dotStroke.Parent = dot

	return { label = label, key = chip, dot = dot }
end

function Tutorial.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local steps = TutorialConfig.STEPS
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	local panel = Instance.new("CanvasGroup")
	panel.Name = "Tutorial"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -12, 0.45, 0)
	panel.Size = UDim2.fromOffset(268, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.15
	panel.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = panel

	local title = Instance.new("TextLabel")
	title.LayoutOrder = 0
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 220, 120)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 16
	title.Text = TutorialConfig.TITLE
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(1, 0)
	close.Size = UDim2.fromOffset(22, 22)
	close.BackgroundTransparency = 1
	close.TextColor3 = Color3.fromRGB(190, 190, 205)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.Text = "X"
	close.Parent = title

	local rows: { [string]: Row } = {}
	for index, step in steps do
		rows[step.id] =
			makeRow(panel, index, if touchOnly then step.touchKey else step.pcKey, step.text)
	end

	local tip = Instance.new("TextLabel")
	tip.LayoutOrder = #steps + 1
	tip.Size = UDim2.new(1, 0, 0, 30)
	tip.BackgroundTransparency = 1
	tip.TextColor3 = Color3.fromRGB(255, 150, 130)
	tip.TextXAlignment = Enum.TextXAlignment.Left
	tip.TextWrapped = true
	tip.Font = Enum.Font.GothamMedium
	tip.TextSize = 12
	tip.Text = TutorialConfig.TIP
	tip.Parent = panel

	local finished = false
	local function hide(delay: number)
		if finished then
			return
		end
		finished = true
		task.delay(delay, function()
			local fade = TweenService:Create(
				panel,
				TweenInfo.new(TutorialConfig.FADE_SECONDS),
				{ GroupTransparency = 1 }
			)
			fade:Play()
			fade.Completed:Connect(function()
				panel:Destroy()
			end)
		end)
	end
	close.Activated:Connect(function()
		hide(0)
	end)

	local done: { [string]: boolean } = {}
	local function complete(id: string)
		if not TutorialProgress.mark(done, steps, id) then
			return
		end
		local row = rows[id]
		if row then
			row.dot.BackgroundTransparency = 0
			row.label.TextColor3 = DONE_COLOR
		end
		if TutorialProgress.allDone(done, steps) then
			hide(TutorialConfig.FADE_DELAY_SECONDS)
		end
	end

	-- Attribute signals: the server sets these when it accepts the action.
	for _, step in steps do
		if step.signal ~= "ShopOpened" then
			player:GetAttributeChangedSignal(step.signal):Connect(function()
				complete(step.id)
			end)
		end
	end

	-- The shop window belongs to another HUD feature, so wait for it without blocking.
	task.spawn(function()
		local window = screen:WaitForChild("ShopWindow", 10)
		if window and window:IsA("GuiObject") then
			window:GetPropertyChangedSignal("Visible"):Connect(function()
				if window.Visible then
					for _, step in steps do
						if step.signal == "ShopOpened" then
							complete(step.id)
						end
					end
				end
			end)
		end
	end)
end

return Tutorial
