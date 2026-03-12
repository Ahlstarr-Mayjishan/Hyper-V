--[[
    Hyper-V - Skeleton Component
    Hiệu ứng loading skeleton
]]

local Skeleton = {}

function Skeleton.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Skeleton})
    
    self.Name = config.Name or "Skeleton"
    self.Width = config.Width or 1
    self.Height = config.Height or 20
    self.Radius = config.Radius or 4
    self.Speed = config.Speed or 1.5
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Skeleton:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(self.Width, 0, 0, self.Height)
    Container.BackgroundColor3 = self.Theme.Second
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, self.Radius)
    
    -- Gradient overlay for shimmer effect
    local Gradient = Instance.new("UIGradient")
    Gradient.Rotation = 45
    Gradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    }
    Gradient.Parent = Container
    
    -- Animation
    self:Animate(Gradient)
    
    return Container
end

function Skeleton:Animate(gradient)
    local TweenService = game:GetService("TweenService")
    
    -- Create the shimmer animation
    local function shimmer()
        local startPos = -1
        local endPos = 1
        
        gradient.Position = UDim2.new(startPos, 0, 0, 0)
        
        local tween = TweenService:Create(gradient, TweenInfo.new(self.Speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
            Position = UDim2.new(endPos, 0, 2, 0)
        })
        
        tween:Play()
    end
    
    shimmer()
end

function Skeleton:Stop()
    -- Can be extended to stop animation
end

-- Multiple skeleton lines for loading content
function Skeleton.newLines(config, theme, utilities)
    local self = setmetatable({}, {__index = Skeleton})
    
    self.Name = config.Name or "SkeletonLines"
    self.Lines = config.Lines or 3
    self.Height = config.Height or 20
    self.Spacing = config.Spacing or 8
    self.Speed = config.Speed or 1.5
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Skeleton.newLines:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, (self.Lines * self.Height) + ((self.Lines - 1) * self.Spacing))
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    
    -- Create lines
    for i = 1, self.Lines do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, self.Height)
        line.Position = UDim2.new(0, 0, 0, (i - 1) * (self.Height + self.Spacing))
        line.BackgroundColor3 = self.Theme.Second
        line.BorderSizePixel = 0
        line.Parent = Container
        self.Utilities:CreateCorner(line, 4)
        
        -- Make last line shorter
        if i == self.Lines then
            line.Size = UDim2.new(0.6, 0, 0, self.Height)
        end
        
        -- Gradient shimmer
        local Gradient = Instance.new("UIGradient")
        Gradient.Rotation = 45
        Gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        }
        Gradient.Parent = line
        
        -- Animate each line with delay
        task.delay(i * 0.1, function()
            self:Animate(Gradient)
        end)
    end
    
    return Container
end

function Skeleton.newLines:Animate(gradient)
    local TweenService = game:GetService("TweenService")
    
    local function shimmer()
        local startPos = -1
        local endPos = 1
        
        gradient.Position = UDim2.new(startPos, 0, 0, 0)
        
        local tween = TweenService:Create(gradient, TweenInfo.new(self.Speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
            Position = UDim2.new(endPos, 0, 2, 0)
        })
        
        tween:Play()
    end
    
    shimmer()
end

return Skeleton
