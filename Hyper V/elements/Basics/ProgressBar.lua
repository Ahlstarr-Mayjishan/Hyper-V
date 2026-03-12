--[[
    Hyper-V - ProgressBar Component
    Thanh tiến trình
]]

local ProgressBar = {}

function ProgressBar.new(config, theme, utilities)
    local self = setmetatable({}, {__index = ProgressBar})
    
    self.Name = config.Name or "ProgressBar"
    self.Value = config.Value or 0
    self.Max = config.Max or 100
    self.ShowPercentage = config.ShowPercentage or true
    self.Animated = config.Animated ~= false
    self.OnChange = config.OnChange
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function ProgressBar:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, 30)
    Container.BackgroundColor3 = self.Theme.Second
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 5)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.TextColor3 = self.Theme.Text
    Title.TextSize = 12
    Title.Font = Enum.Font.Gotham
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    -- Percentage
    local Percentage = Instance.new("TextLabel")
    Percentage.Size = UDim2.new(0, 50, 0, 20)
    Percentage.Position = UDim2.new(1, -55, 0, 0)
    Percentage.AnchorPoint = Vector2.new(1, 0)
    Percentage.BackgroundTransparency = 1
    Percentage.Text = tostring(self.Value) .. "%"
    Percentage.TextColor3 = self.Theme.Accent
    Percentage.TextSize = 12
    Percentage.Font = Enum.Font.GothamBold
    Percentage.TextXAlignment = Enum.TextXAlignment.Right
    Percentage.Parent = Container
    
    -- Fill
    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.Position = UDim2.new(0, 0, 0, 0)
    Fill.BackgroundColor3 = self.Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Container
    self.Utilities:CreateCorner(Fill, 5, 0, 5, 0)
    
    -- Set initial value
    self:SetValue(self.Value)
    
    return Container
end

function ProgressBar:SetValue(value)
    value = math.clamp(value, 0, self.Max)
    self.Value = value
    
    local percentage = (value / self.Max)
    local parent = self.Parent
    
    -- Find the container
    local Container = parent:FindFirstChild(self.Name) or parent
    local Fill = Container:FindFirstChild("Fill")
    local Percentage = Container:FindFirstChildWhichIsA("TextLabel", true)
    
    if Fill then
        if self.Animated then
            local TweenService = game:GetService("TweenService")
            TweenService:Create(Fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(percentage, 0, 1, 0)
            }):Play()
        else
            Fill.Size = UDim2.new(percentage, 0, 1, 0)
        end
    end
    
    if Percentage then
        Percentage.Text = math.floor(percentage * 100) .. "%"
    end
    
    if self.OnChange then
        self.OnChange(value)
    end
end

function ProgressBar:GetValue()
    return self.Value
end

function ProgressBar:Increment(amount)
    self:SetValue(self.Value + (amount or 1))
end

function ProgressBar:Decrement(amount)
    self:SetValue(self.Value - (amount or 1))
end

return ProgressBar
