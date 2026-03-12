local MultiSelectDropdown = {}
MultiSelectDropdown.__index = MultiSelectDropdown

function MultiSelectDropdown.new(config, theme, utilities)
    local self = setmetatable({}, MultiSelectDropdown)

    self.Name = config.Name or "MultiSelectDropdown"
    self.Title = config.Title or config.Name or "Multi Select"
    self.Options = config.Options or {}
    self.Selected = {}
    self.Callback = config.Callback or config.OnChange
    self.Parent = config.Parent
    self.Theme = theme
    self.Utilities = utilities
    self.IsOpen = false

    for _, value in ipairs(config.Default or {}) do
        self.Selected[value] = true
    end

    self:Create()
    self:RefreshSummary()
    return self
end

function MultiSelectDropdown:Create()
    local container = Instance.new("Frame")
    container.Name = self.Name
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundColor3 = self.Theme.Second
    container.BorderSizePixel = 0
    container.Parent = self.Parent
    self.Utilities:CreateCorner(container, 6)
    self.Utilities:CreateStroke(container, self.Theme.Border)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, -10, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.Text
    title.TextSize = 13
    title.Font = Enum.Font.Gotham
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local summary = Instance.new("TextLabel")
    summary.Size = UDim2.new(0.5, -35, 1, 0)
    summary.Position = UDim2.new(0.5, 0, 0, 0)
    summary.BackgroundTransparency = 1
    summary.TextColor3 = self.Theme.TitleText
    summary.TextSize = 12
    summary.Font = Enum.Font.GothamBold
    summary.TextXAlignment = Enum.TextXAlignment.Right
    summary.Parent = container

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = self.Theme.Text
    arrow.TextSize = 12
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = container

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 0, 0)
    panel.Position = UDim2.new(0, 0, 1, 4)
    panel.BackgroundColor3 = self.Theme.Default
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ClipsDescendants = true
    panel.Parent = container
    self.Utilities:CreateCorner(panel, 6)
    self.Utilities:CreateStroke(panel, self.Theme.Border)

    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Size = UDim2.new(1, -10, 0, 26)
    buttonsFrame.Position = UDim2.new(0, 5, 0, 5)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = panel

    local selectAll = Instance.new("TextButton")
    selectAll.Size = UDim2.new(0.5, -3, 1, 0)
    selectAll.BackgroundColor3 = self.Theme.Second
    selectAll.BorderSizePixel = 0
    selectAll.Text = "Select all"
    selectAll.TextColor3 = self.Theme.Text
    selectAll.TextSize = 11
    selectAll.Font = Enum.Font.GothamBold
    selectAll.Parent = buttonsFrame
    self.Utilities:CreateCorner(selectAll, 5)

    local clear = Instance.new("TextButton")
    clear.Size = UDim2.new(0.5, -3, 1, 0)
    clear.Position = UDim2.new(0.5, 6, 0, 0)
    clear.BackgroundColor3 = self.Theme.Second
    clear.BorderSizePixel = 0
    clear.Text = "Clear"
    clear.TextColor3 = self.Theme.Text
    clear.TextSize = 11
    clear.Font = Enum.Font.GothamBold
    clear.Parent = buttonsFrame
    self.Utilities:CreateCorner(clear, 5)

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -10, 0, math.min(#self.Options * 28, 144))
    list.Position = UDim2.new(0, 5, 0, 36)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 4
    list.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = list
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
        panel.Size = UDim2.new(1, 0, 0, 42 + math.min(layout.AbsoluteContentSize.Y + 4, 144))
    end)

    self.Container = container
    self.Panel = panel
    self.List = list
    self.Summary = summary
    self.Arrow = arrow
    self.OptionButtons = {}

    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SetOpen(not self.IsOpen)
        end
    end)

    selectAll.MouseButton1Click:Connect(function()
        for _, option in ipairs(self.Options) do
            self.Selected[option] = true
        end
        self:RefreshOptions()
        self:Emit()
    end)

    clear.MouseButton1Click:Connect(function()
        self.Selected = {}
        self:RefreshOptions()
        self:Emit()
    end)

    for _, option in ipairs(self.Options) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -2, 0, 24)
        button.BackgroundColor3 = self.Theme.Second
        button.BorderSizePixel = 0
        button.TextColor3 = self.Theme.Text
        button.TextSize = 12
        button.Font = Enum.Font.Gotham
        button.Parent = list
        self.Utilities:CreateCorner(button, 5)
        self.OptionButtons[option] = button

        button.MouseButton1Click:Connect(function()
            self.Selected[option] = not self.Selected[option] or nil
            self:RefreshOptions()
            self:Emit()
        end)
    end

    self:RefreshOptions()
end

function MultiSelectDropdown:SetOpen(isOpen)
    self.IsOpen = isOpen
    self.Panel.Visible = isOpen
    self.Arrow.Text = isOpen and "^" or "v"
end

function MultiSelectDropdown:RefreshOptions()
    for option, button in pairs(self.OptionButtons) do
        local selected = self.Selected[option] == true
        button.Text = selected and ("[x] " .. option) or ("[ ] " .. option)
        button.BackgroundColor3 = selected and self.Theme.Accent or self.Theme.Second
        button.TextColor3 = selected and Color3.new(1, 1, 1) or self.Theme.Text
    end
    self:RefreshSummary()
end

function MultiSelectDropdown:RefreshSummary()
    local selected = self:GetValue()
    if #selected == 0 then
        self.Summary.Text = "None"
    elseif #selected <= 2 then
        self.Summary.Text = table.concat(selected, ", ")
    else
        self.Summary.Text = string.format("%d selected", #selected)
    end
end

function MultiSelectDropdown:GetValue()
    local values = {}
    for _, option in ipairs(self.Options) do
        if self.Selected[option] then
            table.insert(values, option)
        end
    end
    return values
end

function MultiSelectDropdown:SetValue(values, silent)
    self.Selected = {}
    for _, value in ipairs(values or {}) do
        self.Selected[value] = true
    end
    self:RefreshOptions()
    if not silent then
        self:Emit()
    end
end

function MultiSelectDropdown:Emit()
    if self.Callback then
        self.Callback(self:GetValue())
    end
end

return MultiSelectDropdown
