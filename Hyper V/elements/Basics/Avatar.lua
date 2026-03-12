--[[
    Hyper-V - Avatar Component
    Hiển thị avatar người chơi
]]

local Avatar = {}

function Avatar.new(config, theme, utilities)
    local self = setmetatable({}, {__index = Avatar})
    
    self.Name = config.Name or "Avatar"
    self.UserId = config.UserId or 0
    self.Size = config.Size or UDim2.new(0, 80, 0, 80)
    self.ShowName = config.ShowName ~= false
    self.Circle = config.Circle ~= false
    self.OnClick = config.OnClick
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function Avatar:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = self.Size
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    
    if self.Circle then
        self.Utilities:CreateCorner(Container, self.Size.X.Offset / 2)
    else
        self.Utilities:CreateCorner(Container, 6)
    end
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Avatar Image
    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Size = UDim2.new(1, -4, 1, -4)
    AvatarImage.Position = UDim2.new(0, 2, 0, 2)
    AvatarImage.BackgroundTransparency = 1
    AvatarImage.Image = ""
    AvatarImage.ScaleType = Enum.ScaleType.Crop
    AvatarImage.Parent = Container
    
    -- Get avatar image
    self:LoadAvatar(AvatarImage)
    
    -- Name Label
    if self.ShowName then
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, 0, 0, 16)
        NameLabel.Position = UDim2.new(0, 0, 1, 4)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = ""
        NameLabel.TextColor3 = self.Theme.Text
        NameLabel.TextSize = 11
        NameLabel.Font = Enum.Font.Gotham
        NameLabel.TextXAlignment = Enum.TextXAlignment.Center
        NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        NameLabel.Parent = Container
        
        self:LoadName(NameLabel)
    end
    
    -- Clickable
    if self.OnClick then
        local ClickDetector = Instance.new("ClickDetector")
        ClickDetector.Parent = Container
        
        ClickDetector.MouseClick:Connect(function()
            self.OnClick(self.UserId)
        end)
    end
    
    return Container
end

function Avatar:LoadAvatar(imageLabel)
    task.spawn(function()
        -- Try to get avatar image using Players service
        local Players = game:GetService("Players")
        local thumbType = Enum.ThumbnailType.AvatarBust
        local thumbSize = Vector2.new(352, 352)
        
        local content, isReady = Players:GetUserThumbnailAsync(self.UserId, thumbType, thumbSize)
        
        if isReady then
            imageLabel.Image = content
        else
            -- Fallback to placeholder
            imageLabel.Image = "rbxassetid://7723658504" -- Default avatar
        end
    end)
end

function Avatar:LoadName(label)
    task.spawn(function()
        local success, err = pcall(function()
            local Players = game:GetService("Players")
            local player = Players:GetPlayerByUserId(self.UserId)
            
            if player then
                label.Text = player.Name
            else
                -- Try to get display name
                local httpService = game:GetService("HttpService")
                local url = "https://users.roblox.com/v1/users/" .. self.UserId
                
                -- Simple fallback
                label.Text = "User " .. self.UserId
            end
        end)
        
        if not success then
            label.Text = "User " .. self.UserId
        end
    end)
end

function Avatar:SetUserId(userId)
    self.UserId = userId
    
    local Container = self.Parent:FindFirstChild(self.Name)
    if Container then
        local AvatarImage = Container:FindFirstChildWhichIsA("ImageLabel")
        if AvatarImage then
            self:LoadAvatar(AvatarImage)
        end
        
        local NameLabel = Container:FindFirstChildWhichIsA("TextLabel", true)
        if NameLabel then
            self:LoadName(NameLabel)
        end
    end
end

return Avatar
