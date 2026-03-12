--[[
    Hyper-V - Sparkline / Micro Chart Component
    Mini line chart nhỏ để hiển thị trend trong dashboard cards
]]

local Sparkline = {}

function Sparkline.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Sparkline})
    
    self.Name = config.Name or "Sparkline"
    self.Data = config.Data or {10, 15, 12, 20, 18, 25, 30}
    self.Width = config.Width or 60
    self.Height = config.Height or 25
    self.LineColor = config.LineColor or theme.Accent
    self.FillColor = config.FillColor or theme.Accent
    self.ShowTrend = config.ShowTrend or true
    self.Fill = config.Fill or true
    self.Animate = config.Animate or true
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Sparkline:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, self.Height + (self.ShowTrend and 12 or 0))
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    
    self.Container = Container
    
    -- Chart area
    local chartArea = Instance.new("Frame")
    chartArea.Size = UDim2.new(1, 0, 0, self.Height)
    chartArea.BackgroundTransparency = 1
    chartArea.BorderSizePixel = 0
    chartArea.Parent = Container
    self.ChartArea = chartArea
    
    -- Draw the sparkline
    self:Draw()
    
    -- Trend indicator
    if self.ShowTrend then
        self:DrawTrend()
    end
    
    return Container
end

function Sparkline:Draw()
    local data = self.Data
    if #data < 2 then return end
    
    -- Find min/max for scaling
    local minVal = math.huge
    local maxVal = -math.huge
    for _, v in ipairs(data) do
        minVal = math.min(minVal, v)
        maxVal = math.max(maxVal, v)
    end
    
    local range = maxVal - minVal
    if range == 0 then range = 1 end
    
    local padding = 2
    local chartWidth = self.Width - padding * 2
    local chartHeight = self.Height - padding * 2
    
    -- Draw fill area (optional)
    if self.Fill then
        local fillPoints = {}
        
        for i, val in ipairs(data) do
            local x = padding + (i - 1) / (#data - 1) * chartWidth
            local y = padding + chartHeight - ((val - minVal) / range) * chartHeight
            table.insert(fillPoints, {x = x, y = y})
       
        
        -- Add bottom points to close the polygon
        table.insert(fillPoints, {x = self.Width - padding, y = self.Height - padding})
        table.insert(fillPoints, {x = padding, y = self.Height - padding})
        
        -- Create fill segments
        for i = 1, #fillPoints - 2 do
            local tri = Instance.new("Frame")
            tri.Size = UDim2.new(0, 10, 0, 10)
            tri.AnchorPoint = Vector2.new(0.5, 0.5)
            tri.BackgroundColor3 = self.FillColor
            tri.BackgroundTransparency = 0.7
            tri.BorderSizePixel = 0
            tri.Parent = self.ChartArea
            
            local cx = (fillPoints[i].x + fillPoints[i+1].x) / 2
            local cy = (fillPoints[i].y + fillPoints[i+1].y + self.Height - padding * 2) / 2
            
            tri.Position = UDim2.new(0, cx, 0, cy)
            
            if self.Animate then
                tri.BackgroundTransparency = 1
                self.Utilities:TweenProperty(tri, "BackgroundTransparency", 0.7, 0.3, i * 0.05)
            end
        end
    end
    
    -- Draw line segments
    for i = 1, #data - 1 do
        local x1 = padding + (i - 1) / (#data - 1) * chartWidth
        local y1 = padding + chartHeight - ((data[i] - minVal) / range) * chartHeight
        
        local x2 = padding + i / (#data - 1) * chartWidth
        local y2 = padding + chartHeight - ((data[i+1] - minVal) / range) * chartHeight
        
        local line = self:DrawLine(x1, y1, x2, y2)
        line.Parent = self.ChartArea
        
        if self.Animate then
            line.BackgroundTransparency = 1
            self.Utilities:TweenProperty(line, "BackgroundTransparency", 0, 0.4, i * 0.08)
        end
    end
    
    -- Draw end point dot
    local lastVal = data[#data]
    local lastX = self.Width - padding
    local lastY = padding + chartHeight - ((lastVal - minVal) / range) * chartHeight
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0, lastX - 2, 0, lastY - 2)
    dot.BackgroundColor3 = self.LineColor
    dot.BorderSizePixel = 0
    dot.Parent = self.ChartArea
    self.Utilities:CreateCorner(dot, 2)
    
    if self.Animate then
        dot.BackgroundTransparency = 1
        self.Utilities:TweenProperty(dot, "BackgroundTransparency", 0, 0.5, 0.3)
    end
end

function Sparkline:DrawLine(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, length, 0, 2)
    line.Position = UDim2.new(0, x1, 0, y1 - 1)
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.BackgroundColor3 = self.LineColor
    line.BorderSizePixel = 0
    line.Rotation = math.deg(angle)
    
    return line
end

function Sparkline:DrawTrend()
    local data = self.Data
    if #data < 2 then return end
    
    -- Calculate trend (simple: compare first and last)
    local first = data[1]
    local last = data[#data]
    local change = last - first
    local isUp = change >= 0
    
    local trendIcon = Instance.new("TextLabel")
    trendIcon.Size = UDim2.new(0, 12, 0, 12)
    trendIcon.Position = UDim2.new(1, -2, 0, 0)
    trendIcon.AnchorPoint = Vector2.new(1, 0)
    trendIcon.BackgroundTransparency = 1
    trendIcon.Text = isUp and "↗" or "↘"
    trendIcon.TextColor3 = isUp and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
    trendIcon.TextSize = 12
    trendIcon.Parent = self.Container
    
    -- Percentage
    local percentChange = math.abs(math.round((change / first) * 100))
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Size = UDim2.new(0, 40, 0, 12)
    percentLabel.Position = UDim2.new(1, -16, 0, 0)
    percentLabel.AnchorPoint = Vector2.new(1, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = (isUp and "+" or "-") .. percentChange .. "%"
    percentLabel.TextColor3 = isUp and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(239, 68, 68)
    percentLabel.TextSize = 9
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = self.Container
end

-- Public methods
function Sparkline:SetData(data)
    self.Data = data
    -- Clear and redraw
    for _, v in ipairs(self.ChartArea:GetChildren()) do
        v:Destroy()
    end
    self:Draw()
    if self.ShowTrend then
        for _, v in ipairs(self.Container:GetChildren()) do
            if v:IsA("TextLabel") and v.Text ~= "" then
                v:Destroy()
            end
        end
        self:DrawTrend()
    end
end

function Sparkline:AddValue(value)
    table.insert(self.Data, value)
    if #self.Data > 20 then
        table.remove(self.Data, 1)
    end
    self:SetData(self.Data)
end

return Sparkline
