--[[
    Hyper-V - Slider Component
    Thanh trượt để chọn giá trị số
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local function CreateSlider(config, theme, utilities)
    -- Default values
    local min = config.Min or 0
    local max = config.Max or 100
    local value = config.Value or 50
    local decimals = config.Decimals or 0
    local step = config.Step or 1
    
    local Slider = Instance.new("Frame")
    Slider.Name = "Slider"
    Slider.Size = UDim2.new(1, 0, 0, 45)
    Slider.BackgroundTransparency = 1
    Slider.Parent = config.Parent
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -60, 0, 18)
    Title.BackgroundTransparency = 1
    Title.Text = config.Name or "Slider"
    Title.TextColor3 = theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.Gotham
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Slider
    
    -- Value display
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "Value"
    ValueLabel.Size = UDim2.new(0, 60, 0, 18)
    ValueLabel.Position = UDim2.new(1, 0, 0, 0)
    ValueLabel.AnchorPoint = Vector2.new(1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(value)
    ValueLabel.TextColor3 = theme.Accent
    ValueLabel.TextSize = 13
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Slider
    
    -- Track
    local Track = Instance.new("Frame")
    Track.Name = "Track"
    Track.Size = UDim2.new(1, 0, 0, 6)
    Track.Position = UDim2.new(0, 0, 0, 20)
    Track.BackgroundColor3 = theme.Second
    Track.BorderSizePixel = 0
    Track.Parent = Slider
    utilities:CreateCorner(Track, 3)
    utilities:CreateStroke(Track, theme.Border)
    
    -- Fill
    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    utilities:CreateCorner(Fill, 3)
    
    -- Thumb
    local Thumb = Instance.new("Frame")
    Thumb.Name = "Thumb"
    Thumb.Size = UDim2.new(0, 16, 0, 16)
    Thumb.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
    Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Thumb.BorderSizePixel = 0
    Thumb.Parent = Track
    utilities:CreateCorner(Thumb, 8)
    utilities:CreateStroke(Thumb, theme.Border)
    
    local function UpdateSlider(input)
        local relativeX = input.Position.X - Track.AbsolutePosition.X
        local percent = utilities:Clamp(relativeX / Track.AbsoluteSize.X, 0, 1)
        
        -- Apply step
        local rawValue = min + (max - min) * percent
        value = math.floor(rawValue / step + 0.5) * step
        value = utilities:Clamp(value, min, max)
        
        -- Update visuals
        percent = (value - min) / (max - min)
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        Thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        
        -- Update value text
        if decimals > 0 then
            ValueLabel.Text = string.format("%." .. decimals .. "f", value)
        else
            ValueLabel.Text = tostring(value)
        end
        
        -- Callback
        if config.OnChange then
            config.OnChange(value)
        end
    end
    
    -- Input handling
    local isDragging = false
    
    local function InputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            UpdateSlider(input)
        end
    end
    
    local function InputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end
    
    local function InputChanged(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
            UpdateSlider(input)
        end
    end
    
    Track.InputBegan:Connect(InputBegan)
    Track.InputEnded:Connect(InputEnded)
    Track.InputChanged:Connect(InputChanged)
    
    -- Set value function
    function Slider:SetValue(newValue)
        value = utilities:Clamp(newValue, min, max)
        local percent = (value - min) / (max - min)
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        Thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        
        if decimals > 0 then
            ValueLabel.Text = string.format("%." .. decimals .. "f", value)
        else
            ValueLabel.Text = tostring(value)
        end
    end
    
    -- Get value function
    function Slider:GetValue()
        return value
    end
    
    return Slider
end

return CreateSlider
