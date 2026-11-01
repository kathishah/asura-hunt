--!strict
-- Every sound in the game. To change one, replace its `id` with a sound from the Creator Store
-- (copy the asset id as "rbxassetid://123456789") and check its licence. A sound with an empty id
-- is skipped, so you can also turn one off by clearing it.
--
-- The ids below are placeholders: sound files that ship inside the Roblox app itself, so they work
-- with no upload. They were checked to load, but not listened to. Pick the final ones with your son.

export type SoundDef = {
	id: string,
	volume: number, -- 0 is silent, 1 is normal
	pitchJitter: number, -- each play is a little higher or lower by up to this much, so repeats are less samey
}

local Sounds = {
	-- Beyond this many studs a sound cannot be heard.
	MAX_DISTANCE = 90,
	SOUNDS = {
		-- You
		swing = { id = "rbxasset://sounds/swordslash.wav", volume = 0.5, pitchJitter = 0.1 },
		skill = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.7, pitchJitter = 0.05 },
		dodge = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.6, pitchJitter = 0.1 },
		hurt = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.7, pitchJitter = 0.08 },
		-- Enemies
		hit = { id = "rbxasset://sounds/hit.wav", volume = 0.6, pitchJitter = 0.15 },
		windup = { id = "rbxasset://sounds/bass.wav", volume = 0.5, pitchJitter = 0.1 },
		death = { id = "rbxasset://sounds/kerplunk.wav", volume = 0.9, pitchJitter = 0.1 },
	} :: { [string]: SoundDef },
}

return Sounds
