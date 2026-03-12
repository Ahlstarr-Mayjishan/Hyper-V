--!strict

--[[
    Animation Module - HyperV Animation Engine
    Entry point for all animation functionality

    Export:
    - AnimationEngine: Main engine with all APIs
    - Types: Type definitions
    - Easing: Easing function utilities
    - Tween: Tween class
    - Composite: Sequence and Group classes
    - Runner: Animation runner
]]

local AnimationEngine = require(script.Parent.AnimationEngine)
local Types = require(script.Parent.types)
local Easing = require(script.Parent.Easing)

return {
	-- Main engine
	Engine = AnimationEngine,

	-- Type definitions
	Types = Types,

	-- Easing utilities
	Easing = Easing,

	-- Tween API
	Tween = function(target: Instance, properties: {[string]: any}, config: Types.TweenConfig?)
		return AnimationEngine.Tween(target, properties, config)
	end,

	-- Sequence (serial)
	Sequence = function()
		return AnimationEngine.Sequence()
	end,

	-- Group (parallel)
	Group = function()
		return AnimationEngine.Group()
	end,

	-- Predefined animations
	FadeIn = function(target: Instance, duration: number?)
		return AnimationEngine.FadeIn(target, duration)
	end,

	FadeOut = function(target: Instance, duration: number?)
		return AnimationEngine.FadeOut(target, duration)
	end,

	SlideIn = function(target: Instance, from: "Left" | "Right" | "Top" | "Bottom", duration: number?)
		return AnimationEngine.SlideIn(target, from, duration)
	end,

	SlideOut = function(target: Instance, to: "Left" | "Right" | "Top" | "Bottom", duration: number?)
		return AnimationEngine.SlideOut(target, to, duration)
	end,

	Scale = function(target: Instance, scale: number, duration: number?)
		return AnimationEngine.Scale(target, scale, duration)
	end,

	Shake = function(target: Instance, intensity: number?, duration: number?)
		return AnimationEngine.Shake(target, intensity, duration)
	end,

	Pulse = function(target: Instance, scale: number?, duration: number?)
		return AnimationEngine.Pulse(target, scale, duration)
	end,

	Bounce = function(target: Instance, height: number?, duration: number?)
		return AnimationEngine.Bounce(target, height, duration)
	end,

	Spin = function(target: Instance, rotations: number?, duration: number?)
		return AnimationEngine.Spin(target, rotations, duration)
	end,

	Color = function(target: Instance, color: Color3, duration: number?)
		return AnimationEngine.Color(target, color, duration)
	end,

	-- Utility
	Wait = function(animation)
		return AnimationEngine.Wait(animation)
	end,

	-- Debug
	GetStats = function()
		return AnimationEngine.GetStats()
	end,

	GetDebugInfo = function()
		return AnimationEngine.GetDebugInfo()
	end,

	SetDebug = function(enabled: boolean)
		AnimationEngine.SetDebug(enabled)
	end,

	SetFrameBudget = function(budget: number)
		AnimationEngine.SetFrameBudget(budget)
	end,

	StopAll = function()
		AnimationEngine.StopAll()
	end,

	PauseAll = function()
		AnimationEngine.PauseAll()
	end,

	ResumeAll = function()
		AnimationEngine.ResumeAll()
	end,
}
