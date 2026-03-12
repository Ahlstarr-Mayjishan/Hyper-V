--[[
    Hyper-V - Image Component
    Hiển thị hình ảnh
]]

local Image = {}

function Image.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Image})
    
    self.Name = config.Name or "Image"
    self.Image = config.Image or ""
    self.Size = config.Size or UDim2.new(1, 0, 0, 100)
    self.ScaleType = config.ScaleType or Enum.ScaleType.Fit
    self.Rotation = config.Rotation or 0
    self.Clickable = config.Clickable or false
    self.OnClick = config.OnClick
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Image:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = self.Size
    Container.BackgroundColor3 = self.Theme.Second
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 6)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Image Label
    local ImageLabel = Instance.new("ImageLabel")
    ImageLabel.Size = UDim2.new(1, -4, 1, -4)
    ImageLabel.Position = UDim2.new(0, 2, 0, 2)
    ImageLabel.BackgroundTransparency = 1
    ImageLabel.Image = self.Image
    ImageLabel.ScaleType = self.ScaleType
    ImageLabel.Rotation = self.Rotation
    ImageLabel.ImageColor3 = Color3.new(1, 1, 1)
    ImageLabel.ImageTransparency = 0
    ImageLabel.Parent = Container
    
    -- Make clickable if needed
    if self.Clickable then
        Container.Selectable = true
        Container.Interactive = true
        
        local ClickDetector = Instance.new("ClickDetector")
        ClickDetector.Parent = Container
        
        ClickDetector.MouseClick:Connect(function()
            if self.OnClick then
                self.OnClick()
            end
        end)
        
        -- Hover effect
        Container.MouseEnter:Connect(function()
            ImageLabel.ImageTransparency = 0.2
        end)
        
        Container.MouseLeave:Connect(function()
            ImageLabel.ImageTransparency = 0
        end)
    end
    
    -- Placeholder if no image
    if self.Image == "" then
        local Placeholder = Instance.new("TextLabel")
        Placeholder.Size = UDim2.new(1, 0, 1, 0)
        Placeholder.BackgroundTransparency = 1
        Placeholder.Text = "📷"
        Placeholder.TextSize = 24
        Placeholder.Parent = Container
    end
    
    return Container
end

function Image:SetImage(imageId)
    local Container = self.Parent:FindFirstChild(self.Name)
    if Container then
        local ImageLabel = Container:FindFirstChildWhichIsA("ImageLabel")
        if ImageLabel then
            ImageLabel.Image = imageId
        end
    end
end

function Image:SetColor(color3)
    local Container = self.Parent:FindFirstChild(self.Name)
    if Container then
        local ImageLabel = Container:FindFirstChildWhichIsA("ImageLabel")
        if ImageLabel then
            ImageLabel.ImageColor3 = color3
        end
    end
end

function Image:SetTransparency(transparency)
    local Container = self.Parent:FindFirstChild(self.Name)
    if Container then
        local ImageLabel = Container:FindFirstChildWhichIsA("ImageLabel")
        if ImageLabel then
            ImageLabel.ImageTransparency = transparency
        end
    end
end

return Image
