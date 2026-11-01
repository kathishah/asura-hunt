--!strict
-- Downloads the game's sounds in the background when the player joins, so the first swing or hit
-- is not silent while a sound loads.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared.Config.Sounds)

local Preload = {}

function Preload.start()
	task.spawn(function()
		local list: { Instance } = {}
		for _, def in Sounds.SOUNDS do
			if def.id ~= "" then
				local sound = Instance.new("Sound")
				sound.SoundId = def.id
				table.insert(list, sound)
			end
		end
		local ok, err = pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
		if not ok then
			warn(`[Preload] sounds did not finish loading: {err}`)
		end
		for _, sound in list do
			sound:Destroy()
		end
	end)
end

return Preload
