--[[
    Hyper-V - Modal / Dialog Component
    Popup confirm, form, alert với animation
]]

local Modal = {}

local activeModals = {}

function Modal.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Modal})
    
    self.Name = config.Name or "Modal"
    self.Title = config.Title or "Modal"
    self.Content = config.Content or ""
    self.Type = config.Type or "Confirm"  -- "Confirm", "Alert", "Form", "Custom"
    self.Buttons = config.Buttons or {
        {Label = "OK", Style = "Primary"},
        {Label = "Cancel", Style = "Secondary"}
    }
    self.OnClose = config.OnClose
    self.CloseOnOverlay = config.CloseOnOverlay ~= false
    self.CloseOnESC = config.CloseOnESC ~= false
    self.AnimationSpeed = config.AnimationSpeed or 0.25
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Modal:Create()
    -- Create overlay first (behind everything)
    local Overlay = Instance.new("Frame")
    Overlay.Name = "ModalOverlay"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.Position = UDim2.new(0, 0, 0, 0)
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.BackgroundTransparency = 0
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 1000
    Overlay.Parent = self.Parent
    self.Utilities:CreateCorner(Overlay, 0)
    
    if self.Parent:IsA("GuiBase2d") then
        Overlay.Size = UDim2.new(0, self.Parent.AbsoluteSize.X, 0, self.Parent.AbsoluteSize.Y)
    end
    
    -- Animate overlay fade in
    Overlay.BackgroundTransparency = 1
    self.Utilities:TweenProperty(Overlay, "BackgroundTransparency", 0.5, self.AnimationSpeed, 0)
    
    -- Main modal frame
    local width = 350
    local height = self:CalculateHeight()
    
    local ModalFrame = Instance.new("Frame")
    ModalFrame.Name = self.Name
    ModalFrame.Size = UDim2.new(0, width, 0, 0)  -- Start at 0 for animation
    ModalFrame.Position = UDim2.new(0.5, -width/2, 0.5, 0)
    ModalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ModalFrame.BackgroundColor3 = self.Theme.Default
    ModalFrame.BorderSizePixel = 0
    ModalFrame.ZIndex = 1001
    ModalFrame.Parent = Overlay
    self.Utilities:CreateCorner(ModalFrame, 12)
    self.Utilities:CreateStroke(ModalFrame, self.Theme.Border)
    
    self.ModalFrame = ModalFrame
    self.Overlay = Overlay
    
    -- Content container
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -30, 1, -30)
    contentFrame.Position = UDim2.new(0, 15, 0, 15)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = ModalFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = self.Theme.TitleText
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 1002
    titleLabel.Parent = contentFrame
    
    -- Icon based on type
    local iconText = "ℹ️"
    if self.Type == "Confirm" then iconText = "❓"
    elseif self.Type == "Alert" then iconText = "⚠️"
    elseif self.Type == "Form" then iconText = "📝"
    end
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(1, -30, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = iconText
    icon.TextSize = 16
    icon.ZIndex = 1002
    icon.Parent = contentFrame
    
    -- Content
    local contentText = Instance.new("TextLabel")
    contentText.Size = UDim2.new(1, 0, 0, 40)
    contentText.Position = UDim2.new(0, 0, 0, 30)
    contentText.BackgroundTransparency = 1
    contentText.Text = self.Content
    contentText.TextColor3 = self.Theme.Text
    contentText.TextSize = 13
    contentText.Font = Enum.Font.Gotham
    contentText.TextWrapped = true
    contentText.ZIndex = 1002
    contentText.Parent = contentFrame
    
    -- Buttons
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Size = UDim2.new(1, 0, 0, 35)
    buttonsFrame.Position = UDim2.new(0, 0, 1, -40)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.ZIndex = 1002
    buttonsFrame.Parent = contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 8)
    layout.Parent = buttonsFrame
    
    local buttonStartX = 0
    for i, btn in ipairs(self.Buttons) do
        local button = self:CreateButton(btn, i)
        button.Parent = buttonsFrame
    end
    
    -- Animate modal scale in
    task.wait(0.02)
    self.Utilities:TweenProperty(ModalFrame, "Size", UDim2.new(0, width, 0, height), self.AnimationSpeed, 0, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Setup close handlers
    if self.CloseOnOverlay then
        Overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:Close()
            end
        end)
    end
    
    if self.CloseOnESC then
        local UserInputService = game:GetService("UserInputService")
        self.ESCConnection = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Escape then
                self:Close()
            end
        end)
    end
    
    -- Track active modal
    table.insert(activeModals, self)
    
    return Overlay
end

function Modal:CalculateHeight()
    local height = 100  -- Base
    
    if self.Content and #self.Content > 50 then
        height = height + 20
    end
    
    height = height + 45  -- Buttons area
    
    return height
end

function Modal:CreateButton(btnConfig, index)
    local isPrimary = btnConfig.Style == "Primary"
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 32)
    btn.BackgroundColor3 = isPrimary and self.Theme.Accent or self.Theme.Second
    btn.BorderSizePixel = 0
    btn.Text = btnConfig.Label
    btn.TextColor3 = isPrimary and Color3.new(1, 1, 1) or self.Theme.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.ZIndex = 1002
    self.Utilities:CreateCorner(btn, 6)
    self.Utilities:CreateStroke(btn, self.Theme.Border)
    
    btn.MouseEnter:Connect(function()
        self.Utilities:TweenColor(btn, isPrimary and self.Theme.Accent:Lerp(Color3.new(1,1,1), 0.15) or self.Theme.Second:Lerp(Color3.new(1,1,1), 0.15))
    end)
    
    btn.MouseLeave:Connect(function()
        self.Utilities:TweenColor(btn, isPrimary and self.Theme.Accent or self.Theme.Second)
    end)
    
    btn.MouseButton1Click:Connect(function()
        if btnConfig.Callback then
            btnConfig.Callback()
        end
        self:Close()
    end)
    
    return btn
end

function Modal:Close()
    -- Remove from active modals
    for i, m in ipairs(activeModals) do
        if m == self then
            table.remove(activeModals, i)
            break
        end
    end
    
    -- Disconnect ESC
    if self.ESCConnection then
        self.ESCConnection:Disconnect()
    end
    
    -- Animate out
    self.Utilities:TweenProperty(self.ModalFrame, "Size", UDim2.new(0, self.ModalFrame.Size.X.Offset, 0, 0), self.AnimationSpeed, 0, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
        self.Utilities:TweenProperty(self.Overlay, "BackgroundTransparency", 1, self.AnimationSpeed * 0.5, 0, function()
            self.Overlay:Destroy()
        end)
    end)
    
    if self.OnClose then
        self.OnClose()
    end
end

-- Static method to create and show modal directly
function Modal.Show(config, theme, utilities)
    local modal = Modal.new(config, theme, utilities)
    modal:Create()
    return modal
end

-- Static method to close all modals
function Modal.CloseAll()
    for _, modal in ipairs(activeModals) do
        modal:Close()
    end
    activeModals = {}
end

return Modal
