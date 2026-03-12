--[[
    Hyper-V - Combo Keybind / Chord Bind Component
    Bind tổ hợp 2-3 phím (ví dụ: Ctrl + F)
]]

local ComboKeybind = {}
ComboKeybind.__index = ComboKeybind

-- Track all combo keybinds for global checking
local allComboKeybinds = {}
local heldKeys = {}

function ComboKeybind.new(config, theme, utilities)
    local self = setmetatable({}, ComboKeybind)
    
    self.Name = config.Name or "ComboKeybind"
    self.Title = config.Title or "Combo Key"
    self.Keys = config.Keys or {Enum.KeyCode.LeftControl, Enum.KeyCode.F}
    self.Callback = config.Callback
    self.Description = config.Description or ""
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    self.IsListening = false
    self.IsEnabled = true
    self.Connections = {}
    
    return self
end

function ComboKeybind:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, 45)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    self.Container = Container
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -90, 0, 20)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = self.Title
    Title.TextColor3 = self.Theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    -- Description
    local hasDesc = self.Description and self.Description ~= ""
    if hasDesc then
        local Desc = Instance.new("TextLabel")
        Desc.Size = UDim2.new(1, -90, 0, 14)
        Desc.Position = UDim2.new(0, 10, 0, 24)
        Desc.BackgroundTransparency = 1
        Desc.Text = self.Description
        Desc.TextColor3 = self.Theme.SecondText
        Desc.TextSize = 10
        Desc.Font = Enum.Font.Gotham
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.Parent = Container
    end
    
    -- Keybind display button
    local keybindBtn = Instance.new("TextButton")
    keybindBtn.Size = UDim2.new(0, 80, 0, 22)
    keybindBtn.Position = UDim2.new(1, -80, 0.5, -11)
    keybindBtn.AnchorPoint = Vector2.new(1, 0.5)
    keybindBtn.BackgroundColor3 = self.Theme.Second
    keybindBtn.BorderSizePixel = 0
    keybindBtn.Text = self:GetKeysText()
    keybindBtn.TextColor3 = self.Theme.Text
    keybindBtn.TextSize = 11
    keybindBtn.Font = Enum.Font.GothamBold
    keybindBtn.AutoButtonColor = false
    keybindBtn.Parent = Container
    self.Utilities:CreateCorner(keybindBtn, 6)
    self.Utilities:CreateStroke(keybindBtn, self.Theme.Border)
    
    self.KeybindBtn = keybindBtn
    
    -- Click to edit keys
    keybindBtn.MouseButton1Click:Connect(function()
        self:StartListening()
    end)
    
    -- Hover effect
    keybindBtn.MouseEnter:Connect(function()
        self.Utilities:TweenColor(keybindBtn, self.Theme.Second:Lerp(Color3.new(1,1,1), 0.15))
    end)
    
    keybindBtn.MouseLeave:Connect(function()
        self.Utilities:TweenColor(keybindBtn, self.Theme.Second)
    end)
    
    -- Register this combo
    table.insert(allComboKeybinds, self)
    
    -- Start listening for the combo
    self:SetupComboListener()
    
    return Container
end

function ComboKeybind:GetKeysText()
    local text = ""
    for i, key in ipairs(self.Keys) do
        if i > 1 then
            text = text .. " + "
        end
        text = text .. self:GetKeyName(key)
    end
    return text
end

function ComboKeybind:GetKeyName(key)
    if type(key) == "string" then
        return key
    end
    local keyName = tostring(key)
    keyName = keyName:gsub("Enum%.KeyCode%.", "")
    
    -- Shorten common keys
    local shortcuts = {
        LeftControl = "LCtrl",
        RightControl = "RCtrl",
        LeftShift = "LShift",
        RightShift = "RShift",
        LeftAlt = "LAlt",
        RightAlt = "RAlt",
        LeftBracket = "[",
        RightBracket = "]",
        SemiColon = ";",
        Quote = "'",
        BackSlash = "\\",
        Tab = "Tab",
        Return = "Enter",
        Space = "Space"
    }
    
    return shortcuts[keyName] or keyName
end

function ComboKeybind:SetupComboListener()
    local UserInputService = game:GetService("UserInputService")
    
    -- Track key states
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            heldKeys[input.KeyCode] = true
            self:CheckCombo()
        end
    end))
    
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            heldKeys[input.KeyCode] = false
        end
    end))
end

function ComboKeybind:CheckCombo()
    if not self.IsEnabled then return end
    
    -- Check if all keys in combo are held
    local allHeld = true
    for _, key in ipairs(self.Keys) do
        if not heldKeys[key] then
            allHeld = false
            break
        end
    end
    
    if allHeld and self.Callback then
        self.Callback()
        
        -- Visual feedback
        self:FlashButton()
    end
end

function ComboKeybind:FlashButton()
    local originalColor = self.KeybindBtn.BackgroundColor3
    self.Utilities:TweenColor(self.KeybindBtn, self.Theme.Accent)
    
    task.delay(0.15, function()
        self.Utilities:TweenColor(self.KeybindBtn, self.Theme.Second)
    end)
end

function ComboKeybind:StartListening()
    if self.IsListening then return end
    
    self.IsListening = true
    self.KeybindBtn.Text = "Press keys..."
    self.KeybindBtn.TextColor3 = self.Theme.Accent
    
    -- Clear old connections
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}
    
    local UserInputService = game:GetService("UserInputService")
    local newKeys = {}
    
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
      if input.UserInputType == Enum.UserInputType.Keyboard then
            table.insert(newKeys, input.KeyCode)
            
            -- Update display
            local text = ""
            for i, k in ipairs(newKeys) do
                if i > 1 then text = text .. " + " end
                text = text .. self:GetKeyName(k)
            end
            self.KeybindBtn.Text = text
            
            -- Max 3 keys
            if #newKeys >= 3 then
                self:FinishListening(newKeys)
            end
        end
    end))
    
    -- Cancel on clicking elsewhere
    task.delay(5, function()
        if self.IsListening then
            self:FinishListening(newKeys)
        end
    end)
end

function ComboKeybind:FinishListening(newKeys)
    self.IsListening = false
    
    if #newKeys > 0 then
        self.Keys = newKeys
    end
    
    self.KeybindBtn.Text = self:GetKeysText()
    self.KeybindBtn.TextColor3 = self.Theme.Text
    
    -- Re-setup combo listener
    self.Connections = {}
    self:SetupComboListener()
end

function ComboKeybind:SetKeys(keys)
    self.Keys = keys
    if self.KeybindBtn then
        self.KeybindBtn.Text = self:GetKeysText()
    end
end

function ComboKeybind:GetKeys()
    return self.Keys
end

function ComboKeybind:Enable()
    self.IsEnabled = true
end

function ComboKeybind:Disable()
    self.IsEnabled = false
end

function ComboKeybind:Destroy()
    -- Remove from global list
    for i, cb in ipairs(allComboKeybinds) do
        if cb == self then
            table.remove(allComboKeybinds, i)
            break
        end
    end
    
    -- Disconnect all
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    
    if self.Container and self.Container.Parent then
        self.Container:Destroy()
    end
end

return ComboKeybind
