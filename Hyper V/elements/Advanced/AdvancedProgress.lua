--[[
    Hyper-V - Advanced Progress Bar Component
    Progress Bar nâng cao: Multi-step, Milestone, Circular
]]

local AdvancedProgress = {}

-- Multi-step Progress Bar
function AdvancedProgress.newMultiStep(config, theme, utilities)
    local self = setmetatable({}, {__index = AdvancedProgress})
    
    self.Name = config.Name or "MultiStepProgress"
    self.Steps = config.Steps or 3
    self.CurrentStep = config.CurrentStep or 1
    self.Width = config.Width or 300
    self.Height = config.Height or 8
    self.ActiveColor = config.ActiveColor or theme.Accent
    self.InactiveColor = config.InactiveColor or theme.Second
    self.CompletedColor = config.CompletedColor or Color3.fromRGB(16, 185, 129)
    self.ShowLabels = config.ShowLabels or true
    self.Animate = config.Animate or true
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function AdvancedProgress.newMultiStep:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, (self.ShowLabels and 30 or 10) + self.Height)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 6)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    local stepWidth = (self.Width - (self.Steps - 1) * 5) / self.Steps
    
    for i = 1, self.Steps do
        local stepFrame = Instance.new("Frame")
        stepFrame.Size = UDim2.new(0, stepWidth, 0, self.Height)
        stepFrame.Position = UDim2.new(0, (i - 1) * (stepWidth + 5), 0, self.ShowLabels and 25 or 5)
        stepFrame.BorderSizePixel = 0
        stepFrame.Parent = Container
        
        -- Determine color based on step state
        local color = self.InactiveColor
        if i < self.CurrentStep then
            color = self.CompletedColor
        elseif i == self.CurrentStep then
            color = self.ActiveColor
        end
        
        stepFrame.BackgroundColor3 = color
        
        if i == 1 or i == self.Steps then
            self.Utilities:CreateCorner(stepFrame, 4)
        end
        
        -- Animation
        if self.Animate and i == self.CurrentStep then
            self.Utilities:TweenProperty(stepFrame, "BackgroundTransparency", 0, 0.3, 0)
            -- Pulsing effect for current step
            local TweenService = game:GetService("TweenService")
            local pulse = TweenService:Create(stepFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
                BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)
            })
            pulse:Play()
        end
        
        -- Label
        if self.ShowLabels then
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 16)
            label.Position = UDim2.new(0, 0, 0, -20)
            label.BackgroundTransparency = 1
            label.Text = "Step " .. i
            label.TextColor3 = i <= self.CurrentStep and self.Theme.Text or self.Theme.SecondText
            label.TextSize = 10
            label.Font = Enum.Font.GothamBold
            label.TextAlignment = Enum.TextXAlignment.Center
            label.Parent = stepFrame
        end
    end
    
    self.Container = Container
    return Container
end

function AdvancedProgress.newMultiStep:SetStep(step)
    self.CurrentStep = math.clamp(step, 1, self.Steps)
    -- Redraw would be needed for full update
end

