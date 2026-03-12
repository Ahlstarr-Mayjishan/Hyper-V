--[[
    Hyper-V - Value Slider Component
    Slider kết hợp Input để nhập trực tiếp giá trị
]]

local ValueSlider = {}

function ValueSlider.new(config, theme, utilities)
    local self = setmetatable({}, {__index = ValueSlider})
    
    self.Name = config.Name or "ValueSlider"
    self.Title = config.Title or "Slider"
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Value = config.Value or 50
    self.Step = config.Step or 1
    self.Callback = config.Callback
    self.Description = config.Description or ""
    self.ShowInput = config.ShowInput ~= false
    self.InputWidth = config.InputWidth or 50
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function ValueSlider:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, 55)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    self.Container = Container
    
    -- Title and Value display
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -70, 0, 20)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = self.Title
    Title.TextColor3 = self.Theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -60, 0, 5)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(self.Value)
    valueLabel.TextColor3 = self.Theme.Accent
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = Container
    self.ValueLabel = valueLabel
    
    -- Description
    local hasDesc = self.Description and self.Description ~= ""
    if hasDesc then
        local Desc = Instance.new("TextLabel")
        Desc.Size = UDim2.new(1, -70, 0, 14)
        Desc.Position = UDim2.new(0, 10, 0, 24)
        Desc.BackgroundTransparency = 1
        Desc.Text = self.Description
        Desc.TextColor3 = self.Theme.SecondText
        Desc.TextSize = 10
        Desc.Font = Enum.Font.Gotham
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.Parent = Container
    end
    
    -- Slider Track
    local trackHeight = 6
    local track = Instance.new("Frame")
    track.Size = UDim2.new(self.ShowInput and 1 or 1, -10, 0, trackHeight)
    track.Position = UDim2.new(0, 5, 1, -18)
    track.BackgroundColor3 = self.Theme.Second
    track.BorderSizePixel = 0
    track.Parent = Container
    self.Utilities:CreateCorner(track, 3)
    self.Track = track
    
    -- Progress Fill
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = self.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    self.Utilities:CreateCorner(fill, 3)
    self.Fill = fill
    
    -- Slider Handle
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.BackgroundColor3 = Color3.new(1, 1, 1)
    handle.BorderSizePixel = 0
    handle.Parent = track
    self.Utilities:CreateCorner(handle, 8)
    self.Handle = handle
    
    -- Input Box
    if self.ShowInput then
        local inputBox = Instance.new("TextBox")
        inputBox.Size = UDim2.new(0, self.InputWidth, 0, 24)
        inputBox.Position = UDim2.new(1, -self.InputWidth - 5, 0.5, 12)
        inputBox.AnchorPoint = Vector2.new(1, 0.5)
        inputBox.BackgroundColor3 = self.Theme.Second
        inputBox.BorderSizePixel = 0
        inputBox.Text = tostring(self.Value)
        inputBox.TextColor3 = self.Theme.Text
        inputBox.TextSize = 11
        inputBox.Font = Enum.Font.Gotham
        inputBox.TextXAlignment = Enum.TextXAlignment.Center
        inputBox.ClearTextOnFocus = false
        inputBox.Parent = Container
        self.Utilities:CreateCorner(inputBox, 6)
        self.Utilities:CreateStroke(inputBox, self.Theme.Border)
        self.InputBox = inputBox
        
        -- Input handlers
        inputBox.Focused:Connect(function()
            inputBox.TextTransparency = 0
        end)
        
        inputBox.FocusLost:Connect(function()
            self:SetValueFromInput(inputBox.Text)
        end)
        
        inputBox.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
                    self:SetValueFromInput(inputBox.Text)
                end
            end
        end)
    end
    
    -- Dragging
    local isDragging = false
    
    local function updateFromMouse()
        if not isDragging then return end
        
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        local trackStart = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        
        local relativeX = mouse.X - trackStart
        relativeX = math.clamp(relativeX, 0, trackWidth)
        
        local percent = relativeX / trackWidth
        local rawValue = self.Min + (self.Max - self.Min) * percent
        local steppedValue = math.floor(rawValue / self.Step + 0.5) * self.Step
        steppedValue = math.clamp(steppedValue, self.Min, self.Max)
        
        self:SetValue(steppedValue)
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateFromMouse()
        end
    end)
    
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if isDragging then
            updateFromMouse()
        end
    end)
    
    -- Initial update
    self:UpdateVisual()
    
    return Container
end

function ValueSlider:UpdateVisual()
    local percent = (self.Value - self.Min) / (self.Max - self.Min)
    percent = math.clamp(percent, 0, 1)
    
    -- Update fill
    local trackWidth = self.Track.AbsoluteSize.X
    self.Fill.Size = UDim2.new(percent, 0, 1, 0)
    
    -- Update handle position
    local handlePos = percent * (trackWidth - 16) + 8
    self.Handle.Position = UDim2.new(0, handlePos - 8, 0.5, 0)
    
    -- Update value label
    self.ValueLabel.Text = tostring(self.Value)
    
    -- Update input box
    if self.InputBox then
        self.InputBox.Text = tostring(self.Value)
    end
end

function ValueSlider:SetValue(value)
    local steppedValue = math.floor(value / self.Step + 0.5) * self.Step
    steppedValue = math.clamp(steppedValue, self.Min, self.Max)
    
    if self.Value ~= steppedValue then
        self.Value = steppedValue
        self:UpdateVisual()
        
        if self.Callback then
            self.Callback(self.Value)
        end
    end
end

function ValueSlider:GetValue()
    return self.Value
end

function ValueSlider:SetValueFromInput(text)
    local num = tonumber(text)
    if num then
        self:SetValue(num)
    else
        -- Reset to current value
        if self.InputBox then
            self.InputBox.Text = tostring(self.Value)
        end
    end
end

function ValueSlider:SetRange(min, max)
    self.Min = min
    self.Max = max
    self.Value = math.clamp(self.Value, min, max)
    self:UpdateVisual()
end

return ValueSlider
