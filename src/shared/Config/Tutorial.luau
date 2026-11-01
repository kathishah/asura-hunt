--!strict
-- The "How to play" panel shown when a player joins. Text only: change the words or the order here.
-- Each step is ticked off when its `signal` happens (see UI/Tutorial.luau):
--   "AttackedAt", "SkillReadyAt", "DodgeReadyAt" are player attributes the server sets when the
--   action is accepted, and "ShopOpened" is the shop window being opened.

export type Step = {
	id: string,
	pcKey: string, -- what to press on a keyboard and mouse
	touchKey: string, -- what to press on a phone or tablet
	text: string,
	signal: string,
}

local Tutorial = {
	TITLE = "How to play",
	TIP = "A red glow means a hit is coming. Dodge it!",
	-- Seconds the panel stays after the last step is done, before it fades away.
	FADE_DELAY_SECONDS = 3,
	FADE_SECONDS = 0.8,
	STEPS = {
		{
			id = "attack",
			pcKey = "Click",
			touchKey = "Slash",
			text = "Attack. Three hits in a row make a combo.",
			signal = "AttackedAt",
		},
		{
			id = "skill",
			pcKey = "E",
			touchKey = "Skill",
			text = "Use your path skill (it needs a few seconds to recharge).",
			signal = "SkillReadyAt",
		},
		{
			id = "dodge",
			pcKey = "Q",
			touchKey = "Dodge",
			text = "Dodge. You cannot be hurt for a moment.",
			signal = "DodgeReadyAt",
		},
		{
			id = "shop",
			pcKey = "P",
			touchKey = "Shop",
			text = "Open the shop and spend your gold.",
			signal = "ShopOpened",
		},
	} :: { Step },
}

return Tutorial
