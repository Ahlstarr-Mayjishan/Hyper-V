--[[
    Hyper-V - Macro Button Component
    Ghi và phát lại chuỗi hành động
]]

local MacroButton = {}
MacroButton.__index = MacroButton

function MacroButton.new(config, theme, utilities)
    local self = setmetatable({}, MacroButton)
    
    self.Name = config.Name or "MacroButton"
    self.Title = config.Title or "Macro"
    self.Callback = config.Callback
    self.Description = config.Description or ""
    self.RecordHotkey = config.RecordHotkey or Enum.KeyCode.R
    self.PlayHotkey = config.PlayHotkey or Enum.KeyCode.P
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    self.IsRecording = false
    self.IsPlaying = false
    self.RecordedActions = {}  -- { {key = KeyCode, time = tick()}, ... }
    self.RecordingStartTime = 0
    
    -- Connections
    self.InputConnections = {}
    
    return self
end

function MacroButton:Create()
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
    Title.Size = UDim2.new(1, -140, 0, 20)
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
        Desc.Size = UDim2.new(1, -140, 0, 14)
        Desc.Position = UDim2.new(0, 10, 0, 24)
        Desc.BackgroundTransparency = 1
        Desc.Text = self.Description
        Desc.TextColor3 = self.Theme.SecondText
        Desc.TextSize = 10
        Desc.Font = Enum.Font.Gotham
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.Parent = Container
    end
    
    -- Status indicator
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 100, 0, 16)
    statusLabel.Position = UDim2.new(1, -130, 0, 5)
    statusLabel.AnchorPoint = Vector2.new(1, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = self.Theme.SecondText
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = Container
    self.StatusLabel = statusLabel
    
    -- Action buttons container
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Size = UDim2.new(0, 120, 0, 26)
    buttonsContainer.Position = UDim2.new(1, -130, 0.5, 0)
    buttonsContainer.AnchorPoint = Vector2.new(1, 0.5)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = Container
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 5)
    layout.Parent = buttonsContainer
    
    -- Record Button
    local recordBtn = Instance.new("TextButton")
    recordBtn.Size = UDim2.new(0, 55, 0, 26)
    recordBtn.BackgroundColor3 = self.Theme.Second
    recordBtn.BorderSizePixel = 0
    recordBtn.Text = "Record"
    recordBtn.TextColor3 = self.Theme.Text
    recordBtn.TextSize = 11
    recordBtn.Font = Enum.Font.Gotham
    recordBtn.AutoButtonColor = false
    recordBtn.Parent = buttonsContainer
    self.Utilities:CreateCorner(recordBtn, 6)
    self.Utilities:CreateStroke(recordBtn, self.Theme.Border)
    self.RecordBtn = recordBtn
    
    -- Play Button
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0, 55, 0, 26)
    playBtn.BackgroundColor3 = self.Theme.Second
    playBtn.BorderSizePixel = 0
    playBtn.Text = "Play"
    playBtn.TextColor3 = self.Theme.Text
    playBtn.TextSize = 11
    playBtn.Font = Enum.Font.Gotham
    playBtn.AutoButtonColor = false
    playBtn.Parent = buttonsContainer
    self.Utilities:CreateCorner(playBtn, 6)
    self.Utilities:CreateStroke(playBtn, self.Theme.Border)
    self.PlayBtn = playBtn
    
    -- Button handlers
    recordBtn.MouseButton1Click:Connect(function()
        if self.IsRecording then
            self:StopRecording()
        else
            self:StartRecording()
        end
    end)
    
    playBtn.MouseButton1Click:Connect(function()
        self:Play()
    end)
    
    -- Button hover effects
    recordBtn.MouseEnter:Connect(function()
        self.Utilities:TweenColor(recordBtn, self.Theme.Second:Lerp(Color3.new(1,1,1), 0.15))
    end)
    recordBtn.MouseLeave:Connect(function()
        self.Utilities:TweenColor(recordBtn, self.Theme.Second)
    end)
    
    playBtn.MouseEnter:Connect(function()
        self.Utilities:TweenColor(playBtn, self.Theme.Second:Lerp(Color3.new(1,1,1), 0.15))
    end)
    playBtn.MouseLeave:Connect(function()
        self.Utilities:TweenColor(playBtn, self.Theme.Second)
    end)
    
    return Container
