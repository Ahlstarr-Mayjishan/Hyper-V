--[[
    Hyper-V - Hold Toggle / Hold-to-Activate Component
    Chỉ bật khi giữ phím, tắt khi thả
]]

local HoldToggle = {}
HoldToggle.__index = HoldToggle

function HoldToggle.new(config, theme, utilities)
    local self = setmetatable({}, HoldToggle)
    
    self.Name = config.Name or "HoldToggle"
    self.Title = config.Title or "Hold to Activate"
    self.HoldKey = config.HoldKey or Enum.KeyCode.E
    self.Callback = config.Callback
    self.Description = config.Description or ""
    self.ShowIndicator = config.ShowIndicator ~= false
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    self.IsHeld = false
    self.Connections = {}
    
    return self
end

function HoldToggle:Create()
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
    Title.Size = UDim2.new(1, -120, 0, 20)
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
        Desc.Size = UDim2.new(1, -120, 0, 14)
        Desc.Position = UDim2.new(0, 10, 0, 24)
        Desc.BackgroundTransparency = 1
        Desc.Text = self.Description
        Desc.TextColor3 = self.Theme.SecondText
        Desc.TextSize = 10
        Desc.Font = Enum.Font.Gotham
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.Parent = Container
    end
    
    -- Status indicator (circle)
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0, 36, 0, 20)
    statusFrame.Position = UDim2.new(1, -80, 0.5, -10)
    statusFrame.AnchorPoint = Vector2.new(1, 0.5)
    statusFrame.BackgroundColor3 = self.Theme.Second
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = Container
    self.Utilities:CreateCorner(statusFrame, 10)
    self.StatusFrame = statusFrame
    
    -- Status circle
    local statusCircle = Instance.new("Frame")
    statusCircle.Size = UDim2.new(0, 14, 0, 14)
    statusCircle.Position = UDim2.new(0, 3, 0.5, 0)
    statusCircle.AnchorPoint = Vector2.new(0, 0.5)
    statusCircle.BackgroundColor3 = self.Theme.Text
    statusCircle.BorderSizePixel = 0
    statusCircle.Parent = statusFrame
    self.Utilities:CreateCorner(statusCircle, 7)
    self.StatusCircle = statusCircle
    
    -- Hold key indicator
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0, 45, 0, 20)
    keyLabel.Position = UDim2.new(1, -40, 0.5, -10)
    keyLabel.AnchorPoint = Vector2.new(1, 0.5)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "Hold " .. self:GetKeyName(self.HoldKey)
    keyLabel.TextColor3 = self.Theme.SecondText
    keyLabel.TextSize = 10
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextXAlignment = Enum.TextXAlignment.Right
    keyLabel.Parent = Container
    self.KeyLabel = keyLabel
    
    -- Setup key listeners
    self:SetupListeners()
    
    return Container
end

function HoldToggle:GetKeyName(key)
    if type(key) == "string" then
        return key
    end
    local keyName = tostring(key)
    keyName = keyName:gsub("Enum%.KeyCode%.", "")
    
    local shortcuts = {
        LeftControl = "LCtrl",
        RightControl = "RCtrl",
        LeftShift = "LShift",
        RightShift = "RShift",
        LeftAlt = "LAlt",
        RightAlt = "RAlt",
        LeftBracket = "[",
        RightBracket = "]",
        Return = "Enter",
        Space = "Space"
    }
    
    return shortcuts[keyName] or keyName
end

function HoldToggle:SetupListeners()
    local UserInputService = game:GetService("UserInputService")
    
    -- Key pressed - activate
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == self.HoldKey and input.UserInputType == Enum.UserInputType.Keyboard then
            self:Activate()
        end
    end))
    
    -- Key released - deactivate
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == self.HoldKey and input.UserInputType == Enum.UserInputType.Keyboard then
            self:Deactivate()
        end
    end))
    
    -- If focus lost, deactivate
    table.insert(self.Connections, UserInputService.WindowFocusReleased:Connect(function()
        self:Deactivate()
    end))
end

function HoldToggle:Activate()
    if self.IsHeld then return end
    
    self.IsHeld = true
    self:UpdateVisual(true)
    
    if self.Callback then
        self.Callback(true)
    end
end

function HoldToggle:Deactivate()
    if not self.IsHeld then return end
    
    self.IsHeld = false
    self:UpdateVisual(false)
    
    if self.Callback then
        self.Callback(false)
    end
end

function HoldToggle:UpdateVisual(isActive)
    local targetColor = isActive and self.Theme.Accent or self.Theme.Second
    local circlePos = isActive and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    
    self.Utilities:TweenColor(self.StatusFrame, targetColor)
    self.Utilities:TweenProperty(self.StatusCircle, "Position", circlePos, 0.1)
    
    -- Pulse animation when active
    if isActive then
        local pulse = Instance.new("Frame")
        pulse.Size = UDim2.new(1.5, 0, 1.5, 0)
        pulse.Position = UDim2.new(-0.25, 0, -0.25, 0)
        pulse.BackgroundColor3 = self.Theme.Accent
        pulse.BackgroundTransparency = 0.5
        pulse.BorderSizePixel = 0
        pulse.Parent = self.StatusFrame
        self.Utilities:CreateCorner(pulse, 15)
        
        self.Utilities:TweenProperty(pulse, "Size", UDim2.new(2, 0, 2, 0), 0.6)
        self.Utilities:TweenProperty(pulse, "BackgroundTransparency", 1, 0.6, 0, function()
            pulse:Destroy()
        end)
    end
end

function HoldToggle:SetKey(key)
    self.HoldKey = key
    self.KeyLabel.Text = "Hold " .. self:GetKeyName(key)
    
    -- Re-setup listeners
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}
    self:SetupListeners()
end

function HoldToggle:GetState()
    return self.IsHeld
end

function HoldToggle:Destroy()
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    
    if self.Container and self.Container.Parent then
        self.Container:Destroy()
    end
end

return HoldToggle
