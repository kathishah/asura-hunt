--!strict
-- Floating damage numbers above whatever was hit.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local DamageNumbers = {}

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

function DamageNumbers.start(_screen: ScreenGui)
	Remotes.get("DamageNumber").OnClientEvent:Connect(function(position: Vector3, amount: number)
		showDamageNumber(position, amount)
	end)
end

return DamageNumbers
