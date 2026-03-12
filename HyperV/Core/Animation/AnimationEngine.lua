--!strict

--[[
    Animation Engine - HyperV Animation Engine
    Single Responsibility: Main entry point cho animation system

    Cung cấp:
    - Tween animations với fluent API
    - Keyframe animations
    - Sequence (serial) và Group (parallel) composites
    - Predefined animations (FadeIn, FadeOut, etc)
    - Debug và diagnostics
]]

local TweenService = game:GetService("TweenService")

-- Module imports
local Types = require(script.Parent.types)
local Easing = require(script.Parent.Easing)
local Tween = require(script.Parent.Tween)
local Composite = require(script.Parent.Composite)
local Runner = require(script.Parent.Runner)

-- Type imports
export type AnimationHandle = Types.AnimationHandle
export type TweenConfig = Types.TweenConfig
export type AnimationState = Types.AnimationState
export type EngineConfig = Types.EngineConfig
export type AnimationDebugInfo = Types.AnimationDebugInfo
export type EasingStyle = Types.EasingStyle
export type EasingDirection = Types.EasingDirection

-- ============================================
-- Animation Engine
-- ============================================

local AnimationEngine = {}
AnimationEngine.__index = AnimationEngine

-- Singleton instance
local _instance: AnimationEngine? = nil
local _runner: Runner? = nil

--[[
    Get or create singleton instance
]]
function AnimationEngine.getInstance(config: EngineConfig?): AnimationEngine
	if not _instance then
		_instance = AnimationEngine.new(config)
	end
	return _instance
end

--[[
    Constructor
]]
function AnimationEngine.new(config: EngineConfig?): AnimationEngine
	local self = setmetatable({}, AnimationEngine)

	self._runner = Runner.new(config)
	self._runner:Start()

	return self
end

-- ============================================
-- Tween API
-- ============================================

--[[
    Create a new tween animation
    Fluent API - chain các method lại với nhau

    Ví dụ:
    AnimationEngine.Tween(frame, {Position = UDim2.new(0, 100, 0, 0)})
        :Duration(0.5)
        :Easing("Quad", "Out")
        :OnComplete(function() print("Done!") end)
        :Play()
]]
function AnimationEngine.Tween(target: Instance, properties: {[string]: any}, config: TweenConfig?): Tween
	local tween = Tween.new(target, properties, config)

	-- Register with runner
	if _runner then
		_runner:Register(tween)
	end

	return tween
end

-- ============================================
-- Sequence API
-- ============================================

--[[
    Create a new sequence (animations chạy serial)

    Ví dụ:
    AnimationEngine.Sequence()
        :Add(AnimationEngine.Tween(frame1, {Position = ...}))
        :Add(AnimationEngine.Tween(frame2, {Position = ...}))
        :OnComplete(function() print("Sequence done!") end)
        :Play()
]]
function AnimationEngine.Sequence(): Composite.Sequence
	local sequence = Composite.Sequence.new()

	-- Register with runner
	if _runner then
		_runner:Register(sequence)
	end

	return sequence
end

-- ============================================
-- Group API
-- ============================================

--[[
    Create a new group (animations chạy parallel)

    Ví dụ:
    AnimationEngine.Group()
        :Add(AnimationEngine.Tween(frame1, {Size = ...}))
        :Add(AnimationEngine.Tween(frame2, {Position = ...}))
        :OnComplete(function() print("All done!") end)
        :Play()
]]
function AnimationEngine.Group(): Composite.Group
	local group = Composite.Group.new()

	-- Register with runner
	if _runner then
		_runner:Register(group)
	end

	return group
end

-- ============================================
-- Predefined Animations
-- ============================================

--[[
    FadeIn animation
    Animation opacity từ 1 xuống 0 (biến mất)
]]
function AnimationEngine.FadeIn(target: Instance, duration: number?): Tween
	return AnimationEngine.Tween(
		target,
		{
			BackgroundTransparency = 0,
			TextTransparency = 0,
			ImageTransparency = 0,
		},
		{
			Duration = duration,
			EasingStyle = "Quad",
			EasingDirection = "Out",
		}
	)
end

--[[
    FadeOut animation
    Animation opacity từ 0 lên 1 (hiện ra)
]]
function AnimationEngine.FadeOut(target: Instance, duration: number?): Tween
	return AnimationEngine.Tween(
		target,
		{
			BackgroundTransparency = 1,
			TextTransparency = 1,
			ImageTransparency = 1,
		},
		{
			Duration = duration,
			EasingStyle = "Quad",
			EasingDirection = "In",
		}
	)
