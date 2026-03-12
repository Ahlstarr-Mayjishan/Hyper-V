--[[
    Animation Module Init
    Export all animation utilities
]]

local AnimationEngine = require(script.AnimationEngine)

return {
    Engine = AnimationEngine,
    Tween = AnimationEngine.Tween,
    Keyframe = AnimationEngine.Keyframe,
    Group = AnimationEngine.Group,
    Sequence = AnimationEngine.Sequence,
    FadeIn = AnimationEngine.FadeIn,
    FadeOut = AnimationEngine.FadeOut,
    SlideIn = AnimationEngine.SlideIn,
    Scale = AnimationEngine.Scale,
    Shake = AnimationEngine.Shake,
    Pulse = AnimationEngine.Pulse,
    Bounce = AnimationEngine.Bounce,
    Wait = AnimationEngine.Wait,
}

