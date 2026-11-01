--!strict
-- Plays a sound from Config/Sounds at a part, so everyone nearby hears it from that spot.
-- Sounds are display only: nothing in the game waits for them.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared.Config.Sounds)

local Sfx = {}

-- Made on first use, so loading this module needs no Roblox objects.
local random: Random? = nil

-- `name` is a key of Config/Sounds. An unknown or empty sound is quietly skipped.
function Sfx.play(name: string, parent: Instance)
	local def = Sounds.SOUNDS[name]
	if not def or def.id == "" then
		return
	end

	if not random then
		random = Random.new()
	end

	local sound = Instance.new("Sound")
	sound.Name = `Sfx_{name}`
	sound.SoundId = def.id
	sound.Volume = def.volume
	sound.PlaybackSpeed = 1 + (random :: Random):NextNumber(-1, 1) * def.pitchJitter
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = Sounds.MAX_DISTANCE
	sound.Parent = parent
	sound:Play()
	-- Removed shortly after, whether or not it finished (a sound that never loads would linger).
	Debris:AddItem(sound, 6)
end

return Sfx