end

--[[
    SlideIn animation - trượt vào từ một hướng
    from: "Left" | "Right" | "Top" | "Bottom"
]]
function AnimationEngine.SlideIn(target: Instance, from: "Left" | "Right" | "Top" | "Bottom", duration: number?): Tween
	local startPosition = target.Position
	local targetPosition = startPosition
	local offset = 50

	if from == "Left" then
		target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset - offset, startPosition.Y.Scale, startPosition.Y.Offset)
	elseif from == "Right" then
		target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + offset, startPosition.Y.Scale, startPosition.Y.Offset)
	elseif from == "Top" then
		target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset, startPosition.Y.Scale, startPosition.Y.Offset - offset)
	elseif from == "Bottom" then
		target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset, startPosition.Y.Scale, startPosition.Y.Offset + offset)
	end

	return AnimationEngine.Tween(
		target,
		{Position = targetPosition},
		{
			Duration = duration,
			EasingStyle = "Quad",
			EasingDirection = "Out",
		}
	)
end

--[[
    SlideOut animation - trượt ra theo một hướng
]]
function AnimationEngine.SlideOut(target: Instance, to: "Left" | "Right" | "Top" | "Bottom", duration: number?): Tween
	local startPosition = target.Position
	local targetPosition = startPosition
	local offset = 50

	if to == "Left" then
		targetPosition = UDim2.new(startPosition.X.Scale, startPosition.X.Offset - offset, startPosition.Y.Scale, startPosition.Y.Offset)
	elseif to == "Right" then
		targetPosition = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + offset, startPosition.Y.Scale, startPosition.Y.Offset)
	elseif to == "Top" then
		targetPosition = UDim2.new(startPosition.X.Scale, startPosition.X.Offset, startPosition.Y.Scale, startPosition.Y.Offset - offset)
	elseif to == "Bottom" then
		targetPosition = UDim2.new(startPosition.X.Scale, startPosition.X.Offset, startPosition.Y.Scale, startPosition.Y.Offset + offset)
	end

	return AnimationEngine.Tween(
		target,
		{Position = targetPosition},
		{
			Duration = duration,
			EasingStyle = "Quad",
			EasingDirection = "In",
		}
	)
end

--[[
    Scale animation - phóng to/thu nhỏ
    scale: > 1 phóng to, < 1 thu nhỏ
]]
function AnimationEngine.Scale(target: Instance, scale: number, duration: number?): Tween
	local startSize = target.Size

	return AnimationEngine.Tween(
		target,
		{
			Size = UDim2.new(
				startSize.X.Scale * scale,
				startSize.X.Offset * scale,
				startSize.Y.Scale * scale,
				startSize.Y.Offset * scale
			)
		},
		{
			Duration = duration,
			EasingStyle = "Back",
			EasingDirection = "Out",
		}
	)
end

--[[
    Shake animation - rung lắc
    intensity: độ mạnh của rung (pixel offset)
    duration: thời gian (default 0.5s)
]]
function AnimationEngine.Shake(target: Instance, intensity: number?, duration: number?): Tween
	local intensityValue = intensity or 10
	local durationValue = duration or 0.5
	local startPosition = target.Position
	local startTime = os.clock()

	-- Sử dụng manual animation thay vì TweenService
	local shake = Tween.new(
		target,
		{Position = startPosition}, -- Dummy properties
		{Duration = durationValue, EasingStyle = "Linear"}
	)

	shake.OnUpdate = function(progress: number)
		if progress < 1 then
			local offsetX = math.random(-intensityValue, intensityValue)
			local offsetY = math.random(-intensityValue, intensityValue)
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + offsetX,
				startPosition.Y.Scale,
				startPosition.Y.Offset + offsetY
			)
		else
			target.Position = startPosition
		end
	end

	return shake
end