-- Milestone Progress Bar
function AdvancedProgress.newMilestone(config, theme, utilities)
    local self = setmetatable({}, {__index = AdvancedProgress})
    
    self.Name = config.Name or "MilestoneProgress"
    self.Value = config.Value or 0
    self.Max = config.Max or 100
    self.Milestones = config.Milestones or {0, 25, 50, 75, 100}
    self.Width = config.Width or 300
    self.Height = config.Height or 20
    self.ActiveColor = config.ActiveColor or theme.Accent
    self.InactiveColor = config.InactiveColor or theme.Second
    self.ShowLabels = config.ShowLabels or true
    self.Animate = config.Animate or true
    self.OnMilestone = config.OnMilestone
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function AdvancedProgress.newMilestone:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, self.Height + (self.ShowLabels and 20 or 0))
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 6)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Background bar
    local bgBar = Instance.new("Frame")
    bgBar.Size = UDim2.new(1, -4, 0, self.Height - 4)
    bgBar.Position = UDim2.new(0, 2, 0.5, -self.Height/2 + 2)
    bgBar.BackgroundColor3 = self.InactiveColor
    bgBar.BorderSizePixel = 0
    bgBar.Parent = Container
    self.Utilities:CreateCorner(bgBar, 4)
    
    -- Progress bar
    local percent = self.Value / self.Max
    local progressWidth = (self.Width - 4) * percent
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)  -- Start at 0 for animation
    progressBar.BackgroundColor3 = self.ActiveColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = bgBar
    self.Utilities:CreateCorner(progressBar, 4)
    
    self.ProgressBar = progressBar
    
    -- Animation
    if self.Animate then
        self.Utilities:TweenProperty(progressBar, "Size", UDim2.new(0, progressWidth, 1, 0), 0.5, 0)
    else
        progressBar.Size = UDim2.new(0, progressWidth, 1, 0)
    end
    
    -- Milestone markers
    if self.ShowLabels then
        for _, milestone in ipairs(self.Milestones) do
            local pos = milestone / 100
            local marker = Instance.new("Frame")
            marker.Size = UDim2.new(0, 1, 0, 6)
            marker.Position = UDim2.new(pos, 0, 0, -6)
            marker.BackgroundColor3 = self.Theme.Border
            marker.BorderSizePixel = 0
            marker.Parent = bgBar
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 30, 0, 14)
            label.Position = UDim2.new(pos, -15, 0, -20)
            label.BackgroundTransparency = 1
            label.Text = milestone .. "%"
            label.TextColor3 = self.Value >= milestone and self.ActiveColor or self.Theme.SecondText
            label.TextSize = 9
            label.Font = Enum.Font.GothamBold
            label.TextAlignment = Enum.TextXAlignment.Center
            label.Parent = bgBar
        end
    end
    
    -- Percentage label
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Size = UDim2.new(0, 40, 0, 16)
    percentLabel.Position = UDim2.new(0.5, -20, 0.5, -8)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = math.round(percent * 100) .. "%"
    percentLabel.TextColor3 = self.Theme.TitleText
    percentLabel.TextSize = 10
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.Parent = Container
    self.PercentLabel = percentLabel
    
    return Container
end

function AdvancedProgress.newMilestone:SetValue(value, max)
    self.Value = value
    if max then self.Max = max end
    
    local percent = self.Value / self.Max
    local progressWidth = (self.Width - 4) * percent
    
    if self.ProgressBar then
        if self.Animate then
            self.Utilities:TweenProperty(self.ProgressBar, "Size", UDim2.new(0, progressWidth, 1, 0), 0.3, 0)
        else
            self.ProgressBar.Size = UDim2.new(0, progressWidth, 1, 0)
        end
    end
    
    if self.PercentLabel then
        self.PercentLabel.Text = math.round(percent * 100) .. "%"
    end
    
    -- Check for milestone
    for _, milestone in ipairs(self.Milestones) do
        if percent * 100 >= milestone and self.OnMilestone then
            self.OnMilestone(milestone)
        end
    end
end

