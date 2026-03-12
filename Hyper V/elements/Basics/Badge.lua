--[[
    Hyper-V - Badge Component
    Badge thông báo
]]

local Badge = {}

function Badge.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Badge})
    
    self.Name = config.Name or "Badge"
    self.Text = config.Text or "1"
    self.Color = config.Color or theme.Accent
    self.Size = config.Size or UDim2.new(0, 20, 0, 20)
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Badge:Create()
    local BadgeFrame = Instance.new("Frame")
    BadgeFrame.Name = self.Name
    BadgeFrame.Size = self.Size
    BadgeFrame.BackgroundColor3 = self.Color
    BadgeFrame.BorderSizePixel = 0
    BadgeFrame.Parent = self.Parent
    self.Utilities:CreateCorner(BadgeFrame, self.Size.X.Offset / 2)
    
    -- Text
    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, 0, 1, 0)
    Text.BackgroundTransparency = 1
    Text.Text = tostring(self.Text)
    Text.TextColor3 = Color3.new(1, 1, 1)
    Text.TextSize = 10
    Text.Font = Enum.Font.GothamBold
    Text.TextAlignment = Enum.TextXAlignment.Center
    Text.TextYAlignment = Enum.TextYAlignment.Center
    Text.Parent = BadgeFrame
    
    -- Small shadow/glow effect
    local Glow = Instance.new("Frame")
    Glow.Size = UDim2.new(1.3, 0, 1.3, 0)
    Glow.Position = UDim2.new(-0.15, 0, -0.15, 0)
    Glow.BackgroundColor3 = self.Color
    Glow.BackgroundTransparency = 0.7
    Glow.BorderSizePixel = 0
    Glow.ZIndex = -1
    Glow.Parent = BadgeFrame
    self.Utilities:CreateCorner(Glow, self.Size.X.Offset / 2 + 2)
    
    self.BadgeFrame = BadgeFrame
    self.TextLabel = Text
    
    return BadgeFrame
end

function Badge:SetText(text)
    self.Text = text
    if self.TextLabel then
        self.TextLabel.Text = tostring(text)
    end
    
    -- Auto-hide if text is empty or 0
    if self.BadgeFrame then
        self.BadgeFrame.Visible = text ~= "" and text ~= "0"
    end
end

function Badge:SetColor(color3)
    self.Color = color3
    if self.BadgeFrame then
        self.BadgeFrame.BackgroundColor3 = color3
    end
end

function Badge:Show()
    if self.BadgeFrame then
        self.BadgeFrame.Visible = true
    end
end

function Badge:Hide()
    if self.BadgeFrame then
        self.BadgeFrame.Visible = false
    end
end

function Badge:Increment()
    local current = tonumber(self.Text) or 0
    self:SetText(current + 1)
end

function Badge:Decrement()
    local current = tonumber(self.Text) or 0
    self:SetText(math.max(0, current - 1))
end

return Badge
