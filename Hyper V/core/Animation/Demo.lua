--[[
    Animation Demo - Test file
    Shows how to use the Animation Engine
]]

local Animation = require(script.Parent)

-- Example 1: Simple Tween
local function example1()
    local frame = script.Parent -- Replace with your frame
    
    -- Basic tween
    Animation.Tween(frame, {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 500, 0, 300),
    }, {
        Duration = 0.5,
        EasingStyle = "Quad",
        EasingDirection = "Out",
    }):Play()
end

-- Example 2: Fade In/Out
local function example2()
    local frame = script.Parent
    
    -- Fade in
    Animation.FadeIn(frame, 0.3)
        :OnComplete(function()
            -- Fade out after 1 second
            task.wait(1)
            Animation.FadeOut(frame, 0.3):Play()
        end)
        :Play()
end

-- Example 3: Animation Group (Parallel)
local function example3()
    local frame1 = script.Parent
    local frame2 = script.Parent.Parent.Frame2
    
    Animation.Group()
        :Add(Animation.Tween(frame1, {Position = UDim2.new(0, 0, 0, 0)}, {Duration = 0.3}))
        :Add(Animation.Tween(frame2, {Position = UDim2.new(0, 500, 0, 0)}, {Duration = 0.3}))
        :Play()
end

-- Example 4: Animation Sequence (Serial)
local function example4()
    local frame = script.Parent
    
    Animation.Sequence()
        :Add(Animation.Tween(frame, {Position = UDim2.new(0, 0, 0, 0)}, {Duration = 0.3}))
        :Add(Animation.Tween(frame, {Size = UDim2.new(0, 200, 0, 200)}, {Duration = 0.3}))
        :Add(Animation.Tween(frame, {Rotation = 360}, {Duration = 0.5}))
        :Play()
end

-- Example 5: Slide In
local function example5()
    local frame = script.Parent
    
    Animation.SlideIn(frame, "Right", 0.5):Play()
end

-- Example 6: Scale/Pulse
local function example6()
    local button = script.Parent
    
    Animation.Pulse(button, 1.1, 0.3):Play()
end

-- Example 7: Shake
local function example7()
    local frame = script.Parent
    
    Animation.Shake(frame, 10, 0.5)
end

-- Example 8: Bounce
local function example8()
    local frame = script.Parent
    
    Animation.Bounce(frame, 50, 0.5):Play()
end

-- Example 9: Complex tween with callbacks
local function example9()
    local frame = script.Parent
    
    Animation.Tween(frame, {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 400, 0, 200),
    }, {
        Duration = 0.5,
        EasingStyle = "Back",
        EasingDirection = "Out",
    })
        :OnStart(function()
            print("Animation started!")
        end)
        :OnUpdate(function(progress)
            print("Progress:", math.floor(progress * 100) .. "%")
        end)
        :OnComplete(function()
            print("Animation complete!")
        end)
        :Play()
end

-- Example 10: Chain animations
local function example10()
    local frame = script.Parent
    
    Animation.FadeIn(frame, 0.3)
        :OnComplete(function()
            Animation.Scale(frame, 1.2, 0.3)
                :OnComplete(function()
                    Animation.FadeOut(frame, 0.3):Play()
                end)
                :Play()
        end)
        :Play()
end

-- Example 11: Keyframe animation
local function example11()
    local frame = script.Parent
    
    Animation.Keyframe()
        :AddTrack({
            Target = frame,
            Duration = 1,
            Keyframes = {
                {Time = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 100, 0, 100)},
                {Time = 0.5, Position = UDim2.new(0, 200, 0, 0), Size = UDim2.new(0, 150, 0, 150)},
                {Time = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 100, 0, 100)},
            },
        })
        :Play()
end

-- Example 12: Stop/Pause/Resume
local function example12()
    local frame = script.Parent
    
    local anim = Animation.Tween(frame, {
        Position = UDim2.new(0, 500, 0, 0),
    }, {Duration = 2})
    
    -- Play, then pause after 0.5s
    anim:Play()
    task.wait(0.5)
    anim:Pause()
    
    task.wait(1)
    anim:Resume() -- Continue
    
    task.wait(0.5)
    anim:Stop() -- Stop completely
end

-- Export examples
return {
    Example1 = example1,
    Example2 = example2,
    Example3 = example3,
    Example4 = example4,
    Example5 = example5,
    Example6 = example6,
    Example7 = example7,
    Example8 = example8,
    Example9 = example9,
    Example10 = example10,
    Example11 = example11,
    Example12 = example12,
}