--[[
    Pulse animation - phóng to rồi thu nhỏ về
]]
function AnimationEngine.Pulse(target: Instance, scale: number?, duration: number?): Composite.Group
	local scaleValue = scale or 1.1
	local durationValue = duration or 0.6
	local startSize = target.Size

	return AnimationEngine.Group()
		:Add(
			AnimationEngine.Tween(
				target,
				{
					Size = UDim2.new(
						startSize.X.Scale * scaleValue,
						startSize.X.Offset * scaleValue,
						startSize.Y.Scale * scaleValue,
						startSize.Y.Offset * scaleValue
					)
				},
				{
					Duration = durationValue / 2,
					EasingStyle = "Sine",
					EasingDirection = "InOut",
				}
			)
		)
		:Add(
			AnimationEngine.Tween(
				target,
				{Size = startSize},
				{
					Duration = durationValue / 2,
					EasingStyle = "Sine",
					EasingDirection = "InOut",
				}
			)
		)
end

--[[
    Bounce animation - nảy lên rồi rơi xuống
]]
function AnimationEngine.Bounce(target: Instance, height: number?, duration: number?): Composite.Group
	local heightValue = height or 30
	local durationValue = duration or 0.8
	local startPosition = target.Position

	return AnimationEngine.Group()
		:Add(
			AnimationEngine.Tween(
				target,
				{
					Position = UDim2.new(
						startPosition.X.Scale,
						startPosition.X.Offset,
						startPosition.Y.Scale,
						startPosition.Y.Offset - heightValue
					)
				},
				{
					Duration = durationValue / 2,
					EasingStyle = "Quad",
					EasingDirection = "Out",
				}
			)
		)
		:Add(
			AnimationEngine.Tween(
				target,
				{Position = startPosition},
				{
					Duration = durationValue / 2,
					EasingStyle = "Bounce",
					EasingDirection = "Out",
				}
			)
		)
end

--[[
    Spin animation - xoay
    rotations: số vòng xoay
]]
function AnimationEngine.Spin(target: Instance, rotations: number?, duration: number?): Tween
	local rotationsValue = rotations or 1
	local durationValue = duration or 1
	local startRotation = target.Rotation

	return AnimationEngine.Tween(
		target,
		{Rotation = startRotation + (360 * rotationsValue)},
		{
			Duration = durationValue,
			EasingStyle = "Quad",
			EasingDirection = "InOut",
		}
	)
end

--[[
    Color animation - đổi màu
]]
function AnimationEngine.Color(target: Instance, color: Color3, duration: number?): Tween
	return AnimationEngine.Tween(
		target,
		{BackgroundColor3 = color},
		{
			Duration = duration,
			EasingStyle = "Quad",
			EasingDirection = "Out",
		}
	)
end

-- ============================================
-- Utility Functions
-- ============================================

--[[
    Wait for animation to complete (blocking)
]]
function AnimationEngine.Wait(animation: AnimationHandle): ()
	local completed = false

	local originalComplete = animation.OnComplete
	animation.OnComplete = function()
		completed = true
		if originalComplete then
			originalComplete()
		end
	end

	animation:Play()

	while not completed do
		task.wait()
	end
end

-- ============================================
-- Debug & Diagnostics
-- ============================================

--[[
    Get engine stats
]]
function AnimationEngine.GetStats(): {
	ActiveAnimations: number,
	TotalPlayed: number,
	TotalCompleted: number,
	AverageFrameTime: number,
	MaxFrameTime: number,
	FrameBudget: number,
}?
	if _runner then
		return _runner:GetStats()
	end
	return nil
end

--[[
    Get debug info for all active animations
]]
function AnimationEngine.GetDebugInfo(): {AnimationDebugInfo}?
	if _runner then
		return _runner:GetDebugInfo()
	end
	return nil
end

--[[
    Enable/disable debug mode
]]
function AnimationEngine.SetDebug(enabled: boolean): ()
	if _runner then
		_runner:SetDebug(enabled)
	end
end

--[[
    Set frame budget
]]
function AnimationEngine.SetFrameBudget(budget: number): ()
	if _runner then
		_runner:SetFrameBudget(budget)
	end
end

--[[
    Stop all active animations
]]
function AnimationEngine.StopAll(): ()
	if _runner then
		_runner:StopAll()
	end
end

--[[
    Pause all active animations
]]
function AnimationEngine.PauseAll(): ()
	if _runner then
		_runner:PauseAll()
	end
end

--[[
    Resume all paused animations
]]
function AnimationEngine.ResumeAll(): ()
	if _runner then
		_runner:ResumeAll()
	end
end

-- ============================================
-- Cleanup
-- ============================================

--[[
    Destroy the engine
]]
function AnimationEngine.Destroy(): ()
	if _runner then
		_runner:Destroy()
		_runner = nil
	end
	_instance = nil
end

return AnimationEngine
