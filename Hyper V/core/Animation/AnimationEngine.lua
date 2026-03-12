--[[
    Animation Engine - Core Module
    Single Responsibility: Quản lý và chạy animations
    
    Features:
    - Tween animations với nhiều easing functions
    - Keyframe animations
    - Parallel và Sequence groups
    - Animation tracks
    - Loop/Reverse/Repeat
    - Callbacks (onStart, onUpdate, onComplete)
    - Pause/Resume/Stop controls
]]

local TweenService = game:GetService("TweenService")

-- Types
export type EasingStyle = "Linear" | "Quad" | "Cubic" | "Quart" | "Quint" | "Sine" | "Expo" | "Circ" | "Elastic" | "Bounce" | "Back"
export type EasingDirection = "In" | "Out" | "InOut"

export type TweenConfig = {
    Duration: number?,
    EasingStyle: EasingStyle?,
    EasingDirection: EasingDirection?,
    Delay: number?,
    Repeat: number?, -- -1 for infinite
    Reverses: boolean?,
}

export type Keyframe = {
    Time: number, -- 0 to 1
    [string]: any, -- properties
}

export type KeyframeTrack = {
    Target: Instance,
    Keyframes: {Keyframe},
    Duration: number,
    EasingStyle: EasingStyle?,
    EasingDirection: EasingDirection?,
}

export type AnimationState = "Playing" | "Paused" | "Stopped"

-- Easing Functions Map
local EasingStyles = {
    Linear = Enum.EasingStyle.Linear,
    Quad = Enum.EasingStyle.Quad,
    Cubic = Enum.EasingStyle.Cubic,
    Quart = Enum.EasingStyle.Quart,
    Quint = Enum.EasingStyle.Quint,
    Sine = Enum.EasingStyle.Sine,
    Expo = Enum.EasingStyle.Expo,
    Circ = Enum.EasingStyle.Circ,
    Elastic = Enum.EasingStyle.Elastic,
    Bounce = Enum.EasingStyle.Bounce,
    Back = Enum.EasingStyle.Back,
}

local EasingDirections = {
    In = Enum.EasingDirection.In,
    Out = Enum.EasingDirection.Out,
    InOut = Enum.EasingDirection.InOut,
}

-- Default config
local DEFAULT_TWEEN_CONFIG = {
    Duration = 0.3,
    EasingStyle = "Quad",
    EasingDirection = "Out",
    Delay = 0,
    Repeat = 0,
    Reverses = false,
}

-- Animation Class
local Animation = {}
Animation.__index = Animation

function Animation.new(config: TweenConfig?)
    local self = setmetatable({}, Animation)
    
    self.Config = config or {}
    for k, v in pairs(DEFAULT_TWEEN_CONFIG) do
        if self.Config[k] == nil then
            self.Config[k] = v
        end
    end
    
    self.Target = nil
    self.Properties = {}
    self.OnStart = nil
    self.OnUpdate = nil
    self.OnComplete = nil
    
    self._state = "Stopped" :: AnimationState
    self._elapsed = 0
    self._repeated = 0
    self._reversing = false
    self._tween = nil
    self._connection = nil
    self._startValues = {}
    
    return self
end

function Animation:Target(instance: Instance)
    self.Target = instance
    return self
end

function Animation:Properties(props: {string: any})
    self.Properties = props
    return self
end

function Animation:OnStart(callback: () -> ())
    self.OnStart = callback
    return self
end

function Animation:OnUpdate(callback: (progress: number) -> ())
    self.OnUpdate = callback
    return self
end

function Animation:OnComplete(callback: () -> ())
    self.OnComplete = callback
    return self
end

function Animation:Duration(duration: number)
    self.Config.Duration = duration
    return self
end

function Animation:Easing(style: EasingStyle, direction: EasingDirection?)
    self.Config.EasingStyle = style
    if direction then
        self.Config.EasingDirection = direction
    end
    return self
end

function Animation:Delay(delay: number)
    self.Config.Delay = delay
    return self
end

function Animation:Repeat(count: number)
    self.Config.Repeat = count
    return self
end

function Animation:Reverses(reverses: boolean)
    self.Config.Reverses = reverses
    return self
end

function Animation:Play()
    if not self.Target then
        warn("[Animation] No target set")
        return self
    end
    
    if self._state == "Playing" then
        return self
    end
    
    -- Store start values
    for prop, _ in pairs(self.Properties) do
        self._startValues[prop] = self.Target[prop]
    end
    
    -- Create tween info
    local tweenInfo = TweenInfo.new(
        self.Config.Duration,
        EasingStyles[self.Config.EasingStyle] or Enum.EasingStyle.Quad,
        EasingDirections[self.Config.EasingDirection] or Enum.EasingDirection.Out,
        self.Config.Reverses,
        self.Config.Repeat or 0,
        self.Config.Delay
    )
    
    -- Create tween
    self._tween = TweenService:Create(self.Target, tweenInfo, self.Properties)
    
    -- Connect events
    if self.OnStart then
        self._tween.Completed:Connect(function()
            if self.OnComplete then
                self.OnComplete()
            end
        end)
    end
    
    -- Play
    self._state = "Playing"
    self._tween:Play()
    
    if self.OnStart then
        self.OnStart()
    end
    
    -- Update loop
    task.spawn(function()
        while self._state == "Playing" and self._tween and self._tween.PlaybackState == Enum.PlaybackState.Playing do
            local progress = self._tween.AnimationInfo.Position / (self.Config.Duration or 0.3)
            if self.OnUpdate then
                self.OnUpdate(math.min(1, math.max(0, progress)))
            end
            task.wait()
        end
        
        if self._state == "Playing" and self.OnComplete then
            self.OnComplete()
        end
    end)
    
    return self
