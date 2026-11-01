--!strict
-- Which tutorial steps the player has done. Plain tables only, so it can be tested without Roblox.

local TutorialProgress = {}

type Step = { id: string }

-- Marks a step done. Returns true only the first time, and only for a real step id.
function TutorialProgress.mark(done: { [string]: boolean }, steps: { Step }, id: string): boolean
	if done[id] then
		return false
	end
	for _, step in steps do
		if step.id == id then
			done[id] = true
			return true
		end
	end
	return false
end

function TutorialProgress.remaining(done: { [string]: boolean }, steps: { Step }): number
	local count = 0
	for _, step in steps do
		if not done[step.id] then
			count += 1
		end
	end
	return count
end

function TutorialProgress.allDone(done: { [string]: boolean }, steps: { Step }): boolean
	return #steps > 0 and TutorialProgress.remaining(done, steps) == 0
end

return TutorialProgress
