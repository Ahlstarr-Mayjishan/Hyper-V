local RunService = game:GetService("RunService")

local NumberInput = {}
NumberInput.__index = NumberInput

function NumberInput.new(config, theme, utilities)
    local self = setmetatable({}, NumberInput)

    self.Name = config.Name or "NumberInput"
    self.Title = config.Title or config.Name or "Number Input"
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Value = config.Default or config.Value or self.Min
    self.Step = config.Step or 1
    self.AcceleratedStep = config.AcceleratedStep or (self.Step * 5)
    self.Callback = config.Callback or config.OnChange
    self.Description = config.Description or ""
    self.Parent = config.Parent

    self.Theme = theme
    self.Utilities = utilities
    self.Connections = {}

    self:Create()
    self:SetValue(self.Value, true)
    return self
end

function NumberInput:Create()
    local container = Instance.new("Frame")
    container.Name = self.Name
    container.Size = UDim2.new(1, 0, 0, self.Description ~= "" and 64 or 48)
    container.BackgroundColor3 = self.Theme.Default
    container.BorderSizePixel = 0
    container.Parent = self.Parent
    self.Utilities:CreateCorner(container, 8)
    self.Utilities:CreateStroke(container, self.Theme.Border)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    if self.Description ~= "" then
        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(1, -20, 0, 14)
        description.Position = UDim2.new(0, 10, 0, 24)
        description.BackgroundTransparency = 1
        description.Text = self.Description
        description.TextColor3 = self.Theme.SecondText or self.Theme.Text
        description.TextSize = 10
        description.Font = Enum.Font.Gotham
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.Parent = container
    end

    local controls = Instance.new("Frame")
    controls.Size = UDim2.new(0, 112, 0, 28)
    controls.Position = UDim2.new(1, -122, 0.5, self.Description ~= "" and 6 or 0)
    controls.AnchorPoint = Vector2.new(0, 0.5)
    controls.BackgroundTransparency = 1
    controls.Parent = container

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 28, 0, 28)
    minus.BackgroundColor3 = self.Theme.Second
    minus.BorderSizePixel = 0
    minus.Text = "-"
    minus.TextColor3 = self.Theme.TitleText
    minus.TextSize = 18
    minus.Font = Enum.Font.GothamBold
    minus.Parent = controls
    self.Utilities:CreateCorner(minus, 6)
    self.Utilities:CreateStroke(minus, self.Theme.Border)

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 48, 0, 28)
    input.Position = UDim2.new(0, 32, 0, 0)
    input.BackgroundColor3 = self.Theme.Second
    input.BorderSizePixel = 0
    input.Text = tostring(self.Value)
    input.TextColor3 = self.Theme.Text
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = controls
    self.Utilities:CreateCorner(input, 6)
    self.Utilities:CreateStroke(input, self.Theme.Border)

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 28, 0, 28)
    plus.Position = UDim2.new(0, 84, 0, 0)
    plus.BackgroundColor3 = self.Theme.Second
    plus.BorderSizePixel = 0
    plus.Text = "+"
    plus.TextColor3 = self.Theme.TitleText
    plus.TextSize = 18
    plus.Font = Enum.Font.GothamBold
    plus.Parent = controls
    self.Utilities:CreateCorner(plus, 6)
    self.Utilities:CreateStroke(plus, self.Theme.Border)

    self.Container = container
    self.Input = input
    self.MinusButton = minus
    self.PlusButton = plus

    table.insert(self.Connections, input.FocusLost:Connect(function()
        self:SetValue(tonumber(input.Text) or self.Value)
    end))

    self:_BindStepper(minus, -1)
    self:_BindStepper(plus, 1)
end

function NumberInput:_BindStepper(button, direction)
    local holding = false
    local heldFor = 0
    local heartbeat

    local function applyStep(multiplier)
        local step = multiplier >= 6 and self.AcceleratedStep or self.Step
        self:SetValue(self.Value + (step * direction))
    end

    table.insert(self.Connections, button.MouseButton1Click:Connect(function()
        applyStep(0)
    end))

    table.insert(self.Connections, button.MouseButton1Down:Connect(function()
        holding = true
        heldFor = 0
        heartbeat = RunService.Heartbeat:Connect(function(dt)
            if not holding then
                return
            end
            heldFor = heldFor + dt
            if heldFor >= 0.35 then
                heldFor = heldFor - 0.08
                applyStep(math.floor(heldFor / 0.25))
            end
        end)
    end))

    local function stopHolding()
        holding = false
        if heartbeat then
            heartbeat:Disconnect()
            heartbeat = nil
        end
    end

    table.insert(self.Connections, button.MouseButton1Up:Connect(stopHolding))
    table.insert(self.Connections, button.MouseLeave:Connect(stopHolding))
end

function NumberInput:SetValue(value, silent)
    local nextValue = tonumber(value) or self.Value
    nextValue = math.clamp(nextValue, self.Min, self.Max)

    if self.Step > 0 then
        nextValue = math.floor(nextValue / self.Step + 0.5) * self.Step
    end

    if nextValue == self.Value and not silent then
        if self.Input then
            self.Input.Text = tostring(nextValue)
        end
        return
    end

    self.Value = nextValue
    if self.Input then
        self.Input.Text = tostring(nextValue)
    end

    if not silent and self.Callback then
        self.Callback(nextValue)
    end
end

function NumberInput:GetValue()
    return self.Value
end

return NumberInput
