--!strict
-- Client entry point.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local HUD = require(script.Parent.HUD)
local Input = require(script.Parent.Input)
local Preload = require(script.Parent.Preload)

HUD.start()
Input.start()
Preload.start()

-- Ask the server for our current data (we may have connected after it was first sent).
Remotes.get("ClientReady"):FireServer()
