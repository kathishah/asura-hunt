--!strict
-- The HUD shell. It makes the ScreenGui and starts every feature found in the `UI` folder.
-- To add a HUD feature (shop, boss bar, effects), add a ModuleScript to `src/client/UI` with a
-- `start(screen: ScreenGui)` function. Nothing here needs to change, so parallel features never
-- edit the same file. A feature that errors is skipped and logged; the rest keep working.
-- Placeholder UI built in code; replace with UI designed in Studio when you're ready.

local Players = game:GetService("Players")

local HUD = {}

function HUD.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "AsuraHuntHUD"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local features = script.Parent:WaitForChild("UI")
	for _, module in features:GetChildren() do
		if module:IsA("ModuleScript") then
			local ok, err = pcall(function()
				local feature: any = require(module)
				feature.start(screen)
			end)
			if not ok then
				warn(`[HUD] {module.Name} failed to start: {err}`)
			end
		end
	end
end

return HUD
