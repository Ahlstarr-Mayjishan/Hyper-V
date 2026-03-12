--[[
    ElementFactory - Tạo UI elements với custom colors
    Hỗ trợ override color từ theme mặc định
]]

local ColorOverride = require(script.Parent.ColorOverride)

local ElementFactory = {}
ElementFactory.__index = ElementFactory

function ElementFactory.new()
    local self = setmetatable({}, ElementFactory)
    self.Theme = nil
    self.Utilities = nil
    return self
end

function ElementFactory:SetTheme(theme)
    self.Theme = theme
end

function ElementFactory:SetUtilities(utilities)
    self.Utilities = utilities
end

-- Tạo theme với custom colors
function ElementFactory:CreateTheme(customColors: ColorOverride.ColorConfig?)
    if not customColors then
        return self.Theme
    end
    return ColorOverride:Merge(self.Theme, customColors)
end

-- Create Button với custom color
function ElementFactory:CreateButton(config)
    local customTheme = self:CreateTheme(config.Colors)
    local theme = customTheme or self.Theme
    
    local Button = Instance.new("TextButton")
    Button.Name = config.Name or "Button"
    Button.Size = config.Size or UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = config.BackgroundColor3 or theme.Second
    Button.Text = config.Text or "Button"
    Button.TextColor3 = config.TextColor3 or theme.Text
    Button.TextSize = config.TextSize or 13
    Button.Font = config.Font or Enum.Font.Gotham
    Button.Parent = config.Parent
    
    self.Utilities:CreateCorner(Button, config.CornerRadius or 5)
    self.Utilities:CreateStroke(Button, config.BorderColor3 or theme.Border)
    
    -- Hover effect với custom color
    if config.HoverColor3 then
        local defaultBg = Button.BackgroundColor3
        Button.MouseEnter:Connect(function()
            Button.BackgroundColor3 = config.HoverColor3
        end)
        Button.MouseLeave:Connect(function()
            Button.BackgroundColor3 = defaultBg
        end)
    end
    
    -- Click effect
    if config.OnClick then
        Button.MouseButton1Click:Connect(config.OnClick)
    end
    
    return Button
end

-- Create Frame với custom color
function ElementFactory:CreateFrame(config)
    local theme = self:CreateTheme(config.Colors) or self.Theme
    
    local Frame = Instance.new("Frame")
    Frame.Name = config.Name or "Frame"
    Frame.Size = config.Size or UDim2.new(1, 0, 0, 100)
    Frame.BackgroundColor3 = config.BackgroundColor3 or theme.Default
    Frame.BorderSizePixel = 0
    Frame.Parent = config.Parent
    
    self.Utilities:CreateCorner(Frame, config.CornerRadius or 8)
    self.Utilities:CreateStroke(Frame, config.BorderColor3 or theme.Border)
    
    if config.Padding then
        self.Utilities:CreatePadding(Frame, 
            config.Padding.Top, 
            config.Padding.Bottom, 
            config.Padding.Left, 
            config.Padding.Right
        )
    end
    
    return Frame
end

-- Create Label với custom color
function ElementFactory:CreateLabel(config)
    local theme = self:CreateTheme(config.Colors) or self.Theme
    
    local Label = Instance.new("TextLabel")
    Label.Name = config.Name or "Label"
    Label.Size = config.Size or UDim2.new(1, 0, 0, 30)
    Label.BackgroundTransparency = config.BackgroundTransparent and 1 or 0
    Label.BackgroundColor3 = config.BackgroundColor3 or Color3.new(0, 0, 0)
    Label.Text = config.Text or "Label"
    Label.TextColor3 = config.TextColor3 or theme.Text
    Label.TextSize = config.TextSize or 14
    Label.Font = config.Font or Enum.Font.Gotham
    Label.Parent = config.Parent
    
    if not config.BackgroundTransparent then
        self.Utilities:CreateCorner(Label, config.CornerRadius or 4)
    end
    
    return Label
end

