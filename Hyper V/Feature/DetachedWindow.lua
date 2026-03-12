local DetachedWindow = {}
DetachedWindow.__index = DetachedWindow

local function shiftDescendantZIndex(root, delta, exclusions)
    if delta == 0 then
        return
    end

    exclusions = exclusions or {}

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("GuiObject") and not exclusions[descendant] then
            descendant.ZIndex = descendant.ZIndex + delta
        end
    end
end

local function createTextButton(theme, parent, text, size, position)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = theme.Second
    button.Text = text
    button.TextColor3 = theme.Text
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = parent
    return button
end

function DetachedWindow.new(config, context)
    local self = setmetatable({}, DetachedWindow)

    self.Config = config or {}
    self.HyperV = context.HyperV or context.Rayfield
    self.Rayfield = self.HyperV
    self.Theme = context.Theme
    self.Utilities = context.Utilities
    self.Title = self.Config.Title or "Detached Window"
    self.Size = self.Config.Size or UDim2.new(0, 320, 0, 220)
    self.Position = self.Config.Position or UDim2.new(0.5, -160, 0.5, -110)
    self.Parent = self.Config.Parent or self.HyperV.ScreenGui
    self.Closable = self.Config.Closable ~= false
    self.StackContent = self.Config.StackContent ~= false
    self.TargetLookup = {}
    self.Connections = {}
    self.DragCleanup = nil
    self.DraggingEnabled = true

    self:Create()
    return self
end

function DetachedWindow:Create()
    local frame = Instance.new("Frame")
    frame.Name = self.Config.Name or "DetachedWindow"
    frame.Size = self.Size
    frame.Position = self.Position
    frame.BackgroundColor3 = self.Theme.Main
    frame.BorderSizePixel = 0
    frame.Parent = self.Parent
    frame.ZIndex = self.Config.ZIndex or 20
    self.Utilities:CreateCorner(frame, 8)
    local stroke = self.Utilities:CreateStroke(frame, self.Theme.Border, 1)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 34)
    titleBar.BackgroundColor3 = self.Theme.Default
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    titleBar.ZIndex = frame.ZIndex + 1
    self.Utilities:CreateCorner(titleBar, 8)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -90, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = self.Theme.TitleText
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    titleLabel.ZIndex = frame.ZIndex + 2

    local dockButton = createTextButton(
        self.Theme,
        titleBar,
        self.Config.DockButtonText or "Dock",
        UDim2.new(0, 46, 0, 24),
        UDim2.new(1, -84, 0.5, -12)
    )
    dockButton.ZIndex = frame.ZIndex + 2
    self.Utilities:CreateCorner(dockButton, 6)

    local closeButton = createTextButton(
        self.Theme,
        titleBar,
        "X",
        UDim2.new(0, 24, 0, 24),
        UDim2.new(1, -32, 0.5, -12)
    )
    closeButton.TextColor3 = Color3.fromRGB(255, 110, 110)
    closeButton.Visible = self.Closable
    closeButton.ZIndex = frame.ZIndex + 2
    self.Utilities:CreateCorner(closeButton, 6)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -50)
    content.Position = UDim2.new(0, 8, 0, 42)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = false
    content.Parent = frame
    content.ZIndex = frame.ZIndex + 1

    if self.StackContent then
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = content
    end

    local dockMenu = Instance.new("Frame")
    dockMenu.Name = "DockMenu"
    dockMenu.Size = UDim2.new(0, 180, 0, 0)
    dockMenu.Position = UDim2.new(1, -188, 0, 38)
    dockMenu.BackgroundColor3 = self.Theme.Default
    dockMenu.BorderSizePixel = 0
    dockMenu.Visible = false
    dockMenu.AutomaticSize = Enum.AutomaticSize.Y
    dockMenu.Parent = frame
    dockMenu.ZIndex = frame.ZIndex + 5
    self.Utilities:CreateCorner(dockMenu, 6)
    self.Utilities:CreateStroke(dockMenu, self.Theme.Border, 1)
    local menuPadding = Instance.new("UIPadding")
    menuPadding.PaddingTop = UDim.new(0, 6)
    menuPadding.PaddingBottom = UDim.new(0, 6)
    menuPadding.PaddingLeft = UDim.new(0, 6)
    menuPadding.PaddingRight = UDim.new(0, 6)
    menuPadding.Parent = dockMenu
    local menuLayout = Instance.new("UIListLayout")
    menuLayout.Padding = UDim.new(0, 4)
    menuLayout.Parent = dockMenu

    self.Frame = frame
    self.Stroke = stroke
    self.TitleBar = titleBar
    self.TitleLabel = titleLabel
    self.DockButton = dockButton
    self.CloseButton = closeButton
    self.Content = content
    self.DockMenu = dockMenu

    table.insert(self.Connections, dockButton.MouseButton1Click:Connect(function()
        self:ToggleDockMenu()
    end))

    table.insert(self.Connections, closeButton.MouseButton1Click:Connect(function()
        if self.Config.OnCloseRequested then
            local shouldContinue = self.Config.OnCloseRequested(self)
            if shouldContinue == false then
                return
            end
        end
        self:Destroy()
    end))

    self.DragCleanup = self.Utilities:MakeDraggable(frame, titleBar, {
        canDrag = function()
            return self.DraggingEnabled
        end,
        onDragStart = function(input, startPos)
            self:BringToFront()
            if self.Config.OnDragStart then
                self.Config.OnDragStart(self, input, startPos)
            end
        end,
        onDragMove = function(input, newPosition, delta)
            if self.Config.OnDragMove then
                self.Config.OnDragMove(self, input, newPosition, delta)
            end
        end,
        onDragEnd = function(input, endPosition)
            if self.Config.OnDragEnd then
                self.Config.OnDragEnd(self, input, endPosition)
            end
        end,
    })

    if self.Config.Content then
        self:SetContent(self.Config.Content)
    end
