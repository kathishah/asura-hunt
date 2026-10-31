--!strict
-- Small building blocks shared by the HUD features in `UI/`.

local Widgets = {}

function Widgets.newLabel(parent: Instance, order: number): TextLabel
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

function Widgets.newButton(
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

return Widgets
