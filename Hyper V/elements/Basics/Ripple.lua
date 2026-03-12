--[[
    Hyper-V - Ripple Effect Component
    Hiệu ứng sóng khi click
]]

local Ripple = {}

function Ripple.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Ripple})
    
    self.Color = config.Color or Color3.new(1, 1, 1)
    self.Speed = config.Speed or 0.5
    self.MaxSize = config.MaxSize or 2
    self.Transparency = config.Transparency or 0.5
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Ripple:Create(parent)
    if not parent then return end
    
    local TweenService = game:GetService("TweenService")
    
    -- Create ripple circle
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = self.Color
    ripple.BackgroundTransparency = 1
    ripple.BorderSizePixel = 0
    ripple.ZIndex = 100
    ripple.Parent = parent
    
    self.Utilities:CreateCorner(ripple, 100)
    
    -- Calculate size based on parent
    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * self.MaxSize
    
    -- Animate ripple
    local appear = TweenService:Create(ripple, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1 - self.Transparency
    })
    
    local fade = TweenService:Create(ripple, TweenInfo.new(self.Speed, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, size * 1.2, 0, size * 1.2)
    })
    
    appear.Completed:Connect(function()
        fade:Play()
    end)
    
    fade.Completed:Connect(function()
        ripple:Destroy()
    end)
    
    appear:Play()
    
    return ripple
end

-- Static method to add ripple to any button
function Ripple:AddTo(element, color)
    color = color or Color3.new(1, 1, 1)
    
    element.MouseButton1Click:Connect(function()
        self:Create(element)
    end)
end

-- Add ripple to all buttons in a container
function Ripple:AddToContainer(container, color)
    color = color or Color3.new(1, 1, 1)
    
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("TextButton") or child:IsA("ImageButton") then
            self:AddTo(child, color)
        end
    end
end

return Ripple
