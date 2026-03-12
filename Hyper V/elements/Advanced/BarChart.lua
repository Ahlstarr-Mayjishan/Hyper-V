--[[
    Hyper-V - Bar Chart Component
    Biểu đồ cột - So sánh các giá trị
]]

local BarChart = {}

function BarChart.new(config, theme, utilities)
    local self = setmetatable({}, {__index = BarChart})
    
    self.Name = config.Name or "BarChart"
    self.Title = config.Title or ""
    self.Data = config.Data or {}  -- { {label = "Name", value = 100, color = Color3}, ... }
    self.Width = config.Width or 400
    self.Height = config.Height or 180
    self.Orientation = config.Orientation or "vertical"  -- "vertical" or "horizontal"
    self.ShowValues = config.ShowValues or true
    self.ShowLabels = config.ShowLabels or true
    self.Animate = config.Animate or true
    self.BarSpacing = config.BarSpacing or 4
    self.FixedMaxValue = config.MaxValue
    self.MaxValue = config.MaxValue  -- Auto if nil
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function BarChart:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, self.Height + (self.Title ~= "" and 25 or 0))
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    local contentOffset = 0
    
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
        contentOffset = 25
    end
    
    -- Chart area
    local ChartArea = Instance.new("Frame")
    ChartArea.Size = UDim2.new(1, -20, 0, self.Height - 15)
    ChartArea.Position = UDim2.new(0, 10, 0, contentOffset + 5)
    ChartArea.BackgroundTransparency = 1
    ChartArea.BorderSizePixel = 0
    ChartArea.Parent = Container
    
    self.ChartArea = ChartArea
    
    -- Calculate max value
    if not self.MaxValue then
        self.MaxValue = 100
        for _, item in ipairs(self.Data) do
            self.MaxValue = math.max(self.MaxValue, item.value or 0)
        end
    end
    
    -- Draw bars
    if self.Orientation == "vertical" then
        self:DrawVerticalBars()
    else
        self:DrawHorizontalBars()
    end
    
    return Container
end

function BarChart:DrawVerticalBars()
    local barCount = #self.Data
    if barCount == 0 then return end
    
    local chartWidth = self.ChartArea.AbsoluteSize.X
    local chartHeight = self.ChartArea.AbsoluteSize.Y
    local barWidth = (chartWidth - (barCount - 1) * self.BarSpacing) / barCount
    
    -- Grid lines
    for i = 1, 4 do
        local gridLine = Instance.new("Frame")
        gridLine.Size = UDim2.new(1, 0, 0, 1)
        gridLine.Position = UDim2.new(0, 0, (i-1)/4, 0)
        gridLine.BackgroundColor3 = self.Theme.Border
        gridLine.BorderSizePixel = 0
        gridLine.Transparency = 0.5
        gridLine.Parent = self.ChartArea
    end
    
    for i, item in ipairs(self.Data) do
        local value = item.value or 0
        local label = item.label or "Item " .. i
        local color = item.color or self.Theme.Accent
        
        local barHeight = (value / self.MaxValue) * (chartHeight - 25)
        barHeight = math.max(barHeight, 4)
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, barWidth, 0, 0)  -- Start at 0 for animation
        bar.Position = UDim2.new(0, (i-1) * (barWidth + self.BarSpacing), 1, 0)
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.BackgroundColor3 = color
        bar.BorderSizePixel = 0
        bar.Parent = self.ChartArea
        self.Utilities:CreateCorner(bar, 4)
        
        -- Animate bar growth
        if self.Animate then
            self.Utilities:TweenProperty(bar, "Size", UDim2.new(0, barWidth, 0, barHeight), 0.5, i * 0.1)
        else
            bar.Size = UDim2.new(0, barWidth, 0, barHeight)
        end
        
        -- Value label on top
        if self.ShowValues then
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(1, 0, 0, 16)
            valueLabel.Position = UDim2.new(0, 0, 0, -20)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(value)
            valueLabel.TextColor3 = self.Theme.Text
            valueLabel.TextSize = 10
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextAlignment = Enum.TextXAlignment.Center
            valueLabel.Parent = bar
            
            if self.Animate then
                valueLabel.TextTransparency = 1
                self.Utilities:TweenProperty(valueLabel, "TextTransparency", 0, 0.3, i * 0.1 + 0.3)
            end
        end
        
        -- Label on bottom
        if self.ShowLabels then
            local labelText = Instance.new("TextLabel")
            labelText.Size = UDim2.new(1, 0, 0, 16)
            labelText.Position = UDim2.new(0, 0, 1, 4)
            labelText.BackgroundTransparency = 1
            labelText.Text = tostring(label)
            labelText.TextColor3 = self.Theme.SecondText
            labelText.TextSize = 9
            labelText.Font = Enum.Font.Gotham
            labelText.TextXAlignment = Enum.TextXAlignment.Center
            labelText.TextTruncate = Enum.TextTruncate.AtEnd
            labelText.Parent = self.ChartArea
            
            -- Position based on bar position
            labelText.Position = UDim2.new(0, (i-1) * (barWidth + self.BarSpacing) + barWidth/2, 1, 4)
            labelText.AnchorPoint = Vector2.new(0.5, 0)
        end
        
        -- Hover effect
        bar.MouseEnter:Connect(function()
            self.Utilities:TweenColor(bar, color:Lerp(Color3.new(1,1,1), 0.15))
        end)
        
        bar.MouseLeave:Connect(function()
            self.Utilities:TweenColor(bar, color)
        end)
    end
