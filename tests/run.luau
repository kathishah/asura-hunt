-- Headless checks for logic that does not need Roblox: saved data, config rules, server decisions
-- and enemy behaviour. Run with:  lune run tests/run
-- It runs the real files from src/ against the fake Roblox in harness.luau.
-- It does NOT replace a Studio playtest: nothing here draws, moves or collides.
--
-- Every file in tests/cases is a test case: `return function(t)` using t.check, t.section and
-- t.harness. Add a new file there for a new feature; this runner never needs editing.

local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")
local harness = require("./harness")

local passed, failed = 0, 0
local function check(name: string, condition: boolean, detail: any?)
	if condition then
		passed += 1
		print(`  ok    {name}`)
	else
		failed += 1
		print(`  FAIL  {name}{if detail ~= nil then ` ({detail})` else ""}`)
	end
end
local function section(title: string)
	print(`\n{title}`)
end

local names = {}
for _, file in fs.readDir("tests/cases") do
	local name = file:match("^(.+)%.luau$")
	if name then
		table.insert(names, name)
	end
end
table.sort(names)

for _, name in names do
	local run = require(`./cases/{name}`)
	local ok, err = pcall(run, { check = check, section = section, harness = harness, task = task })
	if not ok then
		failed += 1
		print(`  FAIL  case "{name}" crashed: {err}`)
	end
end

print(`\n{passed} passed, {failed} failed`)
process.exit(if failed == 0 then 0 else 1)
