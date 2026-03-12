--[[
    Hyper-V - Toggle Group / Radio Group Component
    Chỉ chọn một trong nhiều lựa chọn độc quyền
]]

local ToggleGroup = {}
ToggleGroup.__index = ToggleGroup

function ToggleGroup.new(config, theme, utilities)
    local self = setmetatable({}, ToggleGroup)
    
    self.Name = config.Name or "ToggleGroup"
    self.Title = config.Title or "Select Option"
    self.Options = config.Options or {"Option 1", "Option 2", "Option 3"}
    self.SelectedIndex = config.Default or 1
    self.Callback = config.Callback
    self.Description = config.Description or ""
    self.Style = config.Style or "toggle"  -- "toggle" or "button"
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    self.OptionButtons = {}
    self.OptionStates = {}
    
    return self
end

function ToggleGroup:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, 45 + (#self.Options * 30))
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    self.Container = Container
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 20)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = self.Title
    Title.TextColor3 = self.Theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    -- Description
    local hasDesc = self.Description and self.Description ~= ""
    if hasDesc then
        local Desc = Instance.new("TextLabel")
        Desc.Size = UDim2.new(1, -20, 0, 14)
        Desc.Position = UDim2.new(0, 10, 0, 24)
        Desc.BackgroundTransparency = 1
        Desc.Text = self.Description
        Desc.TextColor3 = self.Theme.SecondText
        Desc.TextSize = 10
        Desc.Font = Enum.Font.Gotham
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.Parent = Container
    end
    
    -- Options container
    local optionsStartY = hasDesc and 40 or 30
    
    for i, option in ipairs(self.Options) do
        local isSelected = i == self.SelectedIndex
        local button = self:CreateOptionButton(option, i, isSelected, optionsStartY + (i - 1) * 30)
        table.insert(self.OptionButtons, button)
        self.OptionStates[i] = isSelected
    end
    
    return Container
end

function ToggleGroup:CreateOptionButton(label, index, isSelected, yPos)
    local button
    
    if self.Style == "button" then
        -- Button style
        button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 0, 0, 26)
        button.AutomaticSize = Enum.AutomaticSize.X
        button.Padding = UDim.new(0, 12)
        button.BackgroundColor3 = isSelected and self.Theme.Accent or self.Theme.Second
        button.BorderSizePixel = 0
        button.Text = label
        button.TextColor3 = isSelected and Color3.new(1, 1, 1) or self.Theme.Text
        button.TextSize = 11
        button.Font = Enum.Font.Gotham
        button.AutoButtonColor = false
    else
        -- Toggle style
        button = Instance.new("Frame")
        button.Size = UDim2.new(1, -20, 0, 26)
        button.Position = UDim2.new(0, 10, 0, yPos)
        button.BackgroundColor3 = self.Theme.Second
        button.BorderSizePixel = 0
        self.Utilities:CreateCorner(button, 6)
        
        -- Toggle circle
        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, 16, 0, 16)
        circle.Position = UDim2.new(0, 4, 0.5, 0)
        circle.AnchorPoint = Vector2.new(0, 0.5)
        circle.BackgroundColor3 = isSelected and self.Theme.Accent or self.Theme.Second
        circle.BorderSizePixel = 0
        circle.Parent = button
        self.Utilities:CreateCorner(circle, 8)
        
        -- Inner circle when selected
        if isSelected then
            local inner = Instance.new("Frame")
            inner.Size = UDim2.new(0, 8, 0, 8)
            inner.Position = UDim2.new(0.5, -4, 0.5, 0)
            inner.AnchorPoint = Vector2.new(0.5, 0.5)
            inner.BackgroundColor3 = Color3.new(1, 1, 1)
            inner.BorderSizePixel = 0
            inner.Parent = circle
            self.Utilities:CreateCorner(inner, 4)
        end
        
        -- Label
        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(1, -35, 1, 0)
        labelText.Position = UDim2.new(0, 28, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = self.Theme.Text
        labelText.TextSize = 12
        labelText.Font = Enum.Font.Gotham
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = button
        
        -- Clickable overlay
        local clickOverlay = Instance.new("TextButton")
        clickOverlay.Size = UDim2.new(1, 0, 1, 0)
        clickOverlay.BackgroundTransparency = 1
        clickOverlay.Text = ""
        clickOverlay.Parent = button
        
        button.Circle = circle
        button.ClickOverlay = clickOverlay
    end
    
    button.Parent = self.Container
    
    -- Hover and click effects
    local function applyHover()
        local bg = self.Style == "button" and button or button
        self.Utilities:TweenColor(bg, isSelected and self.Theme.Accent:Lerp(Color3.new(1,1,1), 0.1) or self.Theme.Second:Lerp(Color3.new(1,1,1), 0.1))
    end
    
    local function applyNormal()
        local bg = self.Style == "button" and button or button
        self.Utilities:TweenColor(bg, isSelected and self.Theme.Accent or self.Theme.Second)
    end
    
    local clickTarget = self.Style == "button" and button or button.ClickOverlay
    
    clickTarget.MouseEnter:Connect(applyHover)
    clickTarget.MouseLeave:Connect(applyNormal)
    
    clickTarget.MouseButton1Click:Connect(function()
        self:Select(index)
    end)
    
    return button
end

function ToggleGroup:Select(index)
    if self.SelectedIndex == index then return end
    
    -- Deselect old
    local oldIndex = self.SelectedIndex
    self.SelectedIndex = index
    self.OptionStates[oldIndex] = false
    self.OptionStates[index] = true
    
    -- Update visuals
    self:UpdateOptionVisual(oldIndex, false)
    self:UpdateOptionVisual(index, true)
    
    if self.Callback then
        self.Callback(index, self.Options[index])
    end
end

function ToggleGroup:UpdateOptionVisual(index, isSelected)
    local button = self.OptionButtons[index]
    if not button then return end
    
    if self.Style == "button" then
        self.Utilities:TweenColor(button, isSelected and self.Theme.Accent or self.Theme.Second)
        button.TextColor3 = isSelected and Color3.new(1, 1, 1) or self.Theme.Text
    else
        self.Utilities:TweenColor(button, isSelected and self.Theme.Accent or self.Theme.Second)
        if button.Circle then
            self.Utilities:TweenColor(button.Circle, isSelected and self.Theme.Accent or self.Theme.Second)
            
            -- Add or remove inner circle
            if isSelected and not button.Circle.Inner then
                local inner = Instance.new("Frame")
                inner.Size = UDim2.new(0, 8, 0, 8)
                inner.Position = UDim2.new(0.5, -4, 0.5, 0)
                inner.AnchorPoint = Vector2.new(0.5, 0.5)
                inner.BackgroundColor3 = Color3.new(1, 1, 1)
                inner.BorderSizePixel = 0
                inner.Name = "Inner"
                inner.Parent = button.Circle
                self.Utilities:CreateCorner(inner, 4)
                button.Circle.Inner = inner
            elseif not isSelected and button.Circle.Inner then
                button.Circle.Inner:Destroy()
                button.Circle.Inner = nil
            end
        end
    end
end

function ToggleGroup:GetSelected()
    return self.SelectedIndex, self.Options[self.SelectedIndex]
end

function ToggleGroup:SetSelected(index)
    self:Select(index)
end

return ToggleGroup