-- Create Input với custom color
function ElementFactory:CreateInput(config)
    local theme = self:CreateTheme(config.Colors) or self.Theme
    
    local Input = Instance.new("TextBox")
    Input.Name = config.Name or "Input"
    Input.Size = config.Size or UDim2.new(1, 0, 0, 35)
    Input.BackgroundColor3 = config.BackgroundColor3 or theme.Second
    Input.Text = config.Text or ""
    Input.PlaceholderText = config.Placeholder or ""
    Input.TextColor3 = config.TextColor3 or theme.Text
    Input.PlaceholderColor3 = theme.SecondText
    Input.TextSize = config.TextSize or 13
    Input.Font = config.Font or Enum.Font.Gotham
    Input.Parent = config.Parent
    Input.ClearTextOnFocus = config.ClearOnFocus ~= false
    
    self.Utilities:CreateCorner(Input, config.CornerRadius or 5)
    self.Utilities:CreateStroke(Input, config.BorderColor3 or theme.Border)
    
    return Input
end

-- Create Card với custom color
function ElementFactory:CreateCard(config)
    local theme = self:CreateTheme(config.Colors) or self.Theme
    
    local Container = Instance.new("Frame")
    Container.Name = config.Name or "Card"
    Container.Size = config.Size or UDim2.new(1, 0, 0, 80)
    Container.BackgroundColor3 = config.BackgroundColor3 or theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = config.Parent
    
    self.Utilities:CreateCorner(Container, config.CornerRadius or 8)
    self.Utilities:CreateStroke(Container, config.BorderColor3 or theme.Border)
    
    -- Title
    if config.Title then
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -20, 0, 20)
        Title.Position = UDim2.new(0, 10, 0, 5)
        Title.BackgroundTransparency = 1
        Title.Text = config.Title
        Title.TextColor3 = config.TitleColor3 or theme.TitleText
        Title.TextSize = 14
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Container
    end
    
    -- Content
    if config.Content then
        local Content = Instance.new("TextLabel")
        Content.Size = UDim2.new(1, -20, 0, 30)
        Content.Position = UDim2.new(0, 10, 0, 28)
        Content.BackgroundTransparency = 1
        Content.Text = config.Content
        Content.TextColor3 = config.TextColor3 or theme.Text
        Content.TextSize = 12
        Content.TextWrapped = true
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.Parent = Container
    end
    
    -- Hover effect
    if config.Clickable then
        local defaultBg = Container.BackgroundColor3
        Container.MouseEnter:Connect(function()
            Container.BackgroundColor3 = config.HoverColor3 or theme.Second
        end)
        Container.MouseLeave:Connect(function()
            Container.BackgroundColor3 = defaultBg
        end)
    end
    
    return Container
end

-- Create Slider với custom color
function ElementFactory:CreateSlider(config)
    local theme = self:CreateTheme(config.Colors) or self.Theme
    local sliderColor = config.AccentColor3 or theme.Accent
    
    local Slider = Instance.new("Frame")
    Slider.Name = config.Name or "Slider"
    Slider.Size = UDim2.new(1, 0, 0, 45)
    Slider.BackgroundTransparency = 1
    Slider.Parent = config.Parent
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 0, 18)
    Title.BackgroundTransparency = 1
    Title.Text = config.Name or "Slider"
    Title.TextColor3 = config.TextColor3 or theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.Gotham
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Slider
    
    -- Value
    local Value = Instance.new("TextLabel")
    Value.Size = UDim2.new(0, 60, 0, 18)
    Value.Position = UDim2.new(1, 0, 0, 0)
    Value.BackgroundTransparency = 1
    Value.Text = tostring(config.Value or 50)
    Value.TextColor3 = config.ValueColor3 or sliderColor
    Value.TextSize = 13
    Value.Font = Enum.Font.GothamBold
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.Parent = Slider
    
    -- Track
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, 0, 0, 6)
    Track.Position = UDim2.new(0, 0, 0, 20)
    Track.BackgroundColor3 = config.TrackColor3 or theme.Second
    Track.BorderSizePixel = 0
    Track.Parent = Slider
    self.Utilities:CreateCorner(Track, 3)
    
    -- Fill
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0.5, 0, 1, 0)
    Fill.BackgroundColor3 = sliderColor
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    self.Utilities:CreateCorner(Fill, 3)
    
    return Slider, Value, Fill
