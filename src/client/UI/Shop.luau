--!strict
-- The shop screen. Open it with the Shop button or the P key (B is kept for a future backpack
-- screen, and S would clash with walking backward). It lists every item in Config/Items
-- with a Buy, Equip or Unequip button. It only asks; the server checks and does everything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Equipment = require(Shared.Equipment)
local Items = require(Shared.Config.Items)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)

local Shop = {}

local function statsText(item: Types.ItemDef): string
	local parts = {}
	if item.damageMultiplier then
		table.insert(parts, `+{math.floor((item.damageMultiplier - 1) * 100 + 0.5)}% damage`)
	end
	if item.healthBonus then
		table.insert(parts, `+{item.healthBonus} health`)
	end
	if item.paths then
		table.insert(parts, table.concat(item.paths, "/") .. " only")
	end
	return table.concat(parts, "  ")
end

local function sortedItems(): { Types.ItemDef }
	local list = {}
	for _, item in Items do
		table.insert(list, item)
	end
	table.sort(list, function(a, b)
		if a.slot ~= b.slot then
			return a.slot < b.slot
		end
		return a.price < b.price
	end)
	return list
end

function Shop.start(screen: ScreenGui)
	local window = Instance.new("Frame")
	window.Name = "ShopWindow"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(420, 400)
	window.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	window.BackgroundTransparency = 0.1
	window.Visible = false
	window.Parent = screen

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 36)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.Text = "Shop"
	title.Parent = window

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(8, 40)
	list.Size = UDim2.new(1, -16, 1, -48)
	list.BackgroundTransparency = 1
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = window

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	local toggle = Instance.new("TextButton")
	toggle.Name = "ShopButton"
	toggle.AnchorPoint = Vector2.new(0, 1)
	toggle.Position = UDim2.new(0, 10, 1, -10)
	toggle.Size = UDim2.fromOffset(110, 34)
	toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 14
	toggle.Text = "Shop [P]"
	toggle.Parent = screen

	local function flip()
		window.Visible = not window.Visible
	end
	toggle.Activated:Connect(flip)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.P then
			flip()
		end
	end)

	local function render(data: Types.PlayerData)
		title.Text = `Shop   (Gold {data.gold})`
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for order, item in sortedItems() do
			local row = Instance.new("Frame")
			row.LayoutOrder = order
			row.Size = UDim2.new(1, -8, 0, 62)
			row.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
			row.Parent = list

			local text = Instance.new("TextLabel")
			text.Position = UDim2.fromOffset(8, 0)
			text.Size = UDim2.new(1, -130, 1, 0)
			text.BackgroundTransparency = 1
			text.TextColor3 = Color3.new(1, 1, 1)
			text.Font = Enum.Font.GothamMedium
			text.TextSize = 13
			text.TextXAlignment = Enum.TextXAlignment.Left
			text.TextWrapped = true
			text.Text = `{item.displayName}  ({item.slot})\n{statsText(item)}\n{item.description}`
			text.Parent = row

			local owned = (data.inventory[item.id] or 0) >= 1
			local equipped = data.equipped[item.slot] == item.id
			local label: string
			local enabled = true
			local action: () -> ()
			if equipped then
				label = "Unequip"
				action = function()
					Remotes.get("UnequipSlot"):FireServer(item.slot)
				end
			elseif owned then
				label = "Equip"
				enabled = Equipment.usableOnPath(item, data.path)
				action = function()
					Remotes.get("EquipItem"):FireServer(item.id)
				end
			else
				label = `Buy {item.price}g`
				enabled = data.gold >= item.price
				action = function()
					Remotes.get("BuyItem"):FireServer(item.id)
				end
			end

			local button = Instance.new("TextButton")
			button.AnchorPoint = Vector2.new(1, 0.5)
			button.Position = UDim2.new(1, -8, 0.5, 0)
			button.Size = UDim2.fromOffset(104, 32)
			button.BackgroundColor3 = if enabled
				then Color3.fromRGB(70, 110, 70)
				else Color3.fromRGB(70, 70, 70)
			button.TextColor3 = Color3.new(1, 1, 1)
			button.Font = Enum.Font.GothamBold
			button.TextSize = 13
			button.Text = label
			button.AutoButtonColor = enabled
			if enabled then
				button.Activated:Connect(action)
			end
			button.Parent = row
		end
	end

	Remotes.get("StatsChanged").OnClientEvent:Connect(render)
end

return Shop
