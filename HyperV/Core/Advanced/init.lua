--!strict

--[[
    Advanced Animation Module - HyperV Advanced
    Advanced animation APIs với priority, chain, stagger, keyframe, morph

    Export:
    - PriorityQueue: Animation với độ ưu tiên
    - Chain: Fluent chain API
    - Stagger: Stagger animation cho list
    - Keyframe: Keyframe-based animation
    - Morph: Interpolate giữa 2 states
]]

local Types = require(script.types)
local PriorityQueue = require(script.PriorityQueue)
local Chain = require(script.Chain)
local Stagger = require(script.Stagger)
local KeyframeModule = require(script.Keyframe)
local Morph = require(script.Morph)

-- Type imports
export type ChainConfig = Types.ChainConfig
export type ChainItem = Types.ChainItem
export type StaggerConfig = Types.StaggerConfig
export type PriorityConfig = Types.PriorityConfig
export type KeyframeConfig = Types.KeyframeConfig
export type MorphConfig = Types.MorphConfig
export type AdvancedAnimationHandle = Types.AdvancedAnimationHandle

local Advanced = {}

-- ============================================
-- Priority Queue API
-- ============================================

--[[
    Create a PriorityQueue
    Priority cao hơn = chạy trước
    MaxConcurrent = số animation chạy đồng thời

    Ví dụ:
    HyperV.PriorityQueue({MaxConcurrent = 2})
        :Enqueue(anim1, 10, "high")
        :Enqueue(anim2, 5, "medium")
        :Enqueue(anim3, 1, "low")
]]
function Advanced.PriorityQueue(config: PriorityConfig?): PriorityQueue
	return PriorityQueue.new(config)
end

-- ============================================
-- Chain API
-- ============================================

--[[
    Create a Chain với fluent API
    Nối nhiều animations dễ dàng

    Ví dụ:
    HyperV.Chain()
        :Then(frame1, {Position = UDim2.new(0, 100, 0, 0)}):Duration(0.3)
        :Then(frame2, {Size = UDim2.new(0, 200, 0, 50)}):Duration(0.5)
        :Wait(0.2)
        :Callback(function() print("Done!") end)
        :Loop(true)
        :Play()
]]
function Advanced.Chain(config: ChainConfig?): Chain
	return Chain.new(config)
end

-- ============================================
-- Stagger API
-- ============================================

--[[
    Create a Stagger animation
    Animation list với stagger delay

    Ví dụ:
    HyperV.Stagger()
        :Instances({frame1, frame2, frame3, frame4})
        :Property("Position")
        :To(UDim2.new(0, 100, 0, 0))
        :Duration(0.3)
        :Delay(0.1)
        :Play()
]]
function Advanced.Stagger(config: StaggerConfig?): Stagger
	return Stagger.new(config)
end

-- ============================================
-- Keyframe API
-- ============================================

--[[
    Create a Keyframe animation

    Ví dụ:
    HyperV.Keyframe()
        :AddTrack({
            Target = frame,
            Keyframes = {
                {Time = 0, Position = UDim2.new(0, 0, 0, 0)},
                {Time = 0.5, Position = UDim2.new(0, 100, 0, 0)},
                {Time = 1, Position = UDim2.new(0, 0, 0, 0)},
            },
            Duration = 2,
        })
        :Loop(true)
        :OnComplete(function() print("Keyframe done!") end)
        :Play()
]]
function Advanced.Keyframe(config: KeyframeConfig?): any
	return KeyframeModule.Keyframe.new(config)
end

-- ============================================
-- Morph API
-- ============================================

--[[
    Create a Morph animation
    Interpolate giữa 2 states

    Ví dụ:
    HyperV.Morph()
        :From(frame, {Size = UDim2.new(0, 100, 0, 100)})
        :To(frame, {Size = UDim2.new(0, 200, 0, 200)})
        :Duration(0.5)
        :Easing("Back", "Out")
        :Play()
]]
function Advanced.Morph(config: MorphConfig?): Morph
	return Morph.new(config)
end

-- ============================================
-- Utility Functions
-- ============================================

--[[
    Quick stagger cho list of instances
    Wrapper tiện lợi

    Ví dụ:
    HyperV.StaggerIn({frame1, frame2, frame3}, "Position", UDim2.new(0, 100, 0, 0))
]]
function Advanced.StaggerIn(instances: {Instance}, property: string, toValue: any, duration: number?): Stagger
	return Stagger.new({
		Instances = instances,
		Property = property,
		ToValue = toValue,
		Duration = duration or 0.3,
		StaggerDelay = 0.1,
	})
end

--[[
    Quick stagger out (reverse)
]]
function Advanced.StaggerOut(instances: {Instance}, property: string, fromValue: any, duration: number?): Stagger
	-- First set all to fromValue
	for _, instance in ipairs(instances) do
		instance[property] = fromValue
	end

	return Stagger.new({
		Instances = instances,
		Property = property,
		ToValue = nil, -- Will restore to current
		Duration = duration or 0.3,
		StaggerDelay = 0.1,
	})
end

--[[
    Quick fade in stagger
]]
function Advanced.StaggerFadeIn(instances: {Instance}, duration: number?, staggerDelay: number?): Stagger
	return Stagger.new({
		Instances = instances,
		Property = "BackgroundTransparency",
		ToValue = 0,
		Duration = duration or 0.3,
		StaggerDelay = staggerDelay or 0.05,
	})
end

--[[
    Quick fade out stagger
]]
function Advanced.StaggerFadeOut(instances: {Instance}, duration: number?, staggerDelay: number?): Stagger
	return Stagger.new({
		Instances = instances,
		Property = "BackgroundTransparency",
		ToValue = 1,
		Duration = duration or 0.3,
		StaggerDelay = staggerDelay or 0.05,
	})
end

-- ============================================
-- Quick Aliases
-- ============================================

Advanced.Queue = Advanced.PriorityQueue
Advanced.Sequence = Advanced.Chain
Advanced.Kf = Advanced.Keyframe

return Advanced