-- Circular Progress Bar
function AdvancedProgress.newCircular(config, theme, utilities)
    local self = setmetatable({}, {__index = AdvancedProgress})
    
    self.Name = config.Name or "CircularProgress"
    self.Value = config.Value or 0
    self.Max = config.Max or 100
    self.Size = config.Size or 80
    self.LineThickness = config.LineThickness or 8
    self.ActiveColor = config.ActiveColor or theme.Accent
    self.InactiveColor = config.InactiveColor or theme.Second
    self.ShowPercent = config.ShowPercent or true
    self.ShowLabel = config.ShowLabel or ""
    self.Animate = config.Animate or true
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function AdvancedProgress.newCircular:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Size, 0, self.Size)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, self.Size/2)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Background circle (using ImageLabel with circle asset or Frame)
    local bgCircle = Instance.new("Frame")
    bgCircle.Size = UDim2.new(1, -4, 1, -4)
    bgCircle.Position = UDim2.new(0, 2, 0, 2)
    bgCircle.BackgroundColor3 = self.InactiveColor
    bgCircle.BorderSizePixel = 0
    bgCircle.Parent = Container
    self.Utilities:CreateCorner(bgCircle, (self.Size - 4) / 2)
    
    -- Progress indicator using rotated frames
    local percent = self.Value / self.Max
    
    -- We'll create a circular progress using multiple segments
    local segments = 36
    local segmentAngle = 360 / segments
    local radius = (self.Size - self.LineThickness - 8) / 2
    
    for i = 1, segments do
        local angle = (i - 1) * segmentAngle - 90
        local isActive = i <= segments * percent
        
        local seg = Instance.new("Frame")
        seg.Size = UDim2.new(0, self.LineThickness, 0, self.LineThickness)
        seg.AnchorPoint = Vector2.new(0.5, 0.5)
        seg.BackgroundColor3 = isActive and self.ActiveColor or self.InactiveColor
        seg.BorderSizePixel = 0
        seg.Name = "Segment"
        
        -- Position in circle
        local cx = self.Size / 2
        local cy = self.Size / 2
        local rad = math.rad(angle)
        local x = cx + radius * math.cos(rad)
        local y = cy + radius * math.sin(rad)
        
        seg.Position = UDim2.new(0, x, 0, y)
        seg.Parent = Container
        self.Utilities:CreateCorner(seg, self.LineThickness/2)
        
        -- Animation
        if self.Animate and isActive then
            seg.BackgroundTransparency = 1
            self.Utilities:TweenProperty(seg, "BackgroundTransparency", 0, 0.1, i * 0.01)
        end
    end
    
    -- Center label
    local centerFrame = Instance.new("Frame")
    centerFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
    centerFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
    centerFrame.BackgroundColor3 = self.Theme.Default
    centerFrame.BorderSizePixel = 0
    centerFrame.Parent = Container
    self.Utilities:CreateCorner(centerFrame, (self.Size * 0.6) / 2)
    self.Utilities:CreateStroke(centerFrame, self.Theme.Border)
    
    -- Percentage
    if self.ShowPercent then
        local percentLabel = Instance.new("TextLabel")
        percentLabel.Size = UDim2.new(1, 0, 0.6, 0)
        percentLabel.Position = UDim2.new(0, 0, 0.2, 0)
        percentLabel.BackgroundTransparency = 1
        percentLabel.Text = math.round(percent * 100) .. "%"
        percentLabel.TextColor3 = self.Theme.TitleText
        percentLabel.TextSize = 16
        percentLabel.Font = Enum.Font.GothamBold
        percentLabel.TextAlignment = Enum.TextXAlignment.Center
        percentLabel.Parent = centerFrame
        self.PercentLabel = percentLabel
    end
    
    -- Custom label
    if self.ShowLabel ~= "" then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0.3, 0)
        label.Position = UDim2.new(0, 0, 0.7, 0)
        label.BackgroundTransparency = 1
        label.Text = self.ShowLabel
        label.TextColor3 = self.Theme.SecondText
        label.TextSize = 10
        label.Font = Enum.Font.Gotham
        label.TextAlignment = Enum.TextXAlignment.Center
        label.Parent = centerFrame
    end
    
    self.Container = Container
    return Container
end

function AdvancedProgress.newCircular:SetValue(value, max)
    self.Value = value
    if max then self.Max = max end
    
    local percent = self.Value / self.Max
    
    -- Update segments
    local segments = 36
    local segmentAngle = 360 / segments
    
    for i, seg in ipairs(self.Container:GetChildren()) do
        if seg.Name == "Segment" then
            local angle = (i - 1) * segmentAngle - 90
            local isActive = i <= segments * percent
            
            if self.Animate then
                self.Utilities:TweenProperty(seg, "BackgroundColor3", isActive and self.ActiveColor or self.InactiveColor, 0.2, 0)
            else
                seg.BackgroundColor3 = isActive and self.ActiveColor or self.InactiveColor
            end
        end
    end
    
    if self.PercentLabel then
        self.PercentLabel.Text = math.round(percent * 100) .. "%"
    end
end

return AdvancedProgress
