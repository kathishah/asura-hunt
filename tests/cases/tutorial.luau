-- The "How to play" panel: its text config and the progress tracking.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness = t.check, t.section, t.harness

	section("Tutorial")
	do
		local world = harness.newWorld()
		local Tutorial = world.load("shared/Config/Tutorial")
		local Progress = world.load("shared/TutorialProgress")
		local steps = Tutorial.STEPS

		local known =
			{ AttackedAt = true, SkillReadyAt = true, DodgeReadyAt = true, ShopOpened = true }
		local ids = {}
		local complete = #steps > 0
		for _, step in steps do
			check(
				`step {step.id}: has all its text`,
				type(step.pcKey) == "string"
					and step.pcKey ~= ""
					and type(step.touchKey) == "string"
					and step.touchKey ~= ""
					and type(step.text) == "string"
					and step.text ~= ""
			)
			check(`step {step.id}: uses a known signal`, known[step.signal] == true, step.signal)
			check(`step {step.id}: id is unique`, ids[step.id] == nil)
			ids[step.id] = true
		end
		check("there is at least one step", complete)
		check("the panel has a title and a tip", Tutorial.TITLE ~= "" and Tutorial.TIP ~= "")
		check(
			"the fade timings are positive",
			Tutorial.FADE_DELAY_SECONDS >= 0 and Tutorial.FADE_SECONDS > 0
		)

		local done = {}
		check("nothing is done at the start", Progress.remaining(done, steps) == #steps)
		check("not all done at the start", not Progress.allDone(done, steps))
		check("marking a real step works", Progress.mark(done, steps, steps[1].id) == true)
		check("marking it again does nothing", Progress.mark(done, steps, steps[1].id) == false)
		check("a made-up step is ignored", Progress.mark(done, steps, "nope") == false)
		check("a made-up step is not recorded", done["nope"] == nil)
		check("one fewer step remains", Progress.remaining(done, steps) == #steps - 1)
		for _, step in steps do
			Progress.mark(done, steps, step.id)
		end
		check("all done once every step is marked", Progress.allDone(done, steps))
		check("an empty list is never all done", not Progress.allDone({}, {}))
	end
end
