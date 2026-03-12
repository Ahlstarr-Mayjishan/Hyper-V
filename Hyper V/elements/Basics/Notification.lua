local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Notification = {}
Notification.__index = Notification
local BRAND_NAME = "Hyper-V"

local container = nil

local typeIcons = {
    info = "i",
    success = "OK",
    warning = "!",
    error = "X",
}

local function ensureContainer(theme)
    if container and container.Parent then
        return container
    end

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    container = Instance.new("Frame")
    container.Name = BRAND_NAME .. "Notifications"
    container.Size = UDim2.new(0, 340, 1, -20)
    container.Position = UDim2.new(1, -350, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = playerGui

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.VerticalAlignment = Enum.VerticalAlignment.Top
    list.Parent = container

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = container

    return container
end

function Notification.new(config, theme, utilities)
    local self = setmetatable({}, Notification)
    self.Title = config.Title or "Notification"
    self.Content = config.Content or ""
    self.Type = config.Type or "info"
    self.Duration = config.Duration or 3
    self.Actions = config.Actions or {}
    self.Theme = theme
    self.Utilities = utilities
    self.Toast = nil
    return self
end

function Notification:_GetAccentColor()
    if self.Type == "success" then
        return self.Theme.Success
    elseif self.Type == "warning" then
        return self.Theme.Warning
    elseif self.Type == "error" then
        return self.Theme.Error
    end
    return self.Theme.Accent
end

function Notification:Create()
    local root = ensureContainer(self.Theme)
    local accent = self:_GetAccentColor()

    local height = #self.Actions > 0 and 96 or 74
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, height)
    toast.BackgroundColor3 = self.Theme.Default
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel = 0
    toast.Parent = root
    self.Utilities:CreateCorner(toast, 8)
    self.Utilities:CreateStroke(toast, self.Theme.Border)

    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(0, 4, 1, 0)
    strip.BackgroundColor3 = accent
    strip.BorderSizePixel = 0
    strip.Parent = toast

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 28, 0, 28)
    icon.Position = UDim2.new(0, 12, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Text = typeIcons[self.Type] or typeIcons.info
    icon.TextColor3 = accent
    icon.TextSize = 13
    icon.Font = Enum.Font.GothamBold
    icon.Parent = toast

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 18)
    title.Position = UDim2.new(0, 48, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = toast

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -70, 0, #self.Actions > 0 and 32 or 38)
    content.Position = UDim2.new(0, 48, 0, 28)
    content.BackgroundTransparency = 1
    content.Text = self.Content
    content.TextColor3 = self.Theme.Text
    content.TextSize = 12
    content.Font = Enum.Font.Gotham
    content.TextWrapped = true
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.Parent = toast

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 20, 0, 20)
    close.Position = UDim2.new(1, -10, 0, 8)
    close.AnchorPoint = Vector2.new(1, 0)
    close.BackgroundTransparency = 1
    close.Text = "X"
    close.TextColor3 = self.Theme.Text
    close.TextSize = 12
    close.Font = Enum.Font.GothamBold
    close.Parent = toast

    if #self.Actions > 0 then
        local actionBar = Instance.new("Frame")
        actionBar.Size = UDim2.new(1, -58, 0, 24)
        actionBar.Position = UDim2.new(0, 48, 1, -30)
        actionBar.BackgroundTransparency = 1
        actionBar.Parent = toast

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 6)
        layout.Parent = actionBar

        for _, action in ipairs(self.Actions) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 64, 1, 0)
            button.BackgroundColor3 = self.Theme.Second
            button.BorderSizePixel = 0
            button.Text = action.Label or action.ActionId or "Action"
            button.TextColor3 = self.Theme.Text
            button.TextSize = 11
            button.Font = Enum.Font.GothamBold
            button.Parent = actionBar
            self.Utilities:CreateCorner(button, 5)

            button.MouseButton1Click:Connect(function()
                if action.ActionId == "Copy" and setclipboard then
                    pcall(setclipboard, self.Content)
                end
                if action.Callback then
                    action.Callback(self)
                end
                self:Dismiss()
            end)
        end
    end

    close.MouseButton1Click:Connect(function()
        self:Dismiss()
    end)

    self.Toast = toast
    toast.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0
    }):Play()

    if self.Duration > 0 then
        task.delay(self.Duration, function()
            if self.Toast and self.Toast.Parent then
                self:Dismiss()
            end
        end)
    end

    return self
end

function Notification:Dismiss()
    if not self.Toast or not self.Toast.Parent then
        return
    end

    local toast = self.Toast
    self.Toast = nil

    TweenService:Create(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 20, 0, 0),
        BackgroundTransparency = 1
    }):Play()

    task.delay(0.2, function()
        if toast and toast.Parent then
            toast:Destroy()
        end
    end)
end

function Notification:Show(title, content, notificationType, duration)
    return Notification.new({
        Title = title,
        Content = content,
        Type = notificationType,
        Duration = duration
    }, self.Theme, self.Utilities):Create()
end

function Notification:Notify(config)
    return Notification.new(config, self.Theme, self.Utilities):Create()
end

function Notification:Success(title, content, duration)
    return self:Show(title, content, "success", duration)
end

function Notification:Warning(title, content, duration)
    return self:Show(title, content, "warning", duration)
end

function Notification:Error(title, content, duration)
    return self:Show(title, content, "error", duration)
end

function Notification:Info(title, content, duration)
    return self:Show(title, content, "info", duration)
end

return Notification
