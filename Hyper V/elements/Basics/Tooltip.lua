--[[
    Hyper-V - Tooltip Component
    Hiển thị tooltip khi hover
]]

local Tooltip = {}
local BRAND_NAME = "Hyper-V"

function Tooltip.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Tooltip})
    
    self.Text = config.Text or "Tooltip"
    self.Delay = config.Delay or 0.5
    self.Theme = theme
    self.Utilities = utilities
    
    self.TooltipFrame = nil
    self.Timer = nil
    self.IsVisible = false
    
    return self
end

function Tooltip:Create()
    local Player = game.Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    
    -- Create tooltip container if not exists
    local tooltipContainer = PlayerGui:FindFirstChild(BRAND_NAME .. "Tooltips")
    if not tooltipContainer then
        tooltipContainer = Instance.new("ScreenGui")
        tooltipContainer.Name = BRAND_NAME .. "Tooltips"
        tooltipContainer.IgnoreGuiInset = true
        tooltipContainer.ResetOnSpawn = false
        tooltipContainer.Parent = PlayerGui
    end
    
    -- Tooltip Frame
    local TooltipFrame = Instance.new("Frame")
    TooltipFrame.Size = UDim2.new(0, 0, 0, 0)
    TooltipFrame.AutomaticSize = Enum.AutomaticSize.XY
    TooltipFrame.BackgroundColor3 = self.Theme.Default
    TooltipFrame.BorderSizePixel = 0
    TooltipFrame.Visible = false
    TooltipFrame.ZIndex = 1000
    TooltipFrame.Parent = tooltipContainer
    self.Utilities:CreateCorner(TooltipFrame, 5)
    self.Utilities:CreateStroke(TooltipFrame, self.Theme.Border)
    
    -- Text
    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(0, 0, 0, 0)
    Text.AutomaticSize = Enum.AutomaticSize.XY
    Text.BackgroundTransparency = 1
    Text.Text = self.Text
    Text.TextColor3 = self.Theme.Text
    Text.TextSize = 12
    Text.Font = Enum.Font.Gotham
    Text.ZIndex = 1000
    Text.Parent = TooltipFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 8)
    Padding.PaddingRight = UDim.new(0, 8)
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.Parent = TooltipFrame
    
    self.TooltipFrame = TooltipFrame
    
    return self
end

function Tooltip:Show(parent)
    if not self.TooltipFrame then
        self:Create()
    end
    
    local TooltipFrame = self.TooltipFrame
    
    -- Position tooltip above parent
    local parentAbsPos = parent.AbsolutePosition
    local parentAbsSize = parent.AbsoluteSize
    
    TooltipFrame.Position = UDim2.new(
        0,
        parentAbsPos.X + parentAbsSize.X / 2 - TooltipFrame.AbsoluteSize.X / 2,
        0,
        parentAbsPos.Y - TooltipFrame.AbsoluteSize.Y - 10
    )
    
    TooltipFrame.Visible = true
    self.IsVisible = true
    
    -- Fade in
    TooltipFrame.BackgroundTransparency = 1
    local TweenService = game:GetService("TweenService")
    TweenService:Create(TooltipFrame, TweenInfo.new(0.15), {
        BackgroundTransparency = 0
    }):Play()
end

function Tooltip:Hide()
    if not self.TooltipFrame then return end
    
    self.IsVisible = false
    self.TooltipFrame.Visible = false
end

function Tooltip:Destroy()
    if self.TooltipFrame then
        self.TooltipFrame:Destroy()
        self.TooltipFrame = nil
    end
end

-- Static method to add tooltip to any element
function Tooltip:AddTo(element, text, delay)
    delay = delay or 0.5
    
    local tooltip = Tooltip.new({Text = text, Delay = delay}, self.Theme, self.Utilities)
    tooltip:Create()
    
    local timer = nil
    
    element.MouseEnter:Connect(function()
        timer = task.delay(delay, function()
            tooltip:Show(element)
        end)
    end)
    
    element.MouseLeave:Connect(function()
        if timer then
            task.cancel(timer)
            timer = nil
        end
        tooltip:Hide()
    end)
    
    return tooltip
end

return Tooltip