end

function DetachedWindow:BringToFront()
    if self.Frame then
        local frameDelta = 30 - self.Frame.ZIndex
        local titleDelta = 31 - self.TitleBar.ZIndex
        local contentDelta = 31 - self.Content.ZIndex
        local dockMenuDelta = 35 - self.DockMenu.ZIndex

        shiftDescendantZIndex(self.Frame, frameDelta, {
            [self.TitleBar] = true,
            [self.Content] = true,
            [self.DockMenu] = true,
        })
        shiftDescendantZIndex(self.TitleBar, titleDelta)
        shiftDescendantZIndex(self.Content, contentDelta)
        shiftDescendantZIndex(self.DockMenu, dockMenuDelta)

        self.Frame.ZIndex = 30
        self.TitleBar.ZIndex = 31
        self.Content.ZIndex = 31
        self.DockMenu.ZIndex = 35
        self.TitleLabel.ZIndex = 32
        self.DockButton.ZIndex = 32
        self.CloseButton.ZIndex = 32
    end
end

function DetachedWindow:SetTitle(title)
    self.Title = title
    if self.TitleLabel then
        self.TitleLabel.Text = title
    end
end

function DetachedWindow:SetContent(guiObject)
    if not guiObject then
        return
    end

    guiObject.Parent = self.Content
    guiObject.Position = UDim2.new(0, 0, 0, 0)
end

function DetachedWindow:RefreshDockMenu()
    for _, child in ipairs(self.DockMenu:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    self.TargetLookup = {}

    local targets = {}
    if self.Config.GetDockTargets then
        targets = self.Config.GetDockTargets(self) or {}
    end

    if #targets == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 24)
        empty.BackgroundTransparency = 1
        empty.Text = "No dock targets"
        empty.TextColor3 = self.Theme.Text
        empty.TextSize = 12
        empty.Font = Enum.Font.Gotham
        empty.Parent = self.DockMenu
        empty.ZIndex = self.Frame.ZIndex + 6
        return
    end

    for index, target in ipairs(targets) do
        self.TargetLookup[index] = target

        local button = Instance.new("TextButton")
        button.Name = "DockTarget" .. index
        button.Size = UDim2.new(1, 0, 0, 26)
        button.BackgroundColor3 = self.Theme.Second
        button.BorderSizePixel = 0
        button.Text = target.Title or target.Name or ("Dock " .. index)
        button.TextColor3 = self.Theme.Text
        button.TextSize = 12
        button.Font = Enum.Font.Gotham
        button.AutoButtonColor = false
        button.Parent = self.DockMenu
        button.ZIndex = self.Frame.ZIndex + 6
        self.Utilities:CreateCorner(button, 5)

        table.insert(self.Connections, button.MouseButton1Click:Connect(function()
            self.DockMenu.Visible = false
            if self.Config.OnDockTargetSelected then
                self.Config.OnDockTargetSelected(self, target)
            end
        end))
    end
end

function DetachedWindow:ToggleDockMenu()
    self:RefreshDockMenu()
    self.DockMenu.Visible = not self.DockMenu.Visible
end

function DetachedWindow:Dock(target)
    if self.Config.OnDockTargetSelected then
        self.Config.OnDockTargetSelected(self, target)
    end
end

function DetachedWindow:Undock()
    if self.Config.OnUndockRequested then
        self.Config.OnUndockRequested(self)
    end
end

function DetachedWindow:SetHighlighted(active)
    if self.Stroke then
        self.Stroke.Color = active and self.Theme.Accent or self.Theme.Border
    end
end

function DetachedWindow:SetDraggingEnabled(enabled)
    self.DraggingEnabled = enabled ~= false
end

function DetachedWindow:Destroy()
    if self.DragCleanup then
        self.DragCleanup()
        self.DragCleanup = nil
    end

    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}

    if self.Frame then
        self.Frame:Destroy()
        self.Frame = nil
    end
end

return DetachedWindow
