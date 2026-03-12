--[[
    Hyper-V - Mini Dashboard Component
    Khung tổng quan với nhiều card thu nhỏ
]]

local MiniDashboard = {}

function MiniDashboard.new(config, theme, utilities)
    local self = setmetatable({}, {__index = MiniDashboard})
    
    self.Name = config.Name or "MiniDashboard"
    self.Title = config.Title or "Dashboard"
    self.Cards = config.Cards or {}  -- { {icon, label, value, color}, ... }
    self.Columns = config.Columns or 2
    self.AutoRefresh = config.AutoRefresh or false
    self.RefreshInterval = config.RefreshInterval or 5
    self.OnRefresh = config.OnRefresh
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function MiniDashboard:Create()
    local cardCount = #self.Cards
    local rows = math.ceil(cardCount / self.Columns)
    local cardWidth = 140
    local cardHeight = 70
    local spacing = 8
    local containerWidth = self.Columns * cardWidth + (self.Columns + 1) * spacing
    local containerHeight = rows * cardHeight + (rows + 1) * spacing + 30
    
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, containerWidth, 0, containerHeight)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = self.Title
    Title.TextColor3 = self.Theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    -- Create cards
    for i, cardData in ipairs(self.Cards) do
        local col = (i - 1) % self.Columns
        local row = math.floor((i - 1) / self.Columns)
        
        local card = self:CreateCard(cardData, col, row, cardWidth, cardHeight, spacing)
        card.Parent = Container
    end
    
    -- Auto refresh
    if self.AutoRefresh then
        self:StartAutoRefresh()
    end
    
    self.Container = Container
    return Container
end

function MiniDashboard:CreateCard(data, col, row, cardWidth, cardHeight, spacing)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, cardWidth, 0, cardHeight)
    card.Position = UDim2.new(0, spacing + col * (cardWidth + spacing), 0, 30 + spacing + row * (cardHeight + spacing))
    card.BackgroundColor3 = self.Theme.Second
    card.BorderSizePixel = 0
    card.Parent = self.Container
    self.Utilities:CreateCorner(card, 6)
    self.Utilities:CreateStroke(card, self.Theme.Border)
    
    local color = data.color or self.Theme.Accent
    
    -- Icon background
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 32, 0, 32)
    iconBg.Position = UDim2.new(0, 8, 0.5, 0)
    iconBg.AnchorPoint = Vector2.new(0, 0.5)
    iconBg.BackgroundColor3 = color
    iconBg.BorderSizePixel = 0
    iconBg.Parent = card
    self.Utilities:CreateCorner(iconBg, 6)
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = data.icon or "📊"
    icon.TextSize = 16
    icon.Parent = iconBg
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 0, 14)
    label.Position = UDim2.new(0, 44, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = data.label or "Label"
    label.TextColor3 = self.Theme.SecondText
    label.TextSize = 10
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = card
    
    -- Value
    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(1, -50, 0, 20)
    value.Position = UDim2.new(0, 44, 0, 22)
    value.BackgroundTransparency = 1
    value.Text = tostring(data.value or 0)
    value.TextColor3 = self.Theme.TitleText
    value.TextSize = 14
    value.Font = Enum.Font.GothamBold
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.TextTruncate = Enum.TextTruncate.AtEnd
    value.Parent = card
    self[data.key or "card" .. #self.Cards] = {
        Label = label,
        Value = value,
        IconBg = iconBg,
        Color = color
    }
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        self.Utilities:TweenColor(card, color:Lerp(self.Theme.Second, 0.7))
    end)
    
    card.MouseLeave:Connect(function()
        self.Utilities:TweenColor(card, self.Theme.Second)
    end)
    
    return card
end

function MiniDashboard:UpdateValue(key, newValue)
    for k, v in pairs(self) do
        if type(v) == "table" and v.Value then
            local cardData = nil
            for _, cd in ipairs(self.Cards) do
                if cd.key == key then
                    cardData = cd
                    break
                end
            end
            if cardData and v.Value then
                v.Value.Text = tostring(newValue)
            end
        end
    end
end

function MiniDashboard:StartAutoRefresh()
    if self.RefreshTask then
        self.RefreshTask:Disconnect()
    end
    
    self.RefreshTask = task.delay(self.RefreshInterval, function()
        if self.OnRefresh then
            self.OnRefresh(self)
        end
        self:StartAutoRefresh()  -- Continue refreshing
    end)
end

function MiniDashboard:StopAutoRefresh()
    if self.RefreshTask then
        task.cancel(self.RefreshTask)
        self.RefreshTask = nil
    end
end

