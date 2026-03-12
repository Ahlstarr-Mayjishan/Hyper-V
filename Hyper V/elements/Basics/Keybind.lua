--[[
    Hyper-V - Keybind Component
    Chức năng gán phím tắt tùy chỉnh
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local function CreateKeybind(config, theme, utilities)
    local currentKey = config.Default or Enum.KeyCode.Unknown
    local isBinding = false
    
    local Keybind = Instance.new("Frame")
    Keybind.Name = "Keybind"
    Keybind.Size = UDim2.new(1, 0, 0, 40)
    Keybind.BackgroundColor3 = theme.Second
    Keybind.BorderSizePixel = 0
    Keybind.Parent = config.Parent
    utilities:CreateCorner(Keybind, 6)
    utilities:CreateStroke(Keybind, theme.Border)
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Name or "Keybind"
    Title.TextColor3 = theme.Text
    Title.TextSize = 13
    Title.Font = Enum.Font.Gotham
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Keybind
    
    -- Key display button
    local KeyButton = Instance.new("TextButton")
    KeyButton.Name = "KeyButton"
    KeyButton.Size = UDim2.new(0, 70, 0, 26)
    KeyButton.Position = UDim2.new(1, 0, 0.5, 0)
    KeyButton.AnchorPoint = Vector2.new(1, 0.5)
    KeyButton.BackgroundColor3 = theme.Default
    KeyButton.Text = utilities:GetKeyName(currentKey)
    KeyButton.TextColor3 = theme.TitleText
    KeyButton.TextSize = 12
    KeyButton.Font = Enum.Font.GothamBold
    KeyButton.Parent = Keybind
    utilities:CreateCorner(KeyButton, 5)
    utilities:CreateStroke(KeyButton, theme.Border)
    
    -- Status indicator
    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(0, 60, 0, 18)
    Status.Position = UDim2.new(1, -80, 0.5, 0)
    Status.AnchorPoint = Vector2.new(1, 0.5)
    Status.BackgroundTransparency = 1
    Status.Text = "Not Bound"
    Status.TextColor3 = theme.Error
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Right
    Status.Parent = Keybind
    
    local function UpdateKeyDisplay(keyName)
        KeyButton.Text = keyName
    end
    
    local function SetBindingMode(mode)
        isBinding = mode
        if mode then
            KeyButton.Text = "..."
            KeyButton.BackgroundColor3 = theme.Accent
            Status.Text = "Press key..."
            Status.TextColor3 = theme.Warning
        else
            KeyButton.BackgroundColor3 = theme.Default
            if currentKey ~= Enum.KeyCode.Unknown then
                Status.Text = "Bound"
                Status.TextColor3 = theme.Success
            else
                Status.Text = "Not Bound"
                Status.TextColor3 = theme.Error
            end
        end
    end
    
    local function BindKey(key)
        -- Unbind previous key
        if currentKey ~= Enum.KeyCode.Unknown then
            local actionName = config.Name or "KeybindAction"
            ContextActionService:UnbindAction(actionName)
        end
        
        currentKey = key
        local keyName = utilities:GetKeyName(key)
        UpdateKeyDisplay(keyName)
        SetBindingMode(false)
        
        -- Bind new key
        if key ~= Enum.KeyCode.Unknown then
            local actionName = config.Name or "KeybindAction"
            ContextActionService:BindAction(
                actionName,
                function(_, inputState)
                    if inputState == Enum.UserInputState.Begin then
                        if config.OnPressed then
                            config.OnPressed()
                        end
                    end
                end,
                false,
                key
            )
        end
        
        if config.OnChange then
            config.OnChange(key)
        end
    end
    
    -- Click to bind
    KeyButton.MouseButton1Click:Connect(function()
        if not isBinding then
            SetBindingMode(true)
        end
    end)
    
    -- Listen for key input
    local inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if isBinding then
            local key = input.KeyCode
            if key ~= Enum.KeyCode.Unknown then
                BindKey(key)
            end
        end
    end)
    
    -- Set initial key
    if currentKey ~= Enum.KeyCode.Unknown then
        BindKey(currentKey)
    end
    
    -- Clear keybind function
    function Keybind:Clear()
        local actionName = config.Name or "KeybindAction"
        ContextActionService:UnbindAction(actionName)
        currentKey = Enum.KeyCode.Unknown
        UpdateKeyDisplay("None")
        Status.Text = "Not Bound"
        Status.TextColor3 = theme.Error
        
        if config.OnChange then
            config.OnChange(nil)
        end
    end
    
    -- Get current key
    function Keybind:GetKey()
        return currentKey
    end
    
    -- Destroy
    local originalDestroy = Keybind.Destroy
    function Keybind:Destroy()
        inputBegan:Disconnect()
        originalDestroy(self)
    end
    
    return Keybind
end

return CreateKeybind
