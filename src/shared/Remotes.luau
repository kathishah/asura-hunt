--!strict
-- Creates all RemoteEvents on the server and looks them up on the client.
-- Add new remote names to REMOTE_NAMES, then use Remotes.get("Name") on either side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local REMOTE_NAMES = {
	-- Client -> server
	"Attack",
	"Dodge",
	"UseSkill",
	"ChoosePath",
	"SpendStat",
	"ClientReady",
	"BuyItem",
	"EquipItem",
	"UnequipSlot",
	-- Server -> client
	"StatsChanged",
	"DamageNumber",
}

local folder: Folder

if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in REMOTE_NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local Remotes = {}

function Remotes.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
