--[[
    Hyper-V - Pie/Doughnut Chart Component
    Biểu đồ tròn - Hiển thị tỉ lệ phần trăm
]]

local PieChart = {}

function PieChart.new(config, theme, utilities)
    local self = setmetatable({}, {__index = PieChart})
    
    self.Name = config.Name or "PieChart"
    self.Title = config.Title or ""
    self.Data = config.Data or {}  -- { {label = "Name", value = 30, color = Color3}, ... }
    self.Size = config.Size or 150
    self.Type = config.Type or "doughnut"  -- "pie" or "doughnut"
    self.ShowPercent = config.ShowPercent or true
    self.ShowLegend = config.ShowLegend or true
    self.Animate = config.Animate or true
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function PieChart:Create()
    local containerHeight = self.Size + (self.Title ~= "" and 25 or 0) + (self.ShowLegend and 80 or 0)
    
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Size + (self.ShowLegend and 150 or 0), 0, containerHeight)
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
    
    -- Calculate total
    local total = 0
    for _, item in ipairs(self.Data) do
        total = total + (item.value or 0)
    end
    
    -- Chart area
    local ChartArea = Instance.new("Frame")
    ChartArea.Size = UDim2.new(0, self.Size, 0, self.Size)
    ChartArea.Position = UDim2.new(0, 5, 0, contentOffset + 5)
    ChartArea.BackgroundTransparency = 1
    ChartArea.BorderSizePixel = 0
    ChartArea.Parent = Container
    
    self.ChartArea = ChartArea
    
    -- Draw pie slices
    self:DrawSlices(total)
    
    -- Center label for doughnut
    if self.Type == "doughnut" then
        local centerLabel = Instance.new("TextLabel")
        centerLabel.Size = UDim2.new(0.6, 0, 0.6, 0)
        centerLabel.Position = UDim2.new(0.2, 0, 0.2, 0)
        centerLabel.BackgroundTransparency = 1
        centerLabel.Text = "100%"
        centerLabel.TextColor3 = self.Theme.TitleText
        centerLabel.TextSize = 16
        centerLabel.Font = Enum.Font.GothamBold
        centerLabel.Parent = ChartArea
        self.CenterLabel = centerLabel
    end
    
    -- Legend
    if self.ShowLegend then
        self:CreateLegend(Container, total)
    end
    
    return Container
end