end

-- Create Toggle với custom color
function ElementFactory:CreateToggle(config)
    local theme = self:CreateTheme(config.Colors) or self.Theme
    local toggleColor = config.AccentColor3 or theme.Accent
    
    local Toggle = Instance.new("Frame")
    Toggle.Name = config.Name or "Toggle"
    Toggle.Size = UDim2.new(1, 0, 0, 40)
    Toggle.BackgroundTransparency = 1
    Toggle.Parent = config.Parent
    
    -- Label
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 0, 20)
    Label.Position = UDim2.new(0, 0, 0, 10)
    Label.BackgroundTransparency = 1
    Label.Text = config.Name or "Toggle"
    Label.TextColor3 = config.TextColor3 or theme.Text
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Toggle
    
    -- Button
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 40, 0, 20)
    Button.Position = UDim2.new(1, 0, 0.5, 0)
    Button.AnchorPoint = Vector2.new(1, 0.5)
    Button.BackgroundColor3 = config.OffColor3 or theme.Second
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.Parent = Toggle
    self.Utilities:CreateCorner(Button, 10)
    
    -- Circle
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = UDim2.new(0, 2, 0.5, 0)
    Circle.AnchorPoint = Vector2.new(0, 0.5)
    Circle.BackgroundColor3 = theme.Text
    Circle.BorderSizePixel = 0
    Circle.Parent = Button
    self.Utilities:CreateCorner(Circle, 8)
    
    -- State
    local enabled = config.Value or false
    local function updateState()
        if enabled then
            Button.BackgroundColor3 = config.OnColor3 or toggleColor
            Circle.Position = UDim2.new(1, -2, 0.5, 0)
            Circle.AnchorPoint = Vector2.new(1, 0.5)
        else
            Button.BackgroundColor3 = config.OffColor3 or theme.Second
            Circle.Position = UDim2.new(0, 2, 0.5, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
        end
    end
    
    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateState()
        if config.OnChange then
            config.OnChange(enabled)
        end
    end)
    
    updateState()
    
    return Toggle, function() return enabled end
end

-- Create ProgressBar với custom color
function ElementFactory:CreateProgressBar(config)
    local theme = self:CreateTheme(config.Colors) or self.Theme
    local barColor = config.AccentColor3 or theme.Accent
    
    local Container = Instance.new("Frame")
    Container.Name = config.Name or "ProgressBar"
    Container.Size = config.Size or UDim2.new(1, 0, 0, 20)
    Container.BackgroundColor3 = config.BackgroundColor3 or theme.Second
    Container.BorderSizePixel = 0
    Container.Parent = config.Parent
    
    self.Utilities:CreateCorner(Container, config.CornerRadius or 4)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(config.Progress or 0.5, 0, 1, 0)
    Fill.BackgroundColor3 = barColor
    Fill.BorderSizePixel = 0
    Fill.Parent = Container
    self.Utilities:CreateCorner(Fill, config.CornerRadius or 4)
    
    -- Text percentage
    if config.ShowPercentage then
        local Percentage = Instance.new("TextLabel")
        Percentage.Size = UDim2.new(1, 0, 1, 0)
        Percentage.BackgroundTransparency = 1
        Percentage.Text = string.format("%d%%", (config.Progress or 0.5) * 100)
        Percentage.TextColor3 = config.TextColor3 or ColorOverride:ContrastColor(barColor)
        Percentage.TextSize = 11
        Percentage.Font = Enum.Font.GothamBold
        Percentage.Parent = Fill
    end
    
    return Container, Fill
end

return ElementFactory

