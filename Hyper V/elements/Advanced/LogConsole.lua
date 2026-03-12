--[[
    Hyper-V - Log Console Component
    Panel hiển thị log real-time với nhiều mức độ
]]

local LogConsole = {}

function LogConsole.new(config, theme, utilities)
    local self = setmetatable({}, {__index = LogConsole})
    
    self.Name = config.Name or "LogConsole"
    self.Title = config.Title or "Console"
    self.Width = config.Width or 450
    self.Height = config.Height or 250
    self.MaxLogs = config.MaxLogs or 100
    self.ShowTimestamp = config.ShowTimestamp or true
    self.ShowClearButton = config.ShowClearButton or true
    self.ShowCopyButton = config.ShowCopyButton or true
    self.AutoScroll = config.AutoScroll or true
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    self.Logs = {}
    self.LogColors = {
        Info = theme.Text,
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68),
        Success = Color3.fromRGB(16, 185, 129),
        System = theme.SecondText,
        Debug = Color3.fromRGB(139, 92, 246)
    }
    
    return self
end

function LogConsole:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, self.Height)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    self.Container = Container
    
    -- Header
    local header = self:CreateHeader()
    header.Parent = Container
    
    -- Scrollable log area
    local logArea = Instance.new("ScrollingFrame")
    logArea.Size = UDim2.new(1, -10, 1, -45)
    logArea.Position = UDim2.new(0, 5, 0, 40)
    logArea.BackgroundColor3 = self.Theme.Second
    logArea.BorderSizePixel = 0
    logArea.ScrollBarThickness = 4
    logArea.ScrollBarImageColor3 = self.Theme.Accent
    logArea.Parent = Container
    self.LogArea = logArea
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = logArea
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = logArea
    
    -- Bottom toolbar
    local toolbar = self:CreateToolbar()
    toolbar.Parent = Container
    
    -- Add welcome log
    self:AddLog("System", "Console initialized. Ready for logs.")
    
    return Container
end

function LogConsole:CreateHeader()
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = self.Theme.Second
    header.BorderSizePixel = 0
    header.Parent = self.Container
    self.Utilities:CreateCorner(header, 8)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Log count badge
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 25, 0, 18)
    badge.Position = UDim2.new(1, -40, 0.5, 0)
    badge.AnchorPoint = Vector2.new(1, 0.5)
    badge.BackgroundColor3 = self.Theme.Accent
    badge.BorderSizePixel = 0
    badge.Text = "0"
    badge.TextColor3 = Color3.new(1, 1, 1)
    badge.TextSize = 10
    badge.Font = Enum.Font.GothamBold
    badge.Parent = header
    self.Utilities:CreateCorner(badge, 9)
    self.Badge = badge
    
    return header
end

function LogConsole:CreateToolbar()
    local toolbar = Instance.new("Frame")
    toolbar.Size = UDim2.new(1, -10, 0, 30)
    toolbar.Position = UDim2.new(0, 5, 1, -35)
    toolbar.BackgroundTransparency = 1
    toolbar.Parent = self.Container
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 5)
    layout.Parent = toolbar
    
    -- Clear button
    if self.ShowClearButton then
        local clearBtn = self:CreateToolButton("Clear", self.Theme.Accent)
        clearBtn.MouseButton1Click:Connect(function()
            self:Clear()
        end)
        clearBtn.Parent = toolbar
    end
    
    -- Copy button
    if self.ShowCopyButton then
        local copyBtn = self:CreateToolButton("Copy", self.Theme.Second)
        copyBtn.MouseButton1Click:Connect(function()
            self:CopyToClipboard()
        end)
        copyBtn.Parent = toolbar
    end
    
    return toolbar
end

function LogConsole:CreateToolButton(text, bgColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 24)
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = self.Theme.Text
    btn.TextSize = 11
    btn.Font = Enum.Font.Gotham
    btn.AutoButtonColor = false
    self.Utilities:CreateCorner(btn, 4)
    self.Utilities:CreateStroke(btn, self.Theme.Border)
    
    btn.MouseEnter:Connect(function()
        self.Utilities:TweenColor(btn, bgColor:Lerp(Color3.new(1,1,1), 0.15))
    end)
    
    btn.MouseLeave:Connect(function()
        self.Utilities:TweenColor(btn, bgColor)
    end)
    
    return btn
end

function LogConsole:AddLog(level, message)
    local timestamp = ""
    if self.ShowTimestamp then
        local time = os.date("%H:%M:%S")
        timestamp = "[" .. time .. "] "
    end
    
    local color = self.LogColors[level] or self.LogColors.Info
    
    local logEntry = Instance.new("Frame")
    logEntry.Size = UDim2.new(1, 0, 0, 20)
    logEntry.BackgroundTransparency = 1
    logEntry.BorderSizePixel = 0
    
    local prefix = "•"
    if level == "Error" then prefix = "✕"
    elseif level == "Warning" then prefix = "⚠"
    elseif level == "Success" then prefix = "✓"
    elseif level == "Debug" then prefix = "⚙"
    end
    
    local logText = Instance.new("TextLabel")
    logText.Size = UDim2.new(1, 0, 1, 0)
    logText.BackgroundTransparency = 1
    logText.Text = prefix .. " " .. timestamp .. message
    logText.TextColor3 = color
    logText.TextSize = 11
    logText.Font = Enum.Font.Gotham
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.TextTruncate = Enum.TextTruncate.AtEnd
    logText.Parent = logEntry
    
    -- Hover to see full message
    logText.MouseEnter:Connect(function()
        logText.TextTransparency = 0.7
    end)
    
    logText.MouseLeave:Connect(function()
        logText.TextTransparency = 0
    end)
    
    logEntry.Parent = self.LogArea
    
    -- Store log
    table.insert(self.Logs, {
        level = level,
        message = message,
        timestamp = timestamp,
        element = logEntry
    })
    
    -- Update badge
    self.Badge.Text = tostring(#self.Logs)
    
    -- Remove old logs if exceeding max
    while #self.Logs > self.MaxLogs do
        local oldLog = table.remove(self.Logs, 1)
        if oldLog.element and oldLog.element.Parent then
            oldLog.element:Destroy()
        end
    end
    
    -- Auto scroll to bottom
    if self.AutoScroll then
        task.wait()
        self.LogArea.CanvasPosition = Vector2.new(0, self.LogArea.CanvasSize.Y.Offset)
    end
end

-- Convenience methods
function LogConsole:Info(message)
    self:AddLog("Info", message)
end

function LogConsole:Warning(message)
    self:AddLog("Warning", message)
end

function LogConsole:Error(message)
    self:AddLog("Error", message)
end

function LogConsole:Success(message)
    self:AddLog("Success", message)
end

function LogConsole:System(message)
    self:AddLog("System", message)
end

function LogConsole:Debug(message)
    self:AddLog("Debug", message)
end

function LogConsole:Clear()
    for _, log in ipairs(self.Logs) do
        if log.element and log.element.Parent then
            log.element:Destroy()
        end
    end
    self.Logs = {}
    self.Badge.Text = "0"
end

function LogConsole:CopyToClipboard()
    local text = ""
    for _, log in ipairs(self.Logs) do
        text = text .. log.timestamp .. "[" .. log.level .. "] " .. log.message .. "\n"
    end
    -- Note: In Roblox, you'd use SetClipboard
    -- For now, just log that it would copy
    self:System("Copied " .. #self.Logs .. " logs to clipboard")
end

return LogConsole