end

function Animation:Pause()
    if self._tween and self._state == "Playing" then
        self._tween:Pause()
        self._state = "Paused"
    end
    return self
end

function Animation:Resume()
    if self._tween and self._state == "Paused" then
        self._tween:Resume()
        self._state = "Playing"
    end
    return self
end

function Animation:Stop()
    if self._tween then
        self._tween:Cancel()
        self._state = "Stopped"
    end
    return self
end

function Animation:GetProgress(): number
    if self._tween then
        return self._tween.AnimationInfo.Position / (self.Config.Duration or 0.3)
    end
    return 0
end

function Animation:IsPlaying(): boolean
    return self._state == "Playing"
end

-- Keyframe Animation
local KeyframeAnimation = {}
KeyframeAnimation.__index = KeyframeAnimation

function KeyframeAnimation.new()
    local self = setmetatable({}, KeyframeAnimation)
    
    self.Tracks = {}
    self.Duration = 1
    self.OnComplete = nil
    self._connection = nil
    
    return self
end

function KeyframeAnimation:AddTrack(track: KeyframeTrack)
    table.insert(self.Tracks, track)
    if track.Duration > self.Duration then
        self.Duration = track.Duration
    end
    return self
end

function KeyframeAnimation:OnComplete(callback: () -> ())
    self.OnComplete = callback
    return self
end

function KeyframeAnimation:Play()
    local startTime = os.clock()
    
    task.spawn(function()
        while true do
            local elapsed = os.clock() - startTime
            local progress = math.min(1, elapsed / self.Duration)
            
            for _, track in ipairs(self.Tracks) do
                local target = track.Target
                local keyframes = track.Keyframes
                
                -- Find surrounding keyframes
                local prevKf = nil
                local nextKf = nil
                
                for i, kf in ipairs(keyframes) do
                    if kf.Time <= progress then
                        prevKf = kf
                    end
                    if kf.Time >= progress and not nextKf then
                        nextKf = kf
                    end
                end
                
                prevKf = prevKf or keyframes[1]
                nextKf = nextKf or keyframes[#keyframes]
                
                -- Interpolate
                if prevKf and nextKf and prevKf ~= nextKf then
                    local localProgress = (progress - prevKf.Time) / (nextKf.Time - prevKf.Time)
                    localProgress = math.max(0, math.min(1, localProgress))
                    
                    for prop, targetValue in next(prevKf) do
                        if prop ~= "Time" then
                            local startValue = prevKf[prop]
                            local currentValue = startValue + (targetValue - startValue) * localProgress
                            target[prop] = currentValue
                        end
                    end
                elseif prevKf then
                    for prop, value in next(prevKf) do
                        if prop ~= "Time" then
                            target[prop] = value
                        end
                    end
                end
            end
            
            if progress >= 1 then
                if self.OnComplete then
                    self.OnComplete()
                end
                break
            end
            
            task.wait()
        end
    end)
    
    return self
end

function KeyframeAnimation:Stop()
    -- Would need tracking task to cancel
    return self
end

-- Animation Group (Parallel)
local AnimationGroup = {}
AnimationGroup.__index = AnimationGroup

function AnimationGroup.new()
    local self = setmetatable({}, AnimationGroup)
    
    self.Animations = {} :: {Animation}
    self.OnComplete = nil
    self._running = 0
    
    return self
end

function AnimationGroup:Add(animation: Animation)
    table.insert(self.Animations, animation)
    return self
end

function AnimationGroup:Play()
    self._running = #self.Animations
    
    if self._running == 0 then
        if self.OnComplete then
            self.OnComplete()
        end
        return self
    end
    
    for _, anim in ipairs(self.Animations) do
        anim:OnComplete(function()
            self._running = self._running - 1
            if self._running == 0 and self.OnComplete then
                self.OnComplete()
            end
        end):Play()
    end
    
    return self
end

function AnimationGroup:Stop()
    for _, anim in ipairs(self.Animations) do
        anim:Stop()
    end
    return self
end

function AnimationGroup:Pause()
    for _, anim in ipairs(self.Animations) do
        anim:Pause()
    end
    return self
end

function AnimationGroup:Resume()
    for _, anim in ipairs(self.Animations) do
        anim:Resume()
    end
    return self
end

-- Animation Sequence (Serial)
local AnimationSequence = {}
AnimationSequence.__index = AnimationSequence

function AnimationSequence.new()
    local self = setmetatable({}, AnimationSequence)
    
    self.Animations = {} :: {Animation}
    self.OnComplete = nil
    self._currentIndex = 1
    
    return self
end

function AnimationSequence:Add(animation: Animation)
    table.insert(self.Animations, animation)
    return self
end

function AnimationSequence:Play()
    local function playNext(index)
        if index > #self.Animations then
            if self.OnComplete then
                self.OnComplete()
            end
            return
        end
        
        local anim = self.Animations[index]
        anim:OnComplete(function()
            playNext(index + 1)
        end):Play()
    end
    
    playNext(1)
    return self
end

function AnimationSequence:Stop()
    for _, anim in ipairs(self.Animations) do
        anim:Stop()
    end
    return self
end

-- Utility functions
local AnimationEngine = {}

function AnimationEngine.Tween(target: Instance, properties: {string: any}, config: TweenConfig?): Animation
    return Animation.new(config)
        :Target(target)
        :Properties(properties)
end

function AnimationEngine.Keyframe(): KeyframeAnimation
    return KeyframeAnimation.new()
end

function AnimationEngine.Group(): AnimationGroup
    return AnimationGroup.new()
end

function AnimationEngine.Sequence(): AnimationSequence
    return AnimationSequence.new()
end

-- Predefined animations
function AnimationEngine.FadeIn(target: Instance, duration: number): Animation
    return Animation.new({Duration = duration, EasingStyle = "Quad", EasingDirection = "Out"})
        :Target(target)
        :Properties({BackgroundTransparency = 0, TextTransparency = 0})
end

function AnimationEngine.FadeOut(target: Instance, duration: number): Animation
    return Animation.new({Duration = duration, EasingStyle = "Quad", EasingDirection = "In"})
        :Target(target)
        :Properties({BackgroundTransparency = 1, TextTransparency = 1})
end

function AnimationEngine.SlideIn(target: Instance, from: "Left" | "Right" | "Top" | "Bottom", duration: number): Animation
    local startPos = target.Position
    local targetPos = startPos
    
    local offset = 50
    if from == "Left" then
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset - offset, startPos.Y.Scale, startPos.Y.Offset)
    elseif from == "Right" then
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + offset, startPos.Y.Scale, startPos.Y.Offset)
    elseif from == "Top" then
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset - offset)
    elseif from == "Bottom" then
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + offset)
    end
    
    return Animation.new({Duration = duration, EasingStyle = "Quad", EasingDirection = "Out"})
        :Target(target)
        :Properties({Position = targetPos})
