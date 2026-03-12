local SubTabs = {}
SubTabs.__index = SubTabs

function SubTabs.new(config, theme, utilities)
    local self = setmetatable({}, SubTabs)

    self.Name = config.Name or "SubTabs"
    self.Tabs = config.Tabs or {}
    self.Default = config.Default or ((self.Tabs[1] and self.Tabs[1].Name) or nil)
    self.Height = config.Height or 200
    self.Parent = config.Parent
    self.Theme = theme
    self.Utilities = utilities

    self.Buttons = {}
    self.Pages = {}
    self.ActiveKey = nil

    self:Create()
    return self
end

function SubTabs:Create()
    local container = Instance.new("Frame")
    container.Name = self.Name
    container.Size = UDim2.new(1, 0, 0, self.Height)
    container.BackgroundColor3 = self.Theme.Default
    container.BorderSizePixel = 0
    container.Parent = self.Parent
    self.Utilities:CreateCorner(container, 8)
    self.Utilities:CreateStroke(container, self.Theme.Border)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -10, 0, 28)
    bar.Position = UDim2.new(0, 5, 0, 5)
    bar.BackgroundTransparency = 1
    bar.Parent = container

    local barLayout = Instance.new("UIListLayout")
    barLayout.FillDirection = Enum.FillDirection.Horizontal
    barLayout.Padding = UDim.new(0, 6)
    barLayout.Parent = bar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -38)
    content.Position = UDim2.new(0, 5, 0, 33)
    content.BackgroundTransparency = 1
    content.Parent = container

    self.Container = container
    self.Bar = bar
    self.Content = content

    for _, tab in ipairs(self.Tabs) do
        self:AddTab(tab)
    end

    if self.Default then
        self:Select(self.Default)
    elseif self.Tabs[1] then
        self:Select(self.Tabs[1].Name)
    end
end

function SubTabs:AddTab(tabConfig)
    local key = tabConfig.Key or tabConfig.Name

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, tabConfig.Width or 90, 0, 24)
    button.BackgroundColor3 = self.Theme.Second
    button.BorderSizePixel = 0
    button.Text = tabConfig.Name
    button.TextColor3 = self.Theme.Text
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = self.Bar
    self.Utilities:CreateCorner(button, 5)
    self.Utilities:CreateStroke(button, self.Theme.Border)

    local page = Instance.new("ScrollingFrame")
    page.Name = key .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.Visible = false
    page.Parent = self.Content

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.Parent = page
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
    end)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.Parent = page

    self.Buttons[key] = button
    self.Pages[key] = {
        Config = tabConfig,
        Frame = page,
        Content = page,
    }

    button.MouseButton1Click:Connect(function()
        self:Select(key)
    end)

    if tabConfig.Build then
        tabConfig.Build(self.Pages[key])
    end

    return self.Pages[key]
end

function SubTabs:Select(key)
    for tabKey, page in pairs(self.Pages) do
        local selected = tabKey == key
        page.Frame.Visible = selected
        self.Buttons[tabKey].BackgroundColor3 = selected and self.Theme.Accent or self.Theme.Second
        self.Buttons[tabKey].TextColor3 = selected and Color3.new(1, 1, 1) or self.Theme.Text
    end
    self.ActiveKey = key
end

function SubTabs:GetTab(key)
    return self.Pages[key]
end

return SubTabs
