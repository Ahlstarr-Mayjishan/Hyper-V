--[[
    Hyper-V - Toggle with Keybind Component
    Toggle đi kèm phím tắt để bật/tắt nhanh
]]

local ToggleKeybind = {}

function ToggleKeybind.new(config, theme, utilities)
    local self = setmetatable({}, {__index = ToggleKeybind})
    
    self.Name = config.Name or "ToggleKeybind"
    self.Title = config.Title or "Toggle"
    self.Default = config.Default or false
    self.Keybind = config.Keybind or Enum.KeyCode.F
    self.Callback = config.Callback
    self.Description = config.Description or ""
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    self.Enabled = self.Default
    self.IsListening = false
    
    -- Connections to disconnect
    self.KeyConnection = nil
    self.InputConnections = {}
    
    return self
end

function ToggleKeybind:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, 45)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    self.Container = Container
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -90, 0, 20)
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
        Desc.Size = UDim2.new(1, -90, 0, 14)
        Desc.Position = UDim2.new(0, 10, 0, 24)
        Desc.BackgroundTransparency = 1
        Desc.Text = self.Description
        Desc.TextColor3 = self.Theme.SecondText
        Desc.TextSize = 10
        Desc.Font = Enum.Font.Gotham
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.Parent = Container
    end
    
    -- Toggle Switch
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 36, 0, 20)
    toggleFrame.Position = UDim2.new(1, -80, 0.5, -10)
    toggleFrame.AnchorPoint = Vector2.new(1, 0.5)
    toggleFrame.BackgroundColor3 = self.Theme.Second
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = Container
    self.Utilities:CreateCorner(toggleFrame, 10)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(0, 2, 0.5, 0)
    toggleCircle.AnchorPoint = Vector2.new(0, 0.5)
    toggleCircle.BackgroundColor3 = self.Theme.Text
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleFrame
    self.Utilities:CreateCorner(toggleCircle, 8)
    
    self.ToggleFrame = toggleFrame
    self.ToggleCircle = toggleCircle
    
    -- Keybind Display
    local keybindFrame = Instance.new("TextButton")
    keybindFrame.Size = UDim2.new(0, 60, 0, 20)
    keybindFrame.Position = UDim2.new(1, -40, 0.5, -10)
    keybindFrame.AnchorPoint = Vector2.new(1, 0.5)
    keybindFrame.BackgroundColor3 = self.Theme.Second
    keybindFrame.BorderSizePixel = 0
    keybindFrame.Text = "Key: " .. self:GetKeyName(self.Keybind)
    keybindFrame.TextColor3 = self.Theme.Text
    keybindFrame.TextSize = 10
    keybindFrame.Font = Enum.Font.Gotham
    keybindFrame.AutoButtonColor = false
    keybindFrame.Parent = Container
    self.Utilities:CreateCorner(keybindFrame, 6)
    self.Utilities:CreateStroke(keybindFrame, self.Theme.Border)
    
    self.KeybindFrame = keybindFrame
    
    -- Click handlers
    toggleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Toggle()
        end
    end)
    
    keybindFrame.MouseButton1Click:Connect(function()
        self:StartListening()
    end)
    
    -- Apply initial state
    self:UpdateVisual()
    self:BindKey()
    
    return Container
end

function ToggleKeybind:GetKeyName(key)
    if type(key) == "string" then
        return key
    end
    local keyName = tostring(key)
    keyName = keyName:gsub("Enum%.KeyCode%.", "")
    return keyName
end

function ToggleKeybind:UpdateVisual()
    local targetPos = self.Enabled and UDim2.new(0, 18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    local targetColor = self.Enabled and self.Theme.Accent or self.Theme.Second
    
    self.Utilities:TweenProperty(self.ToggleCircle, "Position", targetPos, 0.15)
    self.Utilities:TweenColor(self.ToggleFrame, targetColor)
end

function ToggleKeybind:Toggle()
    self.Enabled = not self.Enabled
    self:UpdateVisual()
    
    if self.Callback then
        self.Callback(self.Enabled)
    end
end

function ToggleKeybind:StartListening()
    if self.IsListening then return end
    
    self.IsListening = true
    self.KeybindFrame.Text = "Press key..."
    self.KeybindFrame.TextColor3 = self.Theme.Accent
    
    -- Clear old connections
    for _, conn in ipairs(self.InputConnections) do
        conn:Disconnect()
    end
    self.InputConnections = {}
    
    local UserInputService = game:GetService("UserInputService")
    
    table.insert(self.InputConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if self.IsListening and input.UserInputType == Enum.UserInputType.Keyboard then
            self.Keybind = input.KeyCode
            self.KeybindFrame.Text = "Key: " .. self:GetKeyName(self.Keybind)
            self.KeybindFrame.TextColor3 = self.Theme.Text
            self:BindKey()
            self.IsListening = false
        end
    end))
    
    -- Timeout after 5 seconds
    task.delay(5, function()
        if self.IsListening then
            self.IsListening = false
            self.KeybindFrame.Text = "Key: " .. self:GetKeyName(self.Keybind)
            self.KeybindFrame.TextColor3 = self.Theme.Text
        end
    end)
end

function ToggleKeybind:BindKey()
    -- Unbind old key
    if self.KeyConnection then
        self.KeyConnection:Disconnect()
    end
    
    local UserInputService = game:GetService("UserInputService")
    
    self.KeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == self.Keybind then
            self:Toggle()
        end
    end)
end

function ToggleKeybind:SetEnabled(enabled)
    self.Enabled = enabled
    self:UpdateVisual()
end

function ToggleKeybind:GetEnabled()
    return self.Enabled
end

function ToggleKeybind:Destroy()
    if self.KeyConnection then
        self.KeyConnection:Disconnect()
    end
    for _, conn in ipairs(self.InputConnections) do
        conn:Disconnect()
    end
    if self.Container and self.Container.Parent then
        self.Container:Destroy()
    end
end

return ToggleKeybind
