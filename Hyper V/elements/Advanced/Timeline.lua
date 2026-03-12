--[[
    Hyper-V - Timeline / History Chart Component
    Hiển thị sự kiện theo thời gian
]]

local Timeline = {}

function Timeline.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Timeline})
    
    self.Name = config.Name or "Timeline"
    self.Title = config.Title or "Timeline"
    self.Events = config.Events or {}  -- { {time = 0, label = "Event", icon = "🛡", color = Color3}, ... }
    self.StartTime = config.StartTime or 0  -- Start time in seconds
    self.EndTime = config.EndTime or 3600   -- End time in seconds
    self.Width = config.Width or 500
    self.Height = config.Height or 120
    self.ShowLabels = config.ShowLabels or true
    self.ShowTimeAxis = config.ShowTimeAxis or true
    self.IconSize = config.IconSize or 24
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Timeline:Create()
    local containerHeight = self.Height + (self.Title ~= "" and 25 or 0) + (self.ShowLabels and 30 or 0)
    
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, containerHeight)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    self.Container = Container
    local contentY = 0
    
    -- Title
    if self.Title ~= "" then
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -10, 0, 20)
        Title.Position = UDim2.new(0, 5, 0, 5)
        Title.BackgroundTransparency = 1
        Title.Text = self.Title
        Title.TextColor3 = self.Theme.TitleText
        Title.TextSize = 13
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Container
        contentY = 25
    end
    
    -- Timeline track
    local trackHeight = self.Height - 30
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 4)
    track.Position = UDim2.new(0, 10, 0, contentY + 15)
    track.BackgroundColor3 = self.Theme.Second
    track.BorderSizePixel = 0
    track.Parent = Container
    self.Utilities:CreateCorner(track, 2)
    
    -- Time axis labels
    if self.ShowTimeAxis then
        self:DrawTimeAxis(contentY + trackHeight - 5)
    end
    
    -- Draw events
    self:DrawEvents(contentY + 15)
    
    return Container
end

function Timeline:DrawTimeAxis(y)
    local times = {0, 0.25, 0.5, 0.75, 1}
    local timeRange = self.EndTime - self.StartTime
    
    for _, t in ipairs(times) do
        local timeSeconds = self.StartTime + t * timeRange
        local label = self:FormatTime(timeSeconds)
        
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(0, 40, 0, 14)
        timeLabel.Position = UDim2.new(t, -20, 1, 5)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = label
        timeLabel.TextColor3 = self.Theme.SecondText
        timeLabel.TextSize = 9
        timeLabel.Font = Enum.Font.Gotham
        timeLabel.TextAlignment = Enum.TextXAlignment.Center
        timeLabel.Parent = self.Container
    end
end

