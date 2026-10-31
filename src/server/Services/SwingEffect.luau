--!strict
-- The visible arc for a swing or skill, so you can see where and when you attacked. It is made
-- of a few glowing pieces that appear one after another and fade out. It is only decoration: the
-- hit itself is decided by CombatService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Effects = require(Shared.Config.Effects)

local SwingEffect = {}

local folder: Folder? = nil

local function getFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = "Effects"
	created.Parent = workspace
	folder = created
	return created
end

-- `coneDot` is the swing's cone, as in Types.SkillDef, so the arc matches what can really be hit.
function SwingEffect.play(
	root: BasePart,
	range: number,
	coneDot: number,
	color: Color3,
	thickness: number
)
	local config = Effects.SWING
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		return
	end

	local origin = root.Position
	local facing = CFrame.lookAt(origin, origin + flat.Unit)
	local halfAngle = math.acos(math.clamp(coneDot, -1, 1))
	local radius = range * config.reachFraction
	local count = config.segments
	-- A little longer than the gap between pieces, so the arc has no holes.
	local length = math.max(2 * halfAngle * radius / count * 1.25, 0.6)
	local effects = getFolder()

	for index = 1, count do
		local along = if count > 1 then (index - 1) / (count - 1) else 0.5
		local angle = (along * 2 - 1) * halfAngle

		local piece = Instance.new("Part")
		piece.Name = "SwingPiece"
		piece.Size = Vector3.new(length, thickness, thickness * 1.6)
		piece.Material = Enum.Material.Neon
		piece.Color = color
		piece.Transparency = 1
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.CastShadow = false
		piece.CFrame = facing * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius)
		piece.Parent = effects

		task.delay(along * config.sweepSeconds, function()
			if not piece.Parent then
				return
			end
			piece.Transparency = 0.1
			TweenService:Create(piece, TweenInfo.new(config.fadeSeconds), { Transparency = 1 })
				:Play()
			task.delay(config.fadeSeconds + 0.05, function()
				piece:Destroy()
			end)
		end)
	end
end

return SwingEffect
