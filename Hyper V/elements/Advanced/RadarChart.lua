--[[
    Hyper-V - Radar / Spider Chart Component
    Biểu đồ radar cho các chỉ số (Attack, Defense, Speed...)
]]

local RadarChart = {}

function RadarChart.new(config, theme, utilities)
    local self = setmetatable({}, {__index = RadarChart})
    
    self.Name = config.Name or "RadarChart"
    self.Title = config.Title or "Stats"
    self.Stats = config.Stats or {}  -- { {label = "Attack", value = 80, max = 100}, ... }
    self.Size = config.Size or 150
    self.FillColor = config.FillColor or theme.Accent
    self.BorderColor = config.BorderColor or theme.Accent
    self.GridColor = config.GridColor or theme.Border
    self.ShowLabels = config.ShowLabels or true
    self.ShowValues = config.ShowValues or true
    self.AnimationSpeed = config.AnimationSpeed or 0.5
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function RadarChart:Create()
    local containerSize = self.Size + (self.Title ~= "" and 25 or 0) + (self.ShowLabels and 40 or 0)
    
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, containerSize, 0, containerSize)
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
    
    -- Chart area
    local chartSize = self.Size
    local chartArea = Instance.new("Frame")
    chartArea.Size = UDim2.new(0, chartSize, 0, chartSize)
    chartArea.Position = UDim2.new(0.5, -chartSize/2, 0, contentY + chartSize/2 + 10)
    chartArea.AnchorPoint = Vector2.new(0.5, 0.5)
    chartArea.BackgroundTransparency = 1
    chartArea.BorderSizePixel = 0
    chartArea.Parent = Container
    
    self.ChartArea = chartArea
    self.CenterX = chartSize / 2
    self.CenterY = chartSize / 2
    self.Radius = chartSize / 2 - 20
    
    -- Draw grid
    self:DrawGrid()
    
    -- Draw stats polygon
    self:DrawStatsPolygon()
    
    -- Draw labels
    if self.ShowLabels then
        self:DrawLabels()
    end
    
    return Container
end

function RadarChart:DrawGrid()
    local numStats = #self.Stats
    if numStats < 3 then numStats = 3 end
    
    -- Draw concentric polygons for grid levels
    for level = 1, 5 do
        local points = {}
        local radius = self.Radius * (level / 5)
        
        for i = 1, numStats do
            local angle = math.rad((360 / numStats) * (i - 1) - 90)
            local x = self.CenterX + radius * math.cos(angle)
            local y = self.CenterY + radius * math.sin(angle)
            table.insert(points, {x = x, y = y})
        end
        
        -- Draw lines connecting points
        for i = 1, numStats do
            local nextI = (i % numStats) + 1
            local line = self:DrawLine(
                points[i].x, points[i].y,
                points[nextI].x, points[nextI].y,
                self.GridColor,
                level == 5 and 1 or 0.3
            )
            line.Parent = self.ChartArea
        end
        
        -- Draw axis lines
        for i = 1, numStats do
            local angle = math.rad((360 / numStats) * (i - 1) - 90)
            local x = self.CenterX + self.Radius * math.cos(angle)
            local y = self.CenterY + self.Radius * math.sin(angle)
            
            local axisLine = self:DrawLine(self.CenterX, self.CenterY, x, y, self.GridColor, 0.3)
            axisLine.Parent = self.ChartArea
        end
    end
end

function RadarChart:DrawLine(x1, y1, x2, y2, color, transparency)
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, length, 0, 1)
    line.Position = UDim2.new(0, x1, 0, y1)
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.BackgroundColor3 = color
    line.BorderSizePixel = 0
    line.Rotation = math.deg(angle)
    line.BackgroundTransparency = transparency
    
    return line
end

