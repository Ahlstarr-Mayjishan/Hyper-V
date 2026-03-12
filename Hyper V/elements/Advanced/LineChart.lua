--[[
    Hyper-V - Line Chart Component
    Biểu đồ đường - Hiển thị dữ liệu theo thời gian
]]

local LineChart = {}

function LineChart.new(config, theme, utilities)
    local self = setmetatable({}, {__index = LineChart})
    
    self.Name = config.Name or "LineChart"
    self.Title = config.Title or ""
    self.Data = config.Data or {}  -- { {x, y}, {x, y}, ... }
    self.Labels = config.Labels or {}  -- { "Day 1", "Day 2", ... }
    self.Lines = config.Lines or {}  -- { {data = {}, color = Color3}, ... }
    self.Width = config.Width or 400
    self.Height = config.Height or 150
    self.ShowPoints = config.ShowPoints or true
    self.ShowGrid = config.ShowGrid or true
    self.ShowLegend = config.ShowLegend or false
    self.Animate = config.Animate or true
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function LineChart:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, self.Height + (self.Title ~= "" and 25 or 0) + (self.ShowLegend and 30 or 0))
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
    ChartArea.Size = UDim2.new(1, -20, 0, self.Height - 10)
    ChartArea.Position = UDim2.new(0, 10, 0, contentOffset + 5)
    ChartArea.BackgroundTransparency = 1
    ChartArea.BorderSizePixel = 0
    ChartArea.Parent = Container
    
    -- Grid lines
    if self.ShowGrid then
        for i = 1, 4 do
            local gridLine = Instance.new("Frame")
            gridLine.Size = UDim2.new(1, 0, 0, 1)
            gridLine.Position = UDim2.new(0, 0, (i-1)/4, 0)
            gridLine.BackgroundColor3 = self.Theme.Border
            gridLine.BorderSizePixel = 0
            gridLine.Transparency = 0.5
            gridLine.Parent = ChartArea
        end
    end
    
    -- Chart area for drawing
    local DrawArea = Instance.new("Frame")
    DrawArea.Size = UDim2.new(1, -30, 1, -20)
    DrawArea.Position = UDim2.new(0, 15, 0, 10)
    DrawArea.BackgroundTransparency = 1
    DrawArea.ClipsDescendants = true
    DrawArea.Parent = ChartArea
    
    self.ChartArea = ChartArea
    self.DrawArea = DrawArea
    
    -- Draw lines
    self:DrawLines()
    
    -- Legend
    if self.ShowLegend and #self.Lines > 1 then
        self:CreateLegend(Container)
    end
    
    return Container
end