end

function BarChart:DrawHorizontalBars()
    local barCount = #self.Data
    if barCount == 0 then return end
    
    local chartWidth = self.ChartArea.AbsoluteSize.X
    local chartHeight = self.ChartArea.AbsoluteSize.Y
    local barHeight = (chartHeight - (barCount - 1) * self.BarSpacing) / barCount
    
    for i, item in ipairs(self.Data) do
        local value = item.value or 0
        local label = item.label or "Item " .. i
        local color = item.color or self.Theme.Accent
        
        local barWidth = (value / self.MaxValue) * (chartWidth - 60)
        barWidth = math.max(barWidth, 4)
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 0, 0, barHeight)  -- Start at 0 for animation
        bar.Position = UDim2.new(0, 50, 0, (i-1) * (barHeight + self.BarSpacing))
        bar.BackgroundColor3 = color
        bar.BorderSizePixel = 0
        bar.Parent = self.ChartArea
        self.Utilities:CreateCorner(bar, 4)
        
        -- Animate bar growth
        if self.Animate then
            self.Utilities:TweenProperty(bar, "Size", UDim2.new(0, barWidth, 0, barHeight), 0.5, i * 0.1)
        else
            bar.Size = UDim2.new(0, barWidth, 0, barHeight)
        end
        
        -- Label on left
        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(0, 45, 0, barHeight)
        labelText.Position = UDim2.new(0, 0, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = tostring(label)
        labelText.TextColor3 = self.Theme.Text
        labelText.TextSize = 10
        labelText.Font = Enum.Font.Gotham
        labelText.TextXAlignment = Enum.TextXAlignment.Right
        labelText.TextTruncate = Enum.TextTruncate.AtEnd
        labelText.Parent = self.ChartArea
        
        -- Value label
        if self.ShowValues then
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0, 50, 0, barHeight)
            valueLabel.Position = UDim2.new(0, barWidth + 5, 0, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(value)
            valueLabel.TextColor3 = self.Theme.SecondText
            valueLabel.TextSize = 10
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextXAlignment = Enum.TextXAlignment.Left
            valueLabel.Parent = self.ChartArea
        end
    end
end

-- Update chart data dynamically
function BarChart:UpdateData(newData)
    self.Data = newData
    self.MaxValue = self.FixedMaxValue

    if not self.MaxValue then
        self.MaxValue = 100
        for _, item in ipairs(self.Data) do
            self.MaxValue = math.max(self.MaxValue, item.value or 0)
        end
    end
    -- Clear and redraw
    for _, v in ipairs(self.ChartArea:GetChildren()) do
        if v:IsA("Frame") or v:IsA("TextLabel") then
            v:Destroy()
        end
    end
    if self.Orientation == "vertical" then
        self:DrawVerticalBars()
    else
        self:DrawHorizontalBars()
    end
end

-- Add new bar
function BarChart:AddBar(label, value, color)
    table.insert(self.Data, {label = label, value = value, color = color})
    self:UpdateData(self.Data)
end

-- Set single bar value
function BarChart:SetBarValue(index, value)
    if self.Data[index] then
        self.Data[index].value = value
        self:UpdateData(self.Data)
    end
end

return BarChart