end

function MacroButton:StartRecording()
    if self.IsRecording then return end
    
    self.IsRecording = true
    self.RecordedActions = {}
    self.RecordingStartTime = tick()
    
    -- Update UI
    self.RecordBtn.Text = "Stop"
    self.RecordBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
    self.StatusLabel.Text = "Recording..."
    self.StatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
    
    -- Start listening for input
    local UserInputService = game:GetService("UserInputService")
    
    table.insert(self.InputConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if self.IsRecording and input.UserInputType == Enum.UserInputType.Keyboard then
            local elapsed = tick() - self.RecordingStartTime
            table.insert(self.RecordedActions, {
                type = "press",
                key = input.KeyCode,
                time = elapsed
            })
        end
    end))
    
    table.insert(self.InputConnections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if self.IsRecording and input.UserInputType == Enum.UserInputType.Keyboard then
            local elapsed = tick() - self.RecordingStartTime
            table.insert(self.RecordedActions, {
                type = "release",
                key = input.KeyCode,
                time = elapsed
            })
        end
    end))
end

function MacroButton:StopRecording()
    if not self.IsRecording then return end
    
    self.IsRecording = false
    
    -- Disconnect input listeners
    for _, conn in ipairs(self.InputConnections) do
        conn:Disconnect()
    end
    self.InputConnections = {}
    
    -- Update UI
    local actionCount = #self.RecordedActions
    self.RecordBtn.Text = "Record"
    self.RecordBtn.BackgroundColor3 = self.Theme.Second
    self.StatusLabel.Text = actionCount .. " actions"
    self.StatusLabel.TextColor3 = self.Theme.SecondText
    
    if actionCount == 0 then
        self.StatusLabel.Text = "No input"
    end
end

function MacroButton:Play()
    if self.IsPlaying then return end
    if #self.RecordedActions == 0 then
        self.StatusLabel.Text = "No macro"
        return
    end
    
    self.IsPlaying = true
    
    -- Update UI
    self.PlayBtn.Text = "Playing"
    self.PlayBtn.BackgroundColor3 = self.Theme.Accent
    self.StatusLabel.Text = "Playing..."
    self.StatusLabel.TextColor3 = self.Theme.Accent
    
    -- Play recorded actions
    task.spawn(function()
        local lastTime = 0
        
        for i, action in ipairs(self.RecordedActions) do
            -- Wait for delay
            local delay = action.time - lastTime
            if delay > 0 then
                task.wait(delay)
            end
            lastTime = action.time
            
            -- Simulate key press/release
            if self.Callback then
                self.Callback(action.type, action.key)
            end
        end
        
        -- Reset UI after playing
        task.wait(0.3)
        self.IsPlaying = false
        self.PlayBtn.Text = "Play"
        self.PlayBtn.BackgroundColor3 = self.Theme.Second
        self.StatusLabel.Text = "Played " .. #self.RecordedActions .. " actions"
        self.StatusLabel.TextColor3 = Color3.fromRGB(16, 185, 129)
        
        task.delay(2, function()
            self.StatusLabel.Text = "Ready"
            self.StatusLabel.TextColor3 = self.Theme.SecondText
        end)
    end)
end

function MacroButton:GetMacro()
    return self.RecordedActions
end

function MacroButton:SetMacro(actions)
    self.RecordedActions = actions
    self.StatusLabel.Text = #actions .. " actions"
end

function MacroButton:ClearMacro()
    self.RecordedActions = {}
    self.StatusLabel.Text = "Ready"
end

function MacroButton:HasMacro()
    return #self.RecordedActions > 0
end

return MacroButton