function Timeline:DrawEvents(y)
    local trackWidth = self.Width - 40
    local timeRange = self.EndTime - self.StartTime
    
    local defaultIcons = {
        "🛡", "⚔️", "💰", "📜", "⭐", "🎯", "🔔", "💎"
    }
    
    for i, event in ipairs(self.Events) do
        local t = (event.time - self.StartTime) / timeRange
        t = math.clamp(t, 0, 1)
        
        local xPos = 20 + t * trackWidth
        local color = event.color or self.Theme.Accent
        local icon = event.icon or defaultIcons[(i - 1) % #defaultIcons + 1]
        
        -- Event marker (circle)
        local marker = Instance.new("Frame")
        marker.Size = UDim2.new(0, self.IconSize, 0, self.IconSize)
        marker.Position = UDim2.new(0, xPos - self.IconSize/2, 0, y - self.IconSize/2)
        marker.BackgroundColor3 = color
        marker.BorderSizePixel = 0
        marker.Parent = self.Container
        self.Utilities:CreateCorner(marker, self.IconSize/2)
        self.Utilities:CreateStroke(marker, self.Theme.Default)
        
        -- Icon
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon
        iconLabel.TextSize = 12
        iconLabel.Parent = marker
        
        -- Pulse animation
        if self.Utilities.TweenProperty then
            local pulse = Instance.new("Frame")
            pulse.Size = UDim2.new(1.5, 0, 1.5, 0)
            pulse.Position = UDim2.new(-0.25, 0, -0.25, 0)
            pulse.BackgroundColor3 = color
            pulse.BorderSizePixel = 0
            pulse.BackgroundTransparency = 0.5
            pulse.Parent = marker
            self.Utilities:CreateCorner(pulse, self.IconSize * 0.75)
            
            self.Utilities:TweenProperty(pulse, "Size", UDim2.new(2, 0, 2, 0), 1, i * 0.2)
            self.Utilities:TweenProperty(pulse, "BackgroundTransparency", 1, 1, i * 0.2)
        end
        
        -- Hover tooltip
        if self.ShowLabels and event.label then
            local tooltip = Instance.new("Frame")
            tooltip.Size = UDim2.new(0, 100, 0, 30)
            tooltip.Position = UDim2.new(0.5, -50, 0, -35)
            tooltip.AnchorPoint = Vector2.new(0.5, 1)
            tooltip.BackgroundColor3 = self.Theme.Second
            tooltip.BorderSizePixel = 0
            tooltip.Visible = false
            tooltip.Parent = marker
            self.Utilities:CreateCorner(tooltip, 6)
            self.Utilities:CreateStroke(tooltip, self.Theme.Border)
            
            local tooltipText = Instance.new("TextLabel")
            tooltipText.Size = UDim2.new(1, -8, 1, 0)
            tooltipText.Position = UDim2.new(0, 4, 0, 0)
            tooltipText.BackgroundTransparency = 1
            tooltipText.Text = event.label
            tooltipText.TextColor3 = self.Theme.Text
            tooltipText.TextSize = 10
            tooltipText.Font = Enum.Font.Gotham
            tooltipText.TextWrapped = true
            tooltipText.Parent = tooltip
            
            local timeText = Instance.new("TextLabel")
            timeText.Size = UDim2.new(1, -8, 0, 12)
            timeText.Position = UDim2.new(0, 4, 1, -12)
            timeText.BackgroundTransparency = 1
            timeText.Text = self:FormatTime(event.time)
            timeText.TextColor3 = self.Theme.SecondText
            timeText.TextSize = 9
            timeText.Font = Enum.Font.Gotham
            timeText.Parent = tooltip
            
            marker.MouseEnter:Connect(function()
                tooltip.Visible = true
                self.Utilities:TweenProperty(tooltip, "Size", UDim2.new(0, 120, 0, 40), 0.15)
                self.Utilities:TweenProperty(tooltip, "BackgroundTransparency", 0, 0.15)
            end)
            
            marker.MouseLeave:Connect(function()
                self.Utilities:TweenProperty(tooltip, "BackgroundTransparency", 1, 0.1, 0, function()
                    tooltip.Visible = false
                end)
            end)
        end
        
        -- Vertical line from marker
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 1, 0, 20)
        line.Position = UDim2.new(0.5, 0, 0, self.IconSize/2)
        line.AnchorPoint = Vector2.new(0.5, 0)
        line.BackgroundColor3 = color
        line.BorderSizePixel = 0
        line.BackgroundTransparency = 0.5
        line.Parent = marker
    end
end

function Timeline:FormatTime(seconds)
    if seconds < 60 then
        return math.floor(seconds) .. "s"
    elseif seconds < 3600 then
        local mins = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        return mins .. "m" .. secs .. "s"
    else
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        return hours .. "h" .. mins .. "m"
    end
end

-- Public methods
function Timeline:SetEvents(events)
    self.Events = events
    -- Would need to recreate - for simplicity, just update reference
end

function Timeline:AddEvent(time, label, icon, color)
    table.insert(self.Events, {
        time = time,
        label = label,
        icon = icon,
        color = color
    })
    -- Sort by time
    table.sort(self.Events, function(a, b)
        return a.time < b.time
    end)
end

function Timeline:SetTimeRange(startTime, endTime)
    self.StartTime = startTime
    self.EndTime = endTime
end

return Timeline
