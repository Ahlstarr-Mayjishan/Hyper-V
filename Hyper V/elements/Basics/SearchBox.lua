--[[
    Hyper-V - SearchBox Component
    Ô tìm kiếm
]]

local SearchBox = {}

function SearchBox.new(config, theme, utilities)
    local self = setmetatable({}, {__index = SearchBox})
    
    self.Name = config.Name or "SearchBox"
    self.Placeholder = config.Placeholder or "Search..."
    self.OnChange = config.OnChange
    self.OnSearch = config.OnSearch
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function SearchBox:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, 35)
    Container.BackgroundColor3 = self.Theme.Second
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 5)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Search Icon
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 25, 0, 25)
    Icon.Position = UDim2.new(0, 5, 0.5, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🔍"
    Icon.TextSize = 14
    Icon.Parent = Container
    
    -- Search Input
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -40, 1, 0)
    Input.Position = UDim2.new(0, 35, 0, 0)
    Input.BackgroundTransparency = 1
    Input.Text = ""
    Input.PlaceholderText = self.Placeholder
    Input.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
    Input.TextColor3 = self.Theme.Text
    Input.TextSize = 13
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    Input.Parent = Container
    
    -- Clear Button (x)
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0, 20, 0, 20)
    ClearBtn.Position = UDim2.new(1, -25, 0.5, 0)
    ClearBtn.AnchorPoint = Vector2.new(1, 0.5)
    ClearBtn.BackgroundTransparency = 1
    ClearBtn.Text = "✕"
    ClearBtn.TextColor3 = self.Theme.Text
    ClearBtn.TextSize = 12
    ClearBtn.Visible = false
    ClearBtn.Parent = Container
    
    -- Events
    local function onTextChange()
        local text = Input.Text
        ClearBtn.Visible = #text > 0
        
        if self.OnChange then
            self.OnChange(text)
        end
    end
    
    Input:GetPropertyChangedSignal("Text"):Connect(onTextChange)
    
    Input.Focused:Connect(function()
        self.Utilities:TweenColor(Container, self.Theme.Accent)
    end)
    
    Input.FocusLost:Connect(function()
        self.Utilities:TweenColor(Container, self.Theme.Border)
    end)
    
    ClearBtn.MouseButton1Click:Connect(function()
        Input.Text = ""
        ClearBtn.Visible = false
        Input:CaptureFocus()
    end)
    
    -- Search on Enter
    Input.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Return then
            if self.OnSearch then
                self.OnSearch(Input.Text)
            end
        end
    end)
    
    return Container
end

return SearchBox
