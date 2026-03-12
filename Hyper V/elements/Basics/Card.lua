--[[
    Hyper-V - Card Component
    Thẻ thông tin
]]

local Card = {}

function Card.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Card})
    
    self.Name = config.Name or "Card"
    self.Title = config.Title or ""
    self.Content = config.Content or ""
    self.Height = config.Height or 100
    self.Icon = config.Icon or ""
    self.Clickable = config.Clickable or false
    self.OnClick = config.OnClick
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Card:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, self.Height)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Hover effect for clickable
    if self.Clickable then
        Container.MouseEnter:Connect(function()
            self.Utilities:TweenColor(Container, self.Theme.Second)
        end)
        
        Container.MouseLeave:Connect(function()
            self.Utilities:TweenColor(Container, self.Theme.Default)
        end)
        
        local ClickDetector = Instance.new("ClickDetector")
        ClickDetector.Parent = Container
        
        ClickDetector.MouseClick:Connect(function()
            if self.OnClick then
                self.OnClick()
            end
        end)
    end
    
    -- Icon (optional)
    if self.Icon ~= "" then
        local Icon = Instance.new("TextLabel")
        Icon.Size = UDim2.new(0, 40, 0, 40)
        Icon.Position = UDim2.new(0, 10, 0.5, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Text = self.Icon
        Icon.TextSize = 24
        Icon.Parent = Container
        self.IconLabel = Icon
    end
    
    -- Title
    if self.Title ~= "" then
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -60, 0, 20)
        Title.Position = UDim2.new(0, self.Icon ~= "" and 55 or 10, 0, 10)
        Title.BackgroundTransparency = 1
        Title.Text = self.Title
        Title.TextColor3 = self.Theme.TitleText
        Title.TextSize = 14
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.TextTruncate = Enum.TextTruncate.AtEnd
        Title.Parent = Container
    end
    
    -- Content
    if self.Content ~= "" then
        local Content = Instance.new("TextLabel")
        Content.Size = UDim2.new(1, -60, 0, 40)
        Content.Position = UDim2.new(0, self.Icon ~= "" and 55 or 10, 0, 30)
        Content.BackgroundTransparency = 1
        Content.Text = self.Content
        Content.TextColor3 = self.Theme.Text
        Content.TextSize = 12
        Content.Font = Enum.Font.Gotham
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextWrapped = true
        Content.TextTruncate = Enum.TextTruncate.AtEnd
        Content.Parent = Container
    end
    
    -- Divider (optional)
    if self.ShowDivider ~= false and self.Title ~= "" and self.Content ~= "" then
        local Divider = Instance.new("Frame")
        Divider.Size = UDim2.new(1, -20, 0, 1)
        Divider.Position = UDim2.new(0, 10, 0, 27)
        Divider.BackgroundColor3 = self.Theme.Border
        Divider.BorderSizePixel = 0
        Divider.Parent = Container
    end
    
    return Container
end

function Card:SetTitle(title)
    self.Title = title
    -- Find and update title label
    local Container = self.Parent:FindFirstChild(self.Name)
    if Container then
        local Title = Container:FindFirstChildWhichIsA("TextLabel")
        if Title then
            Title.Text = title
        end
    end
end

function Card:SetContent(content)
    self.Content = content
    -- Find and update content label
    local Container = self.Parent:FindFirstChild(self.Name)
    if Container then
        local contentLabels = Container:GetChildren()
        for _, v in ipairs(contentLabels) do
            if v:IsA("TextLabel") and v.Position.Y.Offset > 25 then
                v.Text = content
                break
            end
        end
    end
end

function Card:SetIcon(icon)
    self.Icon = icon
    local Container = self.Parent:FindFirstChild(self.Name)
    if Container and self.IconLabel then
        self.IconLabel.Text = icon
    end
end

return Card