function LineChart:DrawLines()
    local drawWidth = self.DrawArea.AbsoluteSize.X
    local drawHeight = self.DrawArea.AbsoluteSize.Y
    
    -- Find max value for scaling
    local maxVal = 100
    local minVal = 0
    
    for _, lineData in ipairs(self.Lines) do
        for _, point in ipairs(lineData.data or {}) do
            maxVal = math.max(maxVal, point.y or 0)
        end
    end
    
    -- Draw each line
    for _, lineConfig in ipairs(self.Lines) do
        local data = lineConfig.data or {}
        local color = lineConfig.color or self.Theme.Accent
        
        if #data >= 2 then
            local points = {}
            
            for i, point in ipairs(data) do
                local xPos = (i - 1) / (#data - 1)
                local yPos = 1 - ((point.y - minVal) / (maxVal - minVal))
                
                table.insert(points, {
                    X = xPos * drawWidth,
                    Y = yPos * drawHeight,
                    Value = point.y
                })
            end
            
            -- Draw line segments
            for i = 1, #points - 1 do
                local p1 = points[i]
                local p2 = points[i + 1]
                
                local lineFrame = Instance.new("Frame")
                local dx = p2.X - p1.X
                local dy = p2.Y - p1.Y
                local length = math.sqrt(dx*dx + dy*dy)
                local angle = math.atan2(dy, dx)
                
                lineFrame.Size = UDim2.new(0, length, 0, 2)
                lineFrame.Position = UDim2.new(0, p1.X, 0, p1.Y)
                lineFrame.Rotation = math.deg(angle)
                lineFrame.BackgroundColor3 = color
                lineFrame.BorderSizePixel = 0
                lineFrame.Parent = self.DrawArea
                
                if self.Animate then
                    lineFrame.BackgroundTransparency = 1
                    self.Utilities:TweenProperty(lineFrame, "BackgroundTransparency", 0, 0.5, i * 0.1)
                end
            end
            
            -- Draw points
            if self.ShowPoints then
                for i, p in ipairs(points) do
                    local point = Instance.new("Frame")
                    point.Size = UDim2.new(0, 8, 0, 8)
                    point.Position = UDim2.new(0, p.X - 4, 0, p.Y - 4)
                    point.BackgroundColor3 = color
                    point.BorderSizePixel = 0
                    point.Parent = self.DrawArea
                    self.Utilities:CreateCorner(point, 4)
                    
                    -- Value tooltip on hover
                    local tooltip = Instance.new("TextLabel")
                    tooltip.Size = UDim2.new(0, 40, 0, 18)
                    tooltip.Position = UDim2.new(0.5, -20, 0, -25)
                    tooltip.BackgroundColor3 = self.Theme.Second
                    tooltip.Text = tostring(p.Value)
                    tooltip.TextColor3 = self.Theme.Text
                    tooltip.TextSize = 10
                    tooltip.Font = Enum.Font.Gotham
                    tooltip.Visible = false
                    tooltip.Parent = point
                    self.Utilities:CreateCorner(tooltip, 4)
                    self.Utilities:CreateStroke(tooltip, self.Theme.Border)
                    
                    point.MouseEnter:Connect(function()
                        tooltip.Visible = true
                    end)
                    
                    point.MouseLeave:Connect(function()
                        tooltip.Visible = false
                    end)
                    
                    if self.Animate then
                        point.Size = UDim2.new(0, 0, 0, 0)
                        self.Utilities:TweenProperty(point, "Size", UDim2.new(0, 8, 0, 8), 0.3, i * 0.1)
                    end
                end
            end
        end
    end
end

function LineChart:CreateLegend(parent)
    local legendY = self.Height + (self.Title ~= "" and 25 or 0) + 5
    
    local Legend = Instance.new("Frame")
    Legend.Size = UDim2.new(1, -20, 0, 25)
    Legend.Position = UDim2.new(0, 10, 0, legendY)
    Legend.BackgroundTransparency = 1
    Legend.Parent = parent
    
    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.Padding = UDim.new(0, 15)
    Layout.Parent = Legend
    
    for i, lineConfig in ipairs(self.Lines) do
        local color = lineConfig.color or self.Theme.Accent
        local name = lineConfig.name or "Line " .. i
        
        local item = Instance.new("Frame")
        item.Size = UDim2.new(0, 80, 0, 20)
        item.BackgroundTransparency = 1
        item.Parent = Legend
        
        local colorBox = Instance.new("Frame")
        colorBox.Size = UDim2.new(0, 12, 0, 12)
        colorBox.Position = UDim2.new(0, 0, 0.5, 0)
        colorBox.AnchorPoint = Vector2.new(0, 0.5)
        colorBox.BackgroundColor3 = color
        colorBox.BorderSizePixel = 0
        colorBox.Parent = item
        self.Utilities:CreateCorner(colorBox, 2)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -18, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = self.Theme.Text
        label.TextSize = 10
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = item
    end
end

-- Update chart data dynamically
function LineChart:UpdateData(newData)
    self.Data = newData
    -- Clear and redraw
    for _, v in ipairs(self.DrawArea:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
    self:DrawLines()
end

-- Add new point to line
function LineChart:AddPoint(lineIndex, x, y)
    if self.Lines[lineIndex] then
        table.insert(self.Lines[lineIndex].data, {x = x, y = y})
        self:UpdateData()
    end
end

return LineChart
