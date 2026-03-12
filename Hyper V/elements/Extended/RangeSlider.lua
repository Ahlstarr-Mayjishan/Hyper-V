local UserInputService = game:GetService("UserInputService")

local RangeSlider = {}
RangeSlider.__index = RangeSlider

function RangeSlider.new(config, theme, utilities)
    local self = setmetatable({}, RangeSlider)

    self.Name = config.Name or "RangeSlider"
    self.Title = config.Title or config.Name or "Range Slider"
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.MinValue = config.DefaultMin or config.MinValue or self.Min
    self.MaxValue = config.DefaultMax or config.MaxValue or self.Max
    self.Step = config.Step or 1
    self.Callback = config.Callback or config.OnChange
    self.Description = config.Description or ""
    self.Parent = config.Parent
    self.Theme = theme
    self.Utilities = utilities

    self.ActiveHandle = nil
    self:Create()
    self:SetValues(self.MinValue, self.MaxValue, true)
    return self
end

function RangeSlider:Create()
    local container = Instance.new("Frame")
    container.Name = self.Name
    container.Size = UDim2.new(1, 0, 0, self.Description ~= "" and 68 or 52)
    container.BackgroundColor3 = self.Theme.Default
    container.BorderSizePixel = 0
    container.Parent = self.Parent
    self.Utilities:CreateCorner(container, 8)
    self.Utilities:CreateStroke(container, self.Theme.Border)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 90, 0, 20)
    valueLabel.Position = UDim2.new(1, -100, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = ""
    valueLabel.TextColor3 = self.Theme.Accent
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    if self.Description ~= "" then
        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(1, -20, 0, 14)
        description.Position = UDim2.new(0, 10, 0, 23)
        description.BackgroundTransparency = 1
        description.Text = self.Description
        description.TextColor3 = self.Theme.SecondText or self.Theme.Text
        description.TextSize = 10
        description.Font = Enum.Font.Gotham
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.Parent = container
    end

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 1, -18)
    track.BackgroundColor3 = self.Theme.Second
    track.BorderSizePixel = 0
    track.Parent = container
    self.Utilities:CreateCorner(track, 3)
    self.Utilities:CreateStroke(track, self.Theme.Border)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = self.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    self.Utilities:CreateCorner(fill, 3)

    local minHandle = Instance.new("Frame")
    minHandle.Size = UDim2.new(0, 16, 0, 16)
    minHandle.AnchorPoint = Vector2.new(0.5, 0.5)
    minHandle.BackgroundColor3 = Color3.new(1, 1, 1)
    minHandle.BorderSizePixel = 0
    minHandle.Parent = track
    self.Utilities:CreateCorner(minHandle, 8)

    local maxHandle = minHandle:Clone()
    maxHandle.Parent = track

    self.Container = container
    self.Track = track
    self.Fill = fill
    self.MinHandle = minHandle
    self.MaxHandle = maxHandle
    self.ValueLabel = valueLabel

    local function beginDrag(handleName)
        self.ActiveHandle = handleName
    end
    local function endDrag()
        self.ActiveHandle = nil
    end

    minHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginDrag("Min")
        end
    end)
    maxHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginDrag("Max")
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            endDrag()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if self.ActiveHandle and input.UserInputType == Enum.UserInputType.MouseMovement then
            self:_UpdateFromMouse(input.Position.X)
        end
    end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local percent = self:_MouseToPercent(input.Position.X)
            local minPercent = self:_ValueToPercent(self.MinValue)
            local maxPercent = self:_ValueToPercent(self.MaxValue)
            self.ActiveHandle = math.abs(percent - minPercent) <= math.abs(percent - maxPercent) and "Min" or "Max"
            self:_UpdateFromMouse(input.Position.X)
        end
    end)
end

function RangeSlider:_ValueToPercent(value)
    if self.Max == self.Min then
        return 0
    end
    return (value - self.Min) / (self.Max - self.Min)
end

function RangeSlider:_MouseToPercent(mouseX)
    local trackStart = self.Track.AbsolutePosition.X
    local trackWidth = self.Track.AbsoluteSize.X
    local relativeX = math.clamp(mouseX - trackStart, 0, trackWidth)
    return trackWidth > 0 and (relativeX / trackWidth) or 0
end

function RangeSlider:_UpdateFromMouse(mouseX)
    local percent = self:_MouseToPercent(mouseX)
    local rawValue = self.Min + ((self.Max - self.Min) * percent)
    local snapped = math.floor(rawValue / self.Step + 0.5) * self.Step

    if self.ActiveHandle == "Min" then
        self:SetValues(snapped, self.MaxValue)
    else
        self:SetValues(self.MinValue, snapped)
    end
end

function RangeSlider:UpdateVisual()
    local minPercent = self:_ValueToPercent(self.MinValue)
    local maxPercent = self:_ValueToPercent(self.MaxValue)
    self.Fill.Position = UDim2.new(minPercent, 0, 0, 0)
    self.Fill.Size = UDim2.new(math.max(0, maxPercent - minPercent), 0, 1, 0)
    self.MinHandle.Position = UDim2.new(minPercent, 0, 0.5, 0)
    self.MaxHandle.Position = UDim2.new(maxPercent, 0, 0.5, 0)
    self.ValueLabel.Text = string.format("%s - %s", tostring(self.MinValue), tostring(self.MaxValue))
end

function RangeSlider:SetValues(minValue, maxValue, silent)
    local nextMin = math.clamp(minValue or self.MinValue, self.Min, self.Max)
    local nextMax = math.clamp(maxValue or self.MaxValue, self.Min, self.Max)

    if nextMin > nextMax then
        nextMin, nextMax = math.min(nextMin, nextMax), math.max(nextMin, nextMax)
    end

    self.MinValue = nextMin
    self.MaxValue = nextMax
    self:UpdateVisual()

    if not silent and self.Callback then
        self.Callback(self.MinValue, self.MaxValue)
    end
end

function RangeSlider:GetValue()
    return self.MinValue, self.MaxValue
end

function RangeSlider:SetValue(value, silent)
    if type(value) == "table" then
        return self:SetValues(value[1], value[2], silent)
    end

    return self:SetValues(value, self.MaxValue, silent)
end

return RangeSlider