function RadarChart:DrawStatsPolygon()
    local numStats = #self.Stats
    if numStats < 3 then return end
    
    local points = {}
    
    for i, stat in ipairs(self.Stats) do
        local maxValue = stat.max or 100
        local percent = (stat.value or 0) / maxValue
        percent = math.clamp(percent, 0, 1)
        
        local angle = math.rad((360 / numStats) * (i - 1) - 90)
        local radius = self.Radius * percent
        local x = self.CenterX + radius * math.cos(angle)
        local y = self.CenterY + radius * math.sin(angle)
        
        table.insert(points, {
            x = x, 
            y = y, 
            percent = percent,
            stat = stat
        })
    end
    
    -- Draw filled polygon using segments
    for i = 1, numStats do
        local nextI = (i % numStats) + 1
        
        local tri = Instance.new("Frame")
        tri.Size = UDim2.new(0, 20, 0, 20)
        tri.AnchorPoint = Vector2.new(0.5, 0.5)
        tri.BackgroundColor3 = self.FillColor
        tri.BorderSizePixel = 0
        tri.BackgroundTransparency = 0.7
        tri.Parent = self.ChartArea
        
        local cx = (self.CenterX + points[i].x + points[nextI].x) / 3
        local cy = (self.CenterY + points[i].y + points[nextI].y) / 3
        
        tri.Position = UDim2.new(0, cx, 0, cy)
        
        local angle = math.atan2(points[nextI].y - points[i].y, points[nextI].x - points[i].x)
        local dist = math.sqrt(
            (points[nextI].x - points[i].x)^2 + 
            (points[nextI].y - points[i].y)^2
        )
        
        tri.Size = UDim2.new(0, dist, 0, self.Radius * 0.8)
        tri.Rotation = math.deg(angle) + 90
        tri.AnchorPoint = Vector2.new(0.5, 0.5)
        tri.Position = UDim2.new(0, (points[i].x + points[nextI].x)/2, 0, (points[i].y + points[nextI].y)/2)
        
        -- Animation
        if self.Utilities.TweenProperty then
            tri.BackgroundTransparency = 1
            self.Utilities:TweenProperty(tri, "BackgroundTransparency", 0.7, self.AnimationSpeed, i * 0.05)
        end
    end
    
    -- Draw border lines
    for i = 1, numStats do
        local nextI = (i % numStats) + 1
        
        local border = self:DrawLine(
            points[i].x, points[i].y,
            points[nextI].x, points[nextI].y,
            self.BorderColor,
            0
        )
        border.BackgroundTransparency = 1
        border.Parent = self.ChartArea
        
        if self.Utilities.TweenProperty then
            self.Utilities:TweenProperty(border, "BackgroundTransparency", 0, self.AnimationSpeed, i * 0.05)
        end
    end
    
    -- Draw data points
    for i, point in ipairs(points) do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.Position = UDim2.new(0, point.x - 4, 0, point.y - 4)
        dot.BackgroundColor3 = self.BorderColor
        dot.BorderSizePixel = 0
        dot.Parent = self.ChartArea
        self.Utilities:CreateCorner(dot, 4)
        
        if self.Utilities.TweenProperty then
            dot.BackgroundTransparency = 1
            self.Utilities:TweenProperty(dot, "BackgroundTransparency", 0, self.AnimationSpeed + 0.2, i * 0.05)
        end
        
        -- Hover to show value
        if self.ShowValues then
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0, 40, 0, 16)
            valueLabel.Position = UDim2.new(0.5, -20, 0, -25)
            valueLabel.AnchorPoint = Vector2.new(0.5, 1)
            valueLabel.BackgroundColor3 = self.Theme.Second
            valueLabel.BorderSizePixel = 0
            valueLabel.Text = point.stat.value .. "/" .. (point.stat.max or 100)
            valueLabel.TextColor3 = self.Theme.Text
            valueLabel.TextSize = 10
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.Visible = false
            valueLabel.Parent = dot
            self.Utilities:CreateCorner(valueLabel, 4)
            self.Utilities:CreateStroke(valueLabel, self.Theme.Border)
            
            dot.MouseEnter:Connect(function()
                valueLabel.Visible = true
                self.Utilities:TweenProperty(valueLabel, "Size", UDim2.new(0, 50, 0, 20), 0.15)
            end)
            
            dot.MouseLeave:Connect(function()
                self.Utilities:TweenProperty(valueLabel, "Size", UDim2.new(0, 40, 0, 16), 0.1, 0, function()
                    valueLabel.Visible = false
                end)
            end)
        end
    end
end

function RadarChart:DrawLabels()
    local numStats = #self.Stats
    if numStats < 3 then return end
    
    for i, stat in ipairs(self.Stats) do
        local angle = math.rad((360 / numStats) * (i - 1) - 90)
        local labelRadius = self.Radius + 15
        
        local x = self.CenterX + labelRadius * math.cos(angle)
        local y = self.CenterY + labelRadius * math.sin(angle)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 50, 0, 16)
        label.Position = UDim2.new(0, x, 0, y)
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.BackgroundTransparency = 1
        label.Text = stat.label
        label.TextColor3 = self.Theme.SecondText
        label.TextSize = 10
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Parent = self.ChartArea
    end
end

-- Public methods
function RadarChart:UpdateStat(label, value)
    for _, stat in ipairs(self.Stats) do
        if stat.label == label then
            stat.value = value
            break
        end
    end
end

function RadarChart:SetStats(stats)
    self.Stats = stats
end

return RadarChart