function PieChart:DrawSlices(total)
    if total == 0 then return end
    
    local centerX = self.Size / 2
    local centerY = self.Size / 2
    local radius = (self.Type == "doughnut") and (self.Size / 2 - 15) or (self.Size / 2 - 2)
    local innerRadius = (self.Type == "doughnut") and (self.Size / 2 - 30) or 0
    
    local startAngle = -90  -- Start from top
    
    local defaultColors = {
        Color3.fromRGB(59, 130, 246),   -- Blue
        Color3.fromRGB(16, 185, 129),    -- Green
        Color3.fromRGB(245, 158, 11),    -- Yellow
        Color3.fromRGB(239, 68, 68),     -- Red
        Color3.fromRGB(139, 92, 246),    -- Purple
        Color3.fromRGB(236, 72, 153),    -- Pink
        Color3.fromRGB(20, 184, 166),    -- Teal
        Color3.fromRGB(249, 115, 22),    -- Orange
    }
    
    for i, item in ipairs(self.Data) do
        local value = item.value or 0
        local percent = value / total
        local endAngle = startAngle + (percent * 360)
        
        local color = item.color or defaultColors[(i - 1) % #defaultColors + 1]
        
        -- Create slice using multiple segments for smooth arc
        local segments = math.max(math.ceil(percent * 36), 3)
        
        for j = 1, segments do
            local segStartAngle = startAngle + (j - 1) * (percent * 360 / segments)
            local segEndAngle = startAngle + j * (percent * 360 / segments)
            
            self:DrawSegment(ChartArea, centerX, centerY, radius, innerRadius, segStartAngle, segEndAngle, color, i, j == 1)
        end
        
        startAngle = endAngle
    end
end

function PieChart:DrawSegment(parent, cx, cy, radius, innerRadius, startAngle, endAngle, color, sliceIndex, isFirst)
    local TweenService = game:GetService("TweenService")
    
    local function getPoint(angle, r)
        local rad = math.rad(angle)
        return cx + r * math.cos(rad), cy + r * math.sin(rad)
    end
    
    -- Create polygon frame
    local segment = Instance.new("Frame")
    segment.Size = UDim2.new(1, 0, 1, 0)
    segment.Position = UDim2.new(0, 0, 0, 0)
    segment.BackgroundTransparency = 1
    segment.BorderSizePixel = 0
    segment.Parent = parent
    
    -- Draw triangle segments
    local steps = 10
    for i = 1, steps do
        local a1 = startAngle + (i - 1) * (endAngle - startAngle) / steps
        local a2 = startAngle + i * (endAngle - startAngle) / steps
        
        local x1, y1 = getPoint(a1, radius)
        local x2, y2 = getPoint(a2, radius)
        local xi1, yi1 = getPoint(a1, innerRadius)
        local xi2, yi2 = getPoint(a2, innerRadius)
        
        -- Outer triangle
        local tri1 = Instance.new("Frame")
        tri1.Size = UDim2.new(0, 4, 0, 4)
        tri1.Position = UDim2.new(0, x1 - cx + radius, 0, y1 - cy + radius)
        tri1.AnchorPoint = Vector2.new(0.5, 0.5)
        tri1.BackgroundColor3 = color
        tri1.BorderSizePixel = 0
        tri1.Parent = segment
        tri1.Name = "Slice"
        
        -- Inner triangle for doughnut
        if innerRadius > 0 then
            local tri2 = Instance.new("Frame")
            tri2.Size = UDim2.new(0, 4, 0, 4)
            tri2.Position = UDim2.new(0, xi1 - cx + radius, 0, yi1 - cy + radius)
            tri2.AnchorPoint = Vector2.new(0.5, 0.5)
            tri2.BackgroundColor3 = self.Theme.Default
            tri2.BorderSizePixel = 0
            tri2.Parent = segment
        end
        
        if self.Animate then
            tri1.BackgroundTransparency = 1
            local delay = (sliceIndex - 1) * 0.1 + i * 0.01
            self.Utilities:TweenProperty(tri1, "BackgroundTransparency", 0, 0.3, delay)
        end
    end
    
    -- Hover effect area
    local hoverArea = Instance.new("Frame")
    hoverArea.Size = UDim2.new(0, radius * 2, 0, radius * 2)
    hoverArea.Position = UDim2.new(0.5, -radius, 0.5, -radius)
    hoverArea.AnchorPoint = Vector2.new(0.5, 0.5)
    hoverArea.BackgroundTransparency = 1
    hoverArea.Parent = segment
    
    hoverArea.MouseEnter:Connect(function()
        if self.CenterLabel and self.Type == "doughnut" then
            -- Could update center label here
        end
    end)
end

function PieChart:CreateLegend(parent, total)
    local legendX = self.Size + 15
    local legendY = (self.Title ~= "" and 25 or 0) + 5
    
    local Legend = Instance.new("Frame")
    Legend.Size = UDim2.new(1, -self.Size - 25, 0, #self.Data * 18 + 10)
    Legend.Position = UDim2.new(0, legendX, 0, legendY)
    Legend.BackgroundTransparency = 1
    Legend.Parent = parent
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.Parent = Legend
    
    local defaultColors = {
        Color3.fromRGB(59, 130, 246),
        Color3.fromRGB(16, 185, 129),
        Color3.fromRGB(245, 158, 11),
        Color3.fromRGB(239, 68, 68),
        Color3.fromRGB(139, 92, 246),
        Color3.fromRGB(236, 72, 153),
        Color3.fromRGB(20, 184, 166),
        Color3.fromRGB(249, 115, 22),
    }
    
    for i, item in ipairs(self.Data) do
        local value = item.value or 0
        local percent = total > 0 and math.round((value / total) * 100) or 0
        local label = item.label or "Item " .. i
        local color = item.color or defaultColors[(i - 1) % #defaultColors + 1]
        
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, 0, 0, 16)
        itemFrame.BackgroundTransparency = 1
        itemFrame.Parent = Legend
        
        -- Color box
        local colorBox = Instance.new("Frame")
        colorBox.Size = UDim2.new(0, 12, 0, 12)
        colorBox.Position = UDim2.new(0, 0, 0.5, 0)
        colorBox.AnchorPoint = Vector2.new(0, 0.5)
        colorBox.BackgroundColor3 = color
        colorBox.BorderSizePixel = 0
        colorBox.Parent = itemFrame
        self.Utilities:CreateCorner(colorBox, 2)
        
        -- Label
        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(1, -30, 1, 0)
        labelText.Position = UDim2.new(0, 18, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = self.Theme.Text
        labelText.TextSize = 11
        labelText.Font = Enum.Font.Gotham
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.TextTruncate = Enum.TextTruncate.AtEnd
        labelText.Parent = itemFrame
        
        -- Percent
        local percentText = Instance.new("TextLabel")
        percentText.Size = UDim2.new(0, 35, 1, 0)
        percentText.Position = UDim2.new(1, -35, 0, 0)
        percentText.BackgroundTransparency = 1
        percentText.Text = percent .. "%"
        percentText.TextColor3 = self.Theme.SecondText
        percentText.TextSize = 11
        percentText.Font = Enum.Font.GothamBold
        percentText.TextXAlignment = Enum.TextXAlignment.Right
        percentText.Parent = itemFrame
    end
end

-- Update chart data
function PieChart:UpdateData(newData)
    self.Data = newData
    -- Clear and redraw would require recreating the container
    -- For simplicity, this would need to be called on the parent
end

-- Set percentage displayed in center (for doughnut)
function PieChart:SetPercent(percent)
    if self.CenterLabel then
        self.CenterLabel.Text = percent .. "%"
    end
end

return PieChart