-- Predefined dashboard cards for gaming stats
function MiniDashboard.newGamingStats(config, theme, utilities)
    local self = setmetatable({}, {__index = MiniDashboard})
    
    self.Name = config.Name or "GamingStats"
    self.Title = config.Title or "Stats Overview"
    self.XPPerMinute = config.XPPerMinute or 0
    self.GoldPerMinute = config.GoldPerMinute or 0
    self.ActiveQuests = config.ActiveQuests or 0
    self.QuestProgress = config.QuestProgress or 0
    self.Columns = config.Columns or 2
    self.AutoRefresh = config.AutoRefresh or false
    self.RefreshInterval = config.RefreshInterval or 5
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    -- Build cards array
    self.Cards = {
        {key = "xp", icon = "⭐", label = "XP/min", value = self.XPPerMinute, color = Color3.fromRGB(245, 158, 11)},
        {key = "gold", icon = "💰", label = "Gold/min", value = self.GoldPerMinute, color = Color3.fromRGB(234, 179, 8)},
        {key = "quests", icon = "📜", label = "Active Quests", value = self.ActiveQuests, color = Color3.fromRGB(139, 92, 246)},
        {key = "progress", icon = "🎯", label = "Quest Progress", value = self.QuestProgress .. "%", color = Color3.fromRGB(59, 130, 246)},
    }
    
    return self
end

function MiniDashboard.newGamingStats:Create()
    local cardCount = #self.Cards
    local rows = math.ceil(cardCount / self.Columns)
    local cardWidth = 140
    local cardHeight = 70
    local spacing = 8
    local containerWidth = self.Columns * cardWidth + (self.Columns + 1) * spacing
    local containerHeight = rows * cardHeight + (rows + 1) * spacing + 30
    
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, containerWidth, 0, containerHeight)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = self.Title
    Title.TextColor3 = self.Theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    self.Container = Container
    
    -- Create cards
    for i, cardData in ipairs(self.Cards) do
        local col = (i - 1) % self.Columns
        local row = math.floor((i - 1) / self.Columns)
        
        local card = self:CreateCard(cardData, col, row, cardWidth, cardHeight, spacing)
        card.Parent = Container
    end
    
    return Container
end

function MiniDashboard.newGamingStats:CreateCard(data, col, row, cardWidth, cardHeight, spacing)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, cardWidth, 0, cardHeight)
    card.Position = UDim2.new(0, spacing + col * (cardWidth + spacing), 0, 30 + spacing + row * (cardHeight + spacing))
    card.BackgroundColor3 = self.Theme.Second
    card.BorderSizePixel = 0
    card.Parent = self.Container
    self.Utilities:CreateCorner(card, 6)
    self.Utilities:CreateStroke(card, self.Theme.Border)
    
    local color = data.color or self.Theme.Accent
    
    -- Icon background
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 32, 0, 32)
    iconBg.Position = UDim2.new(0, 8, 0.5, 0)
    iconBg.AnchorPoint = Vector2.new(0, 0.5)
    iconBg.BackgroundColor3 = color
    iconBg.BorderSizePixel = 0
    iconBg.Parent = card
    self.Utilities:CreateCorner(iconBg, 6)
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = data.icon or "📊"
    icon.TextSize = 16
    icon.Parent = iconBg
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 0, 14)
    label.Position = UDim2.new(0, 44, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = data.label or "Label"
    label.TextColor3 = self.Theme.SecondText
    label.TextSize = 10
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = card
    
    -- Value
    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(1, -50, 0, 20)
    value.Position = UDim2.new(0, 44, 0, 22)
    value.BackgroundTransparency = 1
    value.Text = tostring(data.value or 0)
    value.TextColor3 = self.Theme.TitleText
    value.TextSize = 14
    value.Font = Enum.Font.GothamBold
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.TextTruncate = Enum.TextTruncate.AtEnd
    value.Parent = card
    
    -- Store reference
    self[data.key] = {Value = value, IconBg = iconBg, Label = label, Color = color}
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        self.Utilities:TweenColor(card, color:Lerp(self.Theme.Second, 0.7))
    end)
    
    card.MouseLeave:Connect(function()
        self.Utilities:TweenColor(card, self.Theme.Second)
    end)
    
    return card
end

-- Update methods for gaming stats
function MiniDashboard.newGamingStats:SetXP(value)
    self.XPPerMinute = value
    if self.xp and self.xp.Value then
        self.xp.Value.Text = tostring(value)
    end
end

function MiniDashboard.newGamingStats:SetGold(value)
    self.GoldPerMinute = value
    if self.gold and self.gold.Value then
        self.gold.Value.Text = tostring(value)
    end
end

function MiniDashboard.newGamingStats:SetActiveQuests(value)
    self.ActiveQuests = value
    if self.quests and self.quests.Value then
        self.quests.Value.Text = tostring(value)
    end
end

function MiniDashboard.newGamingStats:SetQuestProgress(value)
    self.QuestProgress = value
    if self.progress and self.progress.Value then
        self.progress.Value.Text = value .. "%"
    end
end

return MiniDashboard