end

function AnimationEngine.Scale(target: Instance, scale: number, duration: number): Animation
    local startSize = target.Size
    
    return Animation.new({Duration = duration, EasingStyle = "Back", EasingDirection = "Out"})
        :Target(target)
        :Properties({
            Size = UDim2.new(
                startSize.X.Scale * scale,
                startSize.X.Offset * scale,
                startSize.Y.Scale * scale,
                startSize.Y.Offset * scale
            )
        })
end

function AnimationEngine.Shake(target: Instance, intensity: number, duration: number)
    local startPos = target.Position
    local startTime = os.clock()
    
    task.spawn(function()
        while os.clock() - startTime < duration do
            local offset = math.random(-intensity, intensity)
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + offset,
                startPos.Y.Scale,
                startPos.Y.Offset + offset
            )
            task.wait(0.05)
        end
        target.Position = startPos
    end)
end

function AnimationEngine.Pulse(target: Instance, scale: number, duration: number)
    local startSize = target.Size
    
    return AnimationEngine.Group()
        :Add(Animation.new({Duration = duration / 2, EasingStyle = "Sine", EasingDirection = "InOut"})
            :Target(target)
            :Properties({
                Size = UDim2.new(
                    startSize.X.Scale * scale,
                    startSize.X.Offset * scale,
                    startSize.Y.Scale * scale,
                    startSize.Y.Offset * scale
                )
            }))
        :Add(Animation.new({Duration = duration / 2, EasingStyle = "Sine", EasingDirection = "InOut"})
            :Target(target)
            :Properties({Size = startSize}))
end

function AnimationEngine.Bounce(target: Instance, height: number, duration: number)
    local startPos = target.Position
    
    return AnimationEngine.Group()
        :Add(Animation.new({Duration = duration / 2, EasingStyle = "Quad", EasingDirection = "Out"})
            :Target(target)
            :Properties({Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset - height)}))
        :Add(Animation.new({Duration = duration / 2, EasingStyle = "Bounce", EasingDirection = "Out"})
            :Target(target)
            :Properties({Position = startPos}))
end

-- Utility: Wait for animation
function AnimationEngine.Wait(animation: Animation)
    local completed = false
    animation:OnComplete(function()
        completed = true
    end)
    animation:Play()
    
    while not completed do
        task.wait()
    end
end

return AnimationEngine

