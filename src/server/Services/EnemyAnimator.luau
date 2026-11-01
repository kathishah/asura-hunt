--!strict
-- Moves an enemy's whole body by tweening one weld (BodyBuilder's PivotWeld, at its feet). Each
-- animation is a short list of poses; a new animation cancels the one before it, so a hit during a
-- lean simply starts the next move from wherever the body is. The numbers are in
-- Config/Animations. This is only for looks: hits and health are decided elsewhere.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Animations = require(Shared.Config.Animations)
local Posture = require(Shared.Posture)

local EnemyAnimator = {}
EnemyAnimator.__index = EnemyAnimator

-- One pose and how long to take getting there. `lean` is degrees (positive leans forward),
-- `sink` is a fraction of height, `forward` is studs the body is pushed forward (negative is back).
type Move = {
	lean: number,
	sink: number,
	forward: number,
	seconds: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
}

export type EnemyAnimator = typeof(setmetatable(
	{} :: {
		weld: Weld,
		height: number,
		scale: number,
		baseLean: number,
		baseSink: number,
		stage: number,
		token: number,
		tween: Tween?,
		dead: boolean,
	},
	EnemyAnimator
))

function EnemyAnimator.new(weld: Weld, height: number, isBoss: boolean): EnemyAnimator
	local self = setmetatable({
		weld = weld,
		height = height,
		scale = if isBoss then Animations.POSTURE.bossScale else 1,
		baseLean = 0,
		baseSink = 0,
		stage = #Animations.POSTURE.steps,
		token = 0,
		tween = nil :: Tween?,
		dead = false,
	}, EnemyAnimator)
	return self
end

-- The weld position for a pose. The pivot sits at the feet, so rotating it tips the body around
-- its feet.
function EnemyAnimator._cframe(self: EnemyAnimator, lean: number, sink: number, forward: number)
	return CFrame.new(0, -self.height / 2 - sink * self.height, -forward)
		* CFrame.Angles(-math.rad(lean), 0, 0)
end

-- Plays the moves one after another, replacing whatever was playing.
function EnemyAnimator._play(self: EnemyAnimator, moves: { Move })
	self.token += 1
	local token = self.token
	if self.tween then
		self.tween:Cancel()
	end

	task.spawn(function()
		for _, move in moves do
			if self.token ~= token then
				return
			end
			local info = TweenInfo.new(
				move.seconds,
				move.style or Enum.EasingStyle.Quad,
				move.direction or Enum.EasingDirection.Out
			)
			local tween = TweenService:Create(
				self.weld,
				info,
				{ C0 = self:_cframe(move.lean, move.sink, move.forward) }
			)
			self.tween = tween
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

function EnemyAnimator._rest(self: EnemyAnimator, seconds: number): Move
	return {
		lean = self.baseLean,
		sink = self.baseSink,
		forward = 0,
		seconds = seconds,
	}
end

-- Call whenever health changes. The body hunches lower as health drops. Only does anything when
-- the enemy crosses into a different step, so it is cheap to call on every hit.
function EnemyAnimator.setHealth(self: EnemyAnimator, fraction: number)
	if self.dead then
		return
	end
	local config = Animations.POSTURE
	local stage = Posture.stage(fraction, config.steps)
	if stage == self.stage then
		return
	end
	self.stage = stage
	self.baseLean, self.baseSink = Posture.forHealth(fraction, config.steps, self.scale)
	self:_play({ self:_rest(config.changeSeconds) })
end

-- A quick recoil from a hit, then back to the hurt stance.
function EnemyAnimator.flinch(self: EnemyAnimator)
	if self.dead then
		return
	end
	local config = Animations.FLINCH
	self:_play({
		{
			lean = self.baseLean + config.leanDegrees,
			sink = self.baseSink,
			forward = -config.pushBackStuds,
			seconds = config.outSeconds,
		},
		self:_rest(config.backSeconds),
	})
end

-- Leaning back to gather strength while the telegraph glows. `windupSeconds` is the length of the
-- windup, so the pose is reached just before the strike.
function EnemyAnimator.windup(self: EnemyAnimator, windupSeconds: number)
	if self.dead then
		return
	end
	local config = Animations.WINDUP
	self:_play({
		{
			lean = self.baseLean - config.leanBackDegrees,
			sink = self.baseSink,
			forward = -config.pullBackStuds,
			seconds = math.max(windupSeconds * config.reachFraction, 0.05),
			style = Enum.EasingStyle.Sine,
		},
	})
end

-- The lunge when the attack lands, then back to the stance.
function EnemyAnimator.strike(self: EnemyAnimator)
	if self.dead then
		return
	end
	local config = Animations.STRIKE
	self:_play({
		{
			lean = self.baseLean + config.leanDegrees,
			sink = self.baseSink,
			forward = config.lungeStuds,
			seconds = config.outSeconds,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.In,
		},
		self:_rest(config.backSeconds),
	})
end

-- The attack was cancelled (the target stepped away): straighten back up.
function EnemyAnimator.recover(self: EnemyAnimator)
	if self.dead then
		return
	end
	self:_play({ self:_rest(Animations.POSTURE.changeSeconds) })
end

-- Falls over backward, lies there, then sinks into the ground. Takes Posture.deathSeconds in all.
function EnemyAnimator.collapse(self: EnemyAnimator)
	if self.dead then
		return
	end
	self.dead = true
	local config = Animations.DEATH
	local nearlyFlat = config.fallDegrees - 8
	self:_play({
		{
			lean = -nearlyFlat,
			sink = config.restSinkFraction,
			forward = 0,
			seconds = config.fallSeconds,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.In,
		},
		{
			lean = -config.fallDegrees,
			sink = config.restSinkFraction,
			forward = 0,
			seconds = config.settleSeconds,
			style = Enum.EasingStyle.Back,
			direction = Enum.EasingDirection.Out,
		},
		{
			lean = -config.fallDegrees,
			sink = config.restSinkFraction,
			forward = 0,
			seconds = config.lieSeconds,
		},
		{
			lean = -config.fallDegrees,
			sink = config.restSinkFraction + config.sinkHeightFraction,
			forward = 0,
			seconds = config.sinkSeconds,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.In,
		},
	})
end

return EnemyAnimator
